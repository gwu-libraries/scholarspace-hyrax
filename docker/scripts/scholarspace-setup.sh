#!/bin/bash
# Should be executed when container starts, in order to map the scholarspace user to the user outside the container
# This is only really relevant for development, so a staged Dockerfile might be a better approach (down the road)
echo "Creating scholarspace user and group and setting permissions"
groupadd -r scholarspace --gid=${SCHOLARSPACE_GID:-999} \
     && useradd -r -g scholarspace -m --uid=${SCHOLARSPACE_UID:-999} scholarspace \
     && usermod -aG scholarspace www-data \
     && usermod -aG rvm scholarspace \
     && chown -R scholarspace:scholarspace /opt/scholarspace

# Not sure if this step is necessary  
setuser scholarspace ruby2.7 -S passenger-config build-native-support

echo "Starting Passenger..."
exec /sbin/my_init