# Tests

## Installing and running tests locally

**Note: If you are unable to get tests running locally, try enabling [TravisCI] for your repository**

The tests for this project are segregated into unit tests and integration tests. You can run each test suite with the following commands (running both at the same time is currently not supported).

```
grunt test:unit
grunt test:integration
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

## Mock Responses
### Adding new mocks
In order to create a mock bundle pertaining to a test, import [`mock.coffee`](mocha/lib/mock.coffee) into the test file. Add the `setupRecorder` function to the topmost level after which mocks are to be run. Preferrably, it is just after the `describe` in mocha test. Also add the `stopRecorder` function in the `@afterAll` hook of the corresponding scope, passing the bundle name as the parameter (should have `.json` extension). Run the test suite. Make sure that test is as well as the testmine is running. To ensure this, do not add any segregation details to the test.

(OPTIONAL) In the [`mocha-opts.json`](../mocha-opts.json), add `"grep": "unique_test"`. This runs only the `"unique_test"`, reducing the time required to run the test which is setting up the mock.
### Setting up mocks
In order to setup mock responses in a test, add the `setupBundle` function to the scope where `setupRecorder` was added. Pass the bundle name as the first parameter. Run the test after closing the testmine instance, to ensure that the mocks are being setup appropriately.
