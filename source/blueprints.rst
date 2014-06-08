Blueprints
==========

.. image:: _static/images/blueprints.png
   :alt: Blueprints

What is a blueprint?
--------------------

A blueprint defines a collection of views, templates, static files and
other elements that can be applied to an application. For example, let's
imagine that we have a blueprint for an admin panel. This blueprint
would define the views for routes like */admin/login* and
*/admin/dashboard*. It may also include the templates and static files
that will be served on those routes. We can then use this blueprint to
add an admin panel to our app, be it a social network for astronauts or
a CRM for rocket salesmen.

Why would you use blueprints?
-----------------------------

The killer use-case for blueprints is to organize our application into
distinct components. For a Twitter-like microblog, we might have a
blueprint for the website pages, e.g. *index.html* and *about.html*.
Then we could have another for the logged-in dashboard where we show all
of the latest posts and yet another for our administrator's panel. Each
distinct area of the site can be separated into distinct areas of the
code as well. This lets us structure our app as several smaller "apps"
that each do one thing.

.. note::

    Read more about the benefits of using blueprints in `"Why Blueprints" <http://flask.pocoo.org/docs/blueprints/#why-blueprints>`_ from the Flask docs.

Where do you put them?
----------------------

Like everything with Flask, there are many ways that we can organize our
app using blueprints. With blueprints, we can think of the choice as
functional versus divisional (terms I'm borrowing from the business
world).

Functional structure
~~~~~~~~~~~~~~~~~~~~

With a functional structure, you organize the pieces of your app by what
they do. Templates are grouped together in one directory, static files
in another and views in a third.

::

    yourapp/
        __init__.py
        static/
        templates/
            home/
            control_panel/
            admin/
        views/
            __init__.py
            home.py
            control_panel.py
            admin.py
        models.py

With the exception of *yourapp/views/\_\_init\_\_.py*, each of the *.py*
files in the *yourapp/views/* directory from this listing is a blueprint. In
*yourapp/\_\_init\_\_-.py* we would import those blueprints and
**register** them on our ``Flask()`` object. We'll look a little more at
how this is implemented later in this chapter.

.. note::

    At the time of writing this, the Flask website at `http://flask.pocoo.org <http://flask.pocoo.org>`_ uses this structure. Take a look for yourself `on GitHub <https://github.com/mitsuhiko/flask/tree/website/flask_website>`_.

Divisional
~~~~~~~~~~

With the divisional structure, you organize the pieces of the
application based on which part of the app they contribute to. All of
the templates, views and static files for the admin panel go in one
directory, and those for the user control panel go in another.

::

    yourapp/
        __init__.py
        admin/
            __init__.py
            views.py
            static/
            templates/
        home/
            __init__.py
            views.py
            static/
            templates/
        control_panel/
            __init__.py
            views.py
            static/
            templates/
        models.py

With a divisional structure like the app in this listing, each directory
under *yourapp/* is a separate blueprint. All of the blueprints are
applied to the ``Flask()`` app in the top-level *\_\_init\_\_.py*

Which one is best?
~~~~~~~~~~~~~~~~~~

The organizational structure you choose is largely a personal decision.
The only difference is the way the hierarchy is represented -- i.e. you
can architect Flask apps with either methodology -- so you should choose
the one that makes sense to you.

If your app has largely independent pieces that only share things like
models and configuration, divisional might be the way to go. An example
might be a SaaS app that lets user's build websites. You could have
blueprints in "divisions" for the home page, the control panel, the
user's website, and the admin panel. These components may very well have
completely different static files and layouts. If you're considering
spinning off your blueprints as extensions or using them for other
projects, a divisional structure will be easier to work with.

On the other hand, if the components of your app flow together a little
more, it might be better represented with a functional structure. An
example of this would be Facebook. If Facebook used Flask, it might have
blueprints for the static pages (i.e. signed-out home, register, about,
etc.), the dashboard (i.e. the news feed), profiles (*/robert/about* and
*/robert/photos*), settings (*/settings/security* and
*/settings/privacy*) and many more. These components all share a general
layout and styles, but each has its own layout as well. The following listing shows a
heavily abridged version of what Facebook might look like it if were
built with Flask.

::

    facebook/
        __init__.py
        templates/
            layout.html
            home/
                layout.html
                index.html
                about.html
                signup.html
                login.html
            dashboard/
                layout.html
                news_feed.html
                welcome.html
                find_friends.html
            profile/
                layout.html
                timeline.html
                about.html
                photos.html
                friends.html
                edit.html
            settings/
                layout.html
                privacy.html
                security.html
                general.html
        views/
            __init__.py
            home.py
            dashboard.py
            profile.py
            settings.py
        static/
            style.css
            logo.png
        models.py

The blueprints in *facebook/views/* are little more than collections of
views rather than wholly independent components. The same static files
will be used for the views in most of the blueprints. Most of the
templates will extend a master template. A functional structure is a
good way to organize this project.

How do you use them?
--------------------

Basic usage
~~~~~~~~~~~

Let's take a look at the code for one of the blueprints from that
Facebook example.

::

    # facebook/views/profile.py

    from flask import Blueprint, render_template

    profile = Blueprint('profile', __name__)

    @profile.route('/<user_url_slug>')
    def timeline(user_url_slug):
        # Do some stuff
        return render_template('profile/timeline.html')

    @profile.route('/<user_url_slug>/photos')
    def photos(user_url_slug):
        # Do some stuff
        return render_template('profile/photos.html')

    @profile.route('/<user_url_slug>/about')
    def about(user_url_slug):
        # Do some stuff
        return render_template('profile/about.html')

To create a blueprint object, we import the ``Blueprint()`` class and
initialize it with the arguments ``name`` and ``import_name``. Usually
``import_name`` will just be ``__name__``, which is a special Python
variable containing the name of the current module.

We're using a functional structure for this Facebook example. If we were
using a divisional structure, we'd want to tell Flask that the blueprint
has its own template and static directories. This code block shows what that
would look like.

::

    profile = Blueprint('profile', __name__,
                        template_folder='templates',
                        static_folder='static')

We have now defined our blueprint. It's time to register it on our Flask
app.

::

    # facebook/__init__.py

    from flask import Flask
    from .views.profile import profile

    app = Flask(__name__)
    app.register_blueprint(profile)

Now the routes defined in *facebook/views/profile.py* (e.g.
``/<user_url_slug>``) are registered on the application and act just
as if you'd defined them with ``@app.route()``.

Using a dynamic URL prefix
~~~~~~~~~~~~~~~~~~~~~~~~~~

Continuing with the Facebook example, notice how all of the profile
routes start with the ``<user_url_slug>`` portion and pass that value to
the view. We want users to be able to access a profile by going to a URL
like *https://facebo-ok.com/john.doe*. We can stop repeating ourselves
by defining a dynamic prefix for all of the blueprint's routes.

Blueprints let us define both static and dynamic prefixes. We can tell
Flask that all of the routes in a blueprint should be prefixed with
*/profile* for example; that would be a static prefix. In the case of
the Facebook example, the prefix is going to change based on which
profile the user is viewing. Whatever text they choose is the URL slug
of the profile which we should display; this is a dynamic prefix.

We have a choice to make when defining our prefix. We can define the
prefix in one of two places: when we instantiate the ``Blueprint()``
class or when we register it with ``app.register_blueprint()``.

::

    # facebook/views/profile.py

    from flask import Blueprint, render_template

    profile = Blueprint('profile', __name__, url_prefix='/<user_url_slug>')

    # [...]

::

    # facebook/__init__.py

    from flask import Flask
    from .views.profile import profile

    app = Flask(__name__)
    app.register_blueprint(profile, url_prefix='/<user_url_slug>')

While there aren't any technical limitations to either method, it's nice
to have the prefixes available in the same file as the registrations.
This makes it easier to move things around from the top-level. For this
reason, I recommend setting ``url_prefix`` on registration.

We can use converters to make the prefix dynamic, just like in
``route()`` calls. This includes any custom converters that we've
defined. When using converters, we can pre-process the value given
before handing it off to the view. In this case we'll want to grab the
user object based on the URL slug passed into our profile blueprint.
We'll do that by decorating a function with
``url_value_preprocessor()``.

::

    # facebook/views/profile.py

    from flask import Blueprint, render_template, g

    from ..models import User

    # The prefix is defined on registration in facebook/__init__.py.
    profile = Blueprint('profile', __name__)

    @profile.url_value_preprocessor
    def get_profile_owner(endpoint, values):
        query = User.query.filter_by(url_slug=values.pop('user_url_slug'))
        g.profile_owner = query.first_or_404()

    @profile.route('/')
    def timeline():
        return render_template('profile/timeline.html')

    @profile.route('/photos')
    def photos():
        return render_template('profile/photos.html')

    @profile.route('/about')
    def about():
        return render_template('profile/about.html')

We're using the ``g`` object to store the profile owner and ``g`` is
available in the Jinja2 template context. This means that for a
barebones case all we have to do in the view is render the template. The
information we need will be available in the template.

::

    {# facebook/templates/profile/photos.html #}

    {% extends "profile/layout.html" %}

    {% for photo in g.profile_owner.photos.all() %}
        <img src="{{ photo.source_url }}" alt="{{ photo.alt_text }}" />
    {% endfor %}

.. note::

   - The Flask documentation has `a great tutorial <http://flask.pocoo.org/docs/patterns/urlprocessors/#internationalized-blueprint-urls>`_ on using prefixes for internationalizing your URLs.

Using a dynamic subdomain
~~~~~~~~~~~~~~~~~~~~~~~~~

Many SaaS (Software as a Service) applications these days provide users
with a subdomain from which to access their software. Harvest, for
example, is a time tracking application for consultants that gives you
access to your dashboard from yourname.harvestapp.com. Here I'll show
you how to get Flask to work with automatically generated subdomains
like this.

For this section I'm going to use the example of an application that
lets users create their own websites. Imagine that our app has three
blueprints for distinct sections: the home page where users sign-up, the
user administration panel where the user builds their website and the
user's website. Since these three parts are relatively unconnected,
we'll organize them in a divisional structure.

::

    sitemaker/
        __init__.py
        home/
            __init__.py
            views.py
            templates/
                home/
            static/
                home/
        dash/
            __init__.py
            views.py
            templates/
                dash/
            static/
                dash/
        site/
            __init__.py
            views.py
            templates/
                site/
            static/
                site/
        models.py

This table explains the different blueprints in this app.

+-------------------------------+-------------------+-----------------------------------------------------------+
| URL                           | Route             | Description                                               |
+===============================+===================+===========================================================+
| sitemaker.com                 | *sitemaker/home*  | Just a vanilla blueprint. Views, templates and static     |
|                               |                   | files for *index.html*, *about.html* and *pricing.html*.  | 
+-------------------------------+-------------------+-----------------------------------------------------------+
| bigdaddy.sitemaker.com        | *sitemaker/site*  | This blueprint uses a dynamic subdomain and includes the  |
|                               |                   | elements of the user's website. We'll go over some of the |
|                               |                   | code used to implement this blueprint below.              |
+-------------------------------+-------------------+-----------------------------------------------------------+
| bigdaddy.sitemaker.com/admin  | *sitemaker/dash*  | This blueprint could use both a dynamic subdomain and a   |
|                               |                   | URL prefix by combining the techniques in this section    |
|                               |                   | with those from the previous section.                     |
+-------------------------------+-------------------+-----------------------------------------------------------+

We can define our dynamic subdomain the same way we defined our URL
prefix. Both options (in the blueprint directory or in the top-level
*\_\_init\_\_.py*) are available, but once again we'll keep the
definitions in *sitemaker/\_\_init.py\_\_*.

::

    # sitemaker/__init__.py

    from flask import Flask
    from .site import site

    app = Flask(__name__)
    app.register_blueprint(site, subdomain='<site_subdomain>')

Since we're using a divisional structure, we'll define the blueprint in
*sitema-ker/site/\_\_init\_\_.py*.

::

    # sitemaker/site/__init__py

    from flask import Blueprint

    from ..models import Site

    # Note that the capitalized Site and the lowercase site
    # are two completely separate variables. Site is a model
    # and site is a blueprint.

    site = Blueprint('site', __name__)

    @site.url_value_preprocessor
    def get_site(endpoint, values):
        query = Site.query.filter_by(subdomain=values.pop('site_subdomain'))
        g.site = query.first_or_404()

    # Import the views after site has been defined. The views
    # module will needto import 'site' so we need to make
    # sure that we import views after site has been defined.
    import .views

Now we have the site information from the database that we'll use to
display the user's site to the visitor who requests their subdomain.

To get Flask to work with subdomains, we'll need to specify the
``SERVER_NAME`` configuration variable.

::

   # config.py

   SERVER_NAME = 'sitemaker.com'

.. note::

   A few minutes ago, as I was drafting this section, somebody in IRC said that their subdomains were working fine in development, but not in production. I asked if they had the `SERVER_NAME` configured, and it turned out that they had it in development but not production. Setting it in production solved their problem.

   See the conversation between myself (imrobert in the log) and aplavin: `http://dev.pocoo.org/irclogs/%23pocoo.2013-07-30.log <http://dev.pocoo.org/irclogs/%23pocoo.2013-07-30.log>`_

   It was enough of a coincidence that I felt it warranted inclusion in the section.

::

   # U2FtIEJsYWNr/api/views.py

   from . import api

   @api.route('/search')
   def search():
       pass

Step 5: Enjoy
~~~~~~~~~~~~~

Now our application is far more modular than it was with one massive
*views.py* file. The route definitions are simpler because we can group
them together into blueprints and configure things like subdomains and
URL prefixes once for each blueprint.

Summary
-------

-  A blueprint is a collection of views, templates, static files and
   other extensions that can be applied to an application.
-  Blueprints are a great way to organize your application.
-  In a divisional structure, each blueprint is a collection of views,
   templates and static files which constitute a particular section of
   your application.
-  In a functional structure, each blueprint is just a collection of
   views. The templates are all kept together, as are the static files.
-  To use a blueprint, you define it then register it on the application
   with ``Flask.register_blueprint().``.
-  You can define a dynamic URL prefix that will be applied to all
   routes in a blueprint.
-  You can also define a dynamic subdomain for all routes in a
   blueprint.
-  Refactoring a growing application to use blueprints can be done in
   five relatively small steps.

