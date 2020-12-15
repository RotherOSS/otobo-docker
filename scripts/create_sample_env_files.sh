#!/bin/bash

# This is a helper for generating sample Docker Compose environment files from a template.
# The goal is to have a single source.
# Pass -h for usage info.

# parse command line argument
function args()
{
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help --long repository: --long tag: -- "$@")

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

    # the standard behavior, create .docker_compose_env_http and .docker_compose_env_https
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

    cp --backup=numbered .docker_compose_env_http  .docker_compose_env_http.bak
    m4 --prefix-builtins --define "_enable_HTTP" etc/templates/dot_env.m4 > .docker_compose_env_http

    cp --backup=numbered .docker_compose_env_https .docker_compose_env_https.bak
    m4 --prefix-builtins etc/templates/dot_env.m4 > .docker_compose_env_https
fi
