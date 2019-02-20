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

export PSQL_USER=postgres

# We need a running demo webapp
# Set up properties
source server/config/create-ci-properties-files.sh

# We will need a fully operational web-application
echo '#---> Building and releasing web application to test against'
(cd server/testmine && ./setup.sh)
sleep 60 # let webapp startup

# Warm up the keyword search by requesting results, but ignoring the results
$GET "$TESTMODEL_URL/service/search" > /dev/null
# Start any list upgrades
$GET "$TESTMODEL_URL/service/lists?token=test-user-token" > /dev/null
