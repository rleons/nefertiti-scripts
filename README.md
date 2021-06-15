# Nefertiti Scripts

A collection of bash scripts developed for Nefertiti crypto trading bot, with the purpose of sharing automation ideas with the community.

https://nefertiti-tradebot.com/

## Files
```
├── Binance
│   ├── binance-buy-cbs.sh | CBS signals buy bot w/ DCA
│   ├── binance-buy-default.sh | Built-in default strategy buy bot w/ DCA
│   ├── binance-cancel-orders.sh | Cancel unfilled orders
│   ├── binance-sell.sh | Simple sell bot
│   ├── binance.yaml | App declaration for pm2 (process manager)
│   ├── clusters
│   │   ├── binance-urls.txt | Binance API cluster URLs
│   │   └── latency-test.sh | Binance API clusters latency tester
│   └── markets.new | Market pairs for default strategy bot
├── Coinbase
│   ├── coinbase-buy-cbs.sh | CBS signals buy bot w/ DCA
│   ├── coinbase-buy-default.sh | Built-in default strategy buy bot w/ DCA | ALL markets
│   ├── coinbase-sell.sh | Simple sell bot
│   └── coinbase.yaml | App declaration for pm2 (process manager)
├── KuCoin
│   ├── kucoin-buy-cbs.sh | CBS signals buy bot w/ DCA
│   ├── kucoin-buy-default.sh | Built-in default strategy buy bot w/ DCA
│   ├── kucoin-cancel-orders.sh | Cancel unfilled orders
│   ├── kucoin-sell.sh | Simple sell bot
│   ├── kucoin.yaml | App declaration for pm2 (process manager)
│   └── markets.new | Market pairs for default strategy bot
│
└── markets-picker.sh | Filter markets by quote, 24h % change, and orders them by quote volume
```


## Script: [markets-picker.sh](https://github.com/rleons/nefertiti-scripts/blob/main/markets-picker.sh)

### Description:
Script will help you pick markets and filter by a given quote, then it will filter by looking at the last 24h percent change (optionally adjusted), and finally order the top X results by quote trading volume. Note: Original idea inspired by MarcelM shared methods on Nefertiti trading bot community. 

### Dependencies:
jq - https://stedolan.github.io/jq <br>
bc - https://www.gnu.org/software/bc/manual/html_mono/bc.html

### Options:
```
--exchange    - Currently supports Binance (BINA) and KuCoin (KUCN)
--quote       - Script will filter markets by specified quote (Ex: BTC, ETH, USDT)
--top         - The amount or market pairs you want the script to output, ordered by quote volume.
--minchange   - 0.05 is a default value and refers to 5% minimum change in the last 24h.
--maxchange   - 0.15 is a default value and refers to 15% maximum change in the last 24h.
--ignore      - Valid options: 'leveraged'
```

### Examples:
```
./markets-picker.sh --exchange=BINA --quote=BTC --top=15 --ignore=leveraged
./markets-picker.sh --exchange=KUCN --quote=USDT --top=20 --minchange=0.10 --maxchange=0.20
```

### Notes:
- Both --minchange and --maxchange values are applied to both the upside and downside % change. <br>
- The resulting markets are written to a file in CSV format in case you want to automatically feed them to a Nefertiti buy script. Previous file is always backed up with a timestamped filename.
