
.. highlight:: python
    :linenothreshold: 0

Static files
============

.. image:: _static/images/static.png
   :alt: Static files

As their name suggests, static files are the files that don't change. In
your average app, this includes CSS files, JavaScript files and images.
They can also include audio files and other things of that nature.

Organizing your static files
----------------------------

We'll create a directory for our static files called *static* inside our
application package.

::

    myapp/
        __init__.py
        static/
        templates/
        views/
        models.py
    run.py

How you organize the files in *static/* is a matter of personal
preference. Personally, I get a little irked by having third-party
libraries (e.g. jQuery, Bootstrap, etc.) mixed in with my own JavaScript
and CSS files. To avoid this, I recommend separating third-party
libraries out into a *lib/* folder within the appropriate directory.
Some projects use *vendor/* instead of *lib/*.

::

   static/
       css/
           lib/
               bootstrap.css
           style.css
           home.css
           admin.css
       js/
           lib/
               jquery.js
           home.js
           admin.js
       img/
           logo.svg
           favicon.ico

Serving a favicon
~~~~~~~~~~~~~~~~~

The files in our static directory will be served from
*example.com/static/*. By default, web browsers and other software
expects our favicon to be at *example.com/favicon.ico*. To fix this
discrepency, we can add the following in the ``<head>`` section of our
site template.

::

   <link rel="shortcut icon"
       href="{{ url_for('static', filename='img/favicon.ico') }}">

Manage static assets with Flask-Assets
--------------------------------------

Flask-Assets is an extension for managing your static files. There are
two really useful tools that Flask-Assets provides. First, it lets you
define **bundles** of assets in your Python code that can be inserted
together in your template. Second, it lets you **pre-process** those
files. This means that you can combine and minify your CSS and
JavaScript files so that the user only has to load two minified files
(CSS and JavaScript) without forcing you to develop a complex asset
pipeline. You can even compile your files from Sass, LESS, CoffeeScript
and a bunch of other sources.

::

   static/
       css/
           lib/
               reset.css
           common.css
           home.css
           admin.css
       js/
           lib/
               jquery-1.10.2.js
               Chart.js
           home.js
           admin.js
       img/
           logo.svg
           favicon.ico

Defining bundles
~~~~~~~~~~~~~~~~

Our app has two sections: the public site and the admin panel, referred
to as "home" and "admin" respectively in our app. We'll define four
bundles to cover this: a JavaScript and CSS bundle for each section.
We'll put these in an assets module inside our ``util`` package.

::

   # myapp/util/assets.py

   from flask.ext.assets import Bundle, Environment
   from .. import app

   bundles = {

       'home_js': Bundle(
           'js/lib/jquery-1.10.2.js',
           'js/home.js',
           output='gen/home.js),

       'home_css': Bundle(
           'css/lib/reset.css',
           'css/common.css',
           'css/home.css',
           output='gen/home.css),

       'admin_js': Bundle(
           'js/lib/jquery-1.10.2.js',
           'js/lib/Chart.js',
           'js/admin.js',
           output='gen/admin.js),

       'admin_css': Bundle(
           'css/lib/reset.css',
           'css/common.css',
           'css/admin.css',
           output='gen/admin.css)
   }

   assets = Environment(app)

   assets.register(bundles)

Flask-Assets combines your files in the order in which they are listed
here. If *admin.js* requires *jquery-1.10.2.js*, make sure jquery is
listed first.

We're defining the bundles in a dictionary to make it easy to register
them. webassets, the package behind Flask-Assets lets us register
bundles in a number of ways, including passing a dictionary like the one
we made in this snippet. [1]_

Since we're registering our bundles in ``util.assets``, all we have to
do is import that module in *\_\_init\_\_.py* after our app has been
initialized.

:: 

    # myapp/__init__.py

    # [...] Initialize the app

    from .util import assets

Using our bundles
~~~~~~~~~~~~~~~~~

To use our admin bundles, we'll insert them into the parent template for
the admin section: *admin/layout.html*.

::

   templates/
       home/
           layout.html
           index.html
           about.html
       admin/
           layout.html
           dash.html
           stats.html

::

    {# myapp/templates/admin/layout.html #}

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

We can do the same thing for the home bundles in
*templates/home/layout.html*.

Using filters
~~~~~~~~~~~~~

We can use filters to pre-process our static files. This is especially
handy for minifying our JavaScript and CSS bundles.

::

   # myapp/util/assets.py

   # [...]

   bundles = {

       'home_js': Bundle(
           'lib/jquery-1.10.2.js',
           'js/home.js',
           output='gen/home.js',
           filters='jsmin'),

       'home_css': Bundle(
           'lib/reset.css',
           'css/common.css',
           'css/home.css',
           output='gen/home.css',
           filters='cssmin'),

       'admin_js': Bundle(
           'lib/jquery-1.10.2.js',
           'lib/Chart.js',
           'js/admin.js',
           output='gen/admin.js',
           filters='jsmin'),

       'admin_css': Bundle(
           'lib/reset.css',
           'css/common.css',
           'css/admin.css',
           output='gen/admin.css',
           filters='cssmin')
   }

   # [...]

.. note::

    To use the ``jsmin`` and ``cssmin`` filters, you'll need to install the
    ``jsmin`` and ``cssmin`` packages (e.g. with
    ``pip install jsmin cssmin``). Make sure to add them to
    *requirements.txt* too.

Flask-Assets will merge and compress our files the first time the
template is rendered, and it'll automatically update the compressed file
when one of the source files changes.

.. note::

   If you set `ASSETS_DEBUG = True` in your config, Flask-Assets will output each source file individually instead of merging them.

.. note::

   Take a look at some of `the other filters <http://elsdoerfer.name/docs/webassets/builtin_filters.html#js-css-compilers>`_ that we can use with Flask-Assets.

Summary
-------

-  Static files go in the *static/* directory.
-  Separate third-party libraries from your own static files.
-  Specify the location of your favicon in your templates.
-  Use Flask-Assets to insert static files in your templates.
-  Flask-Assets can compile, combine and compress your static files.

.. [1]
    We can see how bundle registration works `in the source <https://github.com/miracle2k/webassets/blob/0.8/src/webassets/env.py#L380>`_.
