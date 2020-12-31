# The webbrowser needs some sample files for running the tests.

# copy the needed files from the web container
mkdir -p tmp/scripts/test
docker cp otobo_web_1:/opt/otobo/scripts/test/sample tmp/scripts/test

# create the target dir in the selenium container
docker exec otobo_selenium-chrome_1 sudo mkdir /opt/otobo
docker exec otobo_selenium-chrome_1 sudo chown seluser:seluser /opt/otobo

# copy the files
docker cp tmp/scripts otobo_selenium-chrome_1:/opt/otobo

# make sure that the copied files are readable by seluser
docker exec otobo_selenium-chrome_1 sudo chown -R seluser:seluser /opt/otobo

# clean up
rm -rf tmp
