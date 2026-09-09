//+------------------------------------------------------------------+
//|                                EA10_Multi_Strategy_Hybrid.mq5    |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- Bollinger Bands Settings ---"
input int                  InpBBPeriod      = 20;          // BB Period (Opt: 10 - 30, step 5)
input double               InpBBDev         = 2.0;         // BB Deviation (Opt: 1.5 - 2.5, step 0.5)

input group "--- RSI Settings ---"
input int                  InpRSIPeriod     = 14;          // RSI Period (Opt: 7 - 21, step 7)
input double               InpRSIOverSold   = 30.0;        // RSI Oversold (Opt: 20 - 35, step 5)
input double               InpRSIOverBought = 70.0;        // RSI Overbought (Opt: 65 - 80, step 5)

input group "--- EMA Trend Filter Settings ---"
input int                  InpEMAPeriod     = 200;         // EMA Period (Opt: 50 - 200, step 50)

input group "--- Dynamic Risk Settings (ATR) ---"
input int                  InpATRPeriod     = 14;          // ATR Period (Opt: 7 - 21, step 7)
input double               InpSLATRMult     = 2.0;         // SL ATR Multiplier (Opt: 1.0 - 3.0, step 0.5)
input double               InpTPATRMult     = 4.0;         // TP ATR Multiplier (Opt: 2.0 - 6.0, step 1.0)

input group "--- Trade Settings ---"
input double               InpLotSize       = 0.1;         // Lot Size
input ulong                InpMagicNumber   = 10010;       // Magic Number EA 10

//--- Global Handles & Variables
CTrade         trade;
int            bbHandle, rsiHandle, emaHandle, atrHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   bbHandle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDev, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   emaHandle = iMA(_Symbol, _Period, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, _Period, InpATRPeriod);

   if(bbHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE || 
      emaHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle indikator.");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(bbHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(emaHandle);
   IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double upperBand[], lowerBand[], rsi[], ema[], atr[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(ema, true);
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0 ||
      CopyBuffer(rsiHandle, 0, 1, 1, rsi) <= 0 ||
      CopyBuffer(emaHandle, 0, 1, 1, ema) <= 0 ||
      CopyBuffer(atrHandle, 0, 1, 1, atr) <= 0)
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

   double slDistance = atr[0] * InpSLATRMult;
   double tpDistance = atr[0] * InpTPATRMult;

   // Buy Hybrid Confluence: Harga < Lower BB + RSI Oversold + Harga > EMA
   if(close1 < lowerBand[0] && rsi[0] < InpRSIOverSold && close1 > ema[0])
   {
      double sl = ask - slDistance;
      double tp = ask + tpDistance;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA10 Hybrid Buy");
      lastBarTime = currentBarTime;
   }
   // Sell Hybrid Confluence: Harga > Upper BB + RSI Overbought + Harga < EMA
   else if(close1 > upperBand[0] && rsi[0] > InpRSIOverBought && close1 < ema[0])
   {
      double sl = bid + slDistance;
      double tp = bid - tpDistance;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA10 Hybrid Sell");
      lastBarTime = currentBarTime;
   }
}