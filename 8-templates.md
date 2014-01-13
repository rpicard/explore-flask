![Templates](images/8.png)

# Templates

While Flask doesn't force you to use any particular templating language, it assumes that you're going to use Jinja. Most of the developers in the Flask community use Jinja, and I recommend that you do the same. There are a few extensions that have been written to let you use other templating languages, but unless you have a good reason (not knowing Jinja yet is not a good reason!) stick with the default; you'll save yourself a lot of time and headache.

{ NOTE: Almost all resources imply Jinj2 when they refer to "Jinja." There was a Jinja1, but we be dealing with it here. When you see Jinja, we're talking about this: http://jinja.pocoo.org/ }

{ SEE MORE: Here are a couple of those extensions for other templating languages.
* Flask-Genshi: http://pythonhosted.org/Flask-Genshi/
* Flask-Mako: http://pythonhosted.org/Flask-Mako/
}

## A quick primer on Jinja

The Jinja documentation does a great job of explaining the syntax and features of the language. I won't reiterate it all here, but I do want to make sure that you see this important note:

> There are two kinds of delimiters. `{% ... %}` and `{{ ... }}`. The first one is used to execute statements such as for-loops or assign values, the latter prints the result of the expression to the template.

{ SOURCE: http://jinja.pocoo.org/docs/templates/#synopsis }

## How to organize templates

So where do templates fit into our app? If you've been following along at home, you may have noticed that Flask is really flexible about where you put things. Templates are no exception. You may also notice that there's usually a recommended place to put things. Two points for you. For templates, that place is in the package directory.

```
myapp/
    __init__.py
    models.py
    views/
    templates/
    static/
run.py
requirements.txt
```

Let's take a closer look at that templates directory.

```
templates/
    layout.html
    index.html
    about.html
    profile/
        layout.html
        index.html
	photos.html
    admin/
        layout.html
        index.html
        analytics.html
```

The structure of the templates parallels the structure of the routes. The template for route myapp.com/admin/analytics is _templates/admin/analytics.html_. There are also some extra templates in there that won't be rendered directly. The _layout.html_ files are meant to be inherited by the other templates.

## Inheritance

Much like Batman’s backstory, a well organized templates directory relies heavily on inheritance. The **base template** usually defines a generalized structure that all of the **child templates** will work within. In our example, _layout.html_ is a base template and the other _.html_ files are child templates.

You’ll generally have one top-level _layout.html_ that defines the general layout for your application and one for each section of your site. If you take a look at the directory above, you’ll see that there is a top-level _myapp/templates/layout.html_ as well as _myapp/templates/profile/layout.html_ and _myapp/templates/admin/layout.html_. The last two files inherit and modify the first.

Inheritance is implemented with the `{% extends %}` and `{% block %}` tags. In the parent template, you can define blocks which will be populated by child templates.

_myapp/templates/layout.html_
```
<!DOCTYPE html>
<html lang="en">
	<head>
    	<title>{% block title %}{% endblock %}</title>
    </head>
    <body>
    {% block body %}
    	<h1>This heading is defined in the parent.</h1>
    {% endblock %}
    </body>
</html>
```

In the child template, you can extend the parent template and define the contents of those blocks.

_myapp/templates/index.html_
```
{% extends "layout.html" %}
{% block title %}Hello world!{% endblock %}
{% block body %}
	{{ super() }}
    <h2>This heading is defined in the child.</h2>
{% endblock %}
```

The `super()` function lets us include the current contents of the block when we redefined them in the child.

{ SEE ALSO: For more information on inheritance, refer to the Jinja Template Inheritence documentation.
* http://jinja.pocoo.org/docs/templates/#template-inheritance
}

## Creating macros

We can implement DRY (Don't Repeat Yourself) principles in our templates by abstracting snippets of code that appear over and over into **macros**. If we're working on some HTML for our app's navigation, we might want to give a different class to the “active” link (i.e. the link to the current page). Without macros we'd end up with a block of if/else statements checking each link to find the acive one. Macros provide a way to modularize that code; they work like functions. Let's look at how we'd mark the active link using a macro.

myapp/templates/layout.html
```
{% from "macros.html" import nav_link with context %}
<!DOCTYPE html>
<html lang="en">
    <head>
    {% block head %}
        <title>My application</title>
    {% endblock %}
    </head>
    <body>
        <ul class="nav-list">
            {{ nav_link('home', 'Home') }}
            {{ nav_link('about', 'About') }}
            {{ nav_link('contact', 'Get in touch') }}
        </ul>
    {% block body %}
    {% endblock %}
    </body>
</html>
```

What we are doing is calling an undefined macro — `nav_link` — and passing it two parameters: the target endpoint (i.e. the function name for the target view) and the text we want to show.

{ NOTE: You may notice that we specified “with context” in the import statement. The Jinja **context** consists of the arguments passed to the `render_template()` function as well as the Jinja environment context from our Python code. These variables are made available in the template that is being rendered. Some variables are explicitly passed by us, e.g. `render_template("index.html", color="red")`, but there are several variables and functions that Flask automatically includes in the context , e.g. `request`, `g` and `session`. When we say `{% from ... import ... with context %}` we are telling Jinja to make all of these variables available to the macro as well.

}

{ SEE ALSO:
* All of the global variables that are passed to the Jinja context by Flask: http://flask.pocoo.org/docs/templating/#standard-context}
* We can define variables and functions that we want to be merged into the Jinja context with context processors: http://flask.pocoo.org/docs/templating/#context-processors }

Now let’s take a look at the macro itself:

myapp/templates/macros.html
```
{% macro nav_link(endpoint, text) %}
{% if request.endpoint.endswith(endpoint) %}
    <li class="active"><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
{% else %}
    <li><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
{% endif %}
{% endmacro %}
```

Now we've defined the macro in _myapp/templates/macros.html_. What we're doing is using Flask's `request` object — which is available in the Jinja context by default — to check whether or not the current request was routed to the endpoint passed to `nav_link`. If it was, than we're currently on that page, and we can mark it as active.

{ NOTE: The from x import y statement takes a relative path for x. If our template was in _myapp/templates/user/blog.html_ we would use `from "../macros.html" import nav_link with context`.
}

## Custom filters

Jinja filters are functions that can be applied to the result of an expression in the `{{ ... }}` delimeters before that result is printed to the template. Here's a look at the syntax:

```
<h2>{{ article.title|title }}</h2>
```

In this snippet, the `title` filter will take `article.title` and return a title-cased version, which will then be printed to the template. The syntax, and functionality, is very much like the UNIX practice of "piping" the output of one program to another.

{ SEE MORE: There are loads of built-in filters like `title`. See the full list here: http://jinja.pocoo.org/docs/templates/#builtin-filters }

We can define our own filters for use in our Jinja templates. As an example, we’ll implement a simple `caps` filter to capitalize all of the letters in a string.

{ NOTE: Jinja already has an `upper` filter that does this, as well as a `capitalize` filter that capitalizes the first character and lowercases the rest. These also handle unicode conversion, but we’ll keep our example focused on the concept at hand.}

We’re going to define our filter in a module located at _myapp/util/filters.py_. This gives us a `util` package in which to put other miscellaneous modules.

myapp/util/filters.py
```
from .. import app

@app.template_filter()
def caps(text):
    """Convert a string to all caps."""
    return text.uppercase()
```

We are registering our function as a Jinja filter by using the `@app.template_filter()` decorator. The default filter name is just the name of the function, but you can pass an argument to the decorator to change that:

```
@app.template_filter('make_caps')
def caps(text):
    """Convert a string to all caps."""
    return text.uppercase()
```

Now we can call `make_caps` in the template rather than `caps`:  `{{ "hello world!"|make_caps }}`.

To make our filter available in the templates, we just need to import it in our top-level ___init.py_.

myapp/__init__.py
```
# Make sure app has been initialized first to prevent circular imports.
from .util import filters
```

## Summary

* Use Jinja for templating.
* Jinja has two kinds of delimeters: `{% ... %}` and `{{ ... }}`. The first one is used to execute statements such as for-loops or assign values, the latter prints the result of the contained expression to the template.
* Templates should go in _myapp/templates/_ — i.e. a directory inside of the application package.
* I recommend that the structure of the _templates/_ directory mirror the URL structure of the app.
* You should have a top-level _layout.html_ in _myapp/templates_ as well as one for each section of the site. The former extend the latter.
* Macros are like functions made-up of template code.
* Filters are functions made-up of Python code and used in templates.