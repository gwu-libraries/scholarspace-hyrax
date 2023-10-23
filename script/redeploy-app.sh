#!/bin/bash
# For use with a Dockerized implementation
# Stops containers, removes app image, deletes app volume, restarts app, recompiles assets
docker compose down
echo "Deleting app image"
docker image rm scholarspace-app
echo "Deleting app volume"
docker volume rm scholarspace-hyrax_app-hyrax
echo "Restarting Docker containers"
docker compose up -d
# If we don't sleep, Docker can't find the user
sleep 2
echo "Precompiling assets"
docker exec -it --user scholarspace $(docker ps --filter name=app -q) bash -lc "docker/scripts/app-init.sh --precompile-assets"