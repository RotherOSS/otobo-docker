# Settings needed by docker-compose itself
# COMPOSE_FILE is used for switching between HTTP and HTPPS
m4_divert(-1)
m4_ifdef(
  `otoflag_HTTP',
  `m4_define(`otovar_WEB_OVERRIDE', `docker-compose/otobo-override-http.yml')',
  `m4_define(`otovar_WEB_OVERRIDE', `docker-compose/otobo-override-https.yml')')
m4_divert`'m4_dnl
COMPOSE_PROJECT_NAME=otobo
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose/otobo-base.yml:otovar_WEB_OVERRIDE()

# Database configuration
# OTOBO_DB_ROOT_PASSWORD must be set
OTOBO_DB_ROOT_PASSWORD=

# HTTP options
m4_ifdef( `otoflag_HTTP',, `# In the HTTPS case http:// redirect to https://
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
m4_ifdef( `otoflag_HTTP', `m4_divert')

# Elasticsearch options
OTOBO_ELASTICSEARCH_ES_JAVA_OPTS=-Xms512m -Xmx512m

################################################################################
# The Docker image for otobo_web_1 and otobo_daemon_1 can be specified explicitly.
# The default is rotheross/otobo:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
#OTOBO_IMAGE_OTOBO=otovar_REPOSITORY()otobo:otovar_TAG()

# more examples
#OTOBO_IMAGE_OTOBO=rotheross/otobo:rel-10_0_6
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

# more examples
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:rel-10_0_6
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_0
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=rotheross/otobo-elasticsearch:devel-rel-10_1
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.0.x
#OTOBO_IMAGE_OTOBO_ELASTICSEARCH=otobo-elasticsearch:local-10.1.x

################################################################################
# The Docker image for otobo_nginx_1 can be specified explicitly.
# The default is rotheross/otobo-nginx-webproxy:latest
################################################################################

# For use with scripts/update.sh, otovar_XXX() will be replaced
#OTOBO_IMAGE_OTOBO_NGINX=otovar_REPOSITORY()otobo-nginx-webproxy:otovar_TAG()

# more examples
#OTOBO_IMAGE_OTOBO_NGINX=rotheross/otobo-nginx-webproxy:rel-10_0_6
#OTOBO_IMAGE_OTOBO_NGINX=rotheross/otobo-nginx-webproxy:devel-rel-10_0
#OTOBO_IMAGE_OTOBO_NGINX=rotheross/otobo-nginx-webproxy:devel-rel-10_1
#OTOBO_IMAGE_OTOBO_NGINX=otobo-nginx-webproxy:local-10.0.x
#OTOBO_IMAGE_OTOBO_NGINX=otobo-nginx-webproxy:local-10.1.x
m4_ifdef( `otoflag_HTTP', `m4_divert(-1)')m4_dnl

# provide a custom Nginx config template dir
#NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/config/template-custom
#COMPOSE_FILE=docker-compose/otobo-base.yml:docker-compose/otobo-override-https.yml:docker-compose/otobo-nginx-custom-config.yml
m4_ifdef( `otoflag_HTTP', `m4_divert')
