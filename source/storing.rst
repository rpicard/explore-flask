
.. highlight:: python
    :linenothreshold: 0

Storing data
============

.. image:: _static/images/storing.png
   :alt: Storing data

Most Flask applications are going to deal with storing data at some
point. There are many different ways to store data. Finding the best one
depends entirely on the data you are going to store. If you are storing
relational data (e.g. a user has posts, posts have a user, etc.) a
relational database is probably going to be the way to go (big suprise).
Other types of data might be more suited to NoSQL data stores, such as
MongoDB.

I'm not going to tell you how to choose a database engine for your
application. There are people who will tell you that NoSQL is the only
way to go and those who will say the same about relational databases.
All I will say on that subject is that if you are unsure, a relational
database (MySQL, PostgreSQL, etc.) will almost certainly work for
whatever you're doing.

Plus, when you use a relational database you get to use SQLAlchemy and
SQLAlchemy is fun.

SQLAlchemy
----------

SQLAlchemy is an ORM (Object Relational Mapper). It's basically an
abstraction layer that sits on top of the raw SQL queries being executed
on our database. It provides a consistent API to a long list of database
engines. The most popular include MySQL, PostgreSQL and SQLite. This
makes it easy to move data between our models and our database and it
makes it really easy to do other things like switch database engines and
migrate our schemas.

There is a great Flask extension that makes using SQLAlchemy in Flask
even easier. It's called Flask-SQLAlchemy. Flask-SQLAlchemy configures a
lot of sane defaults for SQLAlchemy. It also handles some session
management so we don't have to deal with janitorial stuff in our
application code.

Let's dive into some code. We're going to define some models then
configure some SQLAlchemy. The models are going to go in
*myapp/models.py*, but first we are going to define our database in
*myapp/__init__.py*

::

    # ourapp/__init__.py

    from flask import Flask
    from flask.ext.sqlalchemy import SQLAlchemy

    app = Flask(__name__, instance_relative_config=True)

    app.config.from_object('config')
    app.config.from_pyfile('config.py')

    db = SQLAlchemy(app)

First we initialize and configure our Flask app and then we use it to
initialize our SQLAlchemy database handler. We're going to use an
instance folder for our database configuration so we should use the
``instance_relative_config`` option when initializing the app and then
call ``app.config.from_pyfile`` to load it. Then we can define our
models.

::

   # ourapp/models.py

   from . import db 

   class Engine(db.Model):

       # Columns

       id = db.Column(db.Integer, primary_key=True, autoincrement=True)

       title = db.Column(db.String(128))

       thrust = db.Column(db.Integer, default=0)

``Column``, ``Integer``, ``String``, ``Model`` and other SQLAlchemy
classes are all available via the ``db`` object constructed from
Flask-SQLAlchemy. We have defined a model to store the
current state of our spacecraft's engines. Each engine has an id, a
title and a thrust level.

We still need to add some database information to our configuration.
We're using an instance folder to keep confidential configuration
variables out of version control, so we are going to put it in
*instance/config.py*.

::

   # instance/config.py

   SQLALCHEMY_DATABASE_URI = "postgresql://user:password@localhost/spaceshipDB"

.. note::

   Your database URI will be different depending on the engine you use and where it's hosted. See the `SQLAlchemy documentation for this syntax <http://docs.sqlalchemy.org/en/latest/core/engines.html?highlight=database#database-urls>`_.

Initializing the database
~~~~~~~~~~~~~~~~~~~~~~~~~

Now that the database is configured and we have defined a model, we can
initialize the database. This step basically involves creating the
database schema from the model definitions.

Normally that process might be a pain in the ... neck. Lucky for us,
SQLAlchemy has a really cool command that will do all of this for us.

Let's open up a Python terminal in our repository root.

::

    $ pwd
    /Users/me/Code/myapp
    $ workon myapp
    (myapp)$ python
    Python 2.7.5 (default, Aug 25 2013, 00:04:04) 
    [GCC 4.2.1 Compatible Apple LLVM 5.0 (clang-500.0.68)] on darwin
    Type "help", "copyright", "credits" or "license" for more information.
    >>> from myapp import db
    >>> db.create_all()
    >>>

Now, thanks to SQLAlchemy, our tables have been created in the database
specified in our configuration.

Alembic migrations
~~~~~~~~~~~~~~~~~~

The schema of a database is not set in stone. For example, we may want
to add a ``last_fired`` column to the engine table. If we don't have any
data, we can just update the model and run ``db.create_all()`` again.
However, if we have six months of engine data logged in that table, we
probably don't want to start over from scratch. That's where database
migrations come in.

Alembic is a database migration tool created specifically for use with
SQLAlchemy. It lets us keep a versioned history of our database schema
so that we can later upgrade to a new schema and even downgrade back to
an older one.

Alembic has an extensive tutorial to get you started, so I'll just give
you a quick overview and point out a couple of things to watch out for.

We'll create our alembic "migration environment" via the
``alembic init`` command. Once we run this in our repository root
we'll have a new directory with the very creative name *alembic*. Our
repository will end up looking something like the example in this listing,
adapted from the Alembic tutorial.

::

    ourapp/
        alembic.ini
        alembic/
            env.py
            README
            script.py.mako
            versions/
                3512b954651e_add_account.py
                2b1ae634e5cd_add_order_id.py
                3adcc9a56557_rename_username_field.py
        myapp/
            __init__.py
            views.py
            models.py
            templates/
        run.py
        config.py
        requirements.txt


The *alembic/* directory has the scripts that migrate our data between
versions. There is also an *alembic.ini* file that contains
configuration information.

.. note::

    Add *alembic.ini* to *.gitignore*! You are going to have your database
    credentials in this file, so you **do not** want it to end up in version
    control.

    You do want to keep *alembic/* in version control though. It does not
    contain sensitive information (that can't already be derived from your
    source code) and keeping it in version control will mean having multiple
    copies should something happen to the files on your computer.

When it comes time to make a schema change, there are a couple of steps.
First we run ``alembic revision`` to generate a migration script. Then
we'll open up the newly generated Python file in
*myapp/alembic/versions/* and fill in the ``upgrade`` and ``downgrade``
functions using the tools provided by Alembic's ``op`` object.

Once we have our migration script ready, we can run
``alembic upgrade head`` to migrade our data to the latest version.

.. note::

   For the details on configuring Alembic, creating your migration scripts and running your migrations, see `the Alembic tutorial <http://alembic.readthedocs.org/en/latest/tutorial.html>`_.

.. warning::

   Don't forget to put a plan in place to back up your data. The details of that plan are outside the scope of this book, but you should always have your database backed up in a secure and robust way.

.. note::

   The NoSQL scene is less established with Flask, but as long as the database engine of your choice has a Python library, you should be able to use it. There are even several extensions in `the Flask extension registry <http://flask.pocoo.org/extensions/>`_ to help integrate NoSQL engines with Flask.

Summary
-------

-  Use SQLAlchemy to work with relational databases.
-  Use Flask-SQLAlchemy to work with SQLAlchemy.
-  Alembic helps you migrate your data between schema changes.
-  You can use NoSQL databases with Flask, but the methods and tools
   vary between engines.
-  Back up your data!

