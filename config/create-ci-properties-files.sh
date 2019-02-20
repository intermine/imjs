#!/bin/bash

PROPDIR=$HOME/.intermine
TESTMODEL_PROPS=$PROPDIR/testmodel.properties
SED_SCRIPT='s/PSQL_USER/postgres/'

mkdir -p $PROPDIR

echo "#--- creating $TESTMODEL_PROPS"
cp config/testmodel.properties $TESTMODEL_PROPS
sed -i -e $SED_SCRIPT $TESTMODEL_PROPS
