# Explore Flask

Welcome to the *Explore Flask* repository. This is where the reStructuredText
source of the book lives. If you're looking to read the book itself, `go here
<http://exploreflask.com>`_.

## Contributing

If you have some ideas for the book, you can open up an issue in the issue tracker
or submit a pull request. If you're making some big changes, it's probably best
to suggest them first in the issue tracker so we can discuss whether or not they
belong in the book before you do all of the work.

Contributions are all placed in the public domain like the rest of the text.

## Building

### Create Sphinx Docs

Just ``cd`` into the repo and run ``sphinx-build -b html source/ build/`` to build
the website. 

### Create EPUB and HTML

1. Install `Pandoc <http://johnmacfarlane.net/pandoc/>`_.
1. cd ``source``
1. Delete current build folder (if necessary) - ``make clean``
1. Generate EPUP and HTML - ``make``

**Todo**: Add instructions for PDF and MOBI


