_crtdo() {
	local cmdbegin="$1"; shift
	local cmdwrite="$1"; shift

	awk "$@" "
/-+BEGIN/ { $cmdbegin; w=1 }
/-+END/ { end=1 }
{ if (w) { $cmdwrite }; if (end) { w=0; end=0 } }
"
}

# usage: crtsplit <file-prefix>
crtsplit() {
	local prefix="${1:-f}"

	_crtdo 'close(f); i=i+1; f=prefix i' 'print >f' -v i=0 -v "prefix=$prefix"
}

# usage: crtshow [openssl-opts]
crtshow() {
	local opts="$*"
	local cmd

	if [ -z "$opts" ]; then
		opts="-subject -issuer -ext subjectAltName -startdate -enddate -serial -fingerprint"
	fi
	cmd="openssl x509 -noout $opts"
	_crtdo 'close(cmd); print ""' "print | cmd" -v "cmd=$cmd"
}

crtsave() {
	local f="${1:-/dev/stdout}"

	_crtdo '' 'print >f' -v "f=$f"
}

s_client() {
	local addr="$1"
	local opts

	if [ -z "$addr" ]; then
		cat >&2 <<"EOF"
usage: s_client <addr> [openssl-opts]

 - Ctrl-D to end the connection

examples:

  # basic info of certificate chain
  s_client mos.meituan.com 2>/dev/null | crtshow

  # verify and see the result (man 1 verify)
  s_client mos.meituan.com -CAfile `cafiles`

  # save certificate chain into a single file (stdout)
  s_client mos.meituan.com | crtsave

  # split out certificate in the chain into its own file (fN)
  s_client mos.meituan.com | crtsplit
  s_client mos.meituan.com | crtsplit crt
EOF
		return 1
	else
		shift
		opts="$*"
	fi
	if [ "${addr%:*}" = "$addr" ]; then
		addr="$addr:443"
	fi
	opts="-connect $addr -showcerts $opts"
	openssl s_client $opts
}

# list files containing root ca certificates
#
# ca-bundle.crt, normal authority roots
# ca-bundle.trust.crt, higher authority roots (usually with EV capability)
cafiles() {
	local cafiles="
/etc/ssl/certs/ca-certificates.crt
/etc/ssl/certs/ca-bundle.crt
/etc/ssl/certs/ca-bundle.trust.crt
/opt/local/etc/openssl/cert.pem
/usr/local/etc/openssl/cert.pem
"
	local f

	for f in $cafiles; do
		if [ -f "$f" ]; then
			echo "$f"
		fi
	done
}

# list files that may be java keystore files
keystores() {
	local keystorefiles
	local f
	local fjava="$(which java 2>/dev/null)"
	local djava
	local jrecerts
	if [ -x "$fjava" ]; then
		djava="$(readlink -f "$fjava")"
		djava="$(dirname "$djava")"
		djava="$(readlink -f "$djava/../")"
		if [ "${djava%jre}" != "$djava" ]; then
			# some installations use jdk/jre/bin/java
			jrecerts="$djava/lib/security/cacerts"
		else
			# others use jdk/bin/java
			jrecerts="$djava/jre/lib/security/cacerts"
		fi
	fi
	keystorefiles="
/etc/ssl/certs/java/cacerts
/etc/pki/java/cacerts
$jrecerts
"
	for f in $keystorefiles; do
		if [ -f "$f" ]; then
			echo "$f"
		fi
	done
}
