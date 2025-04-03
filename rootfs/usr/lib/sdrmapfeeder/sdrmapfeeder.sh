#!/command/with-contenv bash
# shellcheck shell=bash disable=SC1091,SC2076,SC2268,SC2155,SC2086
export LANG=C.UTF-8

source /scripts/common

ADSBPATH="/run/readsb/aircraft.json"

version='4.0-sdre-docker'
sysinfolastrun=0
# radiosondelastrun=0

# wait for readsb to be ready
while ! [[ -f "$ADSBPATH" ]]; do
	sleep 1
done


if [[ -z $SMUSERNAME ]] || [[ -z $SMPASSWORD ]] || [[ $SMUSERNAME == "yourusername" ]] || [[ $SMPASSWORD == "yourpassword" ]]; then
	echo "Please edit your credentials."
	sleep infinity
fi

REMOTE_URL="https://adsb.feed.sdrmap.org/index.php"
REMOTE_HOST="$(awk -F'/' '{print $3}' <<< "$REMOTE_URL")"

REMOTE_SYS_URL="https://sys.feed.sdrmap.org/index.php"

#####################
#  DNS cache setup  #
#####################

# Set this to '0' if you don't want this script to ever try to self-cache DNS.
# Default is on, but script will automatically not cache if resolver is localhost, or if curl version is too old.
DNS_CACHE=1
# Cache time, default 10min
DNS_TTL=600

declare -A DNS_LOOKUP
declare -A DNS_EXPIRE

# This routine assumes you do no santiy-checking.
#
# Checks for the host in $DNS_LOOKUP{}, and if the corresponding $DNS_EXPIRE{} is less than NOW, return success.
# Otherwise, try looking it up.  Save value if lookup succeeded.
#
# Returns:
#       On Success: returns 0, and host will be in DNS_LOOKUP assoc array.
#       On Fail: Various return codes:
#               - 10 = No Hostname Provided
#               - 20 = Hostname Format Invalid
#               - 30 = Lookup Failed even after $DNS_MAX_LOOPS tries
DNS_WAIT=5

dns_lookup () {
	local HOST=$1

	local NOW=$( date +%s )

	# You need to pass in a hostname :)
	if [[ "x$HOST" = "x" ]]; then
		echo "ERROR: dns_lookup called without a hostname" >&2
		return 10
	fi

	# (is it even a syntactically-valid hostname?)
	if ! [[ $HOST =~ ^[a-zA-Z0-9\.-]+$ ]]; then
		echo "ERROR: Invalid hostname passed into dns_lookup [$HOST]" >&2
		return 20
	fi

	# If the host is cached, and the TTL hasn't expired, return the cached data.
	if [[ ${DNS_LOOKUP[$HOST]} ]]; then
		if [[ ${DNS_EXPIRE[$HOST]} -ge $NOW ]]; then
			return 0
		fi
	fi

	# Ok, let's look this hostname up!  Use the first IP returned.
	#  - XXX : WARNING: This assumed the output format of 'host -v' doesn't change drastically! XXX -

	HOST_IP=$( host -v -W $DNS_WAIT -t a "$HOST" | perl -ne 'if (/^Trying "(.*)"/){$h=$1; next;} if (/\.\s+(\d+)\s+IN\s+A\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {$i=$2; last}; END {printf("%s", $i);}' )
	RV=$?
	# If this is empty, something failed.  Sleep some and try again...
	if [[ $RV -ne 0 ]] || [[ "x$HOST_IP" == "x" ]]; then
		if ping -c1 "$HOST" &>/dev/null && ! host -v -W $DNS_WAIT -t a "$HOST" &>/dev/null; then
			echo "host not working but ping is, disabling DNS caching!"
			DNS_CACHE=0
			return 1
		fi
		echo "ERROR: dns_lookup function unable to resolve $HOST" >&2
		return 30
	fi

	# Resolved ok!
	NOW=$( date +%s )
	DNS_LOOKUP["$HOST"]=$HOST_IP
	DNS_EXPIRE["$HOST"]=$(( NOW + DNS_TTL ))
	return 0
}

if ! (( ADSB_INTERVAL >= 1 )); then
    ADSB_INTERVAL=1
fi
if ! (( SYSINFO_INTERVAL >= 30 )); then
    SYSINFO_INTERVAL=30
fi

while sleep "$ADSB_INTERVAL"; do
	CURL_EXTRA=""
	# If DNS_CACHE is set, use the builtin cache (and correspondingly the additional curl arg
	if [[ $DNS_CACHE -ne 0 ]]; then
		dns_lookup $REMOTE_HOST
		RV=$?
		if [[ $RV -ne 0 ]]; then
			# Some sort of error...  We'll fall back to normal curl usage, but sleep a little.
			echo "DNS Error for ${REMOTE_HOST}, fallback ..."
		else
			REMOTE_IP=${DNS_LOOKUP[$REMOTE_HOST]}
			CURL_EXTRA="--resolve ${REMOTE_HOST}:443:$REMOTE_IP"
		fi
	fi

	if chk_enabled "$SEND_SYSINFO" && (( $(date +"%s") - sysinfolastrun >= SYSINFO_INTERVAL )); then
		sysinfolastrun=$(date +"%s")
		echo "{\
			\"cpu\":{\
				\"model\":\"$(grep 'model name' /proc/cpuinfo |tail -n 1|cut -d ':' -f 2)\",\
				\"cores\":\"$(grep -c -e '^processor' /proc/cpuinfo)\",\
				\"load\":\"$(cut -d ' ' -f 1 < /proc/loadavg)\",\
				\"temp\":\"$(( $(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null |sort -n|tail -n 1) / 1000 ))\",\
				\"throttled\":\"$(vcgencmd get_throttled 2>/dev/null |cut -d '=' -f 2 )\"\
			},\
			\"memory\":{\
				\"total\":\"$(grep 'MemTotal:' /proc/meminfo | cut -d ':' -f 2 | awk '{$1=$1};1')\",\
				\"free\":\"$(grep 'MemFree:' /proc/meminfo | cut -d ':' -f 2 | awk '{$1=$1};1')\",\
				\"available\":\"$(grep 'MemAvailable:' /proc/meminfo| cut -d ':' -f 2 | awk '{$1=$1};1')\"\
			},\
			\"uptime\":\"$(cut -d ' ' -f 1 < /proc/uptime)\",\
			\"os\":{\
				\"kernel\":\"$(uname -r)\"\
			},\
			\"packages\":{\
				\"c2isrepo\":\"$(cat /etc/apt/sources.list.d/* | grep -c 'https://repo.chaos-consulting.de')\",\
				\"sdrmaprepo\":\"$(cat /etc/apt/sources.list.d/* | grep -c 'https://repo.sdrmap.org')\",\
				\"mlat-client-c2is\":\"$(grep -o -m 1 'MlatClient==[0-9.]\+' "$(which mlat-client)"| sed 's/MlatClient==//')\",\
				\"mlat-client-sdrmap\":\"$(grep -o -m 1 'MlatClient==[0-9.]\+' "$(which mlat-client)"| sed 's/MlatClient==//')\",\
				\"stunnel4\":\"$(stunnel 2>&1 | grep -o -m 1 'stunnel [0-9.]\+'| sed 's/stunnel //')\",\
				\"dump1090-mutability\":\"$(dpkg -s dump1090-mutability 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
				\"dump1090-fa\":\"$(readsb --version 2>&1 | sed 's/readsb version: \([0-9.]\+\).*/wreadsb-\1/')\",\
				\"ais-catcher\":\"$(dpkg -s ais-catcher 2>&1 |grep 'Version:'|cut -d ' ' -f 2)\"\
			},\
			\"feeder\":{\
				\"version\":\"$version\",\
				\"interval\":\"$SYSINFO_INTERVAL\" \
			}\
		}" | gzip -c | curl --fail-with-body -sSL \
										-u "$SMUSERNAME":"$SMPASSWORD" \
										-X POST \
										--max-time 10 \
										-H "Content-type: application/json" \
										-H "Content-encoding: gzip" \
										--data-binary @- \
										"$REMOTE_SYS_URL"
	fi
	#

	if gzip -c $ADSBPATH | curl --fail-with-body -sS -u "$SMUSERNAME":"$SMPASSWORD" -X POST \
		$CURL_EXTRA --max-time 10 -H "Content-type: application/json" -H "Content-encoding: gzip" \
		--data-binary @- "$REMOTE_URL"
	then
		touch /run/feed_ok
	else
		rm -f /run/feed_ok
	fi

	# if [[ "$radiosonde" = "true" ]] && [[ $(($(date +"%s") - $radiosondelastrun)) -ge "$radiosondeinterval" ]];
	# 	then
	# 	radiosondelastrun=$(date +"%s")
	# 	if [[ ! -d "$radiosondepath" ]]; then
	# 		echo "The log directory '$radiosondepath' doesn't exist."
	# 		exit 1
	# 	fi;
	# 	for i in $(find $radiosondepath -mmin -0.1 -name "*sonde.log");
	# 		do
	# 		tail -n 1 $i | gzip | curl -s -u $username:$password -X POST -H "Content-type: application/json" -H "Content-encoding: gzip" --data-binary @- https://radiosonde.feed.sdrmap.org/index.php
	# 	done;
	# fi;
done;
