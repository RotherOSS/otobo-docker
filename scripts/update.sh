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

# Disable the Docker warning for the time being - https://github.com/RotherOSS/otobo-docker/pull/124#issuecomment-1590879464
#docker_warning

# get the name of the running script in order to mark the messages printed by the script itself
script_name=${BASH_SOURCE[0]##*/}

# if docker-compose exists, use that, otherwise, use `docker compose`
if ! command -v docker-compose &> /dev/null
then
    echo "[$script_name] docker-compose was not found, using docker compose"
    echo "[$script_name] See https://github.com/RotherOSS/otobo-docker/issues/122 for more into on this."
    DOCKERCOMPOSE="docker compose"
else
    echo "[$script_name] docker-compose found, will continue to use that."
    echo "[$script_name] See https://github.com/RotherOSS/otobo-docker/issues/122 for more info on this."
    DOCKERCOMPOSE="docker-compose"
fi

# During the update there should be no interference from the outside.
# Stop and remove the containers, but keep the named volumes intact
$DOCKERCOMPOSE down

# set up some variables

# the names of the volumes depend on the project name
compose_project_name=$($DOCKERCOMPOSE config --environment | perl -n -e 'm/^COMPOSE_PROJECT_NAME=(.*)/ && print $1')
otobo_volume="${compose_project_name}_opt_otobo"
update_volume="${compose_project_name}_opt_otobo_update"

# Use the same docker image for the update as will be used in the new version.
# Getting that relevant name is not really simple. Usually it is be extracted with jq
# from `docker compose config --format json`. But we can't rely on jq being present.
otobo_image=$($DOCKERCOMPOSE config --images | grep 'otobo:' | head -n 1)
echo "[$script_name] Running the upgrade with the image image: '$otobo_image'"

# Make sure that the image is available
echo "[$script_name] Pulling $otobo_image, please ignore error about local images"
docker pull $otobo_image

# Running commands with different entrypoints in the otobo image.
tmpl_docker_run_cmd="docker run --rm --volume ${otobo_volume}:/opt/otobo --volume ${update_volume}:/opt/otobo_update --entrypoint ENTRYPOINT $otobo_image"
docker_run_rsync=${tmpl_docker_run_cmd/ENTRYPOINT/rsync}
docker_run_perl=${tmpl_docker_run_cmd/ENTRYPOINT/perl}

# The named volume used for the update should already exist, but it is better to make sure
# Note that Docker compose prepends the project name to the volume names.
echo "Creating the volume '$update_volume' if it does not exist yet"
docker volume create ${update_volume}

# The directory with the article data gets special treatment. For that we first need to gather
# the name from the service web.
# The console command Admin::Config::Read is not used here as it depends on the database.
article_dir=$( $docker_run_perl -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{Ticket::Article::Backend::MIMEBase::ArticleDataDir})' )
echo "[$script_name] The article data is in $article_dir"

# get, or update, the non-local images
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo
echo "[$script_name] Updating Docker images from their repositories."
echo "[$script_name] See the file .env for which repositories and tags are used."
echo "[$script_name] Error messages for local images can be ignored."
$DOCKERCOMPOSE pull

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
TZ=UTC printf -v now "%(%F_%H%M%S)T" -1
dir_otobo_update="/opt/otobo_update/$now"
echo "[$script_name] using $dir_otobo_update as backup directory for this update"

# Move files /opt/otobo to $dir_otobo_update. The copying is done using the command 'docker' only, not Docker compose.
# This allows to control which volumes are considered. The Docker compose declaration might have
# have additional volumes which should stay untouched by the upgrade.

# Move the directory tree with the exception of article data dir.
# The excluded dir is given relative to the source dir and is passed with a trailing slash.
# Note the empty directories are not removed.
relative_article_dir=${article_dir/#\/opt\/otobo\//}
$docker_run_rsync \
  --archive \
  $rsync_verbose \
 --remove-source-files \
 --exclude "${relative_article_dir%/}/" \
 /opt/otobo/ "$dir_otobo_update/"

# Restore the hidden files, but some of them will be overwritten by copy_otobo_next
# with files from /opt/otobo_install/otobo_next.
# The --include and --exclude option are a bit daunting. The rule is that each directory
# or file is matched against the option and the first match wins.
echo "[$script_name] restoring hidden files"
$docker_run_rsync -av \
  --exclude "/.copy_otobo_next_finished" \
  --include "/.*" \
  --exclude "*" \
  "$dir_otobo_update/" /opt/otobo/

# The copy_otobo_next task is the same as used in the initial startup.
echo "[$script_name] copying the new files for /opt/otobo"
$DOCKERCOMPOSE run --no-deps --rm web copy_otobo_next

# Rescue some files from the previous installation. These may overwrite
# from /opt/otobo_install/otobo_next.
# Kernel/Config.pm contains installation specific configuration
# locally installed Perl modules may be installed in local
# copy installed stats into var/stats
echo "[$script_name] restore more runtime files"
$docker_run_rsync \
  --archive \
  $rsync_verbose \
  --include "/Kernel/" --include "/Kernel/Config.pm" \
  --include "/local/" --include "/local/**" \
  --include "/var/" --include "/var/stats/" --include "/var/stats/*.installed" \
  --exclude "*" \
  "$dir_otobo_update/" /opt/otobo/

# start containers again, using the new version
echo "[$script_name] starting up the services again"
$DOCKERCOMPOSE up --detach

echo "[$script_name] running '$DOCKERCOMPOSE ps' only as a quick sanity check"
$DOCKERCOMPOSE ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo "[$script_name] sleeping for 10 seconds while the database is starting up"
sleep 10
echo "[$script_name] finished with sleeping"

# complete the update, with running database

# find out the major.minor version of the provious installation, e.g. 11.0 or 11.1
prev_release_file="$dir_otobo_update/RELEASE"
prev_major_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*(\d+)\.\d+/ && print $1' $prev_release_file )
prev_minor_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*\d+\.(\d+)/ && print $1' $prev_release_file )

# run the database update script only for major or minor version upgrades
if (( $prev_major_version < 11 || ($prev_major_version == 11 && $prev_minor_version < 1) )); then
    echo "[$script_name] running DBUpdate-to-11.1.pl"
    $DOCKERCOMPOSE exec web ./scripts/DBUpdate-to-11.1.pl
fi

# reinstall packages in any case
echo "[$script_name] running do_update_tasks"
$DOCKERCOMPOSE exec web /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
echo "[$script_name] printing out the update log"
$DOCKERCOMPOSE exec web cat /opt/otobo/var/log/update.log

echo "[$script_name] finished"
