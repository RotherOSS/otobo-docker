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

# stop and remove the containers, but keep the named volumes
$DOCKERCOMPOSE down

# The article dir gets special treatment. So we need to gather the name from the service web.
# The console command Admin::Config::Read is not used here as it depends on the database.
article_dir=$( $DOCKERCOMPOSE run --rm --no-deps --entrypoint perl web -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{Ticket::Article::Backend::MIMEBase::ArticleDataDir})' )
echo $article_dir
exit

# get, or update, the non-local images
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo "Updating Docker images from their repositories."
echo "See the file .env for which repositories and tags are used."
echo "Error messages for local images can be ignored."
$DOCKERCOMPOSE pull

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
TZ=UTC printf -v now "%(%F_%H%M%S)T" -1
dir_otobo_update="/opt/otobo_update/$now"
echo
echo "using $dir_otobo_update as backup directory for this update"

# Move files /opt/otobo to $dir_otobo_update. The copying is done using the command 'docker' only, not Docker compose.
# This allows to control which volumes are considered. The Docker compose declaration might have
# have additional volumes which should stay untouched by the upgrade.

# The named volume used for the update should already exist, but it is better to make sure
# Note that Docker compose prepends the project name to the volume names.
compose_project_name=$($DOCKERCOMPOSE config --environment | perl -n -e 'm/^COMPOSE_PROJECT_NAME=(.*)/ && print $1')
update_volume="${compose_project_name}_opt_otobo_update"
echo
echo "Creating the volume '$update_volume' if it does not exist yet"
docker volume create ${compose_project_name}_opt_otobo_update

# The only requirement for the used Docker image is that a shell is available.
# Having 'tree' is useful for debugging, so let's use busybox.
docker_run_cmd="docker run --rm --volume ${compose_project_name}_opt_otobo:/opt/otobo --volume ${compose_project_name}_opt_otobo_update:/opt/otobo_update busybox:stable ash -c"
echo
echo "docker_run_cmd: $docker_run_cmd"

# Move the directory tree with the exception of var/article.
$docker_run_cmd "cd /opt/otobo     && mkdir -p $dir_otobo_update     && mv \$(ls -A | grep -v var) $dir_otobo_update"
$docker_run_cmd "cd /opt/otobo/var && mkdir -p $dir_otobo_update/var && mv \$(ls -A | grep -v article) $dir_otobo_update/var"

# the copy_otobo_next() is the same as used on initial startup
$DOCKERCOMPOSE run --no-deps --rm web copy_otobo_next

# rescue some files from the previous installation
$docker_run_cmd "

    echo 'coping files from $dir_otobo_update'

    # Kernel/Config.pm contains installation specific configuration
    mkdir -p /opt/otobo/Kernel
    cp -a $dir_otobo_update/Kernel/Config.pm /opt/otobo/Kernel

    # Articles and attachments might be stored in var/article. This directory
    # might be large. Therefor that directory is not part of the
    # backup, is kept in /opt/otobo/var/article

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

# a quick sanity check
$DOCKERCOMPOSE ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo "sleeping for 10s, while the database is starting up"
sleep 10
echo "finished with sleeping"

# complete the update, with running database

# find out the major.minor version of the provious installation, e.g. 11.0 or 11.1
prev_release_file="$dir_otobo_update/RELEASE"
prev_major_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*(\d+)\.\d+/ && print $1' $prev_release_file )
prev_minor_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*\d+\.(\d+)/ && print $1' $prev_release_file )

# run the database update script only for major or minor version upgrades
if (( $prev_major_version < 11 || ($prev_major_version == 11 && $prev_minor_version < 1) )); then
    echo 'yes'
    $DOCKERCOMPOSE exec web ./scripts/DBUpdate-to-11.1.pl
fi

# reinstall packages in any case
$DOCKERCOMPOSE exec web /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
$DOCKERCOMPOSE exec web cat /opt/otobo/var/log/update.log
