#!/bin/bash

# This is a shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .
# Pass -h for usage info.

# parse command line argument
function args() {
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help -- "$@")

    # print help message in case of invalid optiond
    [ $? -eq 0 ] || {
        print_help_and_exit "1"
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

    # The standard behavior is to use the setup from .env.
    # In .env one may set up a specific repositories and specific tags.
    $0

END_HELP

    exit $1
}

# actually parse the command line
args "$0" "$@"

if [[ $HELP_FLAG -eq 1 ]]
then
    print_help_and_exit "0"
fi

# stop and remove the containers, but keep the named volumes
docker-compose down

# get, or update, the non-local images
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
docker-compose pull

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
