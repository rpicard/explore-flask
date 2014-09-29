
.. highlight:: python
    :linenothreshold: 0

Handling forms
==============

.. image:: _static/images/forms.png
   :alt: Handling forms

The form is the basic element that lets users interact with our web
application. Flask alone doesn't do anything to help us handle forms,
but the Flask-WTF extension lets us use the popular WTForms package in
our Flask applications. This package makes defining forms and handling
submissions easy.

Flask-WTF
---------

The first thing we want to do with Flask-WTF (after installing it) is to
define a form in a ``myapp.forms`` package.

::

   # ourapp/forms.py

   from flask_wtf import Form
   from wtforms import StringField, PasswordField
   from wtforms.validators import DataRequired, Email

   class EmailPasswordForm(Form):
       email = StringField('Email', validators=[DataRequired(), Email()])
       password = PasswordField('Password', validators=[DataRequired()])

.. note::

   Until version 0.9, Flask-WTF provided its own wrappers around the WTForms fields and validators. You may see a lot of code out in the wild that imports ``TextField``, ``PasswordField``, etc. from ``flask.ext.wtforms`` instead of ``wtforms``.

   As of 0.9, we should be importing that stuff straight from ``wtforms``.

The form we defined is going to be a user sign-in form. We could have
called it ``SignInForm()``, but by keeping things a little more
abstract, we can re-use this same form class for other things, like a
sign-up form. If we were to define purpose-specific form classes we'd
end up with a lot of identical forms for no good reason. It's much
cleaner to name forms based on the fields they contain, as that is what
makes them unique. Of course, sometimes we'll have long, one-off forms
that we might want to give a more context-specific name.

This sign-in form can do a few of things for us. It can secure our app
against CSRF vulnerabilites, validate user input and render the
appropriate markup for whatever fields we define for it.

CSRF Protection and validation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CSRF stands for cross site request forgery. CSRF attacks involve a third
party forging a request (like a form submission) to an app's server. A
vulnerable server assumes that the data is coming from a form on its own
site and takes action accordingly.

As an example, let's say that an email provider lets you delete your
account by submitting a form. The form sends a POST request to an
``account_delete`` endpoint on their server and deletes the account
that was logged-in when the form was submitted. We can create a form on
our own site that sends a POST request to the same ``account_delete``
endpoint. Now, if we can get someone to click 'submit' on our form (or
do it via JavaScript when they load the page) their logged-in account
with the email provider will be deleted. Unless of course the email
provider knows not to assume that form submissions are coming from their
own forms.

So how do we stop assuming that POST requests come from our own forms?
WTForms makes it possible by generating a unique token when rendering
each form. That token is meant to be passed back to the server, along
with the form data in the POST request and must be validated before the
form is accepted. The key is that the token is tied to a value stored in
the user's session (cookies) and expires after a certain amount of time
(30 minutes by default). This way the only person who can submit a valid
form is the person who loaded the page (or at least someone at the same
computer), and they can only do it for 30 minutes after loading the
page.

.. note::

   - Read more on how WTForms generates these tokens `in the docs <http://wtforms.simplecodes.com/docs/1.0.1/ext.html#module-wtforms.ext.csrf.session>`_.

   - Learn about CSRF in the `OWASP wiki <https://www.owasp.org/index.php/CSRF>`_.

To start using Flask-WTF for CSRF protection, we'll need to define a
view for our login page.

::

   # ourapp/views.py

   from flask import render_template, redirect, url_for

   from . import app
   from .forms import EmailPasswordForm

   @app.route('/login', methods=["GET", "POST"])
   def login():
       form = EmailPasswordForm()
       if form.validate_on_submit():

           # Check the password and log the user in
           # [...]

           return redirect(url_for('index'))
       return render_template('login.html', form=form)

We import our form from our ``forms`` package and instantiate it in the
view. Then we run ``form.validate_on_submit()``. This function returns
``True`` if the form has been both submitted (i.e. if the HTTP method is
PUT or POST) and validated by the validators we defined in *forms.py*.

.. note::

   - `Documentation for Form.validate_on_submit <https://flask-wtf.readthedocs.org/en/latest/api.html#flask_wtf.Form.validate_on_submit>`_
   - `Source for Form.validate_on_submit <https://github.com/lepture/flask-wtf/blob/v0.9.5/flask_wtf/form.py#L151>`_

If the form has been submitted and validated, we can continue with the
login logic. If it hasn't been submitted (i.e. it's just a GET request),
we want to pass the form object to our template so it can be rendered.
Here's what the template looks like when we're using CSRF protection.

::

    {# ourapp/templates/login.html #}

    {% extends "layout.html" %}
    <html>
        <head>
            <title>Login Page</title>
        </head>
        <body>
            <form action="{{ url_for('login') }}" method="post">
                <input type="text" name="email" />
                <input type="password" name="password" />
                {{ form.csrf_token }}
            </form>
        </body>
    </html>

``{{ form.csrf_token }}`` renders a hidden field containing one of those
fancy CSRF tokens and WTForms looks for that field when it validates the
form. We don't have to worry about including any special "is the token
valid" logic. Hooray!

Protecting AJAX calls with CSRF tokens
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Flask-WTF CSRF tokens aren't limited to protecting form submissions. If
your app makes other requests that might be forged (especially AJAX
calls) you can add CSRF protection there too!

.. note::

    The Flask-WTF documentation talks more about `using these CSRF tokens in AJAX calls <https://flask-wtf.readthedocs.org/en/latest/csrf.html#ajax>`_.

Custom validators
~~~~~~~~~~~~~~~~~

In addition to the built-in form validators provided by WTForms (e.g.
``Required()``, ``Email()``, etc.), we can create our own validators.
We'll demonstrate this by making a ``Unique()`` validator that will
check a database and make sure that the value provided by the user
doesn't already exist. This could be used to make sure that a username
or email address isn't already in use. Without WTForms, we'd probably be
doing these checks in the view, but now we can abstract that away to the
form itself.

We'll start by defining a simple sign-up form.

::

   # ourapp/forms.py

   from flask_wtf import Form
   from wtforms import StringField, PasswordField
   from wtforms.validators import DataRequired, Email

   class EmailPasswordForm(Form):
       email = StringField('Email', validators=[DataRequired(), Email()])
       password = PasswordField('Password', validators=[DataRequired()])

Now we want to add our validator to make sure that the email they
provide isn't already in the database. We'll put the validator in a new
``util`` module, ``util.validators``.

::

    # ourapp/util/validators.py
    from wtforms.validators import ValidationError

    class Unique(object):
        def __init__(self, model, field, message=u'This element already exists.'):
            self.model = model
            self.field = field

        def __call__(self, form, field):
            check = self.model.query.filter(self.field == field.data).first()
            if check:
                raise ValidationError(self.message)

This validator assumes that we're using SQLAlchemy to define our models.
WTForms expects validators to return some sort of callable (e.g. a
callable class).

In *\_\_init\_\_.py* we can specify which arguments should be passed to
the validator. In this case we want to pass the relevant model (e.g. the
``User`` model in our case) and the field to check. When the validator
is called, it will raise a ``ValidationError`` if any instance of the
defined model matches the value submitted in the form. We've also made
it possible to add a message with a generic default that will be
included in the ``ValidationError``.

Now we can modify ``EmailPasswordForm`` to use the ``Unique`` validator.

::

   # ourapp/forms.py

   from flask_wtf import Form
   from wtforms import StringField, PasswordField
   from wtforms.validators import DataRequired

   from .util.validators import Unique
   from .models import User

   class EmailPasswordForm(Form):
       email = StringField('Email', validators=[DataRequired(), Email(),
           Unique(
               User,
               User.email,
               message='There is already an account with that email.'])
       password = PasswordField('Password', validators=[DataRequired()])

.. note::

   Our validator doesn't have to be a callable class. It could also be a factory that returns a callable or just a callable directly. The WTForms documentation has `some examples <http://wtforms.simplecodes.com/docs/0.6.2/validators.html#custom-validators>`_.

Rendering forms
~~~~~~~~~~~~~~~

WTForms can also help us render the HTML for the forms. The ``Field``
class implemented by WTForms renders an HTML representation of that
field, so we just have to call the form fields to render them in our
template. It's just like rendering the ``csrf_token`` field. Listing~
gives an example of a login template using WTForms to render our fields.

::

    {# ourapp/templates/login.html #}

    {% extends "layout.html" %}
    <html>
        <head>
            <title>Login Page</title>
        </head>
        <body>
            <form action="" method="post">
                {{ form.email }}
                {{ form.password }}
                {{ form.csrf_token }}
            </form>
        </body>
    </html>

We can customize how the fields are rendered by passing field properties
as arguments to the call.

::

   <form action="" method="post">
       {{ form.email.label }}: {{ form.email(placeholder='yourname@email.com') }}
       <br>
       {{ form.password.label }}: {{ form.password }}
       <br>
       {{ form.csrf_token }}
   </form>

.. note::

   If we want to pass the "class" HTML attribute, we have to use ``class_=''`` since "class" is a reserved keyword in Python.

.. note::

   The WTForms documentation has a `list of available field properties <http://wtforms.simplecodes.com/docs/1.0.4/fields.html#wtforms.fields.Field.name>`_.

.. note::

   You may notice that we don't need to use Jinja's ``|safe`` filter. This is because WTForms renders HTML safe strings.

   Read more `in the documentation <https://flask-wtf.readthedocs.org/en/v0.8.4/#using-the-safe-filter>`_.

Summary
-------

-  Forms can be scary from a security perspective.
-  WTForms (and Flask-WTF) make it easy to define, secure and render
   your forms.
-  Use the CSRF protection provided by Flask-WTF to secure your forms.
-  You can use sFlask-WTF to protect AJAX calls against CSRF attacks
   too.
-  Define custom form validators to keep validation logic out of your
   views.
-  Use the WTForms field rendering to render your form's HTML so you
   don't have to update it every time you make some changes to the form
   definition.

