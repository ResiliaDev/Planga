#!/bin/sh
./node_modules/brunch/bin/brunch b -p && MIX_ENV=prod mix do phoenix.digest, release --env=prod --upgrade
