# Serving a REST API

## Primer on REST

REST is a pattern for making for making server-side resources available to client applications. The REST application pattern uses HTTP methods to perform operations on those resources. In this section we'll go over resources and methods.

### Resources

Resources are the things that users will be accessing. It's important to distinguish between a resource and a representation of that resource. The resource is the abstract concept of an object used by the application, e.g. a "user." When we're building an API, we will usually serve JSON representations of users (and other resources).

### Methods

HTTP methods, such as the familiar `GET` and `POST` methods are used to view and modify resources. We can perform an operation on a resource by calling a URL, such as `/api/user` with a method that signals our intentions. This is an outline of the basic methods we'll talk about in this section:

{MAKE A TABLE}

url             HTTP Method  Operation
/api/v1.0/users      GET          Get an array of all users
/api/v1.0/users/:id  GET          Get the user with id of :id
/api/v1.0/users      POST         Add a new user and return the user with an id attribute added
/api/v1.0/users/:id  PUT          Update the user with id of :id
/api/v1.0/users/:id  DELETE       Delete the user with id of :id

There are other HTTP methods often used in RESTful APIs, but these are the key players. We can use this structure to back front-end frameworks like Backbone and Angular, or to make resources available to third-party developers.

## Flask-RESTful

Flask-RESTful is a Flask extension developed at Twilio that makes defining REST APIs simple. It uses a feature of Flask called `MethodViews`. When a request is routed to a `MethodView` class, the HTTP method of that request is used to determine which class method will handle the request. The `MethodView` class could have a `get()` method as well as a `post()` method, for example. Flask-RESTful wraps `MethodView` and gives us tools to use it for building REST APIs.

{ SEE MORE:
* Flask-RESTful documentation: http://flask-restful.readthedocs.org/en/latest/index.html
* Flask documentation for `MethodView`: http://flask.pocoo.org/docs/views/ }

### The View Structure

Let's create a simple RESTful API that makes a `User` resource available.

```
from flask import Flask
from flask.ext import restful

app = Flask(__name__)
api = restful.Api(app)

class UserListAPI(restful.Resource):
	def get(self):
    	# Get the list of users
        return users, 200

	def post(self):
    	# Add a user, return status code "201 Created"
        return new_user, 201

class UserAPI(restful.Resource):
	def get(self, id):
    	# Get the user
        return user, 200
    
    def put(self, id):
    	# Update the user
        return updated_user, 200

	def delete(self, id):
    	# Delete the user, return status code "204 No Content"
        return '', 204

api.add_resource(UserListAPI, '/api/v1.0/users', endpoint='users')
api.add_resource(UserAPI, '/api/v1.0/users/<int:id>', endpoint='user')
```

I'll leave the implementation of each function as an exercise for the user, as it's a little out of the scope of this chapter. As you can see, it's trivial to define the methods that can be used on your resources.

### Authentication

### CSRF Protection

## Summary