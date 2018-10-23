#!/bin/bash
mix deps.get
mix compile # Required to have the following command not contain warnings.
relnum=`mix app_version`
echo "Creating COLD release for version ${relnum}..."
cd ./assets;
./node_modules/brunch/bin/brunch b -p ;
cd ../;
MIX_ENV=prod mix do phoenix.digest, release --env=prod
echo "Rsyncing COLD release to Planga directory..."
sudo rsync -hvrPt _build/prod/rel/planga/releases/${relnum}/planga.tar.gz /var/www/planga/
cd /var/www/planga/
tar -xzf /var/www/planga/planga.tar.gz
echo "Done Copying and extracting!"
echo "Restarting application..."
cd ~/repos/Planga/deploy/
sudo service planga restart
/var/www/planga/bin/planga describe
echo "Done!"
echo "Deploy finished!"
