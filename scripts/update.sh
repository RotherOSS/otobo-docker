#!/bin/bash

# This is a shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .
# Pass -h for usage info.

# Initial Values
# DONT_WARN=false - Disabled - https://github.com/RotherOSS/otobo-docker/pull/124#issuecomment-1590879464

# Help Message
function display_help() {
    echo "Usage: update.sh [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Display this help screen"
#    echo "      --dontwarn Don't warn about Docker Compose warnings."
    echo "   "
    echo "The standard behavior is to use the setup from .env."
    echo "In .env one may set up a specific repositories and specific tags."
    echo "   "
}

# Docker Compose Warning
#function docker_warning() {
#    if [ "$DONT_WARN" = false ]; then
#        # assuming the change would be made automatically? 
#       # haven't migrated v1 compose to v2 before
#        echo "Due to changes with docker, your container names may appear differently after the upgrade, [docker-compose] used to be the command used, but with compose v2, [docker compose] is now used."
#        echo "This may change some container names, such as changing [otobo_web_1] to [otobo-web-1]."
#        echo "Please see https://github.com/RotherOSS/otobo-docker/issues/122 for more information."
#        echo "   "
#        read -p "Do you understand? (y/n) " yon
#        case "$yon" in
#            [Yy]*)
#                echo "Continuing."
#                ;;
#            *)
#                echo "Please read the issue mentioned above for more information. Exiting."
#                exit $1
#                ;;
#        esac
#    fi
#}

# Parse cli args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
#        --dontwarn)
#            DONT_WARN=true
#            shift
#            ;;
        *)
            echo "Invalid option: $1"
            echo "Use -h or --help for usage instructions."
            exit 1
            ;;
    esac
done

### Disable for the time being - https://github.com/RotherOSS/otobo-docker/pull/124#issuecomment-1590879464
# docker_warning

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
