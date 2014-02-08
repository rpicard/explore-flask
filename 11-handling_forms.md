# Handling forms

The form is the basic element that lets users interact with your web application. Flask alone doesn't do anything to help you handle forms, but the Flask-WTF extension lets us use the popular WTForms package in our Flask applications. This package makes defining forms and handling submissions easy.

## Flask-WTF

The first thing you want to do with Flask-WTF (after installing it) is to define a form in a myapp.forms package.

myapp/forms.py
```
from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required, Email

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email()])
    password = PasswordField('Password', validators=[Required()])
```

{ NOTE: Until version 0.9, Flask-WTF provided its own wrappers around the WTForms fields and validators. You may see a lot of code out in the wild that imports `TextField`, `PasswordField`, etc. from `flask.ext.wtforms` instead of `wtforms`. You should be importing that stuff straight from `wtforms`. }

This form is going to be a user sign-in form. We could have called it `SignInForm()`, but by keeping things a little more abstract, we can re-use this same form class for other things, like a sign-up form. If we were to define purpose-specific form classes we'd end up with a lot of identical forms for no good reason. It's much cleaner to name forms based on the fields they contain, as that is what makes them unique. Of course, sometimes you'll have long, one-off forms that you might want to give a more context-specific name.

This form can do a few of things for us. It can secure our app against CSRF vulnerabilites, validate user input and render the appropriate markup for whatever fields we define here.

### CSRF Protection and validation

CSRF stands for cross site request forgery. CSRF attacks involve a third party forging a form submission by posting data to an app's server. A vulnerable server assumes that the data is coming from a form on its own site and takes action accordingly.

As an example, let's say that your email provider lets you delete your account by submitting a form. The form sends a POST request to an `account_delete` endpoint on their server and deletes the account that was logged-in when the form was submitted. You can create a form on your own site that sends a POST request to the same `account_delete` endpoint. Now, if you can get someone to click 'submit' on your form (or do it via JavaScript when they load your page) their logged-in account with the email provider will be deleted. Unless of course your email provider knows not to assume that form submissions are coming from their own forms.

So how do we stop assuming that POST requests come from our own forms? WTForms makes it possible by generating a unique token when rendering each form. That token is then passed along with the form data in the POST request and must be validated before the form is accepted. The key is that the token is tied to a value stored in the user's session (cookies) and expires after a certain amount of time (30 minutes by default). This way the only person who can submit a valid form is the person who loaded the page (or at least someone at the same computer), and they can only do it for 30 minutes after loading the page.

{ SEE ALSO:

* Here's the documentation on how WTForms generates these tokens: http://wtforms.simplecodes.com/docs/1.0.1/ext.html#module-wtforms.ext.csrf.session 

* Here's some more information about CSRF: https://www.owasp.org/index.php/CSRF}

To start using Flask-WTF for CSRF protection, we'll need to define a view for our login form.

myapp/views.py
```
from flask import render_template, redirect, url_for

from . import app
from .forms import EmailPasswordForm

@app.route('/login', methods=["GET", "POST"])
def login():
    form = EmailPasswordForm()
    if form.validate_on_submit():
        # Check the password and log the user in
        return redirect(url_for('index'))
    return render_template('login.html', form=form)
```

We import our form from our forms package and instantiate it in the view. Then we run form.validate_on_submit(). This function returns true if the form has been submitted (i.e. if the HTTP method is PUT or POST) and the form validates (remember those validators we defined in forms.py).

{ SEE ALSO: The documentation and source for validate_on_submit():
* http://pythonhosted.org/Flask-WTF/#flask.ext.wtf.Form.validate_on_submit
* https://github.com/ajford/flask-wtf/blob/v0.8.4/flask_wtf/form.py#L120 }

If the form has been submitted and is valid, we can continue with the login logic. If it hasn't been submitted (i.e. it's just a GET request), we want to pass the form object to our template. Here's what the template looks like when we want to make use of that CSRF protection.

myapp/templates/login.html
```
{% extends "layout.html" %}
<html>
    <head>
        <title>Login Page</title>
    </head>
    <body>
        <form action="" method="POST">
            <input type="text" name="email" />
            <input type="password" name="password" />
            {{ form.csrf_token }}
        </form>
    </body>
</html>
```

{ SHOULD THE ACTION BE A url_for() CALL? SOMETHING ELSE? }

form.csrf_token prints out the HTML for a hidden field containing a CSRF token. WTForms looks for that field when it validates the form. We don't actually have to worry about looking for it.

#### Custom validators

In addition to the built-in validators provided by WTForms, you can create your own validators. I'll demonstrate this by making a "Unique" validator that will check the database and make sure that the value provided by the user is unique. This could be used to make sure that there aren't any existing users with a certain email address. Normally, we'd have to do this in the view, but we can abstract that away to the form itself.

Lets start by defining a simple sign-up form.

myapp/forms.py
```
from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required, Email

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email()])
    password = PasswordField('Password', validators=[Required()])
```

Now we want to add a validator to make sure that there isn't already a user account with the email they've submitted. We can put it in a new util module, .util.validators.

myapp/util/validators.py
```
from wtforms.validators import ValidationError

class Unique(object):
    def __init__(self, model, field, message=u'This element already exists'):
        self.model = model
        self.field = field

    def __call__(self, form, field):
        check = self.model.query.filter(self.field == field.data).first()
        if check:
            raise ValidationError(self.message)
```

This validator assumes that you're using SQLAlchemy. WTForms expects validators to return some sort of callable (e.g. a callable class). We can specify which arguments should be passed to the validator. In this case we want the model and field that we should be validating against. If an instance of that model exists where that field matches the value in the form, we will raise a ValidationError because it isn't unique. We also want to make it possible to add an optional message that will be included in the ValidationError. We can default to a generic one that will apply to all cases. We actually perform the validation in the __call__ function. This function is called with the "form" and "field" positional arguments.

Now we can modify our sign-up form to use the Unique validator.

myapp/forms.py
```
from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required, Email

from .util.validators import Unique
from .models import User

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email(), Unique(User, User.email, message='There is already an account with that email.'])
    password = PasswordField('Password', validators=[Required()])
```

{ NOTE: Your validator doesn't have to be a callable class. It could also be a factory that returns a callable or just a callable directly. See some examples here: http://wtforms.simplecodes.com/docs/0.6.2/validators.html#custom-validators }

### Rendering forms

WTForms can also help us render the HTML forms themselves. The Field class implemented by WTForms renders an HTML representation of that field when called, so we just have to call our fields in our template to render it. That's how we were able to render the csrf_token field in the previous section. Here's how that template would look if we used WTForms to render our other fields too.

myapp/templates/login.html
```
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
```

{ SHOW THE RESULTING HTML }

We can also get the values of various properties of each field to help us customize how it's rendered. We can also pass HTML elements as arguments to the field call and they will be rendered with the field. Here's what the form would look like if we wanted to add the field labels and a placeholder:

```
<form action="" method="POST">
    {{ form.email.label }}: {{ form.email(placeholder='yourname@email.com') }}<br>
    {{ form.password.label }}: {{ form.password }}<br>
    {{ form.csrf_token }}
</form>
```

{ COULD WE ALSO ADD PLACEHOLDER AT FIELD DEFINITION? }

{ NOTE: If we want to pass the "class" HTML attribute, we have to use "class_='our_class'" since "class" is a reserved keyword in Python. }

{ SEE ALSO: The documented list of available field properties: http://wtforms.simplecodes.com/docs/1.0.4/fields.html#wtforms.fields.Field.name}

{ NOTE: You may notice that we don't need to use Jinja's |safe filter. This is because WTForms renders HTML safe strings. See more here: http://pythonhosted.org/Flask-WTF/#using-the-safe-filter }

## File uploads

### Ink File Picker

## Summary

Forms can be a little complicated because when we accept arbitrary data, we have to bend over backwards to make sure that it isn't malicious. WTForms and the Flask extension Flask-WTF can make it much easier to define forms. We can define our forms as classes in our application. Then we validate, secure, and render them from that definition. Later we can make changes to the form in one place, and they will propagate to the rest of the application.

{ FINISH SUMMARY TO COVER UPLOADS }