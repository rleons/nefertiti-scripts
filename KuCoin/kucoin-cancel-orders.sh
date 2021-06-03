#!/bin/bash

# Aurhor: Roberto Leon
# Description: Nefertiti Crypto Trading Bot - Cancell all unfilled orders
# Example: ./*-cancel-orders.sh --side=buy

### Keys
apikey="x"
apisec="x"
apipass="x"
telekey="x"
telechat="x"
pushapp="x"
pushkey="x"

### Flag args
for i in "$@"
do
case $i in
    --side=*)
    side="${i#*=}"
    shift;;
esac
done
if [ -z ${side+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --side"
    exit 1
fi

### Settings
exchange="KUCN"
markets=$(cat markets.now)

### Build params string
params="
--exchange=$exchange \
--side=$side
--api-key=$apikey \
--api-secret=$apisec \
--api-passphrase=$apipass \
--telegram-app-key=$telekey \
--telegram-chat-id=$telechat \
--pushover-app-key=$pushapp \
--pushover-user-key=$pushkey"

### Execute Nefertiti
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Cancelling $side orders..."
for market in ${markets//,/ }; do
        cryptotrader cancel --market=$market $params
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] All $market buy orders have been cancelled."
done
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Done."
