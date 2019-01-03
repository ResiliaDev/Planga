#!/bin/bash
set -ev # Stop at first error

# Only install webdriven browser if required
if [ "${TEST_SUITE}" = "--only integration:true" ]; then
   sudo apt-get install chromium-chromedriver
fi
