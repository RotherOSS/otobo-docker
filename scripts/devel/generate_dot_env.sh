#!/bin/bash

# This is a helper to be used during development.
# Pass -h for usage info.

# parse command line argument
function args() {
    # -h and --help take no parameters
    # --repository and --tag have mandatory parameters, as indicated by ':'
    options=$(getopt -o h --long help --long template: --long repository: --long tag: --long project: -- "$@")

    # print help message in case of invalid optiond
    [ $? -eq 0 ] || {
        print_help_and_exit "1"
    }

    # set default values
    HELP_FLAG=0
    TEMPLATE="dot_env.m4"
    REPOSITORY="rotheross"
    TAG="latest-10_1"
    PROJECT="otobo"

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

        --project)
            shift; # The arg is next in position args
            PROJECT=$1
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
This script is a helper for easily switching Docker repositories, Docker image versions, and projects.
For using the script one needs a M4 template file from which the file .env can be generated.
The template file is usually called 'dot_env.m4'. In that file,
the macros otovar_REPOSITORY(), otovar_TAG(), and otovar_PROJECT are expanded to the values passed on the command line.

Usage:

    # print this help message
    $0 -h
    $0 --help

    # passing repository and tag is only useful when an m4 template has been set up
    # this is useful mostly during development
    $0 --template dot_env.m4 --repository rotheross --tag latest-10_1
    $0 --template dot_env.m4 --repository rotheross --tag devel-rel-10_1

    # specify the empty string for locally build images
    $0 --template dot_env.m4 --repository "" --tag local-10.1.x

    # specify a project when having to switch between different projects
    $0 --template dot_env.m4 --repository "" --tag local-10.1.x --project otobo-ACME

    # the standard behavior is to create .env from the default settings
    # template:   dot_env.m4
    # repository: rotheross
    # tag:        latest-10_1
    # project:    otobo
    $0
END_HELP

    exit $1
}

# update the .env file
function write_env_file() {

    local template=$1
    local repository=$2
    local tag=$3
    local project=$4

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

    echo "template: '$template'"
    echo "repository: '$repository'"
    echo "tag: '$tag'"
    echo "project: '$project'"

    # update .env
    cp --backup=numbered .env .env.bak
    m4 --prefix-builtins --define "otovar_REPOSITORY=$repository"  --define "otovar_TAG=$tag" --define "otovar_PROJECT=$project" $template > .env
}

# actually parse the command line
args "$0" "$@"

if [[ $HELP_FLAG -eq 1 ]]
then
    print_help_and_exit "0"
fi

write_env_file "$TEMPLATE" "$REPOSITORY" "$TAG" "$PROJECT"
