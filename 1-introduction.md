# Introduction

This book is a collection of the best practices for using Flask. There are a lot of pieces to the average Flask application. You’ll often need to interact with a database and authenticate users, for example. In the coming pages I’ll do my best to explain the “right way” to do this sort of stuff. My recommendations aren’t always going to apply, but I’m hoping that they’ll be a good option most of the time.

## Assumptions

In order to present you with more specific advice, I've written this book with a few fundamental assumptions. It's important to keep this in mind when you're reading and applying these recommendations to your own projects.

### Audience

The content of this book builds upon the information in the official documentation. I highly recommend that you go through the user guide and follow along with the tutorial [LINK TO USER GUIDE AND TUTORIAL]. This will give you a chance to become familiar with the vocabulary of Flask. You should understand what views are, the basics of Jinja templating and other fundamental concepts defined for beginners. I've tried to avoid overlap with the information already available in the user guide, so if you read this book first, there’s a good chance that you’ll find yourself lost (is that an oxymoron?).

With all of that said, the topics in this book aren’t highly advanced. The goal is just to highlight best practices and patterns that will make development easier for you. While I'm trying to avoid too much overlap with the official documentation, you may find that I reiterate certain concepts to make sure that they’re familiar. You shouldn't need to have the beginner's tutorial open while you read this.

### Versions

#### Python 2 versus Python 3

As I write this, the Python community is in the midst of a transition from Python 2 to Python 3. The official stance of the PSF is as follows:

> Python 2.x is the status quo, Python 3.x is the present and future of the language
> Citation: http://wiki.python.org/moin/Python2orPython3

As of version 0.10, Flask runs with Python 3.3. When I asked Armin Ronacher about whether new Flask apps should begin using Python 3, he said they shouldn't:

> I'm not using it myself currently, and I don't ever recommend to people things that I don't believe in myself, so I'm very cautious about recommending Python 3.

His main reason is that there are still things in Python 3 that don’t work yet. Another reason of his for not recommending that new projects use Python 3 is that many dependencies simply don't work with the new version yet. It's possible that eventually Flask will officially recommend Python 3 for new projects, but for now it’s all about Python 2.

{ SEE ALSO:
* This site tracks which packages have been ported to Python 3: https://python3wos.appspot.com/ }

Since this book is meant to provide practical advice, I think it makes sense to write with the assumption of Python 2. Specifically, I'll be writing the book with Python 2.7 in mind. Future updates may very well change this to evolve with the Flask community, but for now 2.7 is where we stand.

#### Flask version 0.10

At the time of writing this, 0.10 is the latest version of Flask (0.10.1 to be exact). Most of the lessons in this book aren’t going to change with minor updates to Flask, but it’s something to keep in mind nonetheless.

## Annual reviews

I’m hesitant to commit to any one update schedule, since there are a lot of variables that will determine the appropriate time for an update. Essentially, if it looks like things are getting out of date, I’ll work on releasing an update. Eventually I might stop, but I’ll make sure to announce that if it happens.

## Conventions used in this book

### Each chapter stands on its own

Each chapter in this book is an isolated lesson. Many books and tutorials are written as one long lesson. Generally this means that an example program or application is created and updated throughout the book to demonstrate concepts and lessons. Instead, examples are included in each lesson to demonstrate the concepts, but the examples from different chapters aren’t meant to be combined into one large project.

### Formatting

Code blocks will be used to present example code. 

```
print “Hello world!” 
```

Directory listings will sometimes be shown to give an overview of the structure of an application or directory.

```
static/
  style.css
  logo.png
  vendor/
    jquery.min.js
```

*Italic text* will be used to denote a file name.

**Bold text** will be used to denote a new or important term.

Supplemental information may appear in one of several boxes:

{ WARNING: Common pitfalls that could cause major problems may be shown in a warning box. }

{ NOTE: Tangential information may be presented in a "note" box. }

{ SEE ALSO: I may provide some links with more information on a given topic in a "see also" box. }

## Summary

* This book contains recommendations for using Flask.
* I’m assuming that you’ve gone through the Flask tutorial.
* I’m using Python 2.7.
* I’m using Flask 0.10.
* I’ll do my best to keep the content of the book up-to-date with annual reviews.
* Each chapter in this book stands on its own.
* There are a few ways that I’ll use formatting to convey additional information about the content.
* Summaries will appear as concise lists of takeaways from the chapters.