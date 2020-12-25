Upcoming releases of OTOBO will come with official support for Docker.

See the OTOBO Installation Guide https://doc.otobo.org/manual/installation/stable/en/content/installation-docker.html
for more information on how the get started.

Here is quick overview over the files in this distribution. Note that some of the files are hidden
and are only listed with ls -a.

    - .docker_compose_env_http               sample .env file for a HTTP bases installation
    - .docker_compose_env_https              sample .env file for a HTTPS bases installation
    - .docker_compose_env_https_custom_nginx sample .env file for a HTTPS bases installation with custom Nginx config
    - .docker_compose_env_https_selenium     for development, support Selenium testing
    - .env                                   Docker Compose environment file, must be created by the user
    - docker-compose                         directory with Docker Compose configuration snippets
    - etc/templates/dot_env.m4               template file used be scripts/create_sample_env_files.sh
    - scripts/create_sample_env_files.sh     a small helper for creating the sample env files
    - scripts/update.sh                      a small helper for updating to updated images
