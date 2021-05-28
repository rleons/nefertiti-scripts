#!/bin/sh

# Author: Roberto Leon
# Description: Simple Nefertiti Crypto Trading Bot Buy Script (KuCoin)
# Crypto Base Scanner (CBS) Signals

### Keys
sigprov="cryptobasescanner.com"
sigkey="x"
apikey="x"
apisec="x"
apipass="x"
telekey="x"
telechat="x"
pushapp="x"
pushkey="x"

### Settings
exchange="KUCN"
quote="USDT"
price="15"
mult="1.03"
repeat="0.0084" # [30 seconds] = 0.5 * (100/60/100)
ignore="leveraged"

### Build params string
params="
--exchange=$exchange \
--quote=$quote \
--price=$price \
--mult=$mult \
--repeat=$repeat \
--ignore=$ignore \
--signals=$sigprov \
--crypto-base-scanner-key=$sigkey \
--api-key=$apikey \
--api-secret=$apisec \
--telegram-app-key=$telekey \
--telegram-chat-id=$telechat \
--pushover-app-key=$pushapp \
--pushover-user-key=$pushkey \
--dca"

### Execute Nefertiti
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Executing buy bot for $sigprov signals with the following settings:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Exchange: $exchange | Price: $price | TP: `echo "($mult-1)*100" | bc`% | Repeat: Every $repeat hour(s)"
cryptotrader buy $params
