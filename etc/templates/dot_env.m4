m4_divert(-1)

This file, etc/templates/dot_env.m4, is a M4 template file. The script script/devel/generate_sample_env_files.sh takes this template
and generates the following files from it:

    .docker_compose_env_http
    .docker_compose_env_http_selenium
    .docker_compose_env_https
    .docker_compose_env_https_custom_nginx
    .docker_compose_env_https_kerberos
    .docker_compose_env_https_selenium

These generated files are not used for running OTOBO. They are sample files for .env. Users can choose their use case and
use the appropriate sample file as a starting point form their own .env file.

See ./scripts/devel/generate_sample_env_files.sh -h for how to regenerated the sample file when making changes here.

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

# a macro that explains the usage of scripts/devel/generate_dot_env.sh
m4_define(
  `otovar_GENERATE_DOT_ENV_BLURB',
# During development it is convenient to be able to switch between different Docker repositories and Docker image versions.
# The switching can be done with scripts/devel/generate_dot_env.sh. In order to activate this feature,
# create the file dot_env.m4 in your Docker Compose working dir, e.g. /opt/otobo-docker, and uncomment the line below.
)

# a macro for setting the default release tag. This macro differs between the different branches.
m4_define(`otovar_DEFAULT_TAG',`latest-10_0')

m4_divert(0)m4_dnl
# Settings that are needed by Docker Compose itself.

# This determines the name of the Docker containers, e.g. 'otobo_web_1'.
COMPOSE_PROJECT_NAME=otobo

# COMPOSE_FILE is a collection of files, separated by COMPOSE_PATH_SEPARATOR, that make up the final config.
# The files usually reside in the subdirectory docker-compose.
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
# Kerberos keytab
OTOBO_NGINX_KERBEROS_KEYTAB=/opt/otobo-docker/nginx-conf/krb5.keytab

# Kerberos config
OTOBO_NGINX_KERBEROS_CONFIG=/opt/otobo-docker/nginx-conf/krb5.conf

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

# Special configuration when running OTOBO in a cluster
#OTOBO_SYNC_WITH_S3=1
OTOBO_SYNC_WITH_S3=0

################################################################################
# The Docker image for the service 'db' can be specified explicitly.
# The default is mariadb:10.5
################################################################################
#OTOBO_IMAGE_DB=

################################################################################
# The Docker image for the services 'web' and 'daemon' can be specified explicitly.
`#' The default is rotheross/otobo:otovar_DEFAULT_TAG()
################################################################################

otovar_GENERATE_DOT_ENV_BLURB()m4_dnl
#OTOBO_IMAGE_OTOBO=otovar_REPOSITORY()otobo:otovar_TAG()

# More examples
#OTOBO_IMAGE_OTOBO=rotheross/otobo:latest-10_1
#OTOBO_IMAGE_OTOBO=rotheross/otobo:latest-10_0
#OTOBO_IMAGE_OTOBO=rotheross/otobo:rel-10_1_3
#OTOBO_IMAGE_OTOBO=rotheross/otobo:rel-10_0_16
#OTOBO_IMAGE_OTOBO=rotheross/otobo:devel-rel-10_1
#OTOBO_IMAGE_OTOBO=rotheross/otobo:devel-rel-10_0
#OTOBO_IMAGE_OTOBO=otobo:local-10.1.x
#OTOBO_IMAGE_OTOBO=otobo:local-10.0.x

################################################################################
# The Docker image for the service 'eleastic' can be specified explicitly.
`#' The default is rotheross/otobo-elasticsearch:otovar_DEFAULT_TAG()
################################################################################

otovar_GENERATE_DOT_ENV_BLURB()m4_dnl
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otovar_REPOSITORY()otobo-elasticsearch:otovar_TAG()

# More examples
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:latest-10_1
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:latest-10_0
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:rel-10_1_3
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:rel-10_0_16
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_1
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_0
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.1.x
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.0.x

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
`#' The default image is rotheross/otovar_NGINX_IMAGE():otovar_DEFAULT_TAG()
################################################################################

otovar_GENERATE_DOT_ENV_BLURB()m4_dnl
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_REPOSITORY()otovar_NGINX_IMAGE():otovar_TAG()

# More examples
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():latest-10_1
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():latest-10_0
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():rel-10_1_3
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():rel-10_0_16
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():devel-rel-10_1
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE():devel-rel-10_0
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_NGINX_IMAGE():local-10.1.x
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_NGINX_IMAGE():local-10.0.x

m4_ifdef( `otoflag_HTTP', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(-1)')m4_dnl

# provide a custom Nginx config template dir
NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/config/template-custom
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(-1)')m4_dnl
################################################################################
# The Docker image for the service 'selenium' can be specified explicitly.
`#' The default image is rotheross/otobo-selenium-chrome:otovar_DEFAULT_TAG()
################################################################################

otovar_GENERATE_DOT_ENV_BLURB()m4_dnl
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otovar_REPOSITORY()otobo-selenium-chrome:otovar_TAG()

# More examples
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:latest-10_1
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:latest-10_0
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:rel-10_1_3
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:rel-10_0_16
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:devel-rel-10_1
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:devel-rel-10_0
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otobo-selenium-chrome:local-10.1.x
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otobo-selenium-chrome:local-10.0.x

m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(0)')m4_dnl
