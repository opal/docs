# Opal Documentation Central

This repo will hold the keys for generating Opal API documentation and guides on the `master` branch, while the `gh-pages` branch will keep track of the generated docs. The source for the docs will be the Opal repo itself.

[![documentation: Opal API](http://img.shields.io/badge/API%20documentation-read%20now-blue.svg)](https://opal.github.io/docs/index.html)

### Generating docs for a single version

The passed version needs to be a valid git ref (e.g. a tag)

    bin/build v0.5.5
    bin/build master

### Rebuilding all the docs

    bin/build-all

### Previewing locally

    bin/server # will use port 5000

