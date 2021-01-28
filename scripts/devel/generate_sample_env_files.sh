#!/bin/bash

# This script is a helper for generating sample Docker Compose environment files from a template.
# It is meant to be used by developers of otobo-docker.
# The goal is to have a single source file for all sample .env files.

# Pass -h for usage info.

# parse command line argument
function args()
{
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help -- "$@")

    # print help message in case of invalid optiond
    [ $? -eq 0 ] || {
        print_help_and_exit 1
    }

    # set default values
    HELP_FLAG=0

    eval set -- "$options"
    while true; do
        case "$1" in
        -h)
            HELP_FLAG=1
            ;;

        --help)
            HELP_FLAG=1
            ;;

        --)
            shift
            break
            ;;

        esac
        shift
    done
}

# print help
function print_help_and_exit() {
    cat <<END_HELP
Usage:

    # print this help message
    $0 -h
    $0 --help

    # the standard behavior:
    # create .docker_compose_env_http, .docker_compose_env_https .docker_compose_env_https_custom_nginx
    $0

END_HELP

    exit $1
}

# actually parse the command line
args $0 "$@"

if [[ $HELP_FLAG -eq 1 ]]
then
    print_help_and_exit 0
fi

# for now we support only the hardcoded template
if [[ -e "etc/templates/dot_env.m4" ]]; then

    # the default file supporting HTTPS via Nginx
    cp --backup=numbered .docker_compose_env_https .docker_compose_env_https.bak || :
    m4 --prefix-builtins etc/templates/dot_env.m4 > .docker_compose_env_https

    # HTTP only
    cp --backup=numbered .docker_compose_env_http  .docker_compose_env_http.bak || :
    m4 --prefix-builtins --define "otoflag_HTTP" etc/templates/dot_env.m4 > .docker_compose_env_http

    # HTTPS with a custom nginx config
    cp --backup=numbered .docker_compose_env_https_custom_nginx .docker_compose_env_https_custom_nginx.bak || :
    m4 --prefix-builtins --define "otoflag_CUSTOM_NGINX" etc/templates/dot_env.m4 > .docker_compose_env_https_custom_nginx

    # for testing: HTTPS and additionally Selenium Testing with Chrome
    cp --backup=numbered .docker_compose_env_https_selenium .docker_compose_env_https_selenium.bak || :
    m4 --prefix-builtins --define "otoflag_SELENIUM" etc/templates/dot_env.m4 > .docker_compose_env_https_selenium

fi
