Organizing your project
=======================

.. figure:: images/organizing.png
   :alt: Organizing your project

   Organizing your project
Flask leaves the organization of your application up to you. This is one
of the reasons I liked Flask as a beginner, but it does mean that you
have to put some thought into how to structure your code. You could put
your entire application in one file, or have it spread across multiple
packages. There are a few organizational patterns that you can follow to
make development and deployment easier.

Definitions
-----------

Let's define some of the terms that we'll run into in this chapter.

**Repository** - This is the base folder where your applications sits.
This term traditionally refers to version control systems, which you
should be using. When I refer to your repository in this chapter, I'm
talking about the root directory of your project. You probably won't
need to leave this directory when working on your application.

**Package** - This refers to a Python package that contains your
application's code. I'll talk more about setting up your app as a
package in this chapter, but for now just know that the package is a
sub-directory of the repository.

**Module** - A module is a single Python file that can be imported by
other Python files. A package is essentially multiple modules packaged
together.

.. raw:: latex

   \begin{aside}
   \label{aside:def_links}
   \heading{Related Links}

   - Read more about Python modules here: [http://docs.python.org/2/tut\-orial/modules.html](http://docs.python.org/2/tutorial/modules.html)
   - That same page has a section on packages as well: [http://docs.pyth\-on.org/2/tutorial/modules.html#packages](http://docs.python.org/2/tutorial/modules.html#packages)

   \end{aside}

Organization patterns
---------------------

Single module
~~~~~~~~~~~~~

A lot of the Flask examples that you'll come across will keep all of the
code in a single file, often *app.py*. This is great for quick projects
(like the ones used for tutorials), where you just need to serve a few
routes and you've got less than a few hundred lines of application code.

.. raw:: latex

   \begin{codelisting}
   \label{code:1module}
   \codecaption{A repository containing a single module application}
   ```
   app.py
   config.py
   requirements.txt
   static/
   templates/
   ```
   \end{codelisting}

Application logic would sit in *app.py* for the example in Listing~.

Package
~~~~~~~

When you're working on a project that's a little more complex, a single
module can get messy. You'll need to define classes for models and
forms, and they'll get mixed in with the code for your routes and
configuration. All of this can frustrate development. To solve this
problem, we can factor out the different components of our app into a
group of inter-connected modules — a package.

\\begin{codelisting}

::

    config.py
    requirements.txt
    run.py
    instance/
        config.py
    yourapp/
        __init__.py
        views.py
        models.py
        forms.py
        static/
        templates/

\\end{codelisting}

The structure shown in Listing~ allows you to group the different
components of your application in a logical way. The class definitions
for models are together in *models.py*, the route definitions are in
*views.py* and forms are defined in *forms.py* (we'll talk about forms
in Chapter~).

Table~ provides a basic rundown of the components you'll find in most
Flask applications. You'll probably end up with a lot of other files in
your repository, but these are common to most Flask applications.

\\begin{table}

\\begin{tabular}{ll}

.. raw:: latex

   \begin{tabular}{lp{0.7\linewidth}}
   \fi

       \textit{/run.py} & This is the file that is invoked to start up a development server. It gets a copy of the app from your package and runs it. This won't be used in production, but it will see a lot of mileage in development. \\
       \textit{/requirements.txt} & This file lists all of the Python packages that your app depends on. You may have separate files for production and development dependencies. \\
       \textit{/config.py} & This file contains most of the configuration variables that your app needs. \\
       \textit{/instance/config.py} & This file contains configuration variables that shouldn't be in version control. This includes things like API keys and database URIs containing passwords. This also contains variables that are specific to this particular instance of your application. For example, you might have DEBUG = False in config.py, but set DEBUG = True in instance/config.py on your local machine for development. Since this file will be read in after config.py, it will override it and set DEBUG = False. \\
       \textit{/yourapp/} & This is the package that contains your application. \\
       \textit{/yourapp/\_\_init\_\_.py} & This file initializes your application and brings together all of the various components. \\
       \textit{/yourapp/views.py} & This is where the routes are defined. It may be split into a package of its own (\textit{yourapp/views/}) with related views grouped together into modules. \\
       \textit{/yourapp/models.py} & This is where you define the models of your application. This may be split into several modules in the same way as views.py. \\
       \textit{/yourapp/static/} & This file contains the public CSS, JavaScript, images and other files that you want to make public via your app. It is accessible from yourapp.com/static/ by default. \\
       \textit{/yourapp/templates/} & This is where you'll put the Jinja2 templates for your app. \\

   \end{tabular}

\\end{table}

Blueprints
~~~~~~~~~~

At some point you may find that you have a lot of related routes. If
you're like me, your first thought will be to split *views.py* into a
package and group those views into modules. When you're at this point,
it may be time to factor your application into blueprints.

Blueprints are essentially components of your app defined in a somewhat
self-contained manner. They act as apps within your application. You
might have different blueprints for the admin panel, the front-end and
the user dashboard. This lets you group views, static files and
templates by components, while letting you share models, forms and other
aspects of your application between these components. We'll talk about
using Blueprints to organize your application in Chapter~.

Summary
-------

-  Using a single module for your application is good for quick
   projects.
-  Using a package for your application is good for projects with views,
   models, forms and other components.
-  Blueprints are a great way to organize projects with several distinct
   components.

