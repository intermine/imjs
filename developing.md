# Developers - running / updating / testing imjs

## Building imjs

### Setup

1. You'll need to have [node.js](https://nodejs.org/en/download/) - but we prefer to use it via [nvm](https://github.com/creationix/nvm#installation) to manage node versions, since node changes versions very fast. Make sure you have Node 8 or greater via `node --version`
2. Once that's set up, make sure you have grunt, mocha, and bower installed globally
```bash
npm install -g mocha grunt bower
```
3. Clone the repo and change into its directory if you haven't already.
4. Install dependencies: `npm install` and then `bower install`. (Note - this is not a duplicate of step 2. Step 2 installs some global dependencies that can be used outside of this package, whereas step 4 installs local dependencies that are used to _build_ this package).

### Running / updating imjs

See the [gruntfile](gruntfile.js) for possible tasks to be run. A default task that runs the build and tests is simply `grunt`.

## Building the docs

If you need to regenerate [the API documentation](http://alexkalderimis.github.io/imjs/), make sure you have [codo](https://www.npmjs.com/package/codo) installed globally, and run `codo` in the root directory. Config is automatically pulled from the [.codoopts](.codoopts) file.

## Releasing imjs

See [release procedures](release-procedure.md).
