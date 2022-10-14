#!/bin/bash
#set -x
pushover () {
        echo "`date` -- $1"  2>&1 | tee -a /tmp/healthcheck.log
        #curl -s -F "token=aziun3sz4315t674nw1f6w71rb12hf" -F "user=gfi96bpd3cor98ghcbojyth616qymb" -F "title=`hostname -s`" -F "message=$1" https://api.pushover.net/1/messages.json
}

services () {
        echo "Checking  $1"
        systemctl is-active $1 --quiet || pushover "$1 service is down"
}


while getopts ':d:anervp' OPTION; do

  case "$OPTION" in
    d)
      check_url="https://$OPTARG"
      ;;
    a)
      services httpd
      ;;
    n)
      services nginx
      ;;
    e)
      services elasticsearch
      ;;
    r)
      services redis
      ;;
    v)
      services varnish
      ;;
    p)
      services php7.4-fpm
      ;;
    ?)
      echo "Usage: $(basename $0) [-a] [-b argument] [-c argument]"
      exit 1
      ;;
  esac

done

shift "$(( OPTIND - 1 ))"
if [ -z "$check_url" ]; then
        echo 'Missing domain name' # >&2
        exit 1
fi

#services httpd
#systemctl is-active nginx --quiet|| pushover "Nginx service is down"
#systemctl is-active httpd --quiet|| pushover "Apache service is down"
#systemctl is-active elasticsearch --quiet|| pushover "Elasticsearch service is down"
#systemctl is-active redis --quiet|| pushover "Redis service is down"
#systemctl is-active varnish --quiet|| pushover "Varnish service is down"
#systemctl is-active php7.4-fpm --quiet || pushover "php-fpm service is down"
#check_url="https://www.lakiotis.gr."

#check for les than 1.5GB memory
#[[ `awk '/MemFree/ { printf "%.0f \n", $2 }' /proc/meminfo` -le 1572864 ]] && pushover "Memory low. less than 1.5GB"
#[[ `awk '/MemFree/ { printf "%.0f \n", $2 }' /proc/meminfo` -le 1202864 ]] && sync; echo 3 > /proc/sys/vm/drop_caches

#check free space for less than 5%
mem=$(df -H | grep -vE '^Filesystem|tmpfs|loop' | awk '{ print $5 " " $1 }')
[ `echo $mem | awk '{ print $1}' | cut -d'%' -f1` -ge 95 ] && pushover "No free space for partition: `echo $mem | awk '{ print $2 }'`"

#check cpu load
cpu=$((`cat /proc/loadavg | awk '{print $3}'|cut -f 1 -d "."` / `grep processor /proc/cpuinfo | wc -l`))
[ $cpu -gt 2 ] && pushover "cpu load too high"

#check website
status=$(curl -s -o /dev/null -w "%{http_code}" $check_url)
[[ $status -ne 200 ]] && pushover " Status Code $status"

