# Expert Advisor (EA) Berbasis MQL5

Project ini berisi pengembangan dan evaluasi beberapa Expert Advisor (EA) menggunakan MQL5. 
EA yang dibuat diuji menggunakan MetaTrader 5 Strategy Tester untuk melihat performanya pada data historis EURUSD.

## Project Overview

Project ini mengembangkan 10 variasi EA dengan menggunakan beberapa indikator dan pendekatan trading, seperti Bollinger Bands, RSI, EMA, MACD, ATR, breakout, dan trailing stop.

Tujuan utama project ini adalah membandingkan performa masing-masing EA berdasarkan hasil backtest.

## EA Variations

| EA | Strategy / Variation |
|---|---|
| EA1 | Bollinger Bands |
| EA2 | Bollinger Bands + EMA |
| EA3 | RSI Mean Reversion |
| EA4 | Bollinger Bands + RSI |
| EA5 | Bollinger Bands + Trailing Stop |
| EA6 | Bollinger Bands Breakout |
| EA7 | RSI + EMA Filter |
| EA8 | MACD Standard |
| EA9 | Bollinger Bands + ATR Dynamic |
| EA10 | Multi-Strategy Hybrid |

## Backtesting Setup

The EAs were tested using the following settings:

- **Instrument:** EURUSD
- **Timeframe:** M15
- **Platform:** MetaTrader 5 Strategy Tester
- **Testing/Modeling:** 1 Minute OHLC
- **Initial Deposit:** USD 10,000
- **Leverage:** 1:100

The same testing conditions were used for all EAs so their performance could be compared.

## Performance Results

| EA | Net Profit ($) | Profit Factor | Sharpe Ratio | Max DD | Trades | Win Rate |
|---|---:|---:|---:|---:|---:|---:|
| EA1 | 367.23 | 1.19 | 0.80 | 5.59% | 79 | 30.38% |
| EA2 | 1,013.54 | 1.81 | 3.48 | 2.41% | 79 | 36.71% |
| EA3 | 1,353.83 | 1.71 | 2.80 | 3.33% | 91 | 40.66% |
| EA4 | 1,590.33 | 1.61 | 4.99 | 2.68% | 347 | 24.50% |
| EA5 | 1,339.27 | 1.63 | 3.16 | 2.77% | 206 | 78.64% |
| EA6 | 813.88 | 1.41 | 1.74 | 2.49% | 85 | 41.18% |
| EA7 | 557.67 | 1.51 | 5.21 | 1.58% | 128 | 65.62% |
| EA8 | 1,057.16 | 1.29 | 2.59 | 4.25% | 326 | 72.09% |
| EA9 | 1,125.43 | 1.25 | 2.75 | 2.43% | 512 | 33.01% |
| EA10 | 346.11 | 1.28 | 3.31 | 2.34% | 210 | 25.71% |

## Main Findings

- **EA4** achieved the highest Net Profit at **USD 1,590.33**.
- **EA2** had the highest Profit Factor at **1.81**.
- **EA7** had the highest Sharpe Ratio at **5.21** and the lowest Maximum Drawdown at **1.58%**.
- **EA5** had the highest Win Rate at **78.64%**.
- **EA3** had the highest Expected Payoff at **14.88**.
- **EA9** generated the highest number of trades with **512 transactions**.

The results show that a high Win Rate or a high number of trades does not necessarily mean better overall performance. The results need to be considered together with profit and risk metrics.

## Tools

- MQL5
- MetaTrader 5
- MetaTrader 5 Strategy Tester

## References

1. *Simple MT5 Bollinger Bands Trading Strategy Tested More Than 300 Trades*. YouTube.  
   https://youtu.be/kkRElHFcyIw

2. MetaQuotes. *Trading Strategy Tester – MetaTrader 5*.  
   https://www.metatrader5.com/en/automated-trading/strategy-tester

3. MetaQuotes. *Strategy Testing – MetaTrader 5 Help*.  
   https://www.metatrader5.com/en/terminal/help/algotrading/testing

## Disclaimer

This project is intended for educational and evaluation purposes. Backtest results on historical data do not guarantee the same performance in live trading.
