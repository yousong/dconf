#!/bin/bash -e

. "$TOPDIR/env.sh"

__port_confd0="/opt/local/etc/macports"
__port_confd1="$DATA_DIR/macports"

__port_ok() {
	[ "$o_os" = "Darwin" ] || return 1
	[ -x "/opt/local/bin/port" ] || return 1
}

config() {
	local f0 f1
	local has_diff

	__port_ok || return 0

	# Glossary
	#
	#   base                macports itself
	#   portfile            recipe for making the port
	#   distfile            (upstream) source code of port
	#   archive             build result of port
	#
	# Config file and options
	#
	#    sources.conf        for fetching "port trees" (Portfiles)
	#    archive_sites.conf  for fetching built binaries
	#    macports.conf       sources_conf
	#                        archive_sites_conf
	#                        rsync_server, rsync_dir: macports base
	#
	# https://trac.macports.org/wiki/Mirrors
	#
	for f0 in "$__port_confd1/"*.conf; do
		f1="$__port_confd0/${f0##*/}"
		if ! diff -uprN "$f1" "$f0"; then
			has_diff=1
			break
		fi
	done
	if test -n "$has_diff"; then
		__notice "macports: conf files differ."
		__notice "macports: See the diff from default conf."
		__notice ""
		__notice "  for f in $__port_confd1/*.conf; do diff -uprN $__port_confd0/\${f##*/}.default \$f; done"
		__notice ""
		__notice "macports: Apply them with the following command."
		__notice ""
		__notice "  sudo cp $__port_confd1/*.conf $__port_confd0"
		__notice ""
	fi
}

collect() {
	local f

	__port_ok || return 0

	for f in "$__port_confd0/"*.conf; do
		cp "$f" "$__port_confd1/${f##*/}"
	done
}
