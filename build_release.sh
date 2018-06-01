#!/bin/sh
cd assets && ./node_modules/brunch/bin/brunch b -p && cd .. && MIX_ENV=prod mix do phx.digest, release --env=prod --upgrade
