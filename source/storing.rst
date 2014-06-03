Storing data
============

.. figure:: _static/images/storing.png
   :alt: Storing data

   Storing data
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
*myapp/\ **init**.py*

\\begin{codelisting}

.. code:: python

    # ourapp/__init__.py

    from flask import Flask
    from flask.ext.sqlalchemy import SQLAlchemy

    app = Flask(__name__, instance_relative_config=True)

    app.config.from_object('config')
    app.config.from_pyfile('config.py')

    db = SQLAlchemy(app)

\\end{codelisting}

First we initialize and configure our Flask app and then we use it to
initialize our SQLAlchemy database handler. We're going to use an
instance folder for our database configuration so we should use the
``instance_relative\-_config`` option when initializing the app and then
call ``app.config.fr\-om_pyfile`` to load it. Then we can define our
models.

.. raw:: latex

   \begin{codelisting}
   \label{code:engine_model1}
   \codecaption{An example class for an "Engine" object}
   ```python
   # ourapp/models.py

   from . import db 

   class Engine(db.Model):

       # Columns

       id = db.Column(db.Integer, primary_key=True, autoincrement=True)

       title = db.Column(db.String(128))

       thrust = db.Column(db.Integer, default=0)
   ```
   \end{codelisting}

``Column``, ``Integer``, ``String``, ``Model`` and other SQLAlchemy
classes are all available via the ``db`` object constructed from
Flask-SQLAlchemy. In Listing~ we have defined a model to store the
current state of our spacecraft's engines. Each engine has an id, a
title and a thrust level.

We still need to add some database information to our configuration.
We're using an instance folder to keep confidential configuration
variables out of version control, so we are going to put it in
*instance/config.py*.

.. raw:: latex

   \begin{codelisting}
   \label{code:}
   \codecaption{Configuring our database}
   ```python
   # instance/config.py

   SQLALCHEMY_DATABASE_URI = "postgresql://user:password@localhost/spaceshipDB"
   ```
   \end{codelisting}

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{WARNING}

   Don't forget to put a plan in place to back up your data. The details of that plan are outside the scope of this book, but you should always have your datbase backed up in a secure and robust way.

   \end{aside}

--------------

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on NoSQL}

   The NoSQL scene is less established with Flask, but as long as the database engine of your choice has a Python library, you should be able to use it. There are even several extensions in the Flask extension registry to help integrate NoSQL engines with Flask: [http://flask.pocoo.org/extensions/](http://flask.pocoo.org/extensions/)

   \end{aside}

Summary
-------

-  Use SQLAlchemy to work with relational databases.
-  Use Flask-SQLAlchemy to work with SQLAlchemy.
-  Alembic helps you migrate your data between schema changes.
-  You can use NoSQL databases with Flask, but the methods and tools
   vary between engines.
-  Back up your data!

