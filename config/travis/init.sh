#!/bin/bash

set -e

if [ -z $(which wget) ]; then
    # use curl
    GET='curl'
else
    GET='wget -O -'
fi

# Pull in the server code.
git clone --single-branch --branch 'master' --depth 1 https://github.com/intermine/intermine.git server

# We need a running demo webapp
source server/testmodel/setup.sh
sleep 5 # wait for tomcat to come on line
# Get messages from 500 errors.
echo 'i.am.a.dev = true' >> server/testmine/dbmodel/resources/testmodel.properties
PSQL_USER=postgres sh server/testmine/setup.sh
sleep 15 # wait for the webapp to come on line


# Start any list upgrades by poking the lists service.
$GET "$TESTMODEL_URL/service/lists?token=test-user-token" > /dev/null
