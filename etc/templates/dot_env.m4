m4_divert(-1)

# Collect which services should be started by collecting the relevant
# Docker compose .yml files. The otobo-base.yml file is always needed.
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
# Settings that are needed by Docker Compose itself.
# COMPOSE_FILE is a collection of snippets that make up the final config.
COMPOSE_PROJECT_NAME=otobo
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
m4_ifdef( `otoflag_HTTP', `m4_divert(-1)')m4_dnl

# HTTPS options
# set OTOBO_WEB_HTTPS_PORT when the HTTPS port is not 443
#OTOBO_WEB_HTTPS_PORT=<your special port>
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
OTOBO_NGINX_KERBEROS_REALM=PORTAL.ROTHER-OSS.COM
m4_ifdef( `otoflag_KERBEROS', `', `m4_divert(0)')m4_dnl

# Elasticsearch options
OTOBO_ELASTICSEARCH_ES_JAVA_OPTS=-Xms512m -Xmx512m

################################################################################
# The Docker image for otobo_web_1 and otobo_daemon_1 can be specified explicitly.
# The default is rotheross/otobo:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
#OTOBO_IMAGE_OTOBO=otovar_REPOSITORY()otobo:otovar_TAG()

# More examples
#OTOBO_IMAGE_OTOBO=rotheross/otobo:rel-10_0_12
#OTOBO_IMAGE_OTOBO=rotheross/otobo:devel-rel-10_0
#OTOBO_IMAGE_OTOBO=rotheross/otobo:devel-rel-10_1
#OTOBO_IMAGE_OTOBO=otobo:local-10.0.x
#OTOBO_IMAGE_OTOBO=otobo:local-10.1.x

################################################################################
# The Docker image for otobo_elastic_1 can be specified explicitly.
# The default is rotheross/otobo-elasticsearch:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otovar_REPOSITORY()otobo-elasticsearch:otovar_TAG()

# More examples
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:rel-10_0_12
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_0
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_1
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.0.x
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.1.x

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
# The Docker image for otobo_nginx_1 can be specified explicitly.
`#' The default image is rotheross/otovar_NGINX_IMAGE:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_REPOSITORY()otovar_NGINX_IMAGE:otovar_TAG()

# More examples
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE:rel-10_0_12
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE:devel-rel-10_0
`#'OTOBO_IMAGE_OTOBO_NGINX=rotheross/otovar_NGINX_IMAGE:devel-rel-10_1
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_NGINX_IMAGE:local-10.0.x
`#'OTOBO_IMAGE_OTOBO_NGINX=otovar_NGINX_IMAGE:local-10.1.x

m4_ifdef( `otoflag_HTTP', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(-1)')m4_dnl

# provide a custom Nginx config template dir
NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/config/template-custom
m4_ifdef( `otoflag_CUSTOM_NGINX', `', `m4_divert(0)')m4_dnl
m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(-1)')m4_dnl
################################################################################
# The Docker image for otobo_selenium_1 can be specified explicitly.
`#' The default image is rotheross/otobo-selenium-chrome:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otovar_REPOSITORY()otobo-selenium-chrome:otovar_TAG()

# More examples
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:rel-10_0_12
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:devel-rel-10_0
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=rotheross/otobo-selenium-chrome:devel-rel-10_1
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otobo-selenium-chrome:local-10.0.x
`#'OTOBO_IMAGE_OTOBO_SELENIUM_CHROME=otobo-selenium-chrome:local-10.1.x

m4_ifdef( `otoflag_SELENIUM', `', `m4_divert(0)')m4_dnl
