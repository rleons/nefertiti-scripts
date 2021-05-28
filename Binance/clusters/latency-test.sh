#!/bin/bash

URLs=binance-urls.txt

cat $URLs | while read url

do
        average=`ping -c 10 $url | grep rtt | cut -d '/' -f 5`
        if [ $average == "" ]; then
                continue
        fi
        echo "Server: $url - Avg: $average"
done
