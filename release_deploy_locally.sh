#!/bin/bash
`mix compile` # Required to have the following command not contain warnings.
relnum=`mix app_version`
echo "Creating release for version ${relnum}..."
# cd ./assets;
# ./node_modules/brunch/bin/brunch b -p ;
# cd ../;
MIX_ENV=prod mix do phoenix.digest, release --env=prod --upgrade
echo "Done!"
echo "Continuing to upload release to local server..."
sudo rsync -hvrPt --ignore-existing _build/prod/rel/plange/releases/${relnum}/plange.tar.gz /var/www/plange/releases/${relnum}/
echo "Done!"
echo "Attempting to upgrade application through SSH."
echo "Enter your sudo-password to hot-upgrade the application to ${relnum}."
sudo /var/www/plange/bin/plange upgrade ${relnum}
echo "Done!"
echo "Deploy finished!"
