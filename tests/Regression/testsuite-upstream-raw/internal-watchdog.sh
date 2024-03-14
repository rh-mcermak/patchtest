#/bin/bash

test -x
__TRESHOLD=$(( 240 * 60 ))
__SLEEP=$(( 15 * 60 ))
__LOG="$1"
test -z $__LOG && exit 1
test +x

echo "`date` internal watchdog $$ starting." >> $__LOG
while true; do
    sleep $__SLEEP
    __DELTA=$(( `date +'%s'` - `stat -c '%Y' $__LOG` ))
    if [[ $__DELTA -gt $__TRESHOLD ]]; then
        echo "`date` internal watchdog $$ rebooting due to inactivity." >> $__LOG
	sync
        sleep 1m
        reboot -f
        sleep 5m
    fi
done
