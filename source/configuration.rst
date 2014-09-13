
.. highlight:: python
    :linenothreshold: 0

Configuration
=============

.. image:: _static/images/configuration.png
   :alt: Configuration

When you're learning Flask, configuration seems simple. You just define
some variables in *config.py* and everything works. That simplicity
starts to fade away when you have to manage configuration for a
production application. You may need to protect secret API keys or use
different configurations for different environments (e.g. development
and production environments). In this chapter we'll go over some
advanced Flask features that makes this managing configuration easier.

The simple case
---------------

A simple application may not need any of these complicated features. You
may just need to put *config.py* in the root of your repository and load
it in *app.py* or *yourapp/\_\_init\_\_.py*

The *config.py* file should contain one variable assignment per line.
When your app is initialized, the variables in *config.py* are used to
configure Flask and its extensions are accessible via the ``app.config``
dictionary -- e.g. ``app.config["DEBUG"]``.

::

   DEBUG = True # Turns on debugging features in Flask
   BCRYPT_LEVEL = 12 # Configuration for the Flask-Bcrypt extension
   MAIL_FROM_EMAIL = "robert@example.com" # For use in application emails

Configuration variables can be used by Flask, extensions or you. In this
example, we could use ``app.config["MAIL_FROM_EMAIL"]`` whenever we
needed the default "from" address for a transactional email -- e.g.
password resets. Putting that information in a configuration variable
makes it easy to change it in the future.

::

    # app.py or app/__init__.py
    from flask import Flask

    app = Flask(__name__)
    app.config.from_object('config')

    # Now we can access the configuration variables via app.config["VAR_NAME"].

+---------------+---------------------------------------------------+----------------------------------------------+
| Variable      | Decription                                        | Recommendation                               |
+===============+===================================================+==============================================+
| DEBUG         | Gives you some handy tools for debugging errors.  | Should be set to ``True`` in development and |
|               | This includes a web-based stack trace and         | ``False`` in production.                     |
|               | interactive Python console for errors.            |                                              |
+---------------+---------------------------------------------------+----------------------------------------------+
| SECRET\_KEY   | This is a secret key that is used by Flask to     | This should be a complex random value.       |
|               | sign cookies. It's also used by extensions like   |                                              |
|               | Flask-Bcrypt. You should define this in your      |                                              |
|               | instance folder to keep it out of version         |                                              |
|               | control. You can read more about instance folders |                                              |
|               | in the next section.                              |                                              |
+---------------+---------------------------------------------------+----------------------------------------------+
| BCRYPT\_LEVEL | If you're using Flask-Bcrypt to hash user         | Later in this book we'll cover some of the   |
|               | passwords, you'll need to specify the number of   | best practices for using Bcrypt in your      |
|               | "rounds" that the algorithm executes in hashing a | Flask application.                           |
|               | password. If you aren't using Flask-Bcrypt, you   |                                              |
|               | should probably start. The more rounds used to    |                                              |
|               | hash a password, the longer it'll take for an     |                                              |
|               | attacker to guess a password given the hash. The  |                                              |
|               | number of rounds should increase over time as     |                                              |
|               | computing power increases.                        |                                              |
+---------------+---------------------------------------------------+----------------------------------------------+

.. warning::

   Make sure ``DEBUG`` is set to ``False`` in production. Leaving it on will allow users to run arbitrary Python code on your server.

Instance folder
---------------

Sometimes you'll need to define configuration variables that contain
sensitive information. We'll want to separate these variables from those
in *config.py* and keep them out of the repository. You may be hiding
secrets like database passwords and API keys, or defining variables
specific to a given machine. To make this easy, Flask gives us a feature
called **instance folders**. The instance folder is a sub-directory of
the repository root and contains a configuration file specifically for
this instance of the application. We don't want to commit it into
version control.

::

    config.py
    requirements.txt
    run.py
    instance/
      config.py
    yourapp/
      __init__.py
      models.py
      views.py
      templates/
      static/

Using instance folders
~~~~~~~~~~~~~~~~~~~~~~

To load configuration variables from an instance folder, we use
``app.config.from_pyfile()``. If we set
``instance_relative_config=True`` when we create our app with the
``Flask()`` call, ``app.config.from_pyfile()`` will load the
specified file from the *instance/* directory.

::

    # app.py or app/__init__.py

    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object('config')
    app.config.from_pyfile('config.py')

Now, we can define variables in *instance/config.py* just like you did
in *config.py*. You should also add the instance folder to your version
control system's ignore list. To do this with Git, you would add
``instance/`` on a new line in *.gitignore*.

Secret keys
~~~~~~~~~~~

The private nature of the instance folder makes it a great candidate for
defining keys that you don't want exposed in version control. These may
include your app's secret key or third-party API keys. This is
especially important if your application is open source, or might be at
some point in the future. We usually want other users and contributors
to use their own keys.

::

   # instance/config.py

   SECRET_KEY = 'Sm9obiBTY2hyb20ga2lja3MgYXNz'
   STRIPE_API_KEY = 'SmFjb2IgS2FwbGFuLU1vc3MgaXMgYSBoZXJv'
   SQLALCHEMY_DATABASE_URI= \
   "postgresql://user:TWljaGHFgiBCYXJ0b3N6a2lld2ljeiEh@localhost/databasename"

Minor environment-based configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the difference between your production and development environments
are pretty minor, you may want to use your instance folder to handle the
configuration changes. Variables defined in the *instance/config.py*
file can override the value in *config.py*. You just need to make the
call to ``app.config.from_pyfile()`` after
``app.config.from_object()``. One way to take advantage of this is to
change the way your app is configured on different machines.

::

   # config.py

   DEBUG = False
   SQLALCHEMY_ECHO = False


   # instance/config.py
   DEBUG = True
   SQLALCHEMY_ECHO = True

In production, we would leave the variables in Listing~ out of
*instance/-config.py* and it would fall back to the values defined in
*config.py*.

.. note::

   - Read more about Flask-SQLAlchemy's `configuration keys <http://pythonhosted.org/Flask-SQLAlchemy/config.html#configuration-keys>`_

Configuring based on environment variables
------------------------------------------

The instance folder shouldn't be in version control. This means that you
won't be able to track changes to your instance configurations. That
might not be a problem with one or two variables, but if you have finely
tuned configurations for various environments (production, staging,
development, etc.) you don't want to risk losing that.

Flask gives us the ability to choose a configuration file on load based
on the value of an environment variable. This means that we can have
several configuration files in our repository and always load the right
one. Once we have several configuration files, we can move them to their
own ``config`` directory.

::

    requirements.txt
    run.py
    config/
      __init__.py # Empty, just here to tell Python that it's a package.
      default.py
      production.py
      development.py
      staging.py
    instance/
      config.py
    yourapp/
      __init__.py
      models.py
      views.py
      static/
      templates/

In this listing we have a few different configuration files.

+-----------------------+------------------------------------------------------------------------------+
| config/default.py     | Default values, to be used for all environments or overridden by individual  |
|                       | environments. An example might be setting DEBUG = False in config/default.py |
|                       | and DEBUG = True in config/development.py.                                   |
+-----------------------+------------------------------------------------------------------------------+
| config/development.py | Values to be used during development. Here you might specify the URI of a    |
|                       | database sitting on localhost.                                               |
+-----------------------+------------------------------------------------------------------------------+
| config/production.py  | Values to be used in production. Here you might specify the URI for your     |
|                       | database server, as opposed to the localhost database URI used for           |
|                       | development.                                                                 |
+-----------------------+------------------------------------------------------------------------------+
| config/staging.py     | Depending on your deployment process, you may have a staging step where you  |
|                       | test changes to your application on a server that simulates a production     |
|                       | environment. You'll probably use a different database, and you may want to   |
|                       | alter other configuration values for staging applications.                   |
+-----------------------+------------------------------------------------------------------------------+

To decide which configuration file to load, we'll call
``app.config.from_envvar()``.

::

    # yourapp/__init__.py

    app = Flask(__name__, instance_relative_config=True)

    # Load the default configuration
    app.config.from_object('config.default')

    # Load the configuration from the instance folder
    app.config.from_pyfile('config.py')

    # Load the file specified by the APP_CONFIG_FILE environment variable
    # Variables defined here will override those in the default configuration
    app.config.from_envvar('APP_CONFIG_FILE')

The value of the environment variable should be the absolute path to a
configuration file.

How we set this environment variable depends on the platform in which
we're running the app. If we're running on a regular Linux server, we
can set up a shell script that sets our environment variables and runs
*run.py*.

::

   # start.sh

   APP_CONFIG_FILE=/var/www/yourapp/config/production.py
   python run.py

*start.sh* is unique to each environment, so it should be left out of
version control. On Heroku, we'll want to set the environment variables
with the Heroku tools. The same idea applies to other PaaS platforms.

Summary
-------

-  A simple app may only need one configuration file: *config.py*.
-  Instance folders can help us hide secret configuration values.
-  Instance folders can be used to alter an application's configuration
   for a specific environment.
-  We should use environment variables and
   ``app.config.from_envvar()`` for more complicated environment-based
   configurations.

