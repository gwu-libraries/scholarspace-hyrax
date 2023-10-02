#!/bin/bash

set -e
# Function from https://github.com/phusion/passenger-docker/blob/master/image/buildconfig
# Used to make sure Passenger is running the correct version of Ruby
# Because the Passenger image doesn't support Ruby 2.7.3, we're monkeypatching the image with it
function create_rvm_wrapper_script()
{
	local name="$1"
	local rvm_id="$2"
	local command="$3"
	echo "+ Creating /usr/bin/$name"
	echo '#!/bin/sh' >> "/usr/bin/$name"
	echo exec "/usr/local/rvm/wrappers/$rvm_id/$command" '"$@"' >> "/usr/bin/$name"
	chmod +x "/usr/bin/$name"
}