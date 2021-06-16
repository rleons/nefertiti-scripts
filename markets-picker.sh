#!/bin/bash
#
# Author: Roberto Leon
# Description: Script will help you pick markets by filtering by the given quote,
# then it will filter by looking at the last 24h percent change (optionally adjusted),
# and finally order the top X results by quote trading volume.
# * Original idea inspired by MarcelM shared methods on Nefertiti trading bot community. 
#
# Dependencies:
# jq - https://stedolan.github.io/jq
# bc - https://www.gnu.org/software/bc/manual/html_mono/bc.html
#
# Options:
# --exchange    - Currently supports Binance (BINA), KuCoin (KUCN) and Bittrex (BTRX)
# --quote       - Script will filter markets by specified quote (Ex: BTC, ETH, USDT)
# --top         - The amount or market pairs you want the script to output, ordered by quote volume.
# --minchange   - 0.05 is a default value and refers to 5% minimum change in the last 24h.
# --maxchange   - 0.15 is a default value and refers to 15% maximum change in the last 24h.
# --ignore      - Valid options: 'leveraged'
#
# Examples:
# ./markets-picker.sh --exchange=BINA --quote=BTC --top=15 --ignore=leveraged
# ./markets-picker.sh --exchange=KUCN --quote=USDT --top=20 --minchange=0.10 --maxchange=0.20
#
# Notes:
# - Both --minchange and --maxchange values are applied to both the upside and downside % change.
# - The resulting markets are written to a file in CSV format in case you want to automatically
#   feed them to a Nefertiti buy script. Previous file is always backed up with a timestamped filename.


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
bittrexAPI="https://api.bittrex.com/v3/markets/summaries"

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
    --ignore=*)
    ignore="${i#*=}"
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

### Filter top X markets by (24h quote volume) AND (24h % change greater than --minchange AND less than --maxchange)

    # KuCoin
    if [[ $exchange = "KUCN" || $exchange = "Kucoin" ]]; then

        maxChange=$(echo $maxChange | bc)
        maxChangeNeg=$(echo "-$maxChange" | bc)
        minChange=$(echo $minChange | bc)
        minChangeNeg=$(echo "-$minChange" | bc)
        percChangeMin=$(echo "$minChange*100" | bc)
        percChangeMax=$(echo "$maxChange*100" | bc)

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
        marketsData=$(curl -sS $kucoinAPI | jq '.data.ticker[]')

        if [[ $ignore = "leveraged" ]]; then
            echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Ignoring leveraged tokens..."
            markets=$(echo $marketsData \
            | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
            | jq -s '.[] | select( (.symbol | contains("3L")) or (.symbol | contains("3S")) | not)' \
            )
            else
                markets=$(echo $marketsData \
                | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
                )
        fi

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering top $top $quoteCurr markets ordered by 24h quote volume with the following conditions:"
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ -$percChangeMax% to -$percChangeMin% ] OR [ $percChangeMin% to $percChangeMax% ]"

        markets=$(echo $markets \
            | jq -s \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson maxChange $maxChange \
            --argjson maxChangeNeg $maxChangeNeg \
            '.[] | select(
                (((.changeRate | tonumber) <= $minChangeNeg) and ((.changeRate | tonumber) >= $maxChangeNeg)) or
                (((.changeRate | tonumber) >= $minChange) and ((.changeRate | tonumber) <= $maxChange)) )' \
            | jq -s 'sort_by(.volValue | split(".") | map(tonumber)) | reverse' \
            | jq -s '.[] | map({symbol: .symbol, volValue: (.volValue | tonumber), changeRate: (.changeRate | tonumber)})' \
            | jq --argjson top $top '.[0:$top]' \
            )
        echo $markets | jq
    fi

    # Binance
    if [[ $exchange = "BINA" || $exchange = "Binance" ]]; then

        maxChange=$(echo "$maxChange*100" | bc)
        maxChangeNeg=$(echo "-$maxChange" | bc)
        minChange=$(echo "$minChange*100" | bc)
        minChangeNeg=$(echo "-$minChange" | bc)

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
        marketsData=$(curl -sS $binanceAPI | jq '.[]')

        if [[ $ignore = "leveraged" ]]; then
            echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Ignoring leveraged tokens..."
            markets=$(echo $marketsData \
            | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
            | jq -s '.[] | select( (.symbol | contains("UP")) or (.symbol | contains("DOWN")) | not)' \
            )
            else
                markets=$(echo $marketsData \
                | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
                )
        fi

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering top $top $quoteCurr markets ordered by 24h quote volume with the following conditions:"
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ $maxChangeNeg% to $minChangeNeg% ] OR [ $minChange% to $maxChange% ]"

        markets=$(echo $markets \
            | jq -s \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson maxChange $maxChange \
            --argjson maxChangeNeg $maxChangeNeg \
            '.[] | select(
                (((.priceChangePercent | tonumber) <= $minChangeNeg) and ((.priceChangePercent | tonumber) >= $maxChangeNeg)) or
                (((.priceChangePercent | tonumber) >= $minChange) and ((.priceChangePercent | tonumber) <= $maxChange)) )' \
            | jq -s 'sort_by(.quoteVolume | split(".") | map(tonumber)) | reverse' \
            | jq -s '.[] | map({symbol: .symbol, quoteVolume: (.quoteVolume | tonumber), priceChangePercent: (.priceChangePercent | tonumber)})' \
            | jq --argjson top $top '.[0:$top]' \
            )
        echo $markets | jq
    fi

    # Bittrex
    if [[ $exchange = "BTRX" || $exchange = "Bittrex" ]]; then

        maxChange=$(echo "$maxChange*100" | bc)
        maxChangeNeg=$(echo "-$maxChange" | bc)
        minChange=$(echo "$minChange*100" | bc)
        minChangeNeg=$(echo "-$minChange" | bc)

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
        marketsData=$(curl -sS $bittrexAPI | jq '.[]')

        if [[ $ignore = "leveraged" ]]; then
            echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] No leveraged tokens on $exchange..."
        fi

        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering top $top $quoteCurr markets ordered by 24h quote volume with the following conditions:"
        echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ $maxChangeNeg% to $minChangeNeg% ] OR [ $minChange% to $maxChange% ]"

        markets=$(echo $marketsData \
            | jq -s --arg quoteCurr $quoteCurr '.[] | select(.symbol | endswith($quoteCurr))' \
            | jq -s '.[] | select(.percentChange != null)' \
            | jq -s '.[] | select(.quoteVolume != null)' \
            | jq -s \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson maxChange $maxChange \
            --argjson maxChangeNeg $maxChangeNeg \
            '.[] | select(
                (((.percentChange | tonumber) <= $minChangeNeg) and ((.percentChange | tonumber) >= $maxChangeNeg)) or
                (((.percentChange | tonumber) >= $minChange) and ((.percentChange | tonumber) <= $maxChange)) )' \
            | jq -s 'sort_by(.quoteVolume | split(".") | map(tonumber)) | reverse' \
            | jq -s '.[] | map({symbol: .symbol, quoteVolume: (.quoteVolume | tonumber), percentChange: (.percentChange | tonumber)})' \
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
