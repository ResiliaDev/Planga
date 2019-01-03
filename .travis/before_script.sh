#!/bin/bash
set -ev # Stop at first error

# Compile elixir project + deps
MIX_ENV=test mix compile


# build front-end assets
- cd ./assets;
- yarn
- ./node_modules/brunch/bin/brunch b -p ;
- cd ../;

# Start webdriven browser (only when required)
if [ "${TEST_SUITE}" = "--only integration:true" ]; then
    export DISPLAY=:99.0
    sh -e /etc/init.d/xvfb start
    sleep 3 # give xvfb some time to start
    export PATH=$PATH:/usr/lib/chromium-browser/
    nohup chromedriver &
fi
