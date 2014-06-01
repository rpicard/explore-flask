Patterns for handling users
===========================

.. figure:: images/users.png
   :alt: Patterns for handling users

   Patterns for handling users
One of the most common things that modern web applications need to do is
handle users. An application with basic account features needs to handle
a lot of things like registration, email confirmation, securely storing
passwords, secure password reset, authentication and more. Since a lot
of security issues present themselves when it comes to handling users,
it's generally best to stick to standard patterns in this area.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on assumptions}

   In this chapter I'm going to assume that you're using SQLAlchemy models and WTForms to handle your form input. If you aren't using those, you'll need to adapt these patterns to your preferred methods.

   \end{aside}

Email confirmation
------------------

When a new user gives us their email, we generally want to confirm that
they gave us the right one. Once we've made that confirmation, we can
confidently send password reset links and other sensitive information to
our users without wondering who is on the receiving end.

One of the most common patterns for confirming emails is to send a
password reset link with a unique URL that, when visited, confirms that
user's email address. For example, john@gmail.com signs up at our
application. We register him in the database with an ``email_confirmed``
column set to ``False`` and fire off an email to john@gmail.com with a
unique URL. This URL usually contains a unique token, e.g.
*http://myapp.com/accounts/confirm-/Q2hhZCBDYXRsZXR0IHJvY2tzIG15IHNvY2tz*.
When John gets that email, he clicks the link. Our app sees the token,
knows which email to confirm and sets John's ``email_confirmed`` column
to ``Tr\-ue``.

How do we know which email to confirm with a given token? One way would
be to store the token in the database when it is created and check that
table when we receive the confirmation request. That's a lot of overhead
and, lucky for us, it's unnecessary.

We're going to encode the email address in the token. The token will
also contain a timestamp to let us set a time limit on how long it's
valid. To do this, we'll use the ``itsdangerous`` package. This package
gives us tools to send sensitive data into untrusted environments (like
sending an email confirmation token to an unconfirmed email). In this
case, we're going to use an instance of the ``URLSafeTimedSerializer``
class.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Creating our instance of \texttt{URLSafeTimedSerializer}}
   ```python
   # ourapp/util/security.py

   from itsdangerous import URLSafeTimedSerializer

   from .. import app

   ts = URLSafeTimedSerializer(app.config["SECRET_KEY"])
   ```
   \end{codelisting}

We can use that serializer to generate a confirmation token when a user
gives us their email address. We'll implement a simple account creation
process using this method.

.. raw:: latex

   \begin{codelisting}
   \label{code:confirm1}
   \codecaption{Sending a verification email during registration}
   ```python
   # ourapp/views.py

   from flask import redirect, render_template, url_for

   from . import app, db
   from .forms import EmailPasswordForm
   from .util import ts, send_email

   @app.route('/accounts/create', methods=["GET", "POST"])
   def create_account():
       form = EmailPasswordForm()
       if form.validate_on_submit():
           user = User(
               email = form.email.data,
               password = form.password.data
           )
           db.session.add(user)
           db.session.commit()

           # Now we'll send the email confirmation link
           subject = "Confirm your email"

           token = ts.dumps(self.email, salt='email-confirm-key')

           confirm_url = url_for(
               'confirm_email',
               token=token,
               _external=True)

           html = render_template(
               'email/activate.html',
               confirm_url=confirm_url)

           # We'll assume that send_email has been defined in myapp/util.py
           send_email(user.email, subject, html)

           return redirect(url_for("index"))

       return render_template("accounts/create.html", form=form)
   ```
   \end{codelisting}

The view in Listing~ handles the creation of the user and sends off an
email to the given email address. You may notice that we're using a
template to generate the HTML for the email.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{An example template for the email}
   ```jinja
   {# ourapp/templates/email/activate.html #}

   Your account was successfully created. Please click the link below<br>
   to confirm your email address and activate your account:

   <p>
   <a href="{{ confirm_url }}">{{ confirm_url }}</a>
   </p>

   <p>
   --<br>
   Questions? Comments? Email hello@myapp.com.
   </p>
   ```
   \end{codelisting}

Okay, so now we just need to implement a view that handles the
confirmation link in that email.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{A view that handles a confirmation token}
   ```python
   # ourapp/views.py

   @app.route('/confirm/<token>')
   def confirm_email(token):
       try:
           email = ts.loads(token, salt="email-confirm-key", max_age=86400)
       except:
           abort(404)

       user = User.query.filter_by(email=email).first_or_404()

       user.email_confirmed = True

       db.session.add(user)
       db.session.commit()

       return redirect(url_for('signin'))
   ```
   \end{codelisting}

This view is a simple form view. We just add the ``try ... except`` bit
at the beginning to check that the token is valid. The token contains a
timestamp, so we can tell ``ts.loads()`` to raise an exception if it is
older than ``max_age``. In this case, we're setting ``max_age`` to 86400
seconds, i.e. 24 hours.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on updating emails}

   You can use very similar methods to implement an email update feature. Just send a confirmation link to the new email address with a token that contains both the old and the new addresses. If the token is valid, update the old address with the new one.

   \end{aside}

Storing passwords
-----------------

Rule number one of handling users is to hash passwords with the Bcrypt
(or scrypt, but we'll use Bcrypt here) algorithm before storing them. We
never store passwords in plain text. It's a massive security issue and
it's unfair to our users. All of the hard work has already been done and
abstracted away for us, so there's no excuse for not following the best
practices here.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - OWASP is one of the industry's most trusted source for information regarding web application security. Take a look at some of their recommendations for secure coding here: [https://www.owasp.org/index.php/Secure_Cod\-ing_Cheat_Sheet#Password_Storage](https://www.owasp.org/index.php/Secure_Coding_Cheat_Sheet#Password_Storage)

   \end{aside}

We'll go ahead and use the Flask-Bcrypt extension to implement the
bcrypt package in our application. This extension is basically just a
wrapper around the ``py-bcrypt`` package, but it does handle a few
things that would be annoying to do ourselves (like checking string
encodings before comparing hashes).

\\begin{codelisting}

.. code:: python

    # ourapp/__init__.py

    from flask.ext.bcrypt import Bcrypt

    bcrypt = Bcrypt(app)

\\end{codelisting}

One of the reasons that the Bcrypt algorithm is so highly recommended is
that it is "future adaptable." This means that over time, as computing
power becomes cheaper, we can make it more and more difficult to brute
force the hash by guessing millions of possible passwords. The more
"rounds" we use to hash the password, the longer it will take to make
one guess. If we hash our passwords 20 times with the algorithm before
storing them the attacker has to hash each of their guesses 20 times.

Keep in mind that if we're hashing our passwords 20 times then our
application is going to take a long time to return a response that
depends on that process completing. This means that when choosing the
number of rounds to use, we have to balance security and usability. The
number of rounds we can complete in a given amount of time will depend
on the computational resources available to our application. It's a good
idea to test out some different numbers and shoot for between 0.25 and
0.5 seconds to hash a password. We should try to use at least 12 rounds
though.

To test the time it takes to hash a password, we can time a quick Python
script that, well, hashes a password.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Benchmarking our system}
   ```python
   # benchmark.py

   from flask.ext.bcrypt import generate_password_hash

   # Chance the number of rounds (second argument) until it takes between
   # 0.25 and 0.5 seconds to run.
   generate_password_hash('password1', 12) 
   ```
   \end{codelisting}

Now we can keep timing our changes to the number of rounds with the UNIX
``time`` utility.

\\begin{codelisting}

.. code:: console

    $ time python test.py 

    real    0m0.496s
    user    0m0.464s
    sys     0m0.024s

\\end{codelisting}

I did a quick benchmark on a small server that I have handy and 12
rounds seemed to take the right amount of time, so I'll configure our
example to use that.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Configuring our application to use 12 rounds of hashing}
   ```python
   # config.py

   BCRYPT_LOG_ROUNDS = 12
   ```
   \end{codelisting}

Now that Flask-Bcrypt is configured, it's time to start hashing
passwords. We could do this manually in the view that receives the
request from the sign-up form, but we'd have to do it again in the
password reset and password change views. Instead, what we'll do is
abstract away the hashing so that our app does it without us even
thinking about it. We'll use a **setter** so that when we set
``user.password = 'password1'``, it's automatically hashed with Bcrypt
before being stored.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Creating a setter}
   ```python
   # ourapp/models.py

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
   \end{codelisting}

We're using SQLAlchemy's hybrid extension to define a property with
several different functions called from the same interface. Our setter
is called when we assign a value to the ``user.password`` property. In
it, we hash the plaintext password and store it in the ``_password``
column of the user table. Since we're using a hybrid property we can
then access the hashed password via the same ``user.password`` property.

Now we can implement a sign-up view for an app using this model.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{A sign-up view using our setter}
   ```python
   # ourapp/views.py

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
   \end{codelisting}

Authentication
--------------

Now that we've got a user in the database, we can implement
authentication. We'll want to let a user submit a form with their
username and password (though this might be email and password for some
apps), then make sure that they gave us the correct password. If it all
checks out, we'll mark them as authenticated by setting a cookie in
their browser. The next time they make a request we'll know that they
have already logged in by looking for that cookie.

Let's start by defining a ``UsernamePassword`` form with WTForms.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Our \texttt{UsernamePassword} form}
   ```python
   # ourapp/forms.py

   from flask.ext.wtforms import Form
   from wtforms import TextField, PasswordField, Required

   class UsernamePasswordForm(Form):
       username = TextField('Username', validators=[Required()])
       password = PasswordField('Password', validators=[Required()])
   ```
   \end{codelisting}

Next we'll add a method to our user model that compares a string with
the hashed password stored for that user.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Adding a method to check a password}
   ```python
   # ourapp/models.py

   from . import db

   class User(db.Model):

       # [...] columns and properties

       def is_correct_password(self, plaintext)
           if bcrypt.check_password_hash(self._password, plaintext):
               return True

           return False
   ```
   \end{codelisting}

Flask-Login
~~~~~~~~~~~

Our next goal is to define a sign-in view that serves and accepts our
form. If the user enters the correct credentials, we will authenticate
them using the Flask-Login extension. This extension simplifies the
process of handling user sessions and authentication.

We need to do a little bit of configuration to get Flask-Login ready to
roll.

In *\_\_init\_\_.py* we'll define the Flask-Login ``login_manager``.

\\begin{codelisting}

.. code:: python

    # ourapp/__init__.py

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

\\end{codelisting}

In Listing~ we created an instance of the ``LoginManager``, initialized
it with our ``app`` object, defined the login view and told it how to
get a user object with a user's ``id``. This is the baseline
configuration we should have for Flask-Login.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - See more ways to customize Flask-Login here: [https://flask-login.readthedocs.org/en/latest/#customizing-the-login-process](https://flask-login.readthedocs.org/en/latest/#customizing-the-login-process)

   \end{aside}

Now we can define the ``signin`` view that will handle authentication.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Handling authentication}
   ```python
   # ourapp/views.py

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
   \end{codelisting}

We simply import the ``login_user`` function from Flask-Login, check a
user's login credentials and call ``login_user(user)``. You can log the
current user out with ``logout_user()``.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{}
   ```python
   # ourapp/views.py

   from flask import redirect, url_for
   from flask.ext.login import logout_user

   from . import app

   @app.route('/signout')
   def signout():
       logout_user()

       return redirect(url_for('index'))
   ```
   \end{codelisting}

Forgot your password
--------------------

We'll generally want to implement a "Forgot your password" feature that
lets a user recover their account by email. This area has a plethora of
potential vulnerabilities because the whole point is to let an
unauthenticated user take over an account. We'll implement our password
reset using some of the same techniques as our email confirmation.

We'll need a form to request a reset for a given account's email and a
form to choose a new password once we've confirmed that the
unauthenticated user has access to that email address. The code in this
section assumes that our user model has an email and a password, where
the password is a hybrid property as we previously created.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{WARNING}

   Don't send password reset links to an unconfirmed email address! You want to be sure that you are sending this link to the right person.

   \end{aside}

We're going to need two forms. One is to request that a reset link be
sent to a certain email and the other is to change the password once the
email has been verified.

.. raw:: latex

   \begin{codelisting}
   \label{code:reset1}
   \codecaption{Defining our forms}
   ```python
   # ourapp/forms.py

   from flask.ext.wtforms import Form

   from wtforms import TextField, PasswordField, Required, Email

   class EmailForm(Form):
       email = TextField('Email', validators=[Required(), Email()])

   class PasswordForm(Form):
       password = PasswordField('Email', validators=[Required()])
   ```
   \end{codelisting}

Listing~ assumes that our password reset form just needs one field for
the password. Many apps require the user to enter their new password
twice to confirm that they haven't made a typo. To do this, we'd simply
add another ``PasswordField`` and add the ``EqualTo`` WTForms validator
to the main password field.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   There a lot of interesting discussions in the User Experience (UX) community about the best way to handle this in sign-up forms. I personally like the thoughts of one Stack Exchange user (Roger Attrill) who said:

   "We should not ask for password twice - we should ask for it once and make sure that the 'forgot password' system works seamlessly and flawlessly."

   - Read more about this topic in this thread on the User Experience Stack Exchange: [http://ux.stackexchange.com/questions/20953/why-should-we-ask-the-password-twice-during-registration/21141](http://ux.stackexchange.com/questions/20953/why-should-we-ask-the-password-twice-during-registration/21141)

   - There are also some cool ideas for simplifying sign-up and sign-in forms in this Smashing Magazine article: [http://uxdesign.smash\-ingmagazine.com/2011/05/05/innovative-techniques-to-simplify-signups-and-logins/](http://uxdesign.smashingmagazine.com/2011/05/05/innovative-techniques-to-simplify-signups-and-logins/)

   \end{aside}

Now we'll implement the first view of our process, where a user can
request that a password reset link be sent for a given email address.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{The reset view}
   ```python
   # ourapp/views.py

   from flask import redirect, url_for, render_template

   from . import app
   from .forms import EmailForm
   from .models import User
   from .util import send_email, ts

   @app.route('/reset', methods=["GET", "POST"])
   def reset():
       form = EmailForm()
       if form.validate_on_submit()
           user = User.query.filter_by(email=form.email.data).first_or_404()

           subject = "Password reset requested"

           # Here we use the URLSafeTimedSerializer we created in `util` at the 
           # beginning of the chapter
           token = ts.dumps(self.email, salt='recover-key')

           recover_url = url_for(
               'reset_with_token',
               token=token,
               _external=True)

           html = render_template(
               'email/recover.html',
               recover_url=recover_url)
               
           # Let's assume that send_email was defined in myapp/util.py
           send_email(user.email, subject, html)

           return redirect(url_for('index'))
       return render_template('reset.html', form=form)
   ```
   \end{codelisting}

When the form receives an email address, we grab the user with that
email address, generate a reset token and send them a password reset
URL. That URL routes them to a view that will validate the token and let
them reset the password.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{A view that handles the reset}
   ```python
   # ourapp/views.py

   from flask import redirect, url_for, render_template

   from . import app, db
   from .forms import PasswordForm
   from .models import User
   from .util import ts

   @app.route('/reset/<token>', methods=["GET", "POST"])
   def reset_with_token(token):
       try:
           email = ts.loads(token, salt="recover-key", max_age=86400)
       except:
           abort(404)

       form = PasswordForm()

       if form.validate_on_submit():
           user = User.query.filter_by(email=email).first_or_404()

           user.password = form.password.data

           db.session.add(user)
           db.session.commit()

           return redirect(url_for('signin'))

       return render_template('reset_with_token.html', form=form, token=token)
   ```
   \end{codelisting}

We're using the same token validation method as we did to confirm the
user's email address. The view passes the token from the URL back into
the template. Then the template uses the token to submit the form to the
right URL. Let's have a look at what that template might look like.

\\begin{codelisting}

.. code:: jinja

    {# ourapp/templates/reset_with_token.html #}

    {% extends "layout.html" %}

    {% block body %}
    <form action="{{ url_for('reset_with_token', token=token) }}" method="POST">
        {{ form.password.label }}: {{ form.password }}<br>
        {{ form.csrf_token }}
        <input type="submit" value="Change my password" />
    </form>
    {% endblock %}

\\end{codelisting}

Summary
-------

-  Use the itsdangerous package to create and validate tokens sent to an
   email address.
-  You can use these tokens to validate emails when a user creates an
   account, changes their email or forgets their password.
-  Authenticate users using the Flask-Login extension to avoid dealing
   with a bunch of session management stuff yourself.
-  Always think about how a malicious user could abuse your app to do
   things that you didn't intend.

