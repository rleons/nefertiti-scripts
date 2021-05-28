#!/bin/sh

# Author: Roberto Leon
# Description: Simple Nefertiti Crypto Trading Bot Sell Script (KuCoin)
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
quote="USDT"
mult="1.03"

### Build params string
params="
--exchange=$exchange \
--quote=$quote \
--mult=$mult \
--api-key=$apikey \
--api-secret=$apisec \
--api-passphrase=$apipass \
--telegram-app-key=$telekey \
--telegram-chat-id=$telechat \
--pushover-app-key=$pushapp \
--pushover-user-key=$pushkey"

### Execute Nefertiti
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Executing sell bot with the following settings:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Exchange: $exchange | Quote: $quote | TP: `echo "($mult-1)*100" | bc`%"
cryptotrader sell $params
