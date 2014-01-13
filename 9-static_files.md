# Static files

Static files are the files that don't change. In your average app, this is going to be the CSS files, JavaScript files, and images. They can also include audio files and other things of that nature.

## Organizing your files

We're going to put our static files in a directory called "static" inside our application package:

```
myapp/
    __init__.py
    static/
    templates/
    views/
    models.py
run.py
```

How you organize the files in static/ is a matter of personal preference. Personally, I get a little irked by having third-party libraries (e.g. jQuery, Bootstrap, etc.) mixed in with my own JavaScript and CSS files. To avoid this, I recommend separating third-party libraries out into a vendor/ folder within static/. Here's an example of what an average app's static/ folder might look like.

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
    vendor/
        jquery.js
        bootstrap.css
```

{ ADD A NOTE OR A PARAGRAPH ON SETTING THE FAVICON URL AS DONE HERE: http://maximebf.com/blog/2012/10/building-websites-in-python-with-flask/ }

## Manage static assets with Flask-Assets

The Flask-Assets extension is a tool for managing your static files, primarily JavaScript and CSS. Flask-Assets lets you do two really useful things. First, it lets you define "bundles" of assets in your Python code that can be used together later in your template. Second, it lets you pre-process those files. This means that you can combine and minify the files so that the user only has to load one minified file without forcing you to develop a complex asset pipeline. Not limited to minification of files, you can compile languages like SaSS and CoffeeScript here too.

Here's the static directory we'll be working worth:

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
    vendor/
        jquery-1.10.2.js
        Chart.js
        reset.css
```

{ DECIDE HOW TO ORGANIZE vendor/ AND UPDATE THE EXAMPLES BELOW ACCORDINGLY }

### Defining bundles

Our app has two sections: the public site and the admin panel (referred to as "home" and "admin" respectively). We'll define four bundles to cover this. JavaScript and CSS bundles for home and admin. We'll put these in a assets module in our util package.

myapp/util/assets.py
```
from flask.ext.assets import Bundle, Environment
from .. import app

bundles = {

    'home_js': Bundle(
        'vendor/jquery-1.10.2.js',
        'js/home.js'),

    'home_css': Bundle(
        'vendor/reset.css',
        'css/common.css',
        'css/home.css'),

    'admin_js': Bundle(
        'vendor/jquery-1.10.2.js',
        'vendor/Chart.js',
        'js/admin.js'),

    'admin_css': Bundle(
        'vendor/reset.css',
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
        'vendor/jquery-1.10.2.js',
        'js/home.js',
        filters='jsmin'),

    'home_css': Bundle(
        'vendor/reset.css',
        'css/common.css',
        'css/home.css',
        filters='cssmin'),

    'admin_js': Bundle(
        'vendor/jquery-1.10.2.js',
        'vendor/Chart.js',
        'js/admin.js',
        filters='jsmin'),

    'admin_css': Bundle(
        'vendor/reset.css',
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