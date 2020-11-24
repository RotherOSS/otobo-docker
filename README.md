Upcoming releases of OTOBO will come with official support for Docker.

See the OTOBO Installation Guide https://doc.otobo.org/manual/installation/stable/en/content/installation-docker.html
for more information on how the get started.

Here is quick overview over the files in this distribution. Note that some of the files are hidden
and are only listed with ls -a.

    - .docker_compose_env_https sample .env file for a HTTPS base installation
    - .docker_compose_env_http  sample .env file for a HTTP base installation
    - .env Docker               Docker Compose environment file, must be created by the user
    - docker-compose            directory with Docker Compose files, service declaration files
    - scripts/update.sh         a small helper for updating to updated images
