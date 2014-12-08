
.. highlight:: python
    :linenothreshold: 0

Environment
===========

.. image:: _static/images/environment.png
   :alt: Environment


Your application is probably going to require a lot of software to
function properly. If it doesn't at least require the Flask package, you
may be reading the wrong book. Your application's **environment** is
essentially all of the things that need to be around when it runs. Lucky
for us, there are a number of things that we can do to make managing our
environment much less complicated.

Use virtualenv to manage your environment
-----------------------------------------

`virtualenv <http://www.virtualenv.org/en/latest/>`_ is a tool for isolating your application in what is called a
**virtual environment**. A virtual environment is a directory that
contains the software on which your application depends. A virtual
environment also changes your environment variables to keep your
development environment contained. Instead of downloading packages, like
Flask, to your system-wide — or user-wide — package directories, we can
download them to an isolated directory used only for our current
application. This makes it easy to specify which Python binary to use
and which dependencies we want to have available on a per project basis.

Virtualenv also lets you use different versions of the same package for
different projects. This flexibility may be important if you're working
on an older system with several projects that have different version
requirements.

When using virtualenv, you'll generally have only a few Python packages
installed globally on your system. One of these will be virtualenv
itself. You can install the ``virtualenv`` package with Pip.

Once you have virtualenv on your system, you can start creating virtual
environments. Navigate to your project directory and run the
``virtualenv`` command. It takes one argument, which is the destination
directory of the virtual environment. Listing~ shows what this looks
like.

::

   $ virtualenv venv
   New python executable in venv/bin/python
   Installing Setuptools...........[...].....done.
   Installing Pip..................[...].....done.
   $

virtualenv creates a new directory where the dependencies will be
installed.

Once the new virtual environment has been created, you must activate it
by sourcing the *bin/activate* script that was created inside the
virtual environment.

::

   $ which python
   /usr/local/bin/python
   $ source venv/bin/activate
   (venv)$ which python
   /Users/robert/Code/myapp/venv/bin/python

The *bin/activate* script makes some changes to your shell's environment variables so that everything points to the new virtual environment instead of your global system. You can see the effect in code block above. After activation, the ``python`` command refers to the Python binary inside the virtual environment. When a virtual environment is active, dependencies installed with Pip will be downloaded to that virtual environment instead of the global system.

You may notice that the shell prompt has been changed too. virtualenv prepends the name of the currently activated virtual environment, so you know that you're not working on the global system.

You can deactivate your virtual environment by running the ``deactivate`` command.

::

   (venv)$ deactivate
   $

virtualenvwrapper
~~~~~~~~~~~~~~~~~

`virtualenvwrapper <http://virtualenvwrapper.readthedocs.org/en/latest/>`_ is a package used to manage the virtual environments created by virtualenv. I didn't want to mention this tool until you had seen the basics of virtualenv so that you understand what it's improving upon and understand why you should use it.

That virtual environment directory created in Listing~\ref{code:venv_create} adds clutter to your project repository. You only interact with it directly when activating the virtual environment and it shouldn't be in version control, so there's no need to have it in there. The solution is to use virtualenvwrapper. This package keeps all of your virtual environments out of the way in a single directory, usually _~/.virtualenvs/_ by default.

To install virtualenvwrapper, follow the instructions in the documentation.

.. warning::

   Make sure that you've deactivated all virtual environments before installing virtualenvwrapper. You want it installed globally, not in a pre-existing environment.

Now, instead of running ``virtualenv`` to create an environment, you'll run ``mkvirtualenv``:

::

   $ mkvirtualenv rocket
   New python executable in rocket/bin/python
   Installing setuptools...........[...].....done.
   Installing pip..................[...].....done.
   (rocket)$

``mkvirtualenv`` creates a directory in your virtual environments folder and activates it for you. Just like with plain old ``virtualenv``, ``python`` and ``pip`` now point to that virtual environment instead of the system binaries. To activate a particular environment, use the command: ``workon [environment name]``. ``deactivate`` still deactivates the environment.

Keeping track of dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As a project grows, you'll find that the list of dependencies grows with it. It's not uncommon to need dozens of Python packages installed to run a Flask application. The easiest way to manage these is with a simple text file. Pip can generate a text file listing all installed packages. It can also read in this list to install each of them on a new system, or in a freshly minted environment.

pip freeze
''''''''''

*requirements.txt* is a text file used by many Flask applications to list all of the packages needed to run an application. This code block shows how to create this file and the following one shows how to use that text file to install your dependencies in a new environment.

:: 

   (rocket)$ pip freeze > requirements.txt

::

    $ workon fresh-env
    (fresh-env)$ pip install -r requirements.txt
    [...]
    Successfully installed flask Werkzeug Jinja2 itsdangerous markupsafe
    Cleaning up...
    (fresh-env)$

Manually tracking dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As your project grows, you may find that certain packages listed by
``pip freeze`` aren't actually needed to run the application. You'll
have packages that are installed for development only. ``pip freeze``
doesn't discriminate between the two, it just lists the packages that
are currently installed. As a result, you may want to manually track
your dependencies as you add them. You can separate those packages needed
to run your application and those needed to develop your application
into *require_run.txt* and *require_dev.txt* respectively.

Version control
---------------

Pick a version control system and use it. I recommend Git. From what
I've seen, Git is the most popular choice for new projects these days.
Being able to delete code without worrying about making an irreversible
mistake is invaluable. You'll be able to keep your project free of those
massive blocks of commented out code, because you can delete it now and
revert that change later should the need arise. Plus, you'll have backup
copies of your entire project on GitHub, Bitbucket or your own Gitolite
server.

What to keep out of version control
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

I usually keep a file out of version control for one of two reasons.
Either it's clutter, or it's a secret. Compiled *.pyc* files and virtual
environments --- if you're not using virtualenvwrapper for some reason
--- are examples of clutter. They don't need to be in version control
because they can be recreated from the *.py* files and your
*requirements.txt* files respectively.

API keys, application secret keys and database credentials are examples
of secrets. They shouldn't be in version control because their exposure
would be a massive breach of security.

.. note::

   When making security related decisions, I always like to assume that my repository will become public at some point. This means keeping secrets out and never assuming that a security hole won't be found because, "Who's going to guess that they can do that?" This kind of assumption is known as security by obscurity and it's a bad policy to rely on.

When using Git, you can create a special file called *.gitignore* in
your repository. In it, list wildcard patterns to match
against filenames. Any filename that matches one of the patterns will be
ignored by Git. I recommend using the *.gitignore* shown in Listing~ to
get you started.

::

   *.pyc
   instance/

Instance folders are used to make secret configuration variables
available to your application in a more secure way. We'll talk more
about them later.

.. note:: 

   You can read more about *.gitignore* here: http://git-scm.com/docs/gitignore

Debugging
---------

Debug Mode
~~~~~~~~~~

Flask comes with a handy feature called debug mode. To turn it on, you
just have to set ``debug = True`` in your development configuration.
When it's on, the server will reload on code changes and errors will
come with a stack trace and an interactive console.

.. warning::

   Take care not to enable debug mode in production. The interactive console enables arbitrary code execution and would be a massive security vulnerability if it was left on in the live site.

Flask-DebugToolbar
~~~~~~~~~~~~~~~~~~

`Flask-DebugToolbar <http://flask-debugtoolbar.readthedocs.org/en/latest/>`_ is another great tool for debugging problems with
your application. In debug mode, it overlays a side-bar onto every page
in your application. The side bar gives you information about SQL
queries, logging, versions, templates, configuration and other fun stuff
that makes it easier to track down problems.

.. note::

   - Take a look at the quick start `section on debug mode <http://flask.pocoo.org/docs/quickstart/#debug-mode>`_.
   - There is some good information on handling errors, logging and working with other debuggers `in the flask docs <http://flask.pocoo.org/docs/errorhandling>`_.

Summary
-------

-  Use virtualenv to keep your application's dependencies together.
-  Use virtualenvwrapper to keep your virtual environments together.
-  Keep track of dependencies with one or more text files.
-  Use a version control system. I recommend Git.
-  Use .gitignore to keep clutter and secrets out of version control.
-  Debug mode can give you information about problems in development.
-  The Flask-DebugToolbar extension will give you even more of that
   information.

