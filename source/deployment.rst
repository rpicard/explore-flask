Deployment
==========

.. figure:: _static/images/deployment.png
   :alt: Deployment

   Deployment
We're finally ready to show our app to the world. It's time to deploy.
This process can be a pain because there are so many moving parts. There
are a lot of choices to make when it comes to our production stack as
well. In this chapter, we're going to talk about some of the important
pieces and some of the options we have with each.

The Host
--------

We're going to need a server somewhere. There are thousands of providers
out there, but these are the three that I personally recommend. I'm not
going to go over the details of how to get started with them, because
that's out of the scope of this book. Instead I'll talk about their
benefits with regards to hosting Flask applications.

Amazon Web Services EC2
~~~~~~~~~~~~~~~~~~~~~~~

Amazon Web Services is a collection of services provided by ... Amazon!
There's a good chance that you've heard of them before as they're
probably the most popular choice for new startups these days. The AWS
service that we're most concerned with here is EC2, or Elastic Compute
Cloud. The big selling point of EC2 is that we get virtual servers - or
**instances** as they're called in AWS parlance - that spin up in
seconds. If we need to scale our app quickly it's just a matter of
spinning up a few more EC2 instances for our app and sticking them
behind a load balancer (we can even use the AWS Elastic Load Balancer).

With regards to Flask, AWS is just a regular old virtual server. We can
spin it up with our favorite linux distro and install our Flask app and
our server stack without much overhead. It means that we're going to
need a certain amount of systems administration knowledge though.

Heroku
~~~~~~

Heroku is an application hosting service that is built on top of AWS
services like EC2. They let us take advantage of the convenience of EC2
without the requisite systems administration experience.

With Heroku, we deploy our application with a ``git push`` to their
server. This is really convenient when we don't want to spend our time
SSHing into a server, installing and configuring software and coming up
with a sane deployment procedure. This convenience comes at a price of
course, though both AWS and Heroku offer a certain amount of free
service.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - Heroku has a tutorial on deploying Flask with their service: https://devcenter.heroku.com/articles/getting-started-with-python

   \end{aside}

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - Read more about running and deploying Gunicorn from the docs: [http://docs.gunicorn.org/en/latest/](http://docs.gunicorn.org/en/latest/) 
   - Fabric is a tool that lets you run all of these deployment and management commands from the comfort of your local machine without SSHing into every server: [http://docs.fabfile.org/en/latest](http://docs.fabfile.org/en/latest)

   \end{aside}

Nginx Reverse Proxy
~~~~~~~~~~~~~~~~~~~

A reverse proxy handles public HTTP requests, sends them back to
Gunicorn and gives the response back to the requesting client. Nginx can
be used very effectively as a reverse proxy and Gunicorn "strongly
advises" that we use it.

To configure Nginx as a reverse proxy to a Gunicorn server running on
127.0.0.1:8000, we can create a file for our app:
*/etc/nginx/sites-available/expl-oreflask.com*.

\\begin{codelisting}

.. code:: nginx

    # /etc/nginx/sites-available/exploreflask.com

    # Redirect www.exploreflask.com to exploreflask.com
    server {
            server_name www.exploreflask.com;
            rewrite ^ http://exploreflask.com/ permanent;
    }

    # Handle requests to exploreflask.com on port 80
    server {
            listen 80;
            server_name exploreflask.com;

                    # Handle all locations
            location / {
                            # Pass the request to Gunicorn
                    proxy_pass http://127.0.0.1:8000;
                    
                    # Set some HTTP headers so that our app knows where the 
                    # request really came from
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            }
    }

\\end{codelisting}

Now we'll create a symlink to this file at */etc/nginx/sites-enabled*
and restart Nginx.

\\begin{codelisting}

.. code:: console

    $ sudo ln -s \
    /etc/nginx/sites-available/exploreflask.com \
    /etc/nginx/sites-enabled/exploreflask.com

\\end{codelisting}

We should now be able to make our requests to Nginx and receive the
response from our app.

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - Nginx configuration section in the Gunicorn docs will give you more information about setting Nginx up for this purpose: [http://docs.gunicorn.org/en/latest/deploy.html#nginx-configuration](http://docs.gunicorn.org/en/latest/deploy.html#nginx-configuration)

   \end{aside}

ProxyFix
^^^^^^^^

We may run into some issues with Flask not properly handling the proxied
requests. It has to do with those headers we set in the Nginx
configuration. We can use the Werkzeug ProxyFix to ... fix the proxy.

\\begin{codelisting}

.. code:: python

    # app.py

    from flask import Flask

    # Import the fixer
    from werkzeug.contrib.fixers import ProxyFix

    app = Flask(__name__)

    # Use the fixer
    app.wsgi_app = ProxyFix(app.wsgi_app)

    @app.route('/')
    def index():
            return "Hello World!"

\\end{codelisting}

.. raw:: latex

   \begin{aside}
   \label{aside:}
   \heading{Related Links}

   - Read more about ProxyFix in the Werkzeug docs: [http://werkzeug.pocoo.org/docs/contrib/fixers/#werkzeug.contrib.fixers.ProxyFix](http://werkzeug.pocoo.org/docs/contrib/fixers/#werkzeug.contrib.fixers.ProxyFix)

   \end{aside}

Summary
-------

-  Three good choices for hosting Flask apps are AWS EC2, Heroku and
   Digital Ocean.
-  The basic deployment stack for a Flask application consists of the
   app, an application runner like Gunicorn and a reverse proxy like
   Nginx.
-  Gunicorn should sit behind Nginx and listen on 127.0.0.1 (internal
   requests) not 0.0.0.0 (external requests).
-  Use Werkzeug's ProxyFix to handle the appropriate proxy headers in
   your Flask application.

