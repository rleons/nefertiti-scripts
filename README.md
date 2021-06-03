# Nefertiti Scripts

A collection of bash scripts developed for Nefertiti crypto trading bot, with the purpose of sharing automation ideas with the community.

https://nefertiti-tradebot.com/

## Files
```
├── Binance
│   ├── binance-buy-cbs.sh | CBS signals buy bot
│   ├── binance-buy-default.sh | Built-in default strategy buy bot
│   ├── binance-cancel-orders.sh | Cancel unfilled orders
│   ├── binance-sell.sh | Simple sell bot
│   ├── binance.yaml | App declaration for pm2 (process manager)
│   ├── clusters
│   │   ├── binance-urls.txt | Binance API cluster URLs
│   │   └── latency-test.sh | Binance API clusters latency tester
│   └── markets.now | Market pairs for default strategy bot
├── Coinbase
│   ├── coinbase-buy-cbs.sh | CBS signals buy bot
│   ├── coinbase-buy-default.sh | Built-in default strategy buy bot | ALL markets
│   ├── coinbase-sell.sh | Simple sell bot
│   └── coinbase.yaml | App declaration for pm2 (process manager)
├── KuCoin
│   ├── kucoin-buy-cbs.sh | CBS signals buy bot
│   ├── kucoin-buy-default.sh | Built-in default strategy buy bot
│   ├── kucoin-cancel-orders.sh | Cancel unfilled orders
│   ├── kucoin-sell.sh | Simple sell bot
│   ├── kucoin.yaml | App declaration for pm2 (process manager)
│   └── markets.now | Market pairs for default strategy bot
│
└── markets-picker.sh | Filter markets by exchange, volume, and % change (work in progress)
```
