#!/bin/sh

# Author: Roberto Leon
# Description: Simple Nefertiti Crypto Trading Bot Buy Script (KuCoin)
# Built-in Default Strategy

### Keys
apikey="x"
apisec="x"
apipass="x"
telekey="x"
telechat="x"
pushapp="x"
pushkey="x"

### Settings
exchange="KUCN"
price="15"
mult="1.03"
repeat="1"
dip="7"

### Markets
markets=$(cat markets.new)

### Build params string
params="
--exchange=$exchange \
--price=$price \
--mult=$mult \
--repeat=$repeat \
--dip=$dip \
--market=$markets \
--api-key=$apikey \
--api-secret=$apisec \
--api-passphrase=$apipass \
--telegram-app-key=$telekey \
--telegram-chat-id=$telechat \
--pushover-app-key=$pushapp \
--pushover-user-key=$pushkey \
--dca"

### Execute Nefertiti
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Executing buy bot with the following settings:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Exchange: $exchange | Price: $price | TP: `echo "($mult-1)*100" | bc`% | Repeat: Every $repeat hour(s)"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Markets:" $markets
cryptotrader buy $params
