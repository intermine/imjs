# Tests

## Installing and running tests locally

**Note: If you are unable to get tests running locally, try enabling [TravisCI] for your repository**

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

You will need access to a working InterMine testmine with the loadsadata dataset loaded and the quick-search
enabled. 

1. Clone the InterMine repo [https://github.com/intermine/intermine](https://github.com/intermine/intermine). Make sure you have all the required [dependencies](https://intermine.readthedocs.io/en/latest/system-requirements/software/) installed. 
2. Once everything's installed, you can run a script to set up the TestMine. In a terminal, run:

```bash
cd intermine          #change into the cloned directory.
./testmodel/setup.sh  # initialise InterMine TestMine. 
```


See [our testmodel docs](https://intermine.readthedocs.io/en/latest/get-started/testmine/) for more details.

If this is not located at http://localhost:8080/intermine-demo as expected, you can [pass the location in an environment
variable](https://stackoverflow.com/questions/22312671/setting-environment-variables-for-node-to-retrieve) (TESTMODEL_URL).

## TravisCI

If you enable [TravisCI](https://travis-ci.org/) for your repo, tests will run automatically when you push code to GitHub. This might be easier! 
