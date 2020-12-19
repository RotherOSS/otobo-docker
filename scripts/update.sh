#!/bin/bash

# This is an experimental shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .
# Pass -h for usage info.

# parse command line argument
function args() {
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help --long template: --long repository: --long tag: -- "$@")

    # print help message in case of invalid optiond
    [ $? -eq 0 ] || {
        print_help_and_exit "1"
    }

    # set default values
    HELP_FLAG=0
    TEMPLATE=""
    REPOSITORY="rotheross"
    TAG="latest"

    eval set -- "$options"
    while true; do
        case "$1" in
        -h)
            HELP_FLAG=1
            ;;

        --help)
            HELP_FLAG=1
            ;;

        --template)
            shift; # The arg is next in position args
            TEMPLATE=$1
            ;;

        --repository)
            shift; # The arg is next in position args
            REPOSITORY=$1
            ;;

        --tag)
            shift; # The arg is next in position args
            TAG=$1
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

    # the standard behavior using the setup from .env
    # in .env one may set up a specific repository or tag
    $0

    # passing repository and tag is only useful when an m4 template has been set up
    # this is useful mostly during development
    $0 --template dot_env.m4 --repository rotheross --tag 10.0.7
    $0 --template dot_env.m4 --repository rotheross --tag devel-rel-10_0
    $0 --template dot_env.m4 --repository rotheross --tag devel-rel-10_1

    # specify the empty string for local images
    $0 --template dot_env.m4 --repository "" --tag local-10.0.x
    $0 --template dot_env.m4 --repository "" --tag local-10.1.x

END_HELP

    exit $1
}

# update the .env file
function write_env_file() {

    local template=$1
    local repository=$2
    local tag=$3

# checking the m4 file
    if [[ ! -e "$template" ]]; then
        echo "The template file $template does not exist. Exiting";
    exit 1;
    fi

        if [[ ! -r "$template" ]]; then
            echo "The template file $template is not readable. Exiting";
    exit 2;
    fi

# For easier processing we require that the separator is already added to the repository.
# But don't add the '/' for the local repository.
        if [[ "$repository" == "" ]]; then
        :  # local repository, nothing to do
    elif [[ "$repository" == "/" ]]; then
        repository=""
    else
        repository+="/"
    fi

    # in case the repository was passed with a trailing /
    repository="${repository/\/\//\/}"

    echo "repository: '$repository'"
    echo "tag: '$tag'"

    # update .env
    cp --backup=numbered .env .env.bak
    m4 --prefix-builtins --define "otovar_REPOSITORY=$repository"  --define "otovar_TAG=$tag" dot_env.m4 > .env
}

# actually parse the command line
args "$0" "$@"

if [[ $HELP_FLAG -eq 1 ]]
then
    print_help_and_exit "0"
fi

# stop and remove the containers, but keep the named volumes
docker-compose down

# we might want to update the .env file
if [[ "$TEMPLATE" != "" ]]; then

    write_env_file "$TEMPLATE" "$REPOSITORY" "$TAG"

fi

# TODO: warn when --repository or --tag was passed uselessly

# get, or update, the non-local images
if [[ "$REPOSITORY" != "" ]]; then
    docker-compose pull
fi

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
docker-compose run --no-deps --rm web copy_otobo_next

# start containers again, using the new version
docker-compose up --detach

# a quick sanity check
docker-compose ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo "sleeping for 10s, while the database is starting up"
sleep 10
echo "finished with sleeping"

# complete the update, with running database
docker exec -t otobo_web_1 /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
docker exec -t otobo_web_1 cat /opt/otobo/var/log/update.log
