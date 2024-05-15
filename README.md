OTOBO comes with official support for Docker.

The chapter "Installing using Docker and Docker Compose" in the "Installation and Update" manual
has more information on how the get started.
See https://doc.otobo.org/manual/installation/11.0/en/content/installation-docker.html.

Here is quick overview over the files in this distribution. Note that some of the files are hidden
and are only listed with ls -a.

    - .docker_compose_env_http                  sample .env file for a HTTP based installation
    - .docker_compose_env_https                 sample .env file for a HTTPS based installation
    - .docker_compose_env_https_custom_nginx    sample .env file for a HTTPS based installation with custom Nginx config
    - .docker_compose_env_https_kerberos        sample .env file for a HTTPS based installation with support for Kerberos
    - .docker_compose_env_http_selenium         sample .env file for development, support Selenium testing via HTTP
    - .docker_compose_env_https_selenium        sample .env file for development, support Selenium testing via HTTPS
    - .env                                      Docker Compose environment file, must be created by the user
    - docker-compose                            directory with Docker Compose configuration snippets
    - etc/templates/dot_env.m4                  template file used by create_sample_env_files.sh
    - scripts/devel/create_sample_env_files.sh  a small helper for creating the sample env files
    - scripts/devel/generate_dot_env.sh         a small helper for recreating .env from dot_env.m4
    - scripts/update.sh                         a small helper for updating to updated images
