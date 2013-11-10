![image](images/6.png)

# Advanced patterns for views and routing

## View decorators

Decorators are a Python feature that lets us modify functions using other functions. When a function is “decorated” with another function, the decorator is called and can then call the original function, though it doesn’t have to. We can use decorators to wrap several views with some code that we wish to apply to each.

The syntax for decorating a function looks like this:

```
@decorator_function
def decorated():
    pass
```

If you’ve gone through the Flask tutorial, that syntax might look familiar to you. `@app.route` is a decorator used to route URLs to view functions in Flask apps. 

Let’s take a look at some other decorators you can use in your Flask apps.

### Authentication

If you’re application requires that a user be logged in to access certain areas, there’s a good chance you’re using the Flask-Login extension. In addition to handling the details of user authentication, Flask-Login gives us a decorator to restrict certain views to authenticated users: `@login_required`.

Here are a few views from an example application that uses Flask-Login and the `@login_required` decorator.

```
from Flask import render_template
from flask.ext.login import login_required, current_user


@app.route('/')
def index():
    return render_template("index.html")

@app.route('/dashboard')
@login_required
def account():
    return render_template("account.html")
```
{ WARNING: `@app.route` should always be the outermost view decorator. }

Only an authenticated user will be able to access the _/dashboard_ route. Depending on your Flask-Login configuration, unauthenticated users may be redirected to a sign-in route.

### Caching

Imagine that an article mentioning your application just appeared on CNN and several other news sites. You’re getting thousands of requests per second. Your homepage makes several trips to the database for each request, so all of this attention is slowing things down to a crawl. How can you speed things up quickly, so all of these visitors don’t miss out on our site?

There are many good answers, but the one that is relevant to this chapter is to implement caching. Specifically, we’re going to use the Flask-Cache extension. This extension provides us with a decorator that we can use on our index view to cache the response for some period of time.

You’ll have to configure Flask-Cache to work with the caching software you wish to use. A popular choice is Redis, which is easy to set-up and use. Assuming Flask-Cache is configured, here’s what our decorated view looks like.

```
from flask.ext.cache import Cache
from flask import Flask

app = Flask()

# We'll ignore the configuration settings that you would normally include in this call
cache = Cache(app)

@app.route('/')
@cache.cached(timeout=60)
def index():
    [...] # Make a few database calls to get the information you need
    return render_template(
        'index.html',
        latest_posts=latest_posts, 
        recent_users=recent_users,
        recent_photos=recent_photos
    )

```

Now the function will be run a maximum of once every 60 seconds. The response will be saved in our cache and pulled from there for any intervening requests.

{ NOTE: Flask-Cache also lets us **memoize** functions — or cache the result of a function being called with certain parameters. You can even cache computationally expensive Jinja2 template snippets! }

{ SEE MORE:
* Read more about Redis here: http://redis.io/
* Read about how to use Flask-Cache, and the many other things you can cache here: http://pythonhosted.org/Flask-Cache/
}

### Custom decorators

For this example, let's imagine we have an application that charges users each month. If a user’s account is expired, we’ll redirect them to the billing page and tell them to upgrade.

myapp/util.py
```
from functools import wraps
from datetime import datetime

from flask import flash, redirect, url_for

from flask.ext.login import current_user

def check_expired(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if datetime.utcnow() > current_user.account_expires:
            flash("Your account has expired. Please update your billing information.")
            return redirect(url_for('account_billing'))
        return func(*args, **kwargs)

    return decorated_function
```

{ FIX LINE NUMBERS }

1: When a function is decorated with `@check_expired`, `check_expired()` is called and the decorated function is passed as a parameter.

2: @wraps is a decorator that tells Python that the function decorated_function() wraps around the view function func(). This isn’t strictly necessary, but it makes working with decorated functions a little more natural.

{ SEE MORE: Read more about what wraps() does here: http://docs.python.org/2/library/functools.html#functools.wraps }

3: decorated_function will get all of the args and kwargs that were passed to the original view function func(). This is where we check if the user’s account is expired. If it is, we’ll flash a message and redirect them to the billing page.

7: Now that we've done what we wanted to do, we run the original view func() with its original arguments.

Here’s an example using our custom decorator and the `@login_required` decorator from the Flask-Login extension. We can use multiple decorators by stacking them.

{ NOTE: The topmost decorator will run first, then call the next function in line: either the view function or the next decorator. The decorator syntax is just a little syntactic sugar.
This...
```
@foo
@bar
def bat():
    pass
```

...is the same is this:

```
def bat():
    pass
bat = foo(bar(bat))
```
}

myapp/views.py
```
from flask import render_template

from flask.ext.login import login_required

from . import app
from .util import check_expired

@app.route('/use_app')
@login_required
@check_expired
def use_app():
    """This is where users go to use my amazing app."""

    return render_template('use_app.html')

@app.route('/account/billing')
@login_required
def account_billing():
    """This is where users go to update their billing info."""
    # [...]
    return render_template('account/billing.html')
```

Now when a user tries to access /use_app, check_expired() will make sure that there account hasn't expired before running the view function.

## URL Converters

### Built-in converters

When you define a route in Flask, you can specify parts of it that will be converted into Python variables and passed to the view function. For example, you can specify that you are expecting a portion we’ll call “username” in the URL like so:

```
@app.route('/user/<username>')
def profile(username):
    pass
```

Whatever is in the part of the URL labeled <username> will get passed to the view as the username parameter. You can also specify a converter to filter out what gets passed:

```
@app.route('/user/id/<int:user_id>')
def profile(user_id):
    pass
```

{ CHANCE TO ENCODE BACKER NAME }

With this example, the URL, http://myapp.com/user/id/tomato will return a 404 status code -- not found. This is because the part of the URL that is supposed to be an integer is actually a string.

We could have a second view that looks for a string as well. That would be called for _/user/id/tomato/_ while the first would be called for _/user/id/124_.

Here's a table from the Flask documentation showing the default converters:

{ MAKE IT A TABLE }

string: accepts any text without a slash (the default)

int: accepts integers

float: like int but for floating point values

path: like the default but accepts slashes

### Customer converters

We can also make custom converters to suit our needs. On Reddit — a popular link sharing site — users create and moderate communities for theme-based discussion and link sharing. Some examples are /r/python and /r/flask, denoted by the path in the URL: reddit.com/r/python and reddit.com/r/flask respectively. An interesting feature of Reddit is that you can view the posts from multiple subreddits as one by seperating the names with a plus-sign in the URL, e.g. reddit.com/r/python+flask.

We can use a custom converter to implement this functionality in our Flask app. We’ll take an arbitrary number of elements separated by plus-signs, convert them to a list with our ListConverter class and pass the list of elements to the view function.

Here’s our implementation of the ListConverter class:

util.py
```
from werkzeug.routing import BaseConverter

class ListConverter(BaseConverter):

    def to_python(self, value):
        return value.split('+')

    def to_url(self, values):
        return '+'.join(BaseConverter.to_url(value)
                        for value in values)
```

We need to define two methods: `to_python()` and `to_url()`. As the titles suggest, `to_python()` is used to convert the path in the URL to a Python object that will be passed to the view and `to_url()` is used by `url_for()` to convert arguments to their appropriate forms in the URL.

To use our ListConverter, we first have to tell Flask that it exists.

/myapp/__init__.py
```
from flask import Flask

app = Flask(__name__)

from .util import ListConverter

app.url_map.converters['list'] = ListConverter
```

{ WARNING: This is another chance to run into some circular import problems if your util module has a `from . import app` line. That's why I waited until app had been initialized to import ListConverter. }

Now we can use our converter just like one of the built-ins. We specified the key in the dictionary as “list” so that’s how we use it in `@app.route()`.

views.py
```
from . import app

@app.route('/r/<list:subreddits>')
def subreddit_home(subreddits):
    """Show all of the posts for the given subreddits."""
    posts = []
    for subreddit in subreddits:
        posts.extend(subreddit.posts)

    return render_template('/r/index.html', posts=posts)
```

This should work just like Reddit’s multi-reddit system. This method can be used to make any URL converter you can think of.

## Summary

* The `@login_required` decorator from Flask-Login helps you limit views to authenticated users.
* The Flask-Cache extension gives you a bunch of decorators to implement various methods of caching.
* We can develop custom view decorators to help us organize our code and stick to DRY (Don’t Repeat Yourself) coding principals.
* Custom URL converters can be a great way to implement creative features involving URL’s. 
