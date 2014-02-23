# Serving a REST API

## Primer on REST

For our purposes, there are a couple of important REST concepts.

### Resources

Resources are the things that users will be accessing. It's important to distinguish between a resource and a representation of that resource. The resource is the abstract concept, such as a "user." When we're building an API, we will serve JSON representations of users (and other resources).

### Methods

HTTP methods, such as the familiar `GET` and `POST` methods are used to view and modify resources. We can perform an action on a resource by calling a URL, such as `/api/user` with a method that signals our intentions. This is the basic outline of the different methods used to access a REST resource:

{Make this a table}

url             HTTP Method  Operation
/api/users      GET          Get an array of all users
/api/users/:id  GET          Get the user with id of :id
/api/users      POST         Add a new user and return the user with an id attribute added
/api/users/:id  PUT          Update the user with id of :id
/api/users/:id  DELETE       Delete the user with id of :id

## Flask-RESTful

## Summary