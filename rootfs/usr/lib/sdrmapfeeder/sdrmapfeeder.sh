#!/command/with-contenv bash
# shellcheck shell=bash disable=SC1091,SC2076
export LANG=C.UTF-8

source /scripts/common

ADSBPATH="/run/readsb/aircraft.json"

# version='4.0'
# sysinfolastrun=0
# radiosondelastrun=0

# wait for readsb to be ready
while ! [[ -f "$ADSBPATH" ]]; do
    sleep 1
done


if [[ -z $SMUSERNAME ]] || [[ -z $SMPASSWORD ]] || [[ $SMUSERNAME == "yourusername" ]] || [[ $SMPASSWORD == "yourpassword" ]]; then
	echo "Please edit your credentials."
	sleep infinity
fi

while sleep 1; do
	# if [ "$sysinfo" = "true" ] && [ $(($(date +"%s") - $sysinfolastrun)) -ge "$sysinfointerval" ];
	# 	then
	# 	sysinfolastrun=$(date +"%s")
	# echo "{\
	# 	\"cpu\":{\
	# 		\"model\":\"$(cat /proc/cpuinfo |grep 'model name'|tail -n 1|cut -d ':' -f 2)\",\
	# 		\"cores\":\"$(cat /proc/cpuinfo |grep -c -e '^processor')\",\
	# 		\"load\":\"$(cat /proc/loadavg |cut -d ' ' -f 1)\",\
	# 		\"temp\":\"$(($(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null |sort -n|tail -n 1)/1000))\",\
	# 		\"throttled\":\"$(vcgencmd get_throttled 2>/dev/null |cut -d '=' -f 2 )\"\
	# 	},\
	# 	\"memory\":{\
	# 		\"total\":\"$(cat /proc/meminfo |grep 'MemTotal:'|cut -d ':' -f 2|awk '{$1=$1};1')\",\
	# 		\"free\":\"$(cat /proc/meminfo |grep 'MemFree:'|cut -d ':' -f 2|awk '{$1=$1};1')\",\
	# 		\"available\":\"$(cat /proc/meminfo |grep 'MemAvailable:'|cut -d ':' -f 2|awk '{$1=$1};1')\"\
	# 	},\
	# 	\"uptime\":\"$(cat /proc/uptime |cut -d ' ' -f 1)\",\
	# 	\"os\":{\
	# 		\"kernel\":\"$(uname -r)\"\
	# 	},\
	# 	\"packages\":{\
	# 		\"c2isrepo\":\"$(cat /etc/apt/sources.list.d/*|grep -c 'https://repo.chaos-consulting.de')\",\
	# 		\"sdrmaprepo\":\"$(cat /etc/apt/sources.list.d/*|grep -c 'https://repo.sdrmap.org')\",\
	# 		\"mlat-client-c2is\":\"$(dpkg -s mlat-client-c2is 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
	# 		\"mlat-client-sdrmap\":\"$(dpkg -s mlat-client-sdrmap 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
	# 		\"stunnel4\":\"$(dpkg -s stunnel4 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
	# 		\"dump1090-mutability\":\"$(dpkg -s dump1090-mutability 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
	# 		\"dump1090-fa\":\"$(dpkg -s dump1090-fa 2>&1|grep 'Version:'|cut -d ' ' -f 2)\",\
	# 		\"ais-catcher\":\"$(dpkg -s ais-catcher 2>&1 |grep 'Version:'|cut -d ' ' -f 2)\"\
	# 	},\
	# 	\"feeder\":{\
	# 		\"version\":\"$version\",\
	# 		\"interval\":\"$sysinfointerval\"
	# 	}\
	# }"| gzip -c |curl -s -u $username:$password -X POST -H "Content-type: application/json" -H "Content-encoding: gzip" --data-binary @- https://sys.feed.sdrmap.org/index.php
	# fi;


	if gzip -c $ADSBPATH | curl --fail-with-body -sS -u "$SMUSERNAME":"$SMPASSWORD" -X POST -H "Content-type: application/json" -H "Content-encoding: gzip" --data-binary @- https://adsb.feed.sdrmap.org/index.php
	then
		touch /run/feed_ok
	else
		rm -f /run/feed_ok
        # sleep a bit if this fails, no need to hammer the server if this doesn't work
        sleep 4
	fi

	# if [ "$radiosonde" = "true" ] && [ $(($(date +"%s") - $radiosondelastrun)) -ge "$radiosondeinterval" ];
	# 	then
	# 	radiosondelastrun=$(date +"%s")
	# 	if [ ! -d "$radiosondepath" ]; then
	# 		echo "The log directory '$radiosondepath' doesn't exist."
	# 		exit 1
	# 	fi;
	# 	for i in $(find $radiosondepath -mmin -0.1 -name "*sonde.log");
	# 		do
	# 		tail -n 1 $i | gzip | curl -s -u $username:$password -X POST -H "Content-type: application/json" -H "Content-encoding: gzip" --data-binary @- https://radiosonde.feed.sdrmap.org/index.php
	# 	done;
	# fi;
done;
