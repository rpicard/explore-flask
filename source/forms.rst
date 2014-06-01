Handling forms
==============

.. figure:: images/forms.png
   :alt: Handling forms

   Handling forms
The form is the basic element that lets users interact with our web
application. Flask alone doesn't do anything to help us handle forms,
but the Flask-WTF extension lets us use the popular WTForms package in
our Flask applications. This package makes defining forms and handling
submissions easy.

Flask-WTF
---------

The first thing we want to do with Flask-WTF (after installing it) is to
define a form in a ``myapp.forms`` package.

.. raw:: latex

   \begin{codelisting}
   \label{code:form1}
   \codecaption{Defining our first form}
   ```python
   # ourapp/forms.py

   from flask.ext.wtforms import Form
   from wtforms import TextField, PasswordField, Required, Email

   class EmailPasswordForm(Form):
       email = TextField('Email', validators=[Required(), Email()])
       password = PasswordField('Password', validators=[Required()])
   ```
   \end{codelisting}

.. raw:: latex

   \begin{aside}
   \label{aside:callables}
   \heading{A note on returning callables}

   Our validator doesn't have to be a callable class. It could also be a factory that returns a callable or just a callable directly. See some examples here: [http://wtforms.simplecodes.com/docs/0.6.2/validators.html#custom-validators](http://wtforms.simplecodes.com/docs/0.6.2/validators.html#custom-validators)

   \end{aside}

Rendering forms
~~~~~~~~~~~~~~~

WTForms can also help us render the HTML for the forms. The ``Field``
class implemented by WTForms renders an HTML representation of that
field, so we just have to call the form fields to render them in our
template. It's just like rendering the ``csrf_token`` field. Listing~
gives an example of a login template using WTForms to render our fields.

\\begin{codelisting}

.. code:: jinja

    {# ourapp/templates/login.html #}

    {% extends "layout.html" %}
    <html>
        <head>
            <title>Login Page</title>
        </head>
        <body>
            <form action="" method="POST">
                {{ form.email }}
                {{ form.password }}
                {{ form.csrf_token }}
            </form>
        </body>
    </html>

\\end{codelisting}

We can customize how the fields are rendered by passing field properties
as arguments to the call.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Adding a \texttt{placeholder} property to the email field}
   ```jinja
   <form action="" method="POST">
       {{ form.email.label }}: {{ form.email(placeholder='yourname@email.com') }}
       <br>
       {{ form.password.label }}: {{ form.password }}
       <br>
       {{ form.csrf_token }}
   </form>
   ```
   \end{codelisting}

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on adding a class property}

   If we want to pass the "class" HTML attribute, we have to use `class_=''` since "class" is a reserved keyword in Python.

   \end{aside}

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on Jinja's \texttt{|safe} filter}

   You may notice that we don't need to use Jinja's `|safe` filter. This is because WTForms renders HTML safe strings.

   See more here: [http://pythonhosted.org/Flask-WTF/#using-the-safe-filter](http://pythonhosted.org/Flask-WTF/#using-the-safe-filter)

   \end{aside}

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

