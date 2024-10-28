m4_divert(-1)

This file, etc/templates/dot_env.m4, is a M4 template file. The script script/devel/generate_sample_env_files.sh
takes this template and generates the following files from it:

    .docker_compose_env_http
    .docker_compose_env_http_selenium
    .docker_compose_env_https
    .docker_compose_env_https_custom_nginx
    .docker_compose_env_https_kerberos
    .docker_compose_env_https_selenium

These generated files are not used for running OTOBO. They are only sample files for the actual config file .env.
Users can choose their use case and use the appropriate sample file as a starting point for their own .env file.

Please adapt the macros otovar_MINOR_RELEASE_TAG, otovar_PATCH_LEVEL_TAG, otovar_DEVEL_TAG, and otovar_LOCAL_BUILD_TAG
when creating new releases or development branches.
See ./scripts/devel/generate_sample_env_files.sh -h for how to regenerate the sample file after making changes here.

# These are the macros that should be adapted for new releases and new development branches.
# All of these macros affect only comment lines in the generated sample .env files.
m4_define(`otovar_MINOR_RELEASE_TAG',`latest-11_0')
m4_define(`otovar_PATCH_LEVEL_TAG',`rel-11_0_7')
m4_define(`otovar_DEVEL_TAG',`devel-rel-11_0')
m4_define(`otovar_LOCAL_BUILD_TAG',`local-11.0.x')

# Collect which services should be started by collecting the relevant
# Docker Compose .yml files. The otobo-base.yml file is always needed.
m4_define(`otovar_COMPOSE_FILE',`docker-compose/otobo-base.yml')

# add the .yml file for HTTP
m4_define(
  `otovar_COMPOSE_FILE',
  otovar_COMPOSE_FILE`'m4_ifdef(
    `otoflag_HTTP',
    `:docker-compose/otobo-override-http.yml',
    `'))

# add the .yml file for HTTPS with Kerberos
m4_define(
  `otovar_COMPOSE_FILE',
  otovar_COMPOSE_FILE`'m4_ifdef(
    `otoflag_KERBEROS',
    `:docker-compose/otobo-override-https-kerberos.yml',
    `'))

# add the .yml file for HTTPS, including the custom config and the Selenium case
m4_define(
  `otovar_COMPOSE_FILE',
  otovar_COMPOSE_FILE`'m4_ifdef(
    `otoflag_HTTPS',
    `:docker-compose/otobo-override-https.yml',
    `'))

# add the .yml file for the custom Nginx config if required
m4_define(
  `otovar_COMPOSE_FILE',
  otovar_COMPOSE_FILE`'m4_ifdef(
    `otoflag_CUSTOM_NGINX',
    `:docker-compose/otobo-nginx-custom-config.yml',
    `'))

# add the .yml file for Selenium if required
m4_define(
  `otovar_COMPOSE_FILE',
  otovar_COMPOSE_FILE`'m4_ifdef(
    `otoflag_SELENIUM',
    `:docker-compose/otobo-selenium.yml',
    `'))

m4_divert(0)m4_dnl
# This file contains default values for environment values that are needed either by Docker Compose itself
# or by the docker compose files.

# COMPOSE_PROJECT_NAME declares the prefix of the name of the Docker containers. So if the
# project name is 'acme_support' then the web container is named either 'acme_support_web_1' for
# Compose V1 or 'acme_support-web-1 for Compose V2. The project name also declares
# the prefix of named volumes. Thus changing the project name allows to have
# seperate containers and volumes for separate installations of OTOBO.
#
# Note that when COMPOSE_PROJECT_NAME is set in the shell environment,
# then that setting has higher precedence.
COMPOSE_PROJECT_NAME=otobo
#COMPOSE_PROJECT_NAME=acme_support

# COMPOSE_FILE is a collection of files, separated by COMPOSE_PATH_SEPARATOR, that make up the final config.
# The files usually reside in the subdirectory docker-compose.
# Additional services can be added by concatenating more files to COMPOSE_FILE. An example would services
# for S3 compatible storage. That is: :docker-compose/otobo-localstack.yml or :docker-compose/otobo-minio.yml
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=otovar_COMPOSE_FILE

# Database configuration
# OTOBO_DB_ROOT_PASSWORD must be set
OTOBO_DB_ROOT_PASSWORD=

# Set this to a value in bytes to overwrite the default query size set for OTOBO
#OTOBO_DB_QUERY_CACHE_SIZE=

# HTTP options
m4_ifdef(
  `otoflag_HTTP',
  `',
  `# In the HTTPS case http:// redirects to https://
')m4_dnl
# Set OTOBO_WEB_HTTP_PORT when the HTTP port is not 80
#OTOBO_WEB_HTTP_PORT=<your special port>

# Set OTOBO_WEB_HTTP_IPADDR when only requests addressed to a specific IP should be served.
# See https://docs.docker.com/compose/compose-file/compose-file-v3/#ports
#OTOBO_WEB_HTTP_IPADDR=<your special ip address>
m4_ifdef( `otoflag_HTTP', `m4_divert(-1)')m4_dnl

# HTTPS options

# set OTOBO_WEB_HTTPS_PORT when the HTTPS port is not 443
#OTOBO_WEB_HTTPS_PORT=<your special port>

# Set OTOBO_WEB_HTTPS_IPADDR when only requests addressed to a specific IP should be served.
# See https://docs.docker.com/compose/compose-file/compose-file-v3/#ports
#OTOBO_WEB_HTTPS_IPADDR=<your special ip address>

# The settings OTOBO_NGINX_SSL_CERTIFICATE and OTOBO_NGINX_SSL_CERTIFICATE_KEY
# are mandatory when HTTPS is used.
# The configured pathes must be absolute pathes that are available in the container.
#OTOBO_NGINX_SSL_CERTIFICATE=/etc/nginx/ssl/ssl-cert.crt
#OTOBO_NGINX_SSL_CERTIFICATE_KEY=/etc/nginx/ssl/ssl-key.key
OTOBO_NGINX_SSL_CERTIFICATE=
OTOBO_NGINX_SSL_CERTIFICATE_KEY=
m4_ifdef( `otoflag_HTTP', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_KERBEROS', `', `m4_divert(-1)')m4_dnl

# Kerberos Options

# Kerberos keytab, default is /etc/krb5.keytab
#OTOBO_NGINX_KERBEROS_KEYTAB=/opt/otobo-docker/nginx-conf/krb5.keytab

# Kerberos config, default is /etc/krb5.conf as generated krb5.conf.template
#OTOBO_NGINX_KERBEROS_CONFIG=/opt/otobo-docker/nginx-conf/krb5.conf

# Kerberos Service Name
OTOBO_NGINX_KERBEROS_SERVICE_NAME=HTTP/portal.rother-oss.com

# Kerberos REALM
OTOBO_NGINX_KERBEROS_REALM=ROTHER-OSS.COM

# Kerberos kdc / AD Controller
OTOBO_NGINX_KERBEROS_KDC=rother-oss.com

# Kerberos Admin Server
OTOBO_NGINX_KERBEROS_ADMIN_SERVER=rother-oss.com

# Kerberos Default Domain
OTOBO_NGINX_KERBEROS_DEFAULT_DOMAIN=rother-oss.com

# Kerberos Substitute Template Directory
NGINX_ENVSUBST_TEMPLATE_DIR=
m4_ifdef( `otoflag_KERBEROS', `', `m4_divert(0)')m4_dnl

# Elasticsearch options
OTOBO_ELASTICSEARCH_ES_JAVA_OPTS=-Xms512m -Xmx512m

################################################################################
# The Docker image for the service 'db' can be specified explicitly.
# The default is mariadb:10.5
################################################################################
#OTOBO_IMAGE_DB=

################################################################################
# The Docker image for the services 'web' and 'daemon' can be specified explicitly.
`#' The default is rotheross/otobo:otovar_MINOR_RELEASE_TAG()
################################################################################

# Examples:
`#'OTOBO_IMAGE_OTOBO=rotheross/otobo:otovar_PATCH_LEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO=rotheross/otobo:otovar_DEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO=otobo:otovar_LOCAL_BUILD_TAG()

################################################################################
# The Docker image for the service 'eleastic' can be specified explicitly.
`#' The default is rotheross/otobo-elasticsearch:otovar_MINOR_RELEASE_TAG()
################################################################################

# Examples:
`#'OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:otovar_PATCH_LEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:otovar_DEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:otovar_LOCAL_BUILD_TAG()

################################################################################
# The Docker image for the service 'redis' can be specified explicitly.
# The default is redis:6.0-alpine
################################################################################
#OTOBO_IMAGE_REDIS=

m4_divert(-1)m4_dnl

# find the image used for Nginx service
m4_define(
  `otovar_NGINX_IMAGE',
  m4_ifdef(
    `otoflag_KERBEROS',
    `otobo-nginx-kerberos-webproxy',
    `otobo-nginx-webproxy'))

m4_divert(0)m4_dnl
m4_ifdef( `otoflag_HTTP', `m4_divert(-1)')m4_dnl
################################################################################
# The Docker image for the service 'nginx' can be specified explicitly.
`#' The default image is rotheross/otovar_NGINX_IMAGE():otovar_MINOR_RELEASE_TAG()
################################################################################

# Examples:
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():otovar_PATCH_LEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():otovar_DEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_NGINX_IMAGE():otovar_LOCAL_BUILD_TAG()

m4_ifdef( `otoflag_HTTP', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(-1)')m4_dnl

# provide a custom Nginx config template dir
NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/config/template-custom
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(-1)')m4_dnl
################################################################################
# The Docker image for the service 'selenium' can be specified explicitly.
`#' The default image is rotheross/otobo-selenium-chrome:otovar_MINOR_RELEASE_TAG()
################################################################################

# Examples:
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:otovar_PATCH_LEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:otovar_DEVEL_TAG()
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otobo-selenium-chrome:otovar_LOCAL_BUILD_TAG()

m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(0)')m4_dnl
