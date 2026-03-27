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
echo "[Note] Running the upgrade with the image image: '$otobo_image'"

# Make sure that the image is available
echo "[Note] Pulling $otobo_image, please ignore error about local images"
docker pull $otobo_image

# Running commands with different entrypoints in the otobo image.
tmpl_docker_run_cmd="docker run --rm --volume ${otobo_volume}:/opt/otobo --volume ${update_volume}:/opt/otobo_update --entrypoint ENTRYPOINT $otobo_image"
docker_run_rsync=${tmpl_docker_run_cmd/ENTRYPOINT/rsync}
docker_run_bash=${tmpl_docker_run_cmd/ENTRYPOINT/bash}
docker_run_perl=${tmpl_docker_run_cmd/ENTRYPOINT/perl}
#echo
#echo "tmpl_docker_run_cmd: $tmpl_docker_run_cmd"
#echo "docker_run_rsync: $docker_run_rsync"
#echo "docker_run_bash: $docker_run_bash"
#echo "docker_run_perl: $docker_run_perl"

# The named volume used for the update should already exist, but it is better to make sure
# Note that Docker compose prepends the project name to the volume names.
echo
echo "Creating the volume '$update_volume' if it does not exist yet"
docker volume create ${update_volume}

# The directory with the article data gets special treatment. For that we first need to gather
# the name from the service web.
# The console command Admin::Config::Read is not used here as it depends on the database.
article_dir=$( $docker_run_perl -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{Ticket::Article::Backend::MIMEBase::ArticleDataDir})' )
echo 
echo "[Note] The article data is in $article_dir"

# get, or update, the non-local images
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo
echo "[Note] Updating Docker images from their repositories."
echo "[Note] See the file .env for which repositories and tags are used."
echo "[Note] Error messages for local images can be ignored."
$DOCKERCOMPOSE pull

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
TZ=UTC printf -v now "%(%F_%H%M%S)T" -1
dir_otobo_update="/opt/otobo_update/$now"
echo
echo "[Note] using $dir_otobo_update as backup directory for this update"

# Move files /opt/otobo to $dir_otobo_update. The copying is done using the command 'docker' only, not Docker compose.
# This allows to control which volumes are considered. The Docker compose declaration might have
# have additional volumes which should stay untouched by the upgrade.

# Move the directory tree with the exception of article data dir.
# The excluded dir is given relative to the source dir.
# Note the empty directories are not removed.
relative_article_dir=${article_dir/#\/opt\/otobo\//}
$docker_run_rsync -av --remove-source-files --exclude $relative_article_dir /opt/otobo/ $dir_otobo_update

# the copy_otobo_next() is the same as used on initial startup
$DOCKERCOMPOSE run --no-deps --rm web copy_otobo_next

# rescue some files from the previous installation
$docker_run_bash -c "

    echo 'coping files from $dir_otobo_update'

    # Kernel/Config.pm contains installation specific configuration
    mkdir -p /opt/otobo/Kernel
    cp -a $dir_otobo_update/Kernel/Config.pm /opt/otobo/Kernel

    # Articles and attachments might be stored in var/article or another directory.
    # This article data directory might be large. Therefore it is not part of the backup,
    # insteed it is kept in place.

    # locally installed Perl modules may be installed in local
    mkdir -p /opt/otobo/local
    cp -a -t /opt/otobo/local $dir_otobo_update/local/*

    # copy the hidden file .bash_history purely for the convenience of having the history available
    cp -a $dir_otobo_update/.bash_history /opt/otobo

    # copy installed stats
    mkdir -p /opt/otobo/var/stats
    cp -a -t /opt/otobo/var/stats $dir_otobo_update/var/stats/*.installed

    echo 'finished coping files from $dir_otobo_update'
"

# start containers again, using the new version
$DOCKERCOMPOSE up --detach

echo "[Note] running '$DOCKERCOMPOSE ps' only as a quick sanity check"
$DOCKERCOMPOSE ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo "[Note] sleeping for 10 seconds while the database is starting up"
sleep 10
echo "[Note] finished with sleeping"

# complete the update, with running database

# find out the major.minor version of the provious installation, e.g. 11.0 or 11.1
prev_release_file="$dir_otobo_update/RELEASE"
prev_major_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*(\d+)\.\d+/ && print $1' $prev_release_file )
prev_minor_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*\d+\.(\d+)/ && print $1' $prev_release_file )

# run the database update script only for major or minor version upgrades
if (( $prev_major_version < 11 || ($prev_major_version == 11 && $prev_minor_version < 1) )); then
    echo "[Note] running DBUpdate-to-11.1.pl"
    $DOCKERCOMPOSE exec web ./scripts/DBUpdate-to-11.1.pl
fi

# reinstall packages in any case
echo "[Note] running do_update_tasks"
$DOCKERCOMPOSE exec web /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
echo "[Note] printing out the update log"
$DOCKERCOMPOSE exec web cat /opt/otobo/var/log/update.log

echo "[Note] finished"
