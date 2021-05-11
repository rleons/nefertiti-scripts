#!/bin/bash
#
# 'Markets Picker' script by Roberto Leon,
# inspired by MarcelM ideas on Nefertiti trading bot community. 
#
# Dependencies:
# cryptotrader - https://nefertiti-tradebot.com
# jq - https://stedolan.github.io/jq
# bc - https://www.gnu.org/software/bc/manual/html_mono/bc.html
#
# Examples:
# ./markets-picker.sh --exchange=BINA --quote=BTC --minvol=100 --minchange=0.05
# ./markets-picker.sh --exchange=KUCN --quote=USDT --minvol=5000000 --minchange=0.05
#
# Notes:
# (1) --minvol amount needs to be entered in quote currency.
# (2) --minchange=0.05 refers to 5%
# (3) If you want to automatically feed results to your Nefertiti buy script,
#     the '$symbols' variable at the end is formatted accordingly.
# (4) A 15% maximum change in the last 24h is statically coded,
#     but you can manually change them on the 'plusLimit' and 'minusLimit' variables
#     in order to increase the amount of filtered markets. This is defined per exchange.
# (5) Both --minchange and statically coded limits are applied to both upside and downside % change.
#

# Default Settings
exchange="BINA"
declare -i minVol="30000000"
minChange="0.05"
quoteCurr="USDT"
scriptDir="${0%/*}"

# Exchange APIs
kucoinAPI="https://api.kucoin.com/api/v1"
binanceAPI="https://api.binance.com/api/v3"

# Flag args
for i in "$@"
do
case $i in
    --exchange=*)
    exchange="${i#*=}"
    shift;;
    --quote=*)
    quoteCurr="${i#*=}"
    shift;;
    --minvol=*)
    declare -i minVol="${i#*=}"
    shift;;
    --minchange=*)
    minChange="${i#*=}"
    shift;;
esac
done

if [ -z ${exchange+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --exchange"
    exit 1
fi
if [ -z ${quoteCurr+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --quote"
    exit 1
fi
if [ -z ${minVol+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --minvol"
    exit 1
fi
if [ -z ${minChange+x} ]; then
    echo $(date +"%Y/%m/%d %H:%M:%S") "[ERROR] missing argument: --minchange"
    exit 1
fi

# Check for dependencies | d00vy
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

# Get markets and filter by quote
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Loading markets from $exchange..."
markets=$(cryptotrader markets --exchange=$exchange \
        | jq -r --arg quoteCurr "$quoteCurr" '.[]
        | select(.name | endswith($quoteCurr)) | .name')

# Filter by (24h volume) AND (24h % change greater than --minchange AND less than 15%)
symbols=""
formattedVol=$(printf "%'.0f\n" $minVol)
percChange=$(echo "$minChange*100" | bc)
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtering $quoteCurr markets with the following conditions:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Trading Volume: >= $formattedVol $quoteCurr"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] 24h Percent Change Between: [ -15.00% to -$percChange% ] OR [ $percChange% to 15.00% ]"

    # KuCoin
    if [[ $exchange = "KUCN" || $exchange = "Kucoin" ]]; then

        plusLimit=$(echo "0.15" | bc)
        minusLimit=$(echo "-0.15" | bc)
        minChange=$(echo $minChange | bc)
        minChangeNeg=$(echo "-$minChange" | bc)
        percChange=$(echo "$minChange*100" | bc)

        for market in $markets; do
            filteredS=$(curl -sS $kucoinAPI"/market/stats?symbol="$market \
            | jq -r --argjson minVol $minVol \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson plusLimit $plusLimit \
            --argjson minusLimit $minusLimit \
            '.data
            | select(
                ((.volValue | tonumber) >= $minVol) and
                    ((((.changeRate | tonumber) <= $minChangeNeg) and ((.changeRate | tonumber) >= $minusLimit)) or
                    (((.changeRate | tonumber) >= $minChange) and ((.changeRate | tonumber) <= $plusLimit)))
            )
            | .symbol')

            if [[ $filteredS != "" ]]; then
                symbols+=$filteredS,
            fi
        done
    fi

    # Binance
    if [[ $exchange = "BINA" || $exchange = "Binance" ]]; then

        plusLimit=$(echo "15" | bc)
        minusLimit=$(echo "-15" | bc)
        minChange=$(echo "$minChange*100" | bc)
        minChangeNeg=$(echo "-$minChange" | bc)
        percChange=$(echo "$minChange" | bc)

        for market in $markets; do
            filteredS=$(curl -sS $binanceAPI"/ticker/24hr?symbol="$market \
            | jq -r --argjson minVol $minVol \
            --argjson minChange $minChange \
            --argjson minChangeNeg $minChangeNeg \
            --argjson plusLimit $plusLimit \
            --argjson minusLimit $minusLimit \
            '.
            | select(
                ((.quoteVolume | tonumber) >= $minVol) and
                    ((((.priceChangePercent | tonumber) <= $minChangeNeg) and ((.priceChangePercent | tonumber) >= $minusLimit)) or
                    (((.priceChangePercent | tonumber) >= $minChange) and ((.priceChangePercent | tonumber) <= $plusLimit)))
            )
            | .symbol')

            if [[ $filteredS != "" ]]; then
                symbols+=$filteredS,
            fi
        done
    fi

symCount=$(echo "$symbols" | awk -F "," '{print NF-1}')
symbols=$(echo $symbols | sed 's/.$//') # Trim extra comma from end of string | Another approach: pairs=${pairs%,}
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] Filtered a total of $symCount $quoteCurr markets:"
echo $(date +"%Y/%m/%d %H:%M:%S") "[INFO] $symbols"
echo
