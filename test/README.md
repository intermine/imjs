Tests
=====

The tests for this project are written for
both node.js (in the mocha directory) and for
the browser (the qunit) directory. Both test
suites can be run with the following grunt
command: 

```
grunt test
```

The browser tests require phantomjs to be installed.

To set up the testing environment: 

You will need access to a working testmodel webservice with the loadsadata dataset loaded and the quick-search
enabled. See [our testmodel docs](http://intermine.readthedocs.io/en/latest/get-started/testmodel/) for details on how to set
the testmodel up. Once the testmodel is set up, to load the extra dataset you need, go to intermine/intermine/testmodel and run setup.sh (e.g. `./setup.sh`).

If this is not located at http://localhost:8080/intermine-demo as expected, you can pass the location in an environment
variable (TESTMODEL_URL).

