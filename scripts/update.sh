#!/bin/bash

# This is an experimental shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .
# Pass -h for usage info.

# parse command line argument
function args()
{
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help --long repository: --long tag: -- "$@")

    [ $? -eq 0 ] || {
        print_help_and_exit 1
    }

    # default values
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

    # the standard behavior for the repository rotheross and the tag latest
    $0

    # passing repository and tag
    $0   --repository rotheross --tag 10.0.6
END_HELP

    exit $1
}

# actually parse the command line
args $0 "$@"

if [[ $HELP_FLAG -eq 1 ]]
then
    print_help_and_exit 0
fi

echo "going on"

exit 0

# Pass the # stop and remove the containers, but keep the named volumes
docker-compose down

# copy the OTOBO software, while containers are still stopped
# e.g. scripts/update.sh rotheross/otobo:rel-10_x_y
# TODO: update .env
docker run -it --rm --volume otobo_opt_otobo:/opt/otobo $1 copy_otobo_next

# start containers again, using the new version
docker-compose up --detach

# a quick sanity check
docker-compose ps

# complete the update, with running database
docker exec -t otobo_web_1 /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
docker exec -t otobo_web_1  cat /opt/otobo/var/log/update.log
