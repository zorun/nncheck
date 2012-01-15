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

# Timeout, in seconds, after which the port is considered as 'closed'
TIMEOUT=2

# Non-blocked ports
PASS=()
# Blocked ports
FAIL=()

# Thanks to La Quadrature du Net for this awesome simple responder <3
responder() {
    echo "http://responder.lqdn.fr:${1}/simple.php"
}

red() {
    echo "\e[1;31m$@\e[0m"
}

green() {
    echo "\e[1;32m$@\e[0m"
}

bold() {
    echo "\e[1m$@\e[0m"
}

color_score() {
    [[ "$1" -eq 100 ]] && echo "$(green ${1}%)" || echo "$(red ${1}%)"
}

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


echo "This is NN check, the Network Neutrality checker."
echo "Visit http://laquadrature.net if you don't know what that means."
echo "I'll now try to establish outgoing connections on various TCP ports!"
echo


# we use curl by default, or wget if curl is not found
if command -v curl >/dev/null 2>&1
then
    BACKEND=curl
    GET_CMD="curl --connect-timeout $TIMEOUT"
elif command -v wget >/dev/null 2>&1
then
    BACKEND=wget
    GET_CMD="wget --tries 1 --connect-timeout $TIMEOUT -O -"
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
