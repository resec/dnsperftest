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
user-service.ems-shard0000.svc.cluster.local
message-service.ems-shard0000.svc.cluster.local
email-storage-service.ems-shard0000.svc.cluster.local
label-service.ems-shard0000.svc.cluster.local
transfer-service.ems-shard0000.svc.cluster.local
search-service.ems-shard0000.svc.cluster.local
spam-filter-service.ems-shard0000.svc.cluster.local
api-service.ems-shard0000.svc.cluster.local
category-service.ems-shard0000.svc.cluster.local
routing-service.ems-router.svc.cluster.local
history-service.ems-shard0000.svc.cluster.local
filter-service.ems-shard0000.svc.cluster.local
index-service.ems-shard0000.svc.cluster.local
nginx-api-service.ems-router.svc.cluster.local
lmtp-service.ems-shard0000.svc.cluster.local
postfix-deliver.ems-router.svc.cluster.local
imap-server.ems-shard0000.svc.cluster.local
"


totaldomains=0
printf "%-18s" ""
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
#    printf "%-8s" "test$totaldomains"
done
printf "%-8s" "Count"
printf "%-8s" "Max"
printf "%-8s" "Min"
printf "%-8s" "Average"
printf "%-8s" "Total"
echo ""


for p in $PROVIDERS; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0
    max=0
    min=99999

    printf "%-18s" "$pname"
    for (( COUNTER=0; COUNTER<=1000; COUNTER+=1 )); do
	    for d in $DOMAINS2TEST; do
		ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
		if [ -z "$ttime" ]; then
			#let's have time out be 1s = 1000ms
			ttime=1000
		elif [ "x$ttime" = "x0" ]; then
			ttime=1
		fi

		if (( ttime > max )); then
			max=$ttime
		fi

		if (( ttime < min )); then
			min=$ttime
		fi

		#printf "%-8s" "$ttime ms"
		ftime=$((ftime + ttime))
	    done
    done
    totalcount=$((COUNTER * totaldomains))
    avg=`bc -lq <<< "scale=2; $ftime/$totalcount"`

    printf "%-8s" "$totalcount"
    printf "%-8s" "$max.00"
    printf "%-8s" "$min.00"
    printf "%-8s" "$avg"
    printf "%-8s" "$ftime"
    echo " ms"
done


exit 0;
