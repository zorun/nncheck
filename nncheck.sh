#!/bin/bash
# 
# Network Neutrality Checker
# (Copyleft) 2012
# 
# This tool probes various outgoing ports to determine if some are blocked.
# 
# Visit http://laquadrature.net for informations about Net Neutrality.

# Don't mess with the comments, they are used when running the script
PORTS=(80 443 8080 # web
    5060 5061 # sip
    25 # smtp
    110 995 # pop3(s)
    143 220 993 # imap(s)
    22 # ssh
    53 # domain
    6666 6667 6697 # irc
    21 20 # ftp
    5222 5223 5269 5280 # Jabber/XMPP
    3724 # WoW
    554 # rtsp
    43 # whois
    23 992 # telnet(s)
)

# Timeout, in seconds, after which the port is considered as 'timeout'
TIMEOUT=2

# Use colors by default?
USE_COLOR="yes"

# Force wget instead of curl? (bad idea)
FORCE_WGET="no"


echo "This is NN check, the Network Neutrality checker."
echo "Visit http://laquadrature.net if you don't know what that means."
echo


show_help() {
    echo "nncheck tries to establish outgoing TCP connections on common ports,"
    echo "and checks whether they are blocked (for instance, your mobile ISP"
    echo "might block the SIP port)."
    echo
    echo "usage: $0 [options]"
    echo "where valid options are:"
    echo "   -h|--help                         This help"
    echo "   -t <timeout>|--timeout <timeout>  Set the timeout in seconds (default: $TIMEOUT)"
    echo "   --no-color                        Disable nice colored output"
    echo "   --force-wget                      Force using wget instead of curl"
    echo "                                     (not recommended)"
    exit 0
}

weird_option() {
    echo -e "Error: option '$1' unrecognized"
    echo "Try $0 -h"
    exit 1
}


# Parse options
while [[ $1 ]]
do
    case "$1" in
        --help|-h) show_help;;
        --no-color) USE_COLOR="no";;
        --force-wget) FORCE_WGET="yes";;
        --timeout|-t) TIMEOUT="$2"; shift;;
        *) weird_option "$1"
    esac
    shift
done


# curl is used by default
CURL_CMD="curl --connect-timeout $TIMEOUT"

# We fall back on wget if needed (because it's less powerful than curl)
WGET_CMD="wget --tries 1 --connect-timeout $TIMEOUT -O -"


# Non-blocked ports
PASS=()
# Blocked ports
FAIL=()


# Thanks to La Quadrature du Net for this awesome simple responder <3
responder() {
    echo "http://responder.lqdn.fr:${1}/simple.php"
}


# Color management

red() {
    [ "$USE_COLOR" = "yes" ] && echo "\e[1;31m$@\e[0m" || echo "$@"
}

green() {
    [ "$USE_COLOR" = "yes" ] && echo "\e[1;32m$@\e[0m" || echo "$@"
}

bold() {
    [ "$USE_COLOR" = "yes" ] && echo "\e[1m$@\e[0m" || echo "$@"
}

color_score() {
    [[ "$1" -eq 100 ]] && echo "$(green ${1}%)" || echo "$(red ${1}%)"
}


# Pretty-printing

print_status() {
    echo -e "[**] Outbound port $(bold "$(printf '%-5d' $1)") is $2"
}

port_info() {
    echo "→ $(grep -w $1 "$0" | cut -d '#' -f 2)"
}

pass() {
    print_status $1 "$(green "open   ")  $(port_info $1)"
    PASS+=($1)
}

closed() {
    print_status $1 "$(red "closed ")  $(port_info $1)"
    FAIL+=($1)
}

timeout() {
    print_status $1 "$(red timeout)  $(port_info $1)"
    FAIL+=($1)
}


echo "I'll now try to establish outgoing connections on various TCP ports!"
echo


# we use curl by default, or wget if curl is not found
if command -v curl >/dev/null 2>&1 && [[ $FORCE_WGET != "yes" ]]
then
    BACKEND=curl
    GET_CMD="$CURL_CMD"
elif command -v wget >/dev/null 2>&1
then
    BACKEND=wget
    GET_CMD="$WGET_CMD"
    echo -e "$(red Warning): curl not found, falling back on wget..." 1>&2
    echo "Consider switching to curl if you want to distinguish between" 1>&2
    echo "'connection refused' and 'timeout'" 1>&2
    echo 1>&2
else
    echo "$(red Error): neither curl nor wget is available." 1>&2
    echo "Please install either one (curl is preferred)" 1>&2
    exit 1
fi


echo -e "[*] Testing $(bold ${#PORTS[*]} ports) for outgoing connection..."

for p in ${PORTS[*]}
do
    $GET_CMD "$(responder $p)" >/dev/null 2>&1
    case $? in
        0) pass $p # Okay
            ;;
        4) closed $p # wget error, whatever that means…
            ;;
        7) closed $p # curl error for connection refused
            ;;
        28) timeout $p # curl error timeout
            ;;
        *) closed $p
    esac
done

let "score = 100 * ${#PASS[*]} / ${#PORTS[*]}"

echo -e "[*] $(bold Summary): $(bold ${#PASS[*]}) $(green open) / $(bold ${#FAIL[*]}) $(red failed)"
echo -e "[*] $(bold NN score): $(color_score ${score})"

echo
echo "Share your score on #laquadrature@irc.freenode.net"
