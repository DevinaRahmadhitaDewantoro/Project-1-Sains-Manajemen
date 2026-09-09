//+------------------------------------------------------------------+
//|                                     EA7_RSI_EMA_Filter.mq5       |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- RSI Settings ---"
input int                  InpRSIPeriod   = 14;          // RSI Period (Opt: 7 - 21, step 7)
input double               InpRSIOverSold = 30.0;        // RSI Oversold (Opt: 20 - 35, step 5)
input double               InpRSIOverBought= 70.0;       // RSI Overbought (Opt: 65 - 80, step 5)
input ENUM_APPLIED_PRICE   InpRSIPrice    = PRICE_CLOSE; // RSI Applied Price

input group "--- EMA Trend Filter Settings ---"
input int                  InpEMAPeriod   = 200;         // EMA Period (Opt: 50 - 200, step 50)
input ENUM_APPLIED_PRICE   InpEMAPrice    = PRICE_CLOSE; // EMA Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 600;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 7007;        // Magic Number EA 7

//--- Global Handles & Variables
CTrade         trade;
int            rsiHandle;
int            emaHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   rsiHandle = iRSI(_Symbol, _Period, InpRSIPeriod, InpRSIPrice);
   if(rsiHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle RSI.");
      return(INIT_FAILED);
   }

   emaHandle = iMA(_Symbol, _Period, InpEMAPeriod, 0, MODE_EMA, InpEMAPrice);
   if(emaHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle EMA.");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(rsiHandle);
   IndicatorRelease(emaHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double rsi[], ema[];
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(ema, true);

   if(CopyBuffer(rsiHandle, 0, 1, 1, rsi) <= 0 ||
      CopyBuffer(emaHandle, 0, 1, 1, ema) <= 0)
   {
      return;
   }

   double close1 = iClose(_Symbol, _Period, 1);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return; 
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Buy Condition: RSI Oversold DAN Harga di atas EMA (Uptrend)
   if(rsi[0] < InpRSIOverSold && close1 > ema[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA7 RSI+EMA Buy");
      lastBarTime = currentBarTime;
   }
   // Sell Condition: RSI Overbought DAN Harga di bawah EMA (Downtrend)
   else if(rsi[0] > InpRSIOverBought && close1 < ema[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA7 RSI+EMA Sell");
      lastBarTime = currentBarTime;
   }
}