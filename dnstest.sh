#!/usr/bin/env bash

command -v bc > /dev/null || { echo "bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "dig was not found. Please install dnsutils."; exit 1; }



NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERS="
10.100.0.100#unbound
10.100.0.10#coredns
"

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="
routing-service.ems-router.svc.cluster.local
user-service.ems-shard%04d.svc.cluster.local
message-service.ems-shard%04d.svc.cluster.local
email-storage-service.ems-shard%04d.svc.cluster.local
label-service.ems-shard%04d.svc.cluster.local
transfer-service.ems-shard%04d.svc.cluster.local
search-service.ems-shard%04d.svc.cluster.local
spam-filter-service.ems-shard%04d.svc.cluster.local
api-service.ems-shard%04d.svc.cluster.local
category-service.ems-shard%04d.svc.cluster.local
routing-service.ems-router.svc.cluster.local
history-service.ems-shard%04d.svc.cluster.local
filter-service.ems-shard%04d.svc.cluster.local
index-service.ems-shard%04d.svc.cluster.local
nginx-api-service.ems-router.svc.cluster.local
lmtp-service.ems-shard%04d.svc.cluster.local
postfix-deliver.ems-router.svc.cluster.local
imap-server.ems-shard%04d.svc.cluster.local
"


totaldomains=0
printf "%-18s" ""
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
    printf "%-8s" "test$totaldomains"
done
printf "%-8s" "Average"
echo ""


for p in $PROVIDERS; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0

    printf "%-18s" "$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
	        #let's have time out be 1s = 1000ms
	        ttime=1000
        elif [ "x$ttime" = "x0" ]; then
	        ttime=1
	    fi

        printf "%-8s" "$ttime ms"
        ftime=$((ftime + ttime))
    done
    avg=`bc -lq <<< "scale=2; $ftime/$totaldomains"`

    echo "  $avg"
done


exit 0;
