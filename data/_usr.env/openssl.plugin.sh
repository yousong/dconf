crtsplit() {
	local crt="$1"
	local prefix="${2:-f}"

	if [ ! -f "$crt" ]; then
		__errmsg "usage: crtsplit <crt> <file-prefix>"
		return 1
	fi
	awk -v prefix="$prefix" '
BEGIN { i=0; f=prefix i }
/BEGIN/ { close(f); i=i+1; f=prefix i }
{ print >f }
' <"$crt"
}

crtshow() {
	local crt="$1"; shift
	local opts="$*"
	local cmd

	if [ ! -f "$crt" ]; then
		__errmsg "usage: crtshow <crt> [openssl-opts]"
		return 1
	fi
	if [ -z "$opts" ]; then
		opts="-subject"
	fi
	cmd="openssl x509 -noout $opts"
	awk -v cmd="$cmd" '
/BEGIN/ {close(cmd)}
{ print | cmd }
' <"$crt"
}

s_client() {
	local addr="$1"
	local cafile="$2"
	local opts

	if [ -z "$addr" ]; then
		__errmsg "s_client <addr> [CAfile]"
	fi
	opts="$opts -connect $addr"
	if [ -f "$cafile" ]; then
		opts="$opts -CAfile $cafile"
	fi
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
