#!/bin/bash

# This is a shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .
# Pass -h for usage info.

# Help Message
function display_help() {
    echo -e "Usage: update.sh [OPTIONS]"
    echo -e "Options:"
    echo -e "  -h, --help     Display this help screen"
    echo -e ""
    echo -e "This script temporarily changes to the parent directory of this script. This is the directory"
    echo -e "that contains the setup for OTOBO running with Docker compose v2."
    echo -e "The standard behavior is to use the setup from .env."
    echo -e "In .env one may set up a specific repositories and specific tags."
    echo -e ""
}

# Parse cli args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        *)
            echo -e "Invalid option: $1"
            echo -e "Use -h or --help for usage instructions."
            exit 1
            ;;
    esac
done

# Get the name of the running script in order to mark the messages printed by the script itself
script_name=${BASH_SOURCE[0]##*/}

# Define colors for the output, usage:
# ${GREEN}✓ Everything is fine.${NC}
# ${YELLOW}⚠ Warning: Something might need attention${NC}
# ${RED}✗ Error: Something went wrong${NC}
# ${CYAN}ℹ Information: Here's something useful${NC}

GREEN='\033[0;32m'       # Green for success
CYAN='\033[0;36m'        # Blue for informations
YELLOW='\033[0;33m'      # Orange/yellow for warnings
RED='\033[0;31m'         # Red for errors
NC='\033[0m'             # No Color (Reset)

# Change into the compose directory while this script is running. The compose directory
# is the sandbox directory that is checked from Git, that is the directory containing the
# hidden file '.env' and the subdirectory 'docker-compose'.
full_script_file=$(realpath -- "${BASH_SOURCE[0]}")
compose_dir=$(dirname $(dirname -- "$full_script_file"))
cd $compose_dir

# Only Docker compose v2 is supported.
# Docker compose v2 is actually a plugin of the the docker command.
DOCKERCOMPOSE="docker compose"

# During the update there should be no interference from the outside.
# Stop and remove the containers, but keep the named volumes intact.
echo -e "[$script_name] ${CYAN}ℹ Stopping the services before starting to update.${NC}"
$DOCKERCOMPOSE down

# Get, or update, the non-local images.
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo -e "[$script_name] ${CYAN}ℹ Pulling Docker images from their repositories.${NC}"
echo -e "[$script_name] ${CYAN} See the file .env for which repositories and tags are used.${NC}"
echo -e "[$script_name] ${CYAN} Error messages for local images can be ignored.${NC}"
$DOCKERCOMPOSE pull

# Running commands with different entrypoints in the otobo image.
docker_run_rsync="docker compose run --rm --entrypoint rsync web"
docker_run_perl="docker compose run --rm --entrypoint perl web"

# For digging into rsync
rsync_verbose=""    # not verbose
#rsync_verbose="-v"  # print the file list
#rsync_verbose="-vv" # print the file list and explain the decision making

# Get, or update, the non-local images.
# There will be error messages for local images,
# but this is acceptable as developers are responsible for the local images.
echo -e "[$script_name] ${CYAN}ℹ Pulling Docker images from their repositories.${NC}"
echo -e "[$script_name] ${CYAN} See the file .env for which repositories and tags are used.${NC}"
echo -e "[$script_name] ${CYAN} Error messages for local images can be ignored.${NC}"
$DOCKERCOMPOSE pull

# There are some directories which require special treatment. These directories should not be moved
# to the update directory. They must be left where they currently are. For that we first
# need to ask the service 'web' for the relevant SysConfig settings.
# The console command Admin::Config::Read is not used here as it depends on the database.
# The directory names are normalized relative to /opt/otobo so that we are on safe grounds.

article_dir=$( $docker_run_perl -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{Ticket::Article::Backend::MIMEBase::ArticleDataDir})' )
if [[ -n $article_dir ]]; then
    relative_article_dir=$(realpath --canonicalize-missing --relative-base /opt/otobo "$article_dir")
    echo -e "[$script_name] ${GREEN}✓ The article data is in $relative_article_dir.${NC}"
else
    echo -e "[$script_name] ${CYAN}ℹ There is no article dir, I think you use not the file system for article storage.${NC}"
    relative_article_dir=""
fi

smime_cert_dir=$( $docker_run_perl -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{SMIME::CertPath})' )
if [[ -n $smime_cert_dir ]]; then
    relative_smime_cert_dir=$(realpath --canonicalize-missing --relative-base /opt/otobo "$smime_cert_dir")
    echo -e "[$script_name] ${GREEN}✓ The S/MIME certificates are in $relative_smime_cert_dir.${NC}"
else
    echo -e "[$script_name] ${CYAN}ℹ There is no directory for the S/MIME certificates.${NC}"
    relative_smime_cert_dir=""
fi

smime_private_dir=$( $docker_run_perl -I . -I Kernel/cpan-lib -MKernel::Config -E 'say Kernel::Config->new->Get(q{SMIME::PrivatePath})' )
if [[ -n $smime_private_dir ]]; then
    relative_smime_private_dir=$(realpath --canonicalize-missing --relative-base /opt/otobo "$smime_private_dir")
    echo -e "[$script_name] ${GREEN}✓ The S/MIME private keys are in $relative_smime_private_dir.${NC}"
else
    echo -e "[$script_name] ${CYAN}ℹ There is no directory for the S/MIME private keys.${NC}"
    relative_smime_cert_dir=""
fi

# PGP keeps the keyring in a hidden directory in /opt/otobo
relative_gpg_dir=.gnupg

# The files in the directory for static HTML should survibe the upgrade
relative_static_dir=var/httpd/htdocs/static

# The directory used by the virtual file system is hard coded in Kernel/System/VirtualFS/FS.pm
relative_virtual_fs_dir=var/virtualfs
echo -e "[$script_name] ${CYAN}ℹ The virtual fs has files in $relative_virtual_fs_dir${NC}"

# The containers are still stopped.
# Copy the OTOBO software from the potentially changed image into the volume mounted at /opt/otobo.
# The required config is taken from the .env file.
TZ=UTC printf -v now "%(%F_%H%M%S)T" -1
dir_otobo_update="/opt/otobo_update/$now"

# Move files /opt/otobo to $dir_otobo_update. The copying is done using the command 'docker' only, not Docker compose.
# This allows to control which volumes are considered. The Docker compose declaration might have
# have additional volumes which should stay untouched by the upgrade.

# Move the directory tree with the exception of some specific directories.
# The excluded directories are given relative to the source dir and have no trailing slash.
# This covers the case where the e.g. article data dir is actually a symlink to another dir.
#
# Note the empty directories are not removed.
#
# The option --archive implies that symlinks should be copied as symlinks. Because of
# the option --remove-source-files the symlinks would be removed in /opt/otobo. This is
# not wanted for this script, thus the option --no-links.
echo -e "[$script_name] ${CYAN}ℹ Moving the old installation to $dir_otobo_update. Note thas some directories are kept in place.${NC}"
$docker_run_rsync \
  --archive \
  --no-links \
  $rsync_verbose \
 --remove-source-files \
 --exclude "$relative_article_dir" \
 --exclude "$relative_smime_cert_dir" \
 --exclude "$relative_smime_private_dir" \
 --exclude "$relative_gpg_dir" \
 --exclude "$relative_static_dir" \
 --exclude "$relative_virtual_fs_dir" \
 /opt/otobo/ "$dir_otobo_update/"

# Restore the hidden files, but some of them will be overwritten by copy_otobo_next
# with files from /opt/otobo_install/otobo_next.
# The --include and --exclude option are a bit daunting. The rule is that each directory
# or file is matched against the option and the first match wins.
echo -e "[$script_name]${CYAN}ℹ Restoring hidden files.${NC}"
$docker_run_rsync \
  --archive \
  $rsync_verbose \
  --exclude "/.copy_otobo_next_finished" \
  --include "/.*" \
  --exclude "*" \
  "$dir_otobo_update/" /opt/otobo/

# The copy_otobo_next task is the same as used in the initial startup.
echo -e "[$script_name]${CYAN}ℹ Copying the new files for /opt/otobo.${NC}"
$DOCKERCOMPOSE run --no-deps --rm web copy_otobo_next

# Rescue some files from the previous installation. These may overwrite
# from /opt/otobo_install/otobo_next.
# Kernel/Config.pm contains installation specific configuration
# locally installed Perl modules may be installed in local
# copy installed stats into var/stats
echo -e "[$script_name]${CYAN}ℹ Restore more runtime files from the backup.${NC}"
$docker_run_rsync \
  --archive \
  $rsync_verbose \
  --include "/Kernel/" --include "/Kernel/Config.pm" \
  --include "/local/" --include "/local/**" \
  --include "/var/" --include "/var/stats/" --include "/var/stats/*.installed" \
  --exclude "*" \
  "$dir_otobo_update/" /opt/otobo/

# start containers again, using the new version
echo -e "[$script_name]${CYAN}ℹ Starting up the services again.${NC}"
$DOCKERCOMPOSE up --detach

echo -e "[$script_name]${CYAN}ℹ Running '$DOCKERCOMPOSE ps' only as a quick sanity check.${NC}"
$DOCKERCOMPOSE ps

# There isn't yet a good check that the database is already running when the webserver starts up.
# So let's sleep for a while and hope the best for later.
echo -e "[$script_name]${CYAN}ℹ Sleeping for 10 seconds while the database is starting up.${NC}"
sleep 10
echo -e "[$script_name]${CYAN}ℹ Finished with sleeping.${NC}"

# complete the update, with running database

# find out the major.minor version of the provious installation, e.g. 11.0 or 11.1
prev_release_file="$dir_otobo_update/RELEASE"
prev_major_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*(\d+)\.\d+/ && print $1' $prev_release_file )
prev_minor_version=$($DOCKERCOMPOSE exec web perl -n -e 'm/^VERSION\s*=\s*\d+\.(\d+)/ && print $1' $prev_release_file )

# run the database update script only for major or minor version upgrades
if (( $prev_major_version < 11 || ($prev_major_version == 11 && $prev_minor_version < 1) )); then
    echo -e "[$script_name]${CYAN}ℹ Running DBUpdate-to-11.1.pl.${NC}"
    $DOCKERCOMPOSE exec web ./scripts/DBUpdate-to-11.1.pl
fi

# reinstall packages in any case
echo -e "[$script_name]${CYAN}ℹ Running do_update_tasks.${NC}"
$DOCKERCOMPOSE exec web /opt/otobo_install/entrypoint.sh do_update_tasks

# inspect the update log
# it is expected that there are messages about missing autoload files. These can be disregarded.
echo -e "[$script_name]${CYAN}ℹ Printing out the log from do_update_tasks.${NC}"
$DOCKERCOMPOSE exec web grep -v 'ERROR: Can.t locate Kernel/Autoload/' /opt/otobo/var/log/update.log

echo -e ""
echo -e ""
echo -e "[$script_name]${GREEN}✓ Update complete. Ready to go!${NC}"
echo -e ""
echo -e "${GREEN}Need help?${NC}"
echo -e "${GREEN} → Get expert support at https://otobo.io/support${NC}"
echo -e "${GREEN} → Join the OTOBO community at https://forum.otobo.io${NC}"
echo -e ""
echo -e ""
