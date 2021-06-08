#!/bin/bash
#
# Author: Roberto Leon
# Description: Script will help you pick markets by filtering by the given quote,
# then it will filter by looking at the last 24h percent change (optionally adjusted),
# and finally order the top X results by BTC trading volume.
# * Original idea inspired by MarcelM shared methods on Nefertiti trading bot community. 
#
# Dependencies:
# jq - https://stedolan.github.io/jq
# bc - https://www.gnu.org/software/bc/manual/html_mono/bc.html
#
# Examples:
# ./markets-picker.sh --exchange=BINA --quote=BTC --top=15
# ./markets-picker.sh --exchange=KUCN --quote=USDT --top=20 --minchange=0.10 --maxchange=0.20
#
# Notes:
# (1) --minchange=0.05 is a default value and refers to 5%.
# (2) --maxchange=0.15 is a default value and refers to 15%.
# (3) Both --minchange and --maxchange values are applied to both the upside and downside % change.


### Default Settings
minChange="0.05"
maxChange="0.15"
scriptDir="${0%/*}"
symbols=""

### CSV Files
fileDate=$(date +"%Y%m%d_%H%M%S")
newFile="markets.new"
oldFile=$fileDate"_markets.old"

### Exchange APIs
kucoinAPI="https://api.kucoin.com/api/v1/market/allTickers"
binanceAPI="https://api.binance.com/api/v3/ticker/24hr"

### Flag args
for i in "$@"
do
case $i in
    --exchange=*)
    exchange="${i#*=}"
    shift;;
    --quote=*)
    quoteCurr="${i#*=}"
    shift;;
    --top=*)
    top="${i#*=}"
    shift;;
    --minchange=*)
    minChange="${i#*=}"
    shift;;
    --maxchange=*)
    maxChange="${i#*=}"
    shift;;
esac
done

### Handle missing arguments
if [ -z ${exchange+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --exchange"
    exit 1
fi
if [ -z ${quoteCurr+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --quote"
    exit 1
fi
if [ -z ${top+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --top"
    exit 1
fi

### Check for dependencies
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Testing for dependencies..."
if (cryptotrader about) | grep -q 'Stefan'; then
    :
    else echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] Please install 'cryptotrader'..."; exit 1
fi
if (jq --help) | grep -q 'JSON'; then
    :
    else echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] Please install 'jq'..."; exit 1
fi
if (bc --help) | grep -q 'mathlib'; then
    :
    else echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] Please install 'bc'..."; exit 1
fi
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Dependencies met..."

### Filter top X markets by (24h BTC volume) AND (24h % change greater than --minchange AND less than --maxchange)

    # KuCoin
    if [[ $exchange = "KUCN" || $exchange = "Kucoin" ]]; then

        plusLimit=$(echo $maxChange | bc)
        minusLimit=$(echo "-$maxChange" | bc)
        minChange=$(echo $minChange | bc)
        minChangeNeg=$(echo "-$minChange" | bc)
        percChangeMin=$(echo "$minChange*100" | bc)
        percChangeMax=$(echo "$maxChange*100" | bc)

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
        marketsData=$(curl -sS $kucoinAPI | jq '.data.ticker[]')

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering top $top $quoteCurr markets ordered by 24h volume with the following conditions:"
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ -$percChangeMax% to -$percChangeMin% ] OR [ $percChangeMin% to $percChangeMax% ]"

        markets=$(echo $marketsData \
            | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
            | jq -s \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson plusLimit $plusLimit \
            --argjson minusLimit $minusLimit \
            '.[] | select(
                (((.changeRate | tonumber) <= $minChangeNeg) and ((.changeRate | tonumber) >= $minusLimit)) or
                (((.changeRate | tonumber) >= $minChange) and ((.changeRate | tonumber) <= $plusLimit)) )' \
            | jq -s 'sort_by(.vol | split(".") | map(tonumber)) | reverse' \
            | jq -s '.[] | map({symbol: .symbol, vol: (.vol | tonumber), changeRate: (.changeRate | tonumber)})' \
            | jq --argjson top $top '.[0:$top]' \
            )
        echo $markets | jq
    fi

    # Binance
    if [[ $exchange = "BINA" || $exchange = "Binance" ]]; then

        plusLimit=$(echo "$maxChange*100" | bc)
        minusLimit=$(echo "-$plusLimit" | bc)
        minChange=$(echo "$minChange*100" | bc)
        minChangeNeg=$(echo "-$minChange" | bc)

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
        marketsData=$(curl -sS $binanceAPI | jq '.[]')

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering top $top $quoteCurr markets ordered by 24h volume with the following conditions:"
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ -$plusLimit% to -$minChange% ] OR [ $minChange% to $plusLimit% ]"

        markets=$(echo $marketsData \
            | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
            | jq -s \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson plusLimit $plusLimit \
            --argjson minusLimit $minusLimit \
            '.[] | select(
                (((.priceChangePercent | tonumber) <= $minChangeNeg) and ((.priceChangePercent | tonumber) >= $minusLimit)) or
                (((.priceChangePercent | tonumber) >= $minChange) and ((.priceChangePercent | tonumber) <= $plusLimit)) )' \
            | jq -s 'sort_by(.volume | split(".") | map(tonumber)) | reverse' \
            | jq -s '.[] | map({symbol: .symbol, volume: (.volume | tonumber), priceChangePercent: (.priceChangePercent | tonumber)})' \
            | jq --argjson top $top '.[0:$top]' \
            )
        echo $markets | jq
    fi

### Create CSV formatted string
marketSymbols=$(echo $markets | jq -r '.[].symbol')
for market in $marketSymbols; do
    if [[ $market != "" ]]; then
        symbols+=$market,
    fi
done
symbols=${symbols%,} # Trim extra comma from end of string

### Backup previous CSV (if any) and write picked markets to a CSV file
if test -f "$newFile"; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Backing up existing $newFile to $oldFile"
    mv $newFile $oldFile
    echo $symbols > $newFile
    echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Picked markets have been saved to $newFile on a CSV format"
else
    echo $symbols > $newFile
    echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Picked markets have been saved to $newFile on CSV format"
fi
