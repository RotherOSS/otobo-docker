#!/bin/bash

# This script is a helper for generating sample Docker Compose environment files from a template.
# It is meant to be used by developers of otobo-docker.
# The goal is to have a single source file for all sample .env files.
# The template is located at "etc/templates/dot_env.m4"

# Pass -h for usage info.

# parse command line argument
function args()
{
    # -h and --help take no parameters
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

    # the standard behavior is to recreate the sample .env files from the template etc/templates/dot_env.m4.
    # Please adapt the macros otovar_MINOR_RELEASE_TAG, otovar_PATCH_LEVEL_TAG, otovar_DEVEL_TAG, and otovar_LOCAL_BUILD_TAG
    # in the template for creating new releases or development branches.
    # The affected sample .env files are:
    #    .docker_compose_env_http
    #    .docker_compose_env_http_selenium
    #    .docker_compose_env_https
    #    .docker_compose_env_https_custom_nginx
    #    .docker_compose_env_https_kerberos
    #    .docker_compose_env_https_selenium
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

    # the default file: HTTPS with Nginx
    sample_file=.docker_compose_env_https
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_HTTPS" --define "otovar_SAMPLE_FILE=$sample_file"  etc/templates/dot_env.m4 > $sample_file

    # HTTPS with Kerberos configuration
    sample_file=.docker_compose_env_https_kerberos
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_KERBEROS" --define "otovar_SAMPLE_FILE=$sample_file" etc/templates/dot_env.m4 > $sample_file

    # HTTP only
    sample_file=.docker_compose_env_http
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_HTTP" --define "otovar_SAMPLE_FILE=$sample_file" etc/templates/dot_env.m4 > $sample_file

    # HTTPS with a custom nginx config
    sample_file=.docker_compose_env_https_custom_nginx
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_HTTPS" --define "otoflag_CUSTOM_NGINX" --define "otovar_SAMPLE_FILE=$sample_file" etc/templates/dot_env.m4 > $sample_file

    # for testing: HTTPS and additionally Selenium Testing with Chrome
    sample_file=.docker_compose_env_https_selenium
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_HTTPS" --define "otoflag_SELENIUM" --define "otovar_SAMPLE_FILE=$sample_file" etc/templates/dot_env.m4 > $sample_file

    # for testing: HTTP and additionally Selenium Testing with Chrome
    sample_file=.docker_compose_env_http_selenium
    cp --backup=numbered $sample_file $sample_file.bak || :
    m4 --prefix-builtins --define "otoflag_HTTP" --define "otoflag_SELENIUM" --define "otovar_SAMPLE_FILE=$sample_file" etc/templates/dot_env.m4 > $sample_file

fi
