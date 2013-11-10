![4.png](images/4.png)

# Organizing your project

Flask doesn't require that your project directory have a certain structure. Unlike Django, which comes with a startapp tool to create your application skeletons, Flask leaves the organization of your application up to you. This is one of the reasons I liked Flask as a beginner, but it does mean that you have to put some thought into how to structure your code. You could put your entire application in one file, or have it spread across multiple packages. Neither of these is ideal for most projects though. There are a few organizational patterns that you can use to make development and deployment easier.

## Definitions

There are a few terms that I want to define for this section.

Repository: This is the base folder where your applications sits. This term traditionally refers to version control systems, but that’s out of the scope here. When I refer to your repository in this chapter, I’m talking about the root directory of your project. You probably won't need to leave this directory when working on your application.

Package: This refers to a Python package that contains your application's code. I'll talk more about setting up your app as a package in this chapter, but for now just know that the package is a sub-directory of the repository.

Module: A module is a single Python file that can be imported by other Python files. A package is essentially multiple modules packaged together.

{ SEE ALSO:
* Read more about Python modules here: http://docs.python.org/2/tutorial/modules.html
* That link has a section on packages as well: http://docs.python.org/2/tutorial/modules.html#packages
}

## Organization patterns

### Single module

A lot of Flask examples that you come across will keep all of the code in a single file, often _app.py_. This is great for quick projects, where you just need to serve a few routes and you’ve got less than a few hundred lines of application code.

The repository for a single module application might look something like this:

```
app.py
config.py
requirements.txt
static/
templates/
```

Application logic would sit in _app.py_ in this example. 

### Package

When you’re working on a project that’s a little more complex, a single module can get messy. You’ll need to define classes for models and forms, and they’ll get mixed in with the code for your routes and configuration. All of this can frustrate development. To solve this problem, we can factor out the different components of our app into a group of inter-connected modules — a package.

The repository for a package-based application will probably look something like this: 

```
config.py
requirements.txt
run.py
instance/
  /config.py
yourapp/
  /__init__.py
  /views.py
  /models.py
  /forms.py
  /static/
  /templates/
```

This structure allows you to group the different components of your application in a logical way. The class definitions for models are together in _models.py_, the route definitions are in _views.py_, and forms are defined in _forms.py_ (we’ll talk about forms later).

This table provides a basic rundown of the components you'll find in most Flask applications:

{ THE FOLLOWING DATA SHOULD BE IN A TABLE }

/run.py : This is the file that is invoked to start up a development server. It gets a copy of the app from your package and runs it. This won't be used in production, but it will see a lot of mileage in development.

/requirements.txt : This file lists all of the Python packages that your app depends on. You may have separate files for production and development dependencies.

/config.py : This file contains most of the configuration variables that your app needs.

/instance/config.py : This file contains configuration variables that shouldn’t be in version control. This includes things like API keys and database URIs containing passwords. This also contains variables that are specific to this particular instance of your application. For example, you might have DEBUG = False in config.py, but set DEBUG = True in instance/config.py on your local machine for development. Since this file will be read in after config.py, it will override it and set DEBUG = False.

/yourapp/ : This is the package that contains your application.

/yourapp/__init__.py : This file initializes your application and brings together all of the various components.

/yourapp/views.py : This is where the routes are defined. It may be split into a package of its own (_yourapp/views/_) with related views grouped together into modules.

/yourapp/models.py : This is where you define the models of your application. This may be split into several modules in the same way as views.py.

/yourapp/static/ : This file contains the public CSS, JavaScript, images and other files that you want to make public via your app. It is accessible from yourapp.com/static/ by default.

/yourapp/templates/ : This is where you'll put the Jinja2 templates for your app.

There will probably be several other files included in your app in the end, but these are common to most Flask applications.

### Blueprints

At some point you may find that you have a lot of related routes. If you’re like me, your first thought will be to split _views.py_ into a package and group related views into modules. When you’re at this point, it may be time to factor your application into blueprints.

Blueprints are essentially components of your app defined in a somewhat self-contained manner. They act as apps within your application. You might have different blueprints for the admin panel, the front-end and the user dashboard. This lets your group views, static files and templates by components, while letting you share models, forms and other aspects of your application between several components.

{ SEE ALSO:
* You can read more about blueprints in chapter 7.
}

## Summary

* Using a single module for your application is good for quick projects.
* Using a package for your application is good for projects with views, models, forms, etc.
* Blueprints are a great way to organize projects with several distinct components.
