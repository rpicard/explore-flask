Explore Flask
=============

Welcome to the *Explore Flask* repository. This is where the reStructuredText
source of the book lives. If you're looking to read the book itself, `go here
<http://exploreflask.com>`_.

Contributing
------------

If you have some ideas for the book, you can open up an issue in the issue tracker
or submit a pull request. If you're making some big changes, it's probably best
to suggest them first in the issue tracker so we can discuss whether or not they
belong in the book before you do all of the work.

Contributions are all placed in the public domain like the rest of the text.

Building
--------

Just ``cd`` into the repo and run ``sphinx-build -b html source/ build/`` to build
the website. Feel free to try your hand at building other formats, but HTML is
the only officially supported one right now.

Building Prerequisites (Ubuntu)
-------------------------------

The documentation is formatted as reStructuredText. `Sphinx 
<http://sphinx-doc.org/>`_ handles conversions to other formats, such as HTML,
LaTeX, and ePub. Currently, the HTML appearance is based on the `Read the Docs 
<http://www.readthedocs.org/>`_ `Sphinx theme. 
<https://github.com/snide/sphinx_rtd_theme>`_ To install the required software
and theme, run:

``sudo apt-get install python-pip python-sphinx``

``sudo pip install sphinx_rtd_theme``
