Tests
=====

The tests for this project are written for
both node.js (in the mocha directory) and for
the browser (the qunit) directory. Both test
suites can be run with the following grunt
command: 

  grunt test

The browser tests require phantomjs to be installed.

You will need access to a working testmodel webservice
with the loadsadata dataset loaded and the quick-search
enabled. See www.intermine.org for details on how to set
one up. If this is not located at http://localhost:8080/intermin-test
as expected, you can pass the location in an environment
variable (TESTMODEL_URL).

