# Developers - running / updating / testing imjs

## Building imjs

### Setup

1. You'll need to have [node.js](https://nodejs.org/en/download/) - but we prefer to use it via [nvm](https://github.com/creationix/nvm#installation) to manage node versions, since node changes versions very fast. Make sure you have Node 8 or greater via `node --version`
2. Once that's set up, make sure you have grunt, mocha installed globally
```bash
npm install -g mocha grunt
```
3. Clone the repo and change into its directory if you haven't already.
4. Install dependencies: `npm install`. (Note - this is not a duplicate of step 2. Step 2 installs some global dependencies that can be used outside of this package, whereas step 4 installs local dependencies that are used to _build_ this package).

### Adding new classes to the API

1. Ideally, any new class added to the API should be in its own separate file.
2. [`service.coffee`](src/service.coffee) acts as the entry point to the API. In order to add to the public part of the API, import the functionality in the file (at the top) and re-export it (at the bottom). Same pattern has to be followed to ensure that your file is correctly being added to the final build file.
3. Update [`build-order.json`](build-order.json) and [`BUILD_ORDER`](BUILD_ORDER) (if required) so that your files are concatenated in the final build in correct order.

### Running / updating imjs

See the [gruntfile](Gruntfile.js) for possible tasks to be run. A default task that runs the build and tests is simply `grunt`.

## Building the docs

If you need to regenerate [the API documentation](http://alexkalderimis.github.io/imjs/), make sure you have [codo](https://www.npmjs.com/package/codo) installed globally, and run `codo` in the root directory. Config is automatically pulled from the [.codoopts](.codoopts) file.

## Running tests

Setting up tests to run on your local machine can be a bit tedious - it's usually easier to set up [TravisCI](https://travis-ci.org/) for your repo, and allow travis to test code you push to a branch on your repo. Read more about testing setup in [test/README.md](test/README.md)

## Releasing imjs

See [release procedures](release-procedure.md).
