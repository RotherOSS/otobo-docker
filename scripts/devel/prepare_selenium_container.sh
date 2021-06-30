# The webbrowser needs some sample files for running the tests.

# copy the needed files from the web container
mkdir -p tmp/scripts/test
docker cp "$(docker-compose ps -q web)":/opt/otobo/scripts/test/sample tmp/scripts/test

# create the target dir in the selenium container
docker-compose exec selenium-chrome sudo mkdir /opt/otobo
docker-compose exec selenium-chrome sudo chown seluser:seluser /opt/otobo

# copy the files
docker cp tmp/scripts "$(docker-compose ps -q selenium-chrome)":/opt/otobo

# make sure that the copied files are readable by seluser
docker-compose exec selenium-chrome sudo chown -R seluser:seluser /opt/otobo

# clean up
rm -rf tmp
