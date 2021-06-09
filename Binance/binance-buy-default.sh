#!/bin/sh

# Author: Roberto Leon
# Description: Simple Nefertiti Crypto Trading Bot Buy Script (Binance)
# Built-in Default Strategy w/ Dollar Cost Averaging

### Keys
apikey="x"
apisec="x"
telekey="x"
telechat="x"
pushapp="x"
pushkey="x"

### Settings
exchange="BINA"
cluster="1"
price="15"
mult="1.03"
repeat="1"
dip="7"

### Markets
markets=$(cat markets.new)

### Build params string
params="
--exchange=$exchange \
--cluster=$cluster \
--price=$price \
--mult=$mult \
--repeat=$repeat \
--dip=$dip \
--market=$markets \
--api-key=$apikey \
--api-secret=$apisec \
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
