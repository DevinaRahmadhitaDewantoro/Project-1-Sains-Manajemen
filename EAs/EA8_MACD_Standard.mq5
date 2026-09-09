//+------------------------------------------------------------------+
//|                                           EA8_MACD_Standard.mq5  |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- MACD Settings ---"
input int                  InpFastEMA     = 12;          // Fast EMA Period (Opt: 8 - 16, step 2)
input int                  InpSlowEMA     = 26;          // Slow EMA Period (Opt: 20 - 32, step 2)
input int                  InpSignalSMA   = 9;           // Signal SMA Period (Opt: 5 - 15, step 2)
input ENUM_APPLIED_PRICE   InpMACDPrice   = PRICE_CLOSE; // MACD Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 600;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 8008;        // Magic Number EA 8

//--- Global Handles & Variables
CTrade         trade;
int            macdHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   macdHandle = iMACD(_Symbol, _Period, InpFastEMA, InpSlowEMA, InpSignalSMA, InpMACDPrice);
   if(macdHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle MACD.");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(macdHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double macdMain[], macdSignal[];
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);

   if(CopyBuffer(macdHandle, 0, 1, 2, macdMain) <= 0 ||
      CopyBuffer(macdHandle, 1, 1, 2, macdSignal) <= 0)
   {
      return;
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return; 
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Bullish Crossover: Main Line memotong ke atas Signal Line
   if(macdMain[1] <= macdSignal[1] && macdMain[0] > macdSignal[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA8 MACD Buy");
      lastBarTime = currentBarTime;
   }
   // Bearish Crossover: Main Line memotong ke bawah Signal Line
   else if(macdMain[1] >= macdSignal[1] && macdMain[0] < macdSignal[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA8 MACD Sell");
      lastBarTime = currentBarTime;
   }
}