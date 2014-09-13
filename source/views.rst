
.. highlight:: python
    :linenothreshold: 0

Advanced patterns for views and routing
=======================================

.. image:: _static/images/views.png
   :alt: Advanced patterns for views and routing

View decorators
---------------

Python decorators are functions that are used to transform other
functions. When a decorated function is called, the decorator is called
instead. The decorator can then take action, modify the arguments, halt
execution or call the original function. We can use decorators to wrap
views with code we'd like to run before they are executed.

::

   @decorator_function
   def decorated():
       pass

If you've gone through the Flask tutorial, the syntax in this code block might
look familiar to you. ``@app.route`` is a decorator used to match URLs
to view functions in Flask apps.

Let's take a look at some other decorators you can use in your Flask
apps.

Authentication
~~~~~~~~~~~~~~

The Flask-Login extension makes it easy to implement a login system. In
addition to handling the details of user authentication, Flask-Login
gives us a decorator to restrict certain views to authenticated users:
``@login_required``.

::

   # app.py

   from flask import render_template
   from flask.ext.login import login_required, current_user


   @app.route('/')
   def index():
       return render_template("index.html")

   @app.route('/dashboard')
   @login_required
   def account():
       return render_template("account.html")

.. warning::

   ``@app.route`` should always be the outermost view decorator.


Only an authenticated user will be able to access the */dashboard*
route. We can configure Flask-Login to redirect unauthenticated users to
a login page, return an HTTP 401 status or anything else we'd like it to
do with them.

.. note::

   Read more about using Flask-Login in `the official docs <http://flask-login.readthedocs.org/en/latest/>`_.

Caching
~~~~~~~

Imagine that an article mentioning our application just appeared on CNN
and some other news sites. We're getting thousands of requests per
second. Our homepage makes several trips to the database for each
request, so all of this attention is slowing things down to a crawl. How
can we speed things up quickly, so all of these visitors don't miss out
on our site?

There are a lot of good answers, but this section is about caching, so
we'll talk about that. Specifically, we're going to use the `Flask-Cache <http://pythonhosted.org/Flask-Cache/>`_
extension. This extension provides us with a decorator that we can use
on our index view to cache the response for some period of time.

Flask-Cache can be configured to work with a bunch of different caching
backends. A popular choice is `Redis <http://redis.io/>`_, which is easy to set-up and use.
Assuming Flask-Cache is already configured, this code block shows what our
decorated view would look like.

::

   # app.py

   from flask.ext.cache import Cache
   from flask import Flask

   app = Flask()

   # We'd normally include configuration settings in this call
   cache = Cache(app)

   @app.route('/')
   @cache.cached(timeout=60)
   def index():
       [...] # Make a few database calls to get the information we need
       return render_template(
           'index.html',
           latest_posts=latest_posts, 
           recent_users=recent_users,
           recent_photos=recent_photos
       )

Now the function will only be run once every 60 seconds, when the cache
expires. The response will be saved in our cache and pulled from there
for any intervening requests.

.. note::

   Flask-Cache also lets us **memoize** functions — or cache the result of a function being called with certain arguments. You can even cache computationally expensive Jinja2 template snippets.

Custom decorators
~~~~~~~~~~~~~~~~~

For this section, let's imagine we have an application that charges
users each month. If a user's account is expired, we'll redirect them to
the billing page and tell them to upgrade.

::

   # myapp/util.py

   from functools import wraps
   from datetime import datetime

   from flask import flash, redirect, url_for

   from flask.ext.login import current_user

   def check_expired(func):
       @wraps(func)
       def decorated_function(*args, **kwargs):
           if datetime.utcnow() > current_user.account_expires:
               flash("Your account has expired. Update your billing info.")
               return redirect(url_for('account_billing'))
           return func(*args, **kwargs)

       return decorated_function

+----+-------------------------------------------------------------------------------+
| 10 | When a function is decorated with ``@check_expired``, ``check_expired()``     |
|    | is called and the decorated function is passed as a parameter.                |
+----+-------------------------------------------------------------------------------+
| 11 | ``@wraps`` is a decorator that does some bookkeeping so that                  |
|    | ``decorated_function()`` appears as ``func()`` for the purposes of            |
|    | documentation and debugging. This makes the behavior of the                   |
|    | functions a little more natural.                                              |
+----+-------------------------------------------------------------------------------+
| 12 | ``decorated_function`` will get all of the args and kwargs that were          |
|    | passed to the original view function ``func()``. This is where we             |
|    | check if the user's account is expired. If it is, we'll flash a               |
|    | message and redirect them to the billing page.                                |
+----+-------------------------------------------------------------------------------+
| 16 | Now that we've done what we wanted to do, we run the decorated                |
|    | view function ``func()`` with its original arguments.                         |
+----+-------------------------------------------------------------------------------+

When we stack decorators, the topmost decorator will run first, then
call the next function in line: either the view function or the next
decorator. The decorator syntax is just a little syntactic sugar.

::

   # This code:
   @foo
   @bar
   def one():
       pass

   r1 = one()

   # is the same as this code:
   def two():
       pass

   two = foo(bar(two))
   r2 = two()

   r1 == r2 # True

This code block shows an example using our custom decorator and the
``@login_required`` decorator from the Flask-Login extension. We can
use multiple decorators by stacking them.

::

   # myapp/views.py

   from flask import render_template

   from flask.ext.login import login_required

   from . import app
   from .util import check_expired

   @app.route('/use_app')
   @login_required
   @check_expired
   def use_app():
       """Use our amazing app."""
       # [...]
       return render_template('use_app.html')

   @app.route('/account/billing')
   @login_required
   def account_billing():
       """Update your billing info."""
       # [...]
       return render_template('account/billing.html')

Now when a user tries to access */use\_app*, ``check_expired()`` will
make sure that their account hasn't expired before running the view
function.

.. note::

   Read more about what the ``wraps()`` function does `in the Python docs <http://docs.python.org/2/library/functools.html#functools.wraps>`_.

URL Converters
--------------

Built-in converters
~~~~~~~~~~~~~~~~~~~

When you define a route in Flask, you can specify parts of it that will
be converted into Python variables and passed to the view function.

::

   @app.route('/user/<username>')
   def profile(username):
       pass

Whatever is in the part of the URL labeled ``<username>`` will get
passed to the view as the username argument. You can also specify a
converter to filter the variable before it's passed to the view.

::

   @app.route('/user/id/<int:user_id>')
   def profile(user_id):
       pass

In this code block, the URL *http://myapp.com/user/id/Q29kZUxlc3NvbiEh* will
return a 404 status code -- not found. This is because the part of the
URL that is supposed to be an integer is actually a string.

We could have a second view that looks for a string as well. That would
be called for */user/id/Q29kZUxlc3NvbiEh/* while the first would be
called for */user/id/124*.

This table shows Flask's built-in URL converters.

+--------+-------------------------------------------------+
| string | Accepts any text without a slash (the default). |
+--------+-------------------------------------------------+
| int    | Accepts integers.                               |
+--------+-------------------------------------------------+
| float  | Like int but for floating point values.         |
+--------+-------------------------------------------------+
| path   | Like string but accepts slashes.                |
+--------+-------------------------------------------------+

Custom converters
~~~~~~~~~~~~~~~~~

We can also make custom converters to suit our needs. On Reddit — a
popular link sharing site — users create and moderate communities for
theme-based discussion and link sharing. Some examples are /r/python and
/r/flask, denoted by the path in the URL: *reddit.com/r/python* and
*reddit.com/r/flask* respectively. An interesting feature of Reddit is
that you can view the posts from multiple subreddits as one by
seperating the names with a plus-sign in the URL, e.g.
*reddit.com/r/python+flask*.

We can use a custom converter to implement this feature in our own Flask
apps. We'll take an arbitrary number of elements separated by
plus-signs, convert them to a list with a ``ListConverter`` class and
pass the list of elements to the view function.

::

   # myapp/util.py

   from werkzeug.routing import BaseConverter

   class ListConverter(BaseConverter):

       def to_python(self, value):
           return value.split('+')

       def to_url(self, values):
           return '+'.join(BaseConverter.to_url(value)
                           for value in values)

We need to define two methods: ``to_python()`` and ``to_url()``. As the
names suggest, ``to_python()`` is used to convert the path in the URL to
a Python object that will be passed to the view and ``to_url()`` is used
by ``url_for()`` to convert arguments to their appropriate forms in the
URL.

To use our ``ListConverter``, we first have to tell Flask that it
exists.

::

    # /myapp/__init__.py

    from flask import Flask

    app = Flask(__name__)

    from .util import ListConverter

    app.url_map.converters['list'] = ListConverter

.. warning::

   This is another chance to run into some circular import problems if your ``util`` module has a ``from . import app`` line. That's why I waited until app had been initialized to import ``ListConverter``.

   Now we can use our converter just like one of the built-ins. We specified the key in the dictionary as "list" so that's how we use it in ``@app.route()``.

::

   # myapp/views.py

   from . import app

   @app.route('/r/<list:subreddits>')
   def subreddit_home(subreddits):
       """Show all of the posts for the given subreddits."""
       posts = []
       for subreddit in subreddits:
           posts.extend(subreddit.posts)

       return render_template('/r/index.html', posts=posts)

This should work just like Reddit's multi-reddit system. This same
method can be used to make any URL converter we can dream of.

Summary
-------

-  The ``@login_required`` decorator from Flask-Login helps you limit
   views to authenticated users.
-  The Flask-Cache extension gives you a bunch of decorators to
   implement various methods of caching.
-  We can develop custom view decorators to help us organize our code
   and stick to DRY (Don't Repeat Yourself) coding principles.
-  Custom URL converters can be a great way to implement creative
   features involving URL's.

