Most Flask applications are going to deal with storing data at some point. There are many different ways to store data. Finding the best one depends entirely on the data you are going to store. If you are storing relational data (e.g. a user has many posts and a post has one user) a relational database is probably going to be the way to go (big suprise). Other types of data might be more suited to NoSQL data stores, such as MongoDB.

I am not going to tell you how to choose a database engine for your application. There are people who will tell you that NoSQL is the only way to go and those who will say the same about relational databases. All I will say on that subject is that if you are unsure, a relational database (MySQL, PostgreSQL, etc.) will almost certainly work for whatever you are doing.

Plus, when you use a relational database you get to use SQLAlchemy and SQLAlchemy is fun.

# SQLAlchemy

SQLAlchemy is an ORM (Object Relational Mapper). It is basically an abstraction that sits on top of the raw SQL queries being executed on your database. It provides a consistent API to a long list of database engines. The most popular include MySQL, PostgreSQL, and SQLite. This makes it easy to move data between your models and your databse and it makes it really easy to do other things like switch database engines and migrate your schemas.



## Alembic migrations
{ WARNING: Don't forget to back up your data! }

# NoSQL options
# Search (WhooshAlchemy?)
# Summary