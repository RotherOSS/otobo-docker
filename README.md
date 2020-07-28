This README contains detailed info about running OTOBO under Docker.
For a regular installation see https://doc.otobo.org/manual/installation/stable/en/content/installation-docker.html .

# Basic info regarding running OTOBO under Docker.

For running OTOBO under HTTP altogether five docker containers are started.
For HTTPS yet another container for nginx as a webproxy is started.
These containers are managed via Docker compose.
The user can control the setup via the file _.env_.

## Overview over the containers

* Container otobo_web_1

OTOBO webserver on internal port 5000.

* Container otobo_cron_1

The OTOBO daemon. A cronjob checks restarts the daemon in case of failures.

* Container otobo_db_1

Run the relational database MariaDB on internal port 3306.

* Container otobo_elastic_1

Elasticsearch on the internal ports 9200 and 9300.

* Container otobo_redis_1

Run Redis as the caching service.

* Optional container otobo_nginx_1

Run nginx as a reverse proxy for providing HTTPS support.

## Volumes

Volumes are created on the host in order to allow for persistent dats.
These allow starting and stopping the services without loosing data. Keep in mind that
containers are ephemeral and only the data in the volumes is for keeps.

* **otobo_opt_otobo** containing `/opt/otobo` on the container `web` and `cron`.
* **otobo_mariadb_data** containing `/var/lib/mysql` on the container `db`.
* **otobo_elasticsearch_data** containing `/usr/share/elasticsearch/datal` on the container `elastic`.
* **otobo_redis_data** containing data on the container `redis`.
* **otobo_nginx_ssl** contains the TLS files, certificate and private key, must be initialzed manually

## Source files

The relevant files for running OTOBO with Docker are:

* `.docker_compose_env_http`
* `.docker_compose_env_https`
* `docker-compose/otobo-base.yml`
* `docker-compose/otobo-override-http.yml`
* `docker-compose/otobp-override-https.yml`

The file _.env_ is also relevant. This is the file that needs to be created by the user.

### Relevant files in https://github.com/RotherOSS/otobo

* `otobo.web.dockerfile`
* `otobo.nginx.dockerfile`
* `otobo.elasticsearch.dockerfile`
* the scripts in `bin/docker`

## Requirements

The minimal versions that have been tested are listed here. Older versions might work as well.

* Docker 19.03.08
* Docker compose 1.25.0

# Step by step guide for running OTOBO under Docker

## Get the supporting files

Clone the repository https://github.com/RotherOSS/otobo-docker

## Configure Docker Compose

Decide whether OTOBO should run under HTTPS or HTTP.
Back up the hidden file _.env_ when it already exists. Copy the appropriate sampe file to _.env_.
In case _.env_ already existed check whether you want to tranfer setting from the backup to the new file.

Currenty there are two choices.

* .docker_compose_env_http

Run HTTP on port 80 or on the port specified in $OTOBO_WEB_HTTP_PORT.

* .docker_compose_env_https

Run HTTPS on port 443 or on the port specified in $OTOBO_WEB_HTTPS_PORT.

Configure the root database password by setting the config item **OTOBO_DB_ROOT_PASSWORD** in _.env_. This is a required setting.

## Optional configuration of Docker Compose

The are some optional settings that can be set in _.env_.

* OTOBO_WEB_ROOT_HTTP_PORT

Set in case the HTTP port should deviate from the standard port 80.
This is only relevant for the case when OTOBO is actually served via HTTP.
The automatic redirect from HTTP to HTTPS is explicitly set up only for port 80.

* OTOBO_WEB_ROOT_HTTPS_PORT

Set in case the HTTPS port should deviate from the standard port 443.

* OTOBO_ELASTICSEARCH_ES_JAVA_OPTS

This is an option for the Elasticsearch container.
Example setting:
    # Please adjust this value for production env to a value up to 4g.
    OTOBO_Elasticsearch_ES_JAVA_OPTS=-Xms512m -Xmx512m

## Infrastructure

These settings in _.env_ should usually not be changed.

* COMPOSE_PROJECT_NAME

The project name is used as a prefix for the generated volumes and containers.
Must be set because the compose file is located in docker-compose and thus docker-compose
would be used per default.

* COMPOSE_PATH_SEPARATOR

Seperator for the value of **COMPOSE_FILE**. 

* COMPOSE_FILE

Use docker-compose/otobo-base.yml as the base and add the wanted extension files.
E.g docker-compose/otobo-override-http.yml or docker-compose/otobo-override-https.yml.

## Set up TLS

This step is only needed for HTTPS support.

For TLS the webproyx nginx needs a certificate and a private key.
For testing and development a self-signed certificate can be used. In the general case
registered certificates must be used.

### Create a self-signed TLS certificate and private key

`sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout otobo_nginx-selfsigned.key -out otobo_nginx-selfsigned.crt`

### Store the certificate and the private key in a volume

The certificate and the private key are stored in a volume, so that they can be used by nginx later on.

In any case the volume needs to be generated manually when it doesn't already exist.

* `docker volumne inspect otobo_nginx_ssl`
* `docker volume create otobo_nginx_ssl`

For the sample self-generated certificate:

`sudo cp otobo_nginx-selfsigned.key otobo_nginx-selfsigned.crt $(docker volume inspect --format '{{ .Mountpoint }}' otobo_nginx_ssl)`

The filenames _otobo_nginx-selfsigned.key_ and _otobo_nginx-selfsigned.crt_ happen to be the default configuration in the otobo nginx image.

In the general case the companys certificate and private key can be copied into the volume.
The names of the copied files must the be set via environment options when starting the container.
For this make sure that files are declared in your .env file. E.g.

* `OTOBO_NGINX_SSL_CERTIFICATE=/etc/nginx/ssl/otobo_nginx-selfsigned.crt`
* `OTOBO_NGINX_SSL_CERTIFICATE_KEY=/etc/nginx/ssl/otobo_nginx-selfsigned.key`

## Starting the containers

The docker images are pulled from https://hub.docker.com unless they are already available locally.

* If HTTP should not run on port 80 then also set **OTOBO_WEB_HTTP_PORT** in the _.env _ file.
* If HTTPS should not run on port 443 then also set **OTOBO_WEB_HTTPS_PORT** in the _.env_ file.
* run `docker-compose up`
* open http://localhost/hello as a sanity check

## For the curious: inspect the running containers

* `docker-compose ps`
* `docker volume ls`

## Install OTOBO

Install OTOBO by opening http://localhost/otobo/installer.pl.

## Stopping the running containers

* `docker-compose down`

## Upgrading to a new patchlevel release

* Make sure that the images have the tag `latest` or the wanted version
* `docker-compose pull`   fetch the new images
* `docker-compose down`   stop and remove the containers, named volumes are kept
* `docker-compose up`     start again with the new images

## Useful commands

### docker

* start over:             `docker system prune -a`
* show version:           `docker version`
* build an image:         `docker build --tag otobo --file=otobo.web.Dockerfile .`
* run the new image:      `docker run --publish 80:5000 otobo`
* log into the new image: `docker run -it -v opt_otobo:/opt/otobo otobo bash`
* with broke entrypoint:  `docker run -it -v opt_otobo:/opt/otobo --entrypoint bash otobo`
* show running images:    `docker ps`
* show available images:  `docker images`
* list volumes :          `docker volume ls`
* inspect a volumne:      `docker volume inspect otobo_opt_otobo`
* get volumne mountpoint: `docker volume inspect --format '{{ .Mountpoint }}' otobo_nginx_ssl`
* inspect a container:    `docker inspect <container>`
* list files in an image: `docker save --output otobo.tar otobo:latest && tar -tvf otobo.tar`

### docker-compose

* check config:           `docker-compose config`
* check containers:       `docker-compose ps`

## Advanced topics

### Building docker images locally.

This step not needed when the images from http://hub.docker.com are used.

Change into a checked out otobo git repository. E.g. https://github.com/RotherOSS/otobo or a clone of the repository.
Call  bin/docker/build_docker_images.sh`. Go back to the otobo-docker dir and set up the local images in .env.
Then proceed as described above.

### Force a patchlevel upgrade

* `docker-compose down` stop and remove the containers, named volumes are kept
* `docker run -it --rm --volume otobo_opt_otobo:/opt/otobo otobo upgrade_patchlevel_release_with_reinstall` force upgrade
* `docker run -it --rm --volume otobo_opt_otobo:/opt/otobo otobo upgrade_patchlevel_release` force upgrade, skip reinstall
* `docker-compose up` start again with the new images

### An example workflow for restarting with a new installation

Note that all previous data will be lost.

* `sudo service docker restart`    # workaround when sometimes the cached images are not available
* `docker-compose down -v`         # volumes are also removed
* Rebuild local images, see above
* Check sanity at [hello](http://localhost/hello)
* Run the installer at [installer.pl](http://localhost/otobo/installer.pl)
    * Keep the default 'db' for the database host
    * Keep logging to the file /opt/otobo/var/log/otobo.log

### Running with a seperate nginx as a reverse proxy for supporting HTTPS

This is basically an example for running OTOBO behind an external reverse proxy.

#### Build the nginx image

The image contains nginx and openssl along with an adapted config. But there is no sensible editor.
The config for nginx is located in /etc/nginx.

`docker build --tag otobo_nginx --file otobo.nginx.dockerfile .`

#### Create a self-signed TLS certificate and private key

See above.

#### Store the certificate in a volume

See above.

#### Run the container separate from otobo web

This is only an example. In the general case where there is an already existing reverse proxy.

Start the HTTP webserver on port 5000. This is done by setting OTOBO_WEB_HTTP_PORT to 5000 in the file .env.
`docker-compose up`

Nginx running in a separate container should forward to port 80 of the host.
This should work because the otobo web container exposes port 80.
However the container does know the IP of the docker host. Therefore the host must tell the container
the relevant IP.

See https://nickjanetakis.com/blog/docker-tip-65-get-your-docker-hosts-ip-address-from-in-a-container

On the host find the IP of host in the network of the nginx container. E.g. 172.17.0.1.
Run `ip a` and find the ip in the docker0 network adapter.
Or `ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+'`

`docker run -e OTOBO_NGINX_WEB_HOST=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+') --volume=otobo_nginx_ssl:/etc/nginx/ssl --publish 443:443 --publish 80:80 --name otobo_nginx_1 otobo_nginx`

In some cases the default OTOBO_NGINX_WEB_HOST, as defined in scripts/docker/nginx.Docker, suffices:

`docker run --volume=otobo_nginx_ssl:/etc/nginx/ssl --publish 443:443 --publish 80:80 --name otobo_nginx_1 otobo_nginx`

## Resources

* [Perl Maven](https://perlmaven.com/getting-started-with-perl-on-docker)
* [Docker Compose quick start](http://mfg.fhstp.ac.at/development/webdevelopment/docker-compose-ein-quick-start-guide/)
* [docker-otrs](https://github.com/juanluisbaptiste/docker-otrs/)
* [not403](http://not403.blogspot.com/search/label/otrs)
* [cleanup](https://forums.docker.com/t/command-to-remove-all-unused-images)
* [Dockerfile best practices](https://www.docker.com/blog/intro-guide-to-dockerfile-best-practices/)
* [Docker cache invalidation](https://stackoverflow.com/questions/34814669/when-does-docker-image-cache-invalidation-occur)
* [Docker Host IP](https://nickjanetakis.com/blog/docker-tip-65-get-your-docker-hosts-ip-address-from-in-a-container)
* [Environment](https://vsupalov.com/docker-arg-env-variable-guide/)
* [Self signed certificate](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04)
