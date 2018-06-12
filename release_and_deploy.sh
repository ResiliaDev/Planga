#!/bin/bash
`mix compile` # Required to have the following command not contain warnings.
relnum=`mix app_version`
echo "Creating release for version ${relnum}..."
# cd ./assets;
# ./node_modules/brunch/bin/brunch b -p ;
# cd ../;
# MIX_ENV=prod mix do phoenix.digest, release --env=prod --upgrade
echo "Done!"
echo "Continuing to upload release to server..."
rsync -hvrPt --ignore-existing ./_build/prod/rel/planga/releases/${relnum}/planga.tar.gz kristinskruiderij.dev:/var/www/planga/releases/${relnum}/
echo "Done!"
echo "Attempting to upgrade application through SSH."
echo "Enter your sudo-password to hot-upgrade the application to ${relnum}."
ssh kristinskruiderij.dev -t "sudo /var/www/planga/bin/planga upgrade ${relnum}"
echo "Done!"
echo "Deploy finished!"
