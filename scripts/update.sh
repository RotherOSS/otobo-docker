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

# if docker-compose exists, use that, otherwise, use `docker compose`
if ! command -v docker-compose &> /dev/null
then
    echo "[Note] docker-compose was not found, using docker compose"
    echo "[Note] See https://github.com/RotherOSS/otobo-docker/issues/122 for more into on this."
    DOCKERCOMPOSE="docker compose"
else
    echo "[Note] docker-compose found, will continue to use that."
    echo "[Note] See https://github.com/RotherOSS/otobo-docker/issues/122 for more info on this."
    DOCKERCOMPOSE="docker-compose"
fi


# get, or update, the non-local images
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo "Updating Docker images from their repositories."
echo "See the file .env for which repositories and tags are used."
echo "Error messages for local images can be ignored."
$DOCKERCOMPOSE pull

# stop and remove the containers, but keep the named volumes
$DOCKERCOMPOSE down

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
$DOCKERCOMPOSE run --no-deps --rm web copy_otobo_next

# start containers again, using the new version
$DOCKERCOMPOSE up --detach

# a quick sanity check
$DOCKERCOMPOSE ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo "sleeping for 10s, while the database is starting up"
sleep 10
echo "finished with sleeping"

# complete the update, with running database
$DOCKERCOMPOSE exec web /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
$DOCKERCOMPOSE exec web cat /opt/otobo/var/log/update.log
