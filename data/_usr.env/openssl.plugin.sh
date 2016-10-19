# usage: crtsplit <file-prefix>
crtsplit() {
	local prefix="${1:-f}"

	awk -v prefix="$prefix" '
BEGIN { i=0; f=prefix i }
/-+BEGIN/ { close(f); i=i+1; f=prefix i }
{ print >f }
'
}

# usage: crtshow [openssl-opts]
crtshow() {
	local opts="$*"
	local cmd

	if [ -z "$opts" ]; then
		opts="-subject -issuer -startdate -enddate"
	fi
	cmd="openssl x509 -noout $opts"
	awk -v cmd="$cmd" '
/-+BEGIN/ { close(cmd); print "" }
{ print | cmd }
'
}

crtsave() {
	local f="${1:-/dev/stdout}"

	awk -v f="$f" '
/-+BEGIN/ { w=1 }
/-+END/ { print >f; w=0 }
{ if (w) { print >f} }
'
}

s_client() {
	local addr="$1"; shift
	local opts="$*"

	if [ -z "$addr" ]; then
		__errmsg "usage: s_client <addr> [openssl-opts]"
		__errmsg "                                     "
		__errmsg "examples:                            "
		__errmsg "  s_client mos.meituan.com:443 -showcerts 2>/dev/null | crtsave | crtshow"
		__errmsg "  s_client mos.meituan.com:443 -CAfile \`cafiles\`"
		return 1
	fi
	opts="-connect $addr $opts"
	openssl s_client $opts
}

# list files containing root ca certificates
cafiles() {
	local cafiles="
/etc/ssl/certs/ca-certificates.crt
/etc/ssl/certs/ca-bundle.crt
/etc/ssl/certs/ca-bundle.trust.crt
/opt/local/etc/openssl/cert.pem
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
	local fjava="$(which java)"
	local djava
	local jrecerts
	if [ -x "$fjava" ]; then
		djava="$(readlink -f "$fjava")"
		djava="$(dirname "$djava")"
		djava="$(readlink -f "$djava/../")"
		jrecerts="$djava/jre/lib/security/cacerts"
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
