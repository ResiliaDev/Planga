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
sudo rsync -hvrPt --ignore-existing _build/prod/rel/planga/${relnum}/planga.tar.gz /var/www/planga/
tar -xzf /var/www/planga/planga.tar.gz
sudo service planga restart
