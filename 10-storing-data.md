Most Flask applications are going to deal with storing data at some point. There are many different ways to store data. Finding the best one depends entirely on the data you are going to store. If you are storing relational data (e.g. a user has many posts and a post has one user) a relational database is probably going to be the way to go (big suprise). Other types of data might be more suited to NoSQL data stores, such as MongoDB.

I am not going to tell you how to choose a database engine for your application. There are people who will tell you that NoSQL is the only way to go and those who will say the same about relational databases. All I will say on that subject is that if you are unsure, a relational database (MySQL, PostgreSQL, etc.) will almost certainly work for whatever you are doing.

Plus, when you use a relational database you get to use SQLAlchemy and SQLAlchemy is fun.

# SQLAlchemy

SQLAlchemy is an ORM (Object Relational Mapper). It is basically an abstraction that sits on top of the raw SQL queries being executed on your database. It provides a consistent API to a long list of database engines. The most popular include MySQL, PostgreSQL, and SQLite. This makes it easy to move data between your models and your databse and it makes it really easy to do other things like switch database engines and migrate your schemas.

There is a great Flask extension that makes using SQLAlchemy in Flask even easier. It is called Flask-SQLAlchemy. Flask-SQLAlchemy configures a lot of sane defaults for SQLAlchemy. It also handles some sesssion management so that you don't have to deal with janitorial stuff in your application code.

Let's dive into some code. We are going to define some models then configure some SQLAlchemy. The models are going to go in _myapp/models.py_, but first we are going to define our database in _myapp/__init__.py_

_myapp/__init__.py_
```
from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__, instance_relative_config=True)

app.config.from_object('config')
app.config.from_pyfile('config.py')

db = SQLAlchemy(app)
```

Initialize and configure your Flask app then use it to initialize your SQLAlchemy database handler. We are going to use an instance folder for our database configuration so we should use the `instance_relative_config` option when initializing the app and then call `app.config.from_pyfile`. Then you can define your models.

_myapp/models.py_
```
from . import db 

class Engine(db.Model):

    # Columns

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    title = db.Column(db.String(128))

    thrust = db.Column(db.Integer, default=0)
```

`Column`, `Integer`, `String`, `Model` and other SQLAlchemy classes are all available via the `db` object constructed from Flask-SQLAlchemy. Here we have defined a model to store the current state of our spacecraft's engines. Each engine has an id, a title and a thrust level.

We still need to add some database information to our configuration. We are using an instance folder to keep confidential configuration variables out of version control, so we are going to put it in _instance/config.py_.

_instance/config.py_
```
SQLALCHEMY_DATABASE_URI = "postgresql://user:password@localhost/spaceshipDB"
```

{ SEE MORE: Your database URI will be different depending on the engine you use and where it is hosted. See the SQLAlchemy documentation for this here: http://docs.sqlalchemy.org/en/latest/core/engines.html?highlight=database#database-urls }

## Initializing the database

Now that the database is configured and we have defined a model, we can initialize the database. This step basically involves creating that database scheme from the model definitions.

Normally that might be a real pain in the neck to do. Lucky for us, SQLAlchemy has a really cool command that will do all of this for us.

Let's open up a Python terminal in our repository root.

```
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
```

Now, thanks to SQLAlchemy, you will find that the tables have been created in the database specified in your configuration.

## Alembic migrations

The schema of a database is not set in stone. For example, you may want to add a `last_fired` column to the engine table. If you don't have any data, you can just update the model and run `db.create_all()` again. However, if you have six months of engine data logged in that table, you probably do not want to start over from scratch. That's where database migrations come in.

Alembic is a database migration tool created specifically for use with SQLAlchemy. It lets you keep a versioned history of your database schema so that you can upgrade to a new schema and even downgrade back to an older one.

Alembic has an extensive tutorial to get you started, so I'll just give you a quick overview and point out a couple of things to watch out for.

You will create your alembic "migration environment" via an installed `alembic init` command. Run this in your repository root and you will end up with a new directory with the very clever name `alembic`. Your repository will end up looking something like this example adapted from the Alembic tutorial:

```
myapp/
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
    
```

The _alembic/_ directory has the scripts that migrate your data from version to version. There is also an _alembic.ini_ file that contains configuration information.

{ WARNING: Add _alembic.ini_ to _.gitignore_! You are going to have your database credentials in the file so you **do not** want it to end up in version control.

You do want to keep _alembic/_ in versin control though. It does not contain sensitive information (that can't already be derived from your source code) and keeping it in version control will mean having several copies should something happen to the files on your computer. }

When it comes time to make a schema change, there are a couple of steps. First your run `alembic revision` to generate a migration script. Open up the newly generated Python file in _myapp/alembic/versions/_ and fill in the `upgrade` and `downgrade` functions using Alembic's `op` object.

Once we have our migration script ready, we can run `alembic upgrade head` to migrade our data to the latest version.

{ SEE MORE: For the details on configuring Alembic, creating your migration scripts and running your migrations see the Alembic tutorial: http://alembic.readthedocs.org/en/latest/tutorial.html }

{ WARNING: Don't forget to put a plan in place to back up your data. The details of that plan are outside the scope of this book, but you should always have your datbase backed up in a secure and robust way. }

# NoSQL options
# Search (WhooshAlchemy?)
# Summary