#!/bin/bash
# 
# Network Neutrality Checker
# (Copyleft) 2012
# 
# This tool probes various outgoing ports to determine if some are blocked.
# 
# Visit http://laquadrature.net for informations about Net Neutrality.

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

pass() {
    print_status $1 "$(green "open  ")  → $(grep -w $p "$0" | cut -d '#' -f 2)"
    PASS+=($1)
}

fail() {
    print_status $1 "$(red closed)  → $(grep -w $p "$0" | cut -d '#' -f 2)"
    FAIL+=($1)
}


echo "This is NN check, the Network Neutrality checker."
echo "Visit http://laquadrature.net if you don't know what that means."
echo "I'll now try to establish outgoing connections on various TCP ports!"
echo

echo -e "[*] Testing $(bold ${#PORTS[*]} ports) for outgoing connection..."

for p in ${PORTS[*]}
do
    curl --connect-timeout 2 "$(responder $p)" >/dev/null 2>&1 \
        && pass $p || fail $p 
done

let "score = 100 * ${#PASS[*]} / ${#PORTS[*]}"

echo -e "[*] $(bold Summary): $(bold ${#PASS[*]}) $(green open) / $(bold ${#FAIL[*]}) $(red closed)"
echo -e "[*] $(bold NN score): $(color_score ${score})"

echo
echo "Share your score on #laquadrature@irc.freenode.net"
