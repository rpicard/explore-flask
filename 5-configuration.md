![image](images/5.png)

# Configuration

When you're learning Flask, configuration seems simple. You just define some variables in config.py and everything works. That simplicity starts to fade away when you have to manage configuration for a production application. You may need to protect secret API keys or use different configurations for different environments (e.g. development and production). There are some advanced Flask features available to help us make this easier.

## The simple case

A simple application may not need any of these complicated features. You may just need to put _config.py_ in the root of your repository and load it in _app.py_ or _yourapp/__init__.py_

 _config.py_ is should contain one variable assignment per line. Once _config.py_ is loaded later, the configuration variables will be accessible via the `app.config` dictionary, e.g. `app.config[“DEBUG”]`. Here’s an example of a typical _config.py_ file for a small project:

```
DEBUG = True # Turns on debugging features in Flask
BCRYPT_LEVEL = 13 # Configuration for the Flask-Bcrypt extension
MAIL_FROM_EMAIL = "robert@robert.io" # For use in application emails
```

There are some built-in configuration variables like `DEBUG`. There are also some configuration variables for extensions that you may be using like `BCRYPT_LEVEL` for the Flask-Bcrypt extension, used for password hashing. You can even define your own configuration variables for use throughout the application. In this example, I would use `app.config[“MAIL_FROM_EMAIL”]` whenever I needed the default “from” address for a transactional email (e.g. password resets). It makes it easy to change that later on.

To load these configuration variables into the application, I would use `app.config.from_object()` in _app.py_ for a single-module application or _yourapp/__init__.py_ for a package based application. In either case, the code looks something like this:

```
from flask import Flask

app = Flask(__name__)
app.config.from_object('config')
# Now I can access the configuration variables via app.config["VAR_NAME"].
```

### Some important configuration variables

{ THIS INFORMATION SHOULD BE IN A TABLE }

* VARIABLE : DESCRIPTION : DEFAULT VALUE
* DEBUG : Gives you some handy tools for debugging errors. This includes a web-based stack trace and Python console when an request results in an application error. : Should be set to True in development and False in production.
* SECRET_KEY : This is a secret key that is used by Flask to sign cookies and other things. You should define this in your instance folder to keep it out version control. You can read more about instance folders in the next section. : This should be a complex random value.
* BCRYPT_LEVEL : If you’re using Flask-Bcrypt to hash user passwords (if you’re not, start now), you’ll need to specify the number of “rounds” that the algorithm executes in hashing a password. The more rounds used in hashing, the longer it will be for a computer hash (and importantly, to crack) the password. The number of rounds used should increase over time as computing power increases. : As a rule of thumb, take the last two digits of the current year and use that value. For example, I’m writing this in 2013, so I’m currently using a `BCRYPT_LEVEL = 13`. You’ll often hear that you should choose the highest possible level before you application becomes too slow to bear. That’s true, but it’s tough to translate into a number to use. Feel free to play around with higher numbers, but you should be alright with that rule of thumb.

{ WARNING: Make sure DEBUG = False in production. Leaving it on will allow users to run arbitrary Python code on your server. }

## Instance folder

Sometimes you’ll need to define configuration variables that shouldn’t be shared. For this reason, you’ll want to separate them from the variables in _config.py_ and keep them out of the repository. You may be hiding secrets like database passwords and API keys, or defining variables specific to your current machine. To make this easy, Flask gives us a feature called Instance folders. The instance folder is a subdirectory sits in the repository root and contains a configuration file specifically for this instance of the application. It is not committed to version control.

Here’s a simple repository for a Flask application using an instance folder:

```
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
```

### Using instance folders

To load the configuration variables defined inside of an instance folder, you can use `app.config.from_pyfile()`. If we set `instance_relative_config=True` when we create our app with the `Flask()` call, `app.config.from_pyfile()` will check for the specified file in the _instance/_ directory.

```
app = Flask(__name__, instance_relative_config=True)
app.config.from_object('config')
app.config.from_pyfile('config.py')
```

Now, you can define variables in _instance/config.py_ just like you did in _config.py_. You should also add the instance folder to your version control system’s ignore list. To do this with git, you would save `instance/` on a new line in  _gitignore_.

### Secret keys

The private nature of the instance folder makes it a great candidate for defining keys that you don't want exposed in version control. These may include your app's secret key or third-party API keys. This is especially important if your application is open source, or might be at some point in the future.

Your _instance/config.py_ file might look something like this:

{ THIS COULD BE A GOOD CHANCE TO ENCODE BACKER NAMES! }

```
SECRET_KEY = 'ABCDEFG' # This is a bad secret key!
STRIPE_API_KEY = 'yekepirtsaton'
SQLALCHEMY_DATABASE_URI = "postgresql://username:password@localhost/databasename"
```

### Minor environment-based configuration

If the difference between your production and development environments are pretty minor, you may want to use your instance folder to handle the configuration changes. Variables defined in the instance/config.py file can override the value in config.py. You just need to make the call to `app.config.from_pyfile()` after `app.config.from_object()`.  One way to take advantage of this is to change the way your app is configured on different machines. Your development repository might look like this:

config.py
```
DEBUG = False
SQLALCHEMY_ECHO = False
```

instance/config.py
```
DEBUG = True
SQLALCHEMY_ECHO = True
```

Then in production, you would leave these lines out of _instance/config.py_ and it would fall back to the values defined in _config.py_. 

{ SEE MORE:
* Read about Flask-SQLAlchemy’s configuration keys here: http://pythonhosted.org/Flask-SQLAlchemy/config.html#configuration-keys
}

## Configuring from envvar

The instance folder shouldn’t be in version control. This means that you won’t be able to track changes to your instance configurations. That might not be a problem with one or two variables, but if you have a finely tuned configurations for various environments (production, staging, development, etc.) you don’t want to risk loosing that. 

Flask gives us the ability to choose a configuration file on the fly based on the value of an environment variable. This means that we can have several configuration files in our repository (and in version control) and always load the right one, depending on the environment.

When we’re at the point of having several configuration files in the repository, it’s time to move those files into a `config` package. Here’s what that looks like in a repository:

```
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
```

In this case we have a few different configuration files:

{ PUT THIS IN A TABLE }

* _config/default.py_ : Default values, to be used for all environments or overridden by individual environments. An example might be setting `DEBUG = False` in _config/default.py_ and `DEBUG = True` in _config/development.py_.
* _config/development.py_ : Values to be used during development. Here you might specify the URI of a database sitting on localhost.
* _config/production.py_ : Values to be used in production. Here you might specify the URI for your database server, as opposed to the localhost database URI used for development.
* _config/staging.py_ : Depending on your deployment process, you may have a staging step where you test changes to your application on a server that simulates a production environment. You’ll probably use a different database, and you may want to alter other configuration values for staging applications.

To actually use these files in your various environments, you can make a call to `app.config.from_envvar()`:

yourapp/__init__.py
```
app = Flask(__name__, instance_relative_config=True)
app.config.from_object('config.default')
app.config.from_pyfile('config.py') # Don't forget our instance folder
app.config.from_envvar('APP_CONFIG_FILE')
```

`app.config.from_envvar(‘APP_CONFIG_FILE’)` will load the file specified in the environment variable `APP_CONFIG_FILE`. The value of that environment variable should be the full path of a configuration file. 


How you set this environment variable depends on the platform on which you’re running your app. If you’re running on a regular Linux server, you could set up a shell script that sets the environment variables and runs `run.py`:

start.sh
```
APP_CONFIG_FILE=/var/www/yourapp/config/production.py
python run.py
```

If you’re using Heroku, you’ll want to set the environment variables with the Heroku tools. The same idea applies to other “PaaS” platforms.

## Summary

* A simple app may only need one configuration file: _config.py_.
* Instance folders can help us hide secret configuration values.
* Instance folders can be used to alter an application’s configuration for a specific environment.
* We should use environment variables and `app.config.from_envvar()` for complicated, environment-based configurations.
