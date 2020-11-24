#!/usr/bin/env bash

# This is an experimental shortcut for the commands documented in
# https://doc.otobo.org/manual/installation/stable/de/content/updating-docker.html .

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
