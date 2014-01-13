# Static files

As their name suggests, static files are the files that don't change. In your average app, this includes CSS files, JavaScript files and images. They can also include audio files and other things of that nature.

## Organizing your static files

We'll create a directory for our static files called "static" inside our application package.

```
myapp/
    __init__.py
    static/
    templates/
    views/
    models.py
run.py
```

How you organize the files in _static/_ is a matter of personal preference. Personally, I get a little irked by having third-party libraries (e.g. jQuery, Bootstrap, etc.) mixed in with my own JavaScript and CSS files. To avoid this, I recommend separating third-party libraries out into a _lib/_ folder within _static/_. Some projects use _vendor/_ instead of _lib/_. Here's an example of what an average app's _static/_ folder might look like.

```
static/
    css/
        style.css
        home.css
        admin.css
    js/
        home.js
        admin.js
    img/
        logo.svg
        favicon.ico
    lib/
        jquery.js
        bootstrap.css
```

### Serving a favicon

The files in your static directory will be served from yourapp.com/static/. By default web browsers and other software expects your favicon to be at yourapp.com/favicon.ico. To fix this discrepency, you can add the following in the `<head>` section of your site template.

```
<link rel="shortcut icon" href="{{ url_for('static', filename='favicon.ico') }}">
```

## Manage static assets with Flask-Assets

Flask-Assets is an extension for managing your static files. There are two really useful tools that Flask-Assets provides. First, it lets you define **bundles** of assets in your Python code that can be inserted together in your template. Second, it lets you pre-process those files. This means that you can combine and minify your CSS and JavaScript files so that the user only has to load two minified files (CSS and JavaScript) without forcing you to develop a complex asset pipeline. You can even compile your files from Sass, LESS, CoffeeScript and many other sources.

Here's basic the static directory we'll be working worth in this chapter:

myapp/static/
```
static/
    css/
        common.css
        home.css
        admin.css
    js/
        home.js
        admin.js
    img/
        logo.svg
        favicon.ico
    lib/
        jquery-1.10.2.js
        Chart.js
        reset.css
```

{ DECIDE HOW TO ORGANIZE lib/ AND UPDATE THE EXAMPLES BELOW ACCORDINGLY }

### Defining bundles

Our app has two sections: the public site and the admin panel (referred to as "home" and "admin" respectively). We'll define four bundles to cover this. JavaScript and CSS bundles for home and admin. We'll put these in a assets module in our util package.

myapp/util/assets.py
```
from flask.ext.assets import Bundle, Environment
from .. import app

bundles = {

    'home_js': Bundle(
        'lib/jquery-1.10.2.js',
        'js/home.js'),

    'home_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/home.css'),

    'admin_js': Bundle(
        'lib/jquery-1.10.2.js',
        'lib/Chart.js',
        'js/admin.js'),

    'admin_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/admin.css')
}

{ CHECK IF WE HAVE TO DEFINE AN OUTPUT? }

assets = Environment(app)

assets.register(bundles)
```

We're defining the bundles in a dictionary to make it easy to register them. webassets, the package behind Flask-Assets lets us register bundles in a number of ways, including passing a dictionary like the one we made in this snippet.

{ SOURCE: https://github.com/miracle2k/webassets/blob/0.8/src/webassets/env.py#L380 }

myapp/__init__.py
```
# [...] Initialize the app

from .util import assets
```

Since we're doing all of the registering in util.assets, all we have to do is import the module from __init__.py after our app has been initialized (app = Flask(__name__)).

### Using your bundles

Here's the templates folder of our hypothetical application:

myapp/templates/
```
templates/
    home/
        layout.html
        index.html
        about.html
    admin/
        layout.html
        dash.html
        stats.html
```

Now, to use the asset bundles for the admin portion of our application, we'll insert the bundled files into admin/layout.html:

myapp/templates/admin/layout.html
```
<!DOCTYPE html>
<html lang="en">
    <head>
        {% assets "admin_js" %}
            <script type="text/javascript" src="{{ ASSET_URL }}"></script>
        {% endassets %}
        {% assets "admin_css" %}
            <link rel="stylesheet" href="{{ ASSET_URL }}" />
        {% endassets %}
    </head>
    <body>
    {% block body %}
    {% endblock %}
    </body>
</html>
```

We would do the same thing for the home bundles in templates/home/layout.html.

### Using filters

We can use webassets filters to pre-process our static files. This is especially handy for minifying our JavaScript and CSS bundles. We'll modify our code to do just that.

myapp/util/assets.py
```
# [...]

bundles = {

    'home_js': Bundle(
        'lib/jquery-1.10.2.js',
        'js/home.js',
        filters='jsmin'),

    'home_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/home.css',
        filters='cssmin'),

    'admin_js': Bundle(
        'lib/jquery-1.10.2.js',
        'lib/Chart.js',
        'js/admin.js',
        filters='jsmin'),

    'admin_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/admin.css',
        filters='cssmin')
}

# [...]
```

{ NOTE: To use the jsmin and cssmin filters, you'll need to install the jsmin and cssmin packages (e.g. with pip install jsmin cssmin). Make sure to add them to requirements.txt too. }

Now Flask-Assets will merge and compress our files the first time the template is rendered, and it'll automatically update the compressed file when a source file changes.

{ NOTE: If you set ASSETS_DEBUG = True in your config, Flask-Assets will output each source file individually instead of merging them. }

{ SEE ALSO: You can use Flask-Assets to automatically compile Sass, Less, CoffeeScript, and other pre-processors. Take a look at some of these other filters that you can use: http://elsdoerfer.name/docs/webassets/builtin_filters.html#js-css-compilers }

## Summary

We can clean up our static directory by separating third-party files from our own code. Flask-Assets lets us bundle several static files into one. It also lets us use filters to minify those static files, or even compile pre-processor languages (like Sass, Less, CoffeeScript and more).