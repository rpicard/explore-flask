# Patterns for handling users

One of the most common things that modern web applications need to do is handle users. An application with basic account features needs to handle a lot of things like registration, email confirmation, securely storing passwords, secure password reset, authentication and more. Since a lot of security issues present themselves when it comes to handling users, it's generally best to stick to standard patterns in this area.

{ NOTE: In this chapter I'm going to assume that you're using SQLAlchemy models and WTForms to handle your form input. If you aren't using those, you'll need to adapt these patterns to your preferred methods.}

## Email confirmation

When a new user gives you their email, you generally want to confirm that they gave you the right one. Once you have made that confirmation, you can confidently send password reset links and other sensitive information to your users without wondering who is on the receiving end.

One of the most common patterns for confirming emails is to send a password reset link with a unique URL that, when visited, confirms that user's email address. For example, john@gmail.com signs up at your application. Your application registers him in the database with an `email_confirmed` column set to `False` and fires off an email to john@gmail.com with a unique URL. This URL usually contains a unique token, e.g. http://myapp.com/accounts/confirm/kj3kjhj3hj3. When John gets that email, he clicks the link. Your app sees the token, knows which email to confirm and sets John's `email_confirmed` column to `True`.

How do we know which email to confirm with a given token? One way would be to store the token in the database when it is created and check the database when we receive the confirmation request. That's a lot of overhead and, lucky for us, it's unnecessary.

We're going to create a token that actually includes the email address. It'll also contain a timestamp to let us set a time limit on how long the token is valid. To do this, we'll use the `itsdangerous` package. This package gives us tools to send sensitive data into untrusted environments (like sending an email confirmation token to an unconfirmed email). In this case, we're going to use a `URLSafeTimedSerializer`.

_myapp/util/security.py_
```
from itsdangerous import URLSafeTimedSerializer

from .. import app

serializer = URLSafeTimedSerializer(app.config["SECRET_KEY"])
```

Now we can use that serializer to generate a confirmation token when a user gives us their email address.

## Storing passwords

Rule number one of handling users is to hash passwords with the Bcrypt algorithm before storing them. You never store passwords in plain text. It's a massive security issue and it's unfair to your users. All of the hard work has already been done and abstracted away for us, so there's no excuse for not following the best practices here.

{ SEE MORE: OWASP is one of the industry's most trusted source for information regarding web application security. Take a look at some of their recommendations for secure coding here: https://www.owasp.org/index.php/Secure_Coding_Cheat_Sheet#Password_Storage }

We'll go ahead and use the Flask-Bcrypt extension to implement the bcrypt package in our application. This extension is basically just a wrapper around the `py-bcrypt` package, but it does handle a few things that would be annoying to do ourselves (like checking string encodings before comparing hashes).

myapp/__init__.py
```
from flask.ext.bcrypt import Bcrypt

bcrypt = Bcrypt(app)
```

One of the reasons that the Bcrypt algorithm is so highly recommended is that it is "future adaptable." This means that over time, as computing power becomes cheaper we can make it more and more difficult to brute force the hash by guessing millions of possible passwords. The more "rounds" we use to hash the password, the longer it will take to perform one iteration of a guess. If we hash our passwords 20 times with the algorithm before storing them the attacker has to hash each of their guesses 20 times.

Keep in mind that if we're hashing our passwords 20 times then our application is going to take a long time to return a response that depends on that process completing. This means that when choosing the number of rounds to use, we have to balance security and usability. The number of rounds you can complete in a given amount of time will depend on the computational resources available to your application, so it's best to test out some different numbers and shoot for between 0.25 and 0.5 seconds to hash a password. Try to use at least 12 rounds though.

To test the time it takes to hash a password, you can time a quick Python script that, well, hashes a password.

_benchmark.py_
```
from flask.ext.bcrypt import generate_password_hash

# Chance the number of rounds (second argument) until it takes between 0.25 and 0.5 seconds to run.
generate_password_hash('password1', 12) 
```

Now we can keep timing our changes with the UNIX `time` utility.

```
$ time python test.py 

real    0m0.496s
user    0m0.464s
sys     0m0.024s
```

I did a quick benchmark on a small server that I have handy and 12 rounds seemed to take the right amount of time, so I'll configure our example to use that. 

config.py
```
BCRYPT_LOG_ROUNDS = 12
```

Now that Flask-Bcrypt is configured, it's time to start hashing passwords. We could do this manually in the view function that receives the sign-up form, but we would have to repeat that code in the password reset and password change views. Instead, what we'll do is abstract away the hashing so that our app does it without us even thinking about it. We'll use a **setter** so that when we set `user.password = 'password1'`, it is automatically hashed with BCrypt before being stored.

myapp/models.py
```
from sqlalchemy.ext.hybrid import hybrid_property

from . import bcrypt, db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username = db.Column(db.String(64), unique=True)
    _password = db.Column(db.String(128))

    @hybrid_property
    def password(self):
        return self._password

    @password.setter
    def _set_password(self, plaintext):
        self._password = bcrypt.generate_password_hash(plaintext)
```

We're using SQLAlchemy's hybrid extension to define a property with several different functions called from the same interface.. Our setter is called when we assign a value to the `user.password` property. In it, we hash the plaintext password and store it in the `_password` column of the user table. Since we're using a hybrid property we can then access the hashed password via the same `user.password` property.

Now we can implement a sign-up view for an app using this model.

myapp/views.py
```
from . import app, db
from .forms import EmailPasswordForm
from .models import User

@app.route('/signup', methods=["GET", "POST"])
def signup():
    form = EmailPasswordForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, password=form.password.data)
        db.session.add(user)
        db.session.commit()
        return redirect(url_for('index'))

    return render_template('signup.html', form=form)
```

## Authentication

Now that we've got a user in the database, we can implement authentication. We'll want to let a user submit a form with their username and password (though this might be email and password for some apps), then make sure that they gave us the correct password. If it all checks out, we'll mark them as authenticated by setting a cookie in their browser. The next time they make a request we'll know that they have already logged in by looking for that cookie.

Let's start by defining a `UsernamePassword` form with WTForms.

myapp/forms.py
```
from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required

class UsernamePasswordForm(Form):
    username = TextField('Username', validators=[Required()])
    password = PasswordField('Password', validators=[Required()])
```

Next we'll add a method to our user model that compares a given plaintext password with the hashed password stored for that user.

myapp/models.py
```
from . import db

class User(db.Model):

    # [...] columns and properties

    def is_correct_password(self, plaintext)
        if bcrypt.check_password_hash(self._password, plaintext):
            return True

        return False
```

### Flask-Login

Our next goal is to define a sign-in view that serves and accepts our form. If the user enters the correct credentials, we will authenticate them using the Flask-Login extension. This extension simplifies the process of handling user sessions and authentication.

We need to do a little bit of configuration to get Flask-Login ready to roll.

In *__init__.py* we will define the Flask-Login `login_manager`.

*myapp/__init__.py*
```
from flask.ext.login import LoginManager

# Create and configure app
# [...]

from .models import User

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view =  "signin"

@login_manager.user_loader
def load_user(userid):
    return User.query.filter(User.id == userid).first()
```

Here we created an instance of the `LoginManager`, initialized it with our `app` object, defined the login view and told it how to get a user object with a user's `id`. This is the baseline configuration you should have for Flask-Login.

{ SEE MORE: You can see more ways to customize Flask-Login here: https://flask-login.readthedocs.org/en/latest/#customizing-the-login-process } 

Now we can define the `signin` view that will handle authentication.

_myapp/views.py_
```
from flask import redirect, url_for

from flask.ext.login import login_user

from . import app
from .forms import UsernamePasswordForm()

@app.route('signin', methods=["GET", "POST"])
def signin():
    form = UsernamePasswordForm()

    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first_or_404()
        if user.is_correct_password(form.password.data):
            login_user(user)

            return redirect(url_for('index'))
        else:
            return redirect(url_for('signin'))
    return render_template('signin.html', form=form)
```

We simply import the `login_user` function from Flask-Login, check a user's login credentials and call `login_user(user)`. You can log the current user out with `logout_user()`.

_myapp/views.py_
```
from flask import redirect, url_for
from flask.ext.login import logout_user

from . import app

@app.route('/signout')
def signout():
    logout_user()

    return redirect(url_for('index'))
```

{ NOTE: This simple implementation of logout is vulnerable to a CSRF where someone gets a user's browser to load an image with the source http://yourapp.com/signout, thereby signing them out of your application

Many web apps are content to leave their sites vulnerable to a logout CSRF because it is harmless (just a little annoying) and there are some technicalities that can make it futile to try and defend against. Google is one example of such a site. You can see more on Google's list of vulnerabilities that don't qualify for their bug bounty program: http://www.google.com/about/appsecurity/reward-program/#notavuln

You can also read more about these technicalities here: http://scarybeastsecurity.blogspot.com/2010/01/logout-xsrf-significant-web-app-bug.html }

## Forgot your password

You'll generally want to implement a "Forgot your password" feature that lets a user who forgot their password recover their account. This area is ripe for vulnerabilities because the whole point is to let an unauthenticated user take over an account; we just want that user to be the person who is supposed to own the account. We'll implement our password reset using some of the same techniques as our email confirmation. We'll need a form to request a reset for a given account based on that account's email or username and a form to choose a new password once we've confirmed that the unauthenticated user is the right person. This assumes that our user model has an email and a password, where the password is a hybrid property as we previously created.

We're going to need two forms. One is to request a reset link and the other is to perform the reset.

myapp/forms.py
```
from flask.ext.wtforms import Form

from wtforms import TextField, PasswordField, Required, Email

class EmailForm(Form):
    email = TextField('Email', validators=[Required(), Email()])

class PasswordForm(Form):
    password = PasswordField('Email', validators=[Required()])
```

I'm assuming that our password reset form just needs one field for the password. Many apps require the user to enter their new password twice to confirm that they haven't made a typo (because you can't see the contents of a password input field). To do this, we'd simply add another PasswordField and add the EqualTo WTForms validator to the main password field.

{ SEE ALSO: There a lot of interesting discussions in the User Experience (UX) community about the best way to handle this. I personally like the thoughts of one Stack Exchange user (Roger Attrill) who said, "We should not ask for password twice - we should ask for it once and make sure that the 'forgot password' system works seamlessly and flawlessly."

* You can read more about this topic in this thread on the User Experience Stack Exchange (whence the quote came): http://ux.stackexchange.com/questions/20953/why-should-we-ask-the-password-twice-during-registration/21141

* There are also some cool ideas for simplifying the sign-ups and sign-ins in this Smashing Magazine article: http://uxdesign.smashingmagazine.com/2011/05/05/innovative-techniques-to-simplify-signups-and-logins/ }

Now we'll implement the first view of our process, where a user can request a password reset for a given email address.

myapp/views.py
```
from flask import redirect, url_for, render_template

from . import app
from .forms import EmailForm
from .models import User

@app.route('/reset', methods=["GET", "POST"])
def reset():
    form = RequestPasswordResetForm()
    if form.validate_on_submit()
        user = User.query.filter_by(email=form.email.data).first_or_404()
        { IMPLEMENT SEND EMAIL }

        return redirect(url_for('index'))
    return render_template('reset.html', form=form)
```

When the user submits their email address, we grab the user with that email address and send them a password reset URL. That URL has a special token that we can validate in the next view.

myapp/views.py
```
from flask import redirect, url_for, render_template

from . import app, db
from .forms import PasswordForm
from .models import User

@app.route('/reset/<token>')
def reset_with_token(token):
    try:
        email = serializer.loads(token, salt="reset-key", max_age=86400)
    except:
        abort(404)

    form = ResetPasswordForm()

    if form.validate_on_submit():
        user = User.query.filter_by(email=email).first_or_404()

        user.password = form.password.data

        db.session.add(user)
        db.session.commit()

        return redirect(url_for('signin'))

    return render_template('reset_with_token.html', form=form, token=token)
```

This view is a simple form view. We just add the bit at the beginning to check that the token is valid. The token contains a timestamp, so we can tell loads() to raise an exception if it is older than max_age. In this case, we're setting max_age to 86400 seconds, i.e. 24 hours.

We pass the token to the template so that we can submit the form to the correct URL. Let's have a look at what that template might look like.

myapp/templates/reset_with_token.html
```
{% extends "layout.html" %}

{% block body %}
<form action="{{ url_for('reset_with_token', token=token) }}" method="POST">
    {{ form.password.label }}: {{ form.password }}<br>
    {{ form.csrf_token }}
    <input type="submit" value="Change my password" />
</form>
{% endblock %}
```

## Email resets

You'll also want to allow users to change the email address associated with their account. For this feature, you definitely want to require that the user is signed-in before letting them make any changes. What we'll do is let the authenticated user submit a form with a new email address. If that form is validated, we'll send a confirmation link to that new address and, when it's clicked we'll update the user's email address in the database. Let's start by defining the view with the email reset request form.

myapp/views.py
```
from flask.ext.login import login_required

from . import app
from .forms import EmailForm

@app.route('/account/email', methods=["GET", "POST"])
def account_email():
    form = EmailForm()

    if form.validate_on_submit():
        { IMPLEMENT SENDING NEW EMAIL TOKEN }
        return redirect(url_for('account_email'))

    return render_template('account/email.html', form=form)
```

Notice that we are able to re-use our EmailForm from the password reset. That's the benefit of keeping our form definitions abstract. We simply generate a serialized token that contains both the old email address and the new one. We need to include the old email address so that we can confirm that the user who is using the token is the same user who created it.

{ CONTINUE: Implement view that receives the token and updates the email address. }