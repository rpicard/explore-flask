Templates
=========

.. figure:: images/templates.png
   :alt: Templates

   Templates
While Flask doesn't force us to use any particular templating language,
it assumes that we're going to use Jinja. Most of the developers in the
Flask community use Jinja, and I recommend that you do the same. There
are a few extensions that have been written to let us use other
templating languages, but unless you have a good reason (not knowing the
Jinja syntax yet is not a good reason!) stick with the default; you'll
save yourself a lot of time and headache.

.. raw:: latex

   \begin{aside}
   \label{aside:jinja2_note}
   \heading{A note on terminology}

   Almost all resources imply Jinja2 when they refer to "Jinja." There was a Jinja1, but we won't be dealing with it here. When you see Jinja, we're talking about this: [http://jinja.pocoo.org/](http://jinja.pocoo.org/)
   \end{aside}

\\begin{aside}

-  All of the global variables that are passed to the Jinja context by
   Flask: http://flask.pocoo.org/docs/templating/#standard-context}
-  We can define variables and functions that we want to be merged into
   the Jinja context with context processors:
   http://flask.pocoo.org/docs/templating/#context-processors

\\end{aside}

Now it's time time to define the macro that we used in Listing~.

\\begin{codelisting}

.. code:: jinja

    {# myapp/templates/macros.html #}

    {% macro nav_link(endpoint, text) %}
    {% if request.endpoint.endswith(endpoint) %}
        <li class="active"><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
    {% else %}
        <li><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
    {% endif %}
    {% endmacro %}

\\end{codelisting}

Now we've defined the macro in *myapp/templates/macros.html*. In
Listing~ we're using Flask's ``request`` object — which is available in
the Jinja context by default — to check whether or not the current
request was routed to the endpoint passed to ``nav_link``. If it was,
than we're currently on that page, and we can mark it as active.

\\begin{aside}

The from x import y statement takes a relative path for x. If our
template was in *myapp/templates/user/blog.html* we would use
``from "../macros.html" import nav_link with context``.

\\end{aside}

Custom filters
--------------

Jinja filters are functions that can be applied to the result of an
expression in the ``{{ ... }}`` delimeters. It is applied before that
result is printed to the template.

.. raw:: latex

   \begin{codelisting}
   \label{code:jinja_filter1}
   \codecaption{The Jinja filter syntax}
   ```jinja
   <h2>{{ article.title|title }}</h2>
   ```
   \end{codelisting}

In Listing~, the ``title`` filter will take ``article.title`` and return
a title-cased version, which will then be printed to the template. This
looks and works a lot like the UNIX practice of "piping" the output of
one program to another.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   There are loads of built-in filters like `title`. See the full list here: [http://ji\-nja.pocoo.org/docs/templates/#builtin-filters](http://jinja.pocoo.org/docs/templates/#builtin-filters)

   \end{aside}

We can define our own filters for use in our Jinja templates. As an
example, we'll implement a simple ``caps`` filter to capitalize all of
the letters in a string.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{A note on redundancy}

   Jinja already has an `upper` filter that does this, and a `capitalize` filter that capitalizes the first character and lowercases the rest. These also handle unicode conversion, but we'll keep our example simple to focus on the concept at hand.

   \end{aside}

We're going to define our filter in a module located at
*myapp/util/filters.py*. This gives us a ``util`` package in which to
put other miscellaneous modules.

.. raw:: latex

   \begin{codelisting}
   \label{code:jinja_filter2}
   \codecaption{Defining a custom Jinja filter}
   ```python
   # myapp/util/filters.py

   from .. import app

   @app.template_filter()
   def caps(text):
       """Convert a string to all caps."""
       return text.uppercase()
   ```
   \end{codelisting}

In Listing~ we are registering our function as a Jinja filter by using
the ``@app.template_filter()`` decorator. The default filter name is
just the name of the function, but you can pass an argument to the
decorator to change that.

.. raw:: latex

   \begin{codelisting}
   \label{code:jinja_filter3}
   \codecaption{Naming our custom filter}
   ```python
   @app.template_filter('make_caps')
   def caps(text):
       """Convert a string to all caps."""
       return text.uppercase()
   ```
   \end{codelisting}

Now we can call ``make_caps`` in the template rather than ``caps``:
``{{ "he\-llo world!"|make_caps }}``.

To make our filter available in the templates, we just need to import it
in our top-level *\_\_init.py\_\_*.

\\begin{codelisting}

.. code:: python

    # myapp/__init__.py

    # Make sure app has been initialized first to prevent circular imports.
    from .util import filters

\\end{codelisting}

Summary
-------

-  Use Jinja for templating.
-  Jinja has two kinds of delimeters: ``{% ... %}`` and ``{{ ... }}``.
   The first one is used to execute statements such as for-loops or
   assign values, the latter prints the result of the contained
   expression to the template.
-  Templates should go in *myapp/templates/* — i.e. a directory inside
   of the application package.
-  I recommend that the structure of the *templates/* directory mirror
   the URL structure of the app.
-  You should have a top-level *layout.html* in *myapp/templates* as
   well as one for each section of the site. The former extend the
   latter.
-  Macros are like functions made-up of template code.
-  Filters are functions made-up of Python code and used in templates.

