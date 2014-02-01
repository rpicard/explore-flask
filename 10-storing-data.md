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

## Initialize database (create_all)

## Create and save data via the model


## Alembic migrations
{ WARNING: Don't forget to back up your data! }

# NoSQL options
# Search (WhooshAlchemy?)
# Summary