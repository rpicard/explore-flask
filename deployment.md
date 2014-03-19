# Deployment

You're finally ready to show your app to the world. It's time to deploy. This process can be a pain because there are so many moving parts. There are a lot of choices to make when it comes to your production stack as well. I'm going to try and point out the important pieces and some of the options you have with each.

## The Host

You're going to need a server somewhere. There are thousands of providers out there, but these are the three that I personally recommend. I'm not going to go over the details of how to get started with them, because that's out of the scope of this book. Instead I'll talk about their benefits with regards to hosting Flask applications.

### Amazon Web Services EC2

Amazon Web Services is a collection of services provided by ... Amazon! There's a good chance that you've heard of them before as they are probably the most popular choice for new startups these days. The AWS service that we're most concerned with here is EC2, or Elastic Compute Cloud. The big selling point of EC2 is that you get virtual servers, or instances as they're called in AWS parlance, that spin up in seconds. If you need to scale your app quickly it's just a matter of spinning up a few more EC2 instances with your app running and sticking them behind a load balancer (you can even use the AWS Elastic Load Balancer).

With regards to Flask, AWS is just a regular old virtual server. You can spin it up with your favorite linux distro and install your Flask app and your server stack without much overhead. It means that you're going to need a certain amount of systems administration knowledge though.

### Heroku

Heroku is an application hosting service that is built on top of AWS services like EC2. They let you take advantage of the convenience of EC2 without the requisite systems administration experience.

With Heroku, you deploy your application with a `git push` to their server. This is really convenient when you don't want to spend you time SSHing into a server, installing and configuring software and coming up with a sane deployment procedure. This convenience comes at a price of course, though both AWS and Heroku offer a certain amount of free service.

{ SEE MORE: 

* Heroku has a tutorial on deploying Flask with their service: https://devcenter.heroku.com/articles/getting-started-with-python }


{ A NOTE ON DATABASES: Administrating your own databases can be time consuming and doing it well requires some experience. It's great to learn about database administration by doing it yourself for your side projects, but sometimes you'd like to save time and effort by outsourcing that to part professionals. Both Heroku and AWS have database management offerings. I don't have personal experience with either yet, but I've heard great things and it's worth considering if you want to make sure your data is being secured and backed-up without having to do it yourself.

- Heroku Postgres: https://www.heroku.com/postgres
- Amazon RDS: https://aws.amazon.com/rds/ }


### Digital Ocean

Digital Ocean is an EC2 competitor that has recently begun to take off. Like EC2, Digital Ocean lets you spin up virtual servers, now called droplets, quickly. All droplets run on SSDs, which isn't something you get at the lower levels of EC2. The biggest selling point for me is an interface that is far simpler and easier to use than the AWS control panel. Digital Ocean is my personal preference for hosting and I recommend that you take a look at them.

The Flask deployment experience on Digital Ocean is roughly the same as on EC2. You're starting with a clean linux distribution and installing your server stack from there.

{ NOTE: Digital Ocean was nice enough to make a contribution to the Kickstarter campaign for *Explore Flask*. With that said, I promise that my recommendation comes from my own experience as a user. If I didn't like them, I wouldn't have asked them to pledge in the first place. }


## The stack

This section will cover some of the software that you'll need to install on your server to serve your Flask application to the world. The basic stack is a front server that reverse proxies requests to an application runner that is running your Flask app. You'll usually have a database too, so we'll talk a little about those options as well.

### Application runner

The server used to run Flask locally when you're developing your application isn't good at handling real requests. When you're actually serving your application to the public, you want to run it with an application runner like Gunicorn. Gunicorn handles requests and takes care of complicated things like threading.

To use Gunicorn, install the `gunicorn` package in your virtual environment with Pip. Running your app is a simple command away. For the sake of illustration, let's assume that this is our Flask app:

_rocket.py_
```
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
	return "Hello World!"
```

A fine app indeed. Now, to serve it up with Gunicorn, we simply run this command:

```
(myapp)$ gunicorn rocket:app
2014-03-19 16:28:54 [62924] [INFO] Starting gunicorn 18.0
2014-03-19 16:28:54 [62924] [INFO] Listening at: http://127.0.0.1:8000 (62924)
2014-03-19 16:28:54 [62924] [INFO] Using worker: sync
2014-03-19 16:28:54 [62927] [INFO] Booting worker with pid: 62927
```

You should see "Hello World!" at http://127.0.0.1:8000.

To run this server in the background (i.e. daemonize it), we can pass in the `-D` option to Gunicorn. That way it'll run even after you close your current terminal session. If you do that, you might have a hard time finding the process to close later on when you want to stop the server. We can tell Gunicorn to stick the process ID in a file so that we can stop or restart it later without searching through lists of running processess. We use the `-p <file>` option to do that. Altogther, our Gunicorn deployment command looks like this:

```
(myapp)$ gunicorn rocket:app -p rocket.pid -D
(myapp)$ cat rocket.pid
63101
```

To restart and kill the server, we can run these commands respectively:

```
(myapp)$ kill -HUP `cat rocket.pid`
(myapp)$ kill `cat rocket.pid`
```

By default Gunicorn runs on port 8000. If that's taken by another application you can change the port by adding the `-b` bind option. It looks like this:

```
(myapp)$ gunicorn rocket:app -p rocket.pid -b 127.0.0.1:7999 -D
```

#### Making Gunicorn public

{ WARNING: Gunicorn is meant to sit behind a reverse proxy. If you tell it to listen to requests coming in from the public, it makes an easy target for denial of service attacks. It is just not meant to handle those kinds of requests. Only allow outside connections for debugging purposes and make sure to switch it back to only allowing internal connections when you're done. }

If you run Gunicorn like we have been on a server, you won't be able to access it from your local system. That's because by default Gunicorn binds to 127.0.0.1. This means that it will only listen to connections coming from the server itself. This is the behavior that you want when you have a reverse proxy server that is sitting between the public and your Gunicorn server. If, however, you need to make requests from outside of the server for debugging purposes, you can tell Gunicorn to bind to 0.0.0.0. This tells it to listen for all requests.

```
(myapp)$ gunicorn rocket:app -p rocket.pid -b 0.0.0.0:8000 -D
```

{ SEE MORE:
- Read more about running and deploying Gunicorn from the docs: http://docs.gunicorn.org/en/latest/ 
- Fabric is a tool that lets you run all of these deployment and management commands from the comfort of your local machine without SSHing into every server running your application: http://docs.fabfile.org/en/latest }

### Nginx Reverse Proxy

A reverse proxy handles public HTTP requests, sends them back to Gunicorn and gives the response back to the requesting client. Nginx can be used very effectively as a reverse proxy and Gunicorn "strongly advises" that we use it. To configure Nginx as a reverse proxy to Gunicorn running on 127.0.0.1:8000, we can create a file for our app in _/etc/nginx/sites-available_. We'll call it _exploreflask.com_.

Here's a simple example configuration.

_/etc/nginx/sites-available/exploreflask.com_
```
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
                
                # Set some HTTP headers so that our app knows where the request really came from
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}
```

Now create a symlink to this file in _/etc/nginx/sites-enabled_ and restart Nginx.

```
$ sudo ln -s /etc/nginx/sites-available/exploreflask.com /etc/nginx/sites-enabled/exploreflask.com
```

You should now be able to make your requests to Nginx and receive the response from your app.

{ SEE MORE:
- Nginx configuration section in the Gunicorn docs will give you more information about setting Nginx up for this purpose: http://docs.gunicorn.org/en/latest/deploy.html#nginx-configuration }

#### ProxyFix

You main run into some issues with Flask not properly handling the proxied requests. It has to do with those headers we set in the Nginx configuration. We can use the Werkzeug ProxyFix to, ugh, fix the proxy.

_rocket.py_
```
from flask import Flask

# Import the fixer
from werkzeug.contrib.fixers import ProxyFix

app = Flask(__name__)

# Use the fixer
app.wsgi_app = ProxyFix(app.wsgi_app)

@app.route('/')
def index():
	return "Hello World!"
```

{ SEE MORE:

- Read more about ProxyFix in the Werkzeug docs: http://werkzeug.pocoo.org/docs/contrib/fixers/#werkzeug.contrib.fixers.ProxyFix }

## Summary