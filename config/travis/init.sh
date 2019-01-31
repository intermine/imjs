#!/bin/bash

set -e

if [ -z $(which wget) ]; then
    # use curl
    GET='curl'
else
    GET='wget -O -'
fi

cd $HOME

# Pull in the server code.
git clone --single-branch --branch 'master' --depth 1 https://github.com/intermine/intermine.git server

cd server

export PSQL_USER=postgres

# We need a running demo webapp
# Set up properties
source config/create-ci-properties-files.sh

# install everything first. we don't want to test what's in maven
(cd plugin && ./gradlew install)
(cd intermine && ./gradlew install)
(cd bio && ./gradlew install)
(cd bio/sources && ./gradlew install)
(cd bio/postprocess && ./gradlew install)

# set up database for testing
(cd intermine && ./gradlew createUnitTestDatabases)

# We will need a fully operational web-application
echo '#---> Building and releasing web application to test against'
(cd testmine && ./setup.sh)

sleep 60 # let webapp startup

# Warm up the keyword search by requesting results, but ignoring the results
$GET "$TESTMODEL_URL/service/search" > /dev/null
# Start any list upgrades
$GET "$TESTMODEL_URL/service/lists?token=test-user-token" > /dev/null


# Get messages from 500 errors.
echo 'i.am.a.dev = true' >> dbmodel/resources/testmodel.properties
