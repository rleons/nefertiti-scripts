#!/bin/sh

# Author: Roberto Leon
# Description: Simple Nefertiti Crypto Trading Bot Sell Script (Binance)
# Built-in Default Strategy

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
quote="USDT"
hold="BNBUSDT"
mult="1.03"

### Build params string
params="
--exchange=$exchange \
--cluster=$cluster \
--quote=$quote \
--hold=$hold \
--mult=$mult \
--api-key=$apikey \
--api-secret=$apisec \
--telegram-app-key=$telekey \
--telegram-chat-id=$telechat \
--pushover-app-key=$pushapp \
--pushover-user-key=$pushkey"

### Execute Nefertiti
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Executing sell bot with the following settings:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Exchange: $exchange | Quote: $quote | TP: `echo "($mult-1)*100" | bc`%"
cryptotrader sell $params
