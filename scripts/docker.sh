#!/bin/sh -e

. "$TOPDIR/env.sh"

docker_conf_dir="$o_homedir/.docker"
docker_conf="$o_homedir/.docker/config.json"

config() {
	mkdir -p "$docker_conf_dir"
	chmod 700 "$docker_conf_dir"
	cp "$DATA_DIR/_docker/config.json" "$docker_conf"
	chmod 600 "$docker_conf"
}

collect() {
	if [ -f "$docker_conf" ]; then
		if grep -q '"auths": ' "$docker_conf"; then
			__notice "remember to strip off auth tokens"
		fi
		mkdir -p "$DATA_DIR/_docker"
		cp "$docker_conf" "$DATA_DIR/_docker/config.json"
	fi
}
