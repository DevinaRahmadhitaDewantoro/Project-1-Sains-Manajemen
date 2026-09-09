//+------------------------------------------------------------------+
//|                                        EA9_BB_ATR_Dynamic.mq5    |
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
input ENUM_APPLIED_PRICE   InpBBPrice       = PRICE_CLOSE; // BB Applied Price

input group "--- Dynamic Risk Settings (ATR) ---"
input int                  InpATRPeriod     = 14;          // ATR Period (Opt: 7 - 21, step 7)
input double               InpSLATRMult     = 1.5;         // SL ATR Multiplier (Opt: 1.0 - 3.0, step 0.5)
input double               InpTPATRMult     = 3.0;         // TP ATR Multiplier (Opt: 2.0 - 5.0, step 1.0)

input group "--- Trade Settings ---"
input double               InpLotSize       = 0.1;         // Lot Size
input ulong                InpMagicNumber   = 9009;        // Magic Number EA 9

//--- Global Handles & Variables
CTrade         trade;
int            bbHandle;
int            atrHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   bbHandle = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDev, InpBBPrice);
   if(bbHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle Bollinger Bands.");
      return(INIT_FAILED);
   }

   atrHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle ATR.");
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
   IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double upperBand[], lowerBand[], atr[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0 ||
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

   // Hitung SL dan TP Dinamis berbasis Volatilitas ATR
   double slDistance = atr[0] * InpSLATRMult;
   double tpDistance = atr[0] * InpTPATRMult;

   // Buy Condition: Harga di bawah Lower Band
   if(close1 < lowerBand[0])
   {
      double sl = ask - slDistance;
      double tp = ask + tpDistance;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA9 BB Dynamic ATR Buy");
      lastBarTime = currentBarTime;
   }
   // Sell Condition: Harga di atas Upper Band
   else if(close1 > upperBand[0])
   {
      double sl = bid + slDistance;
      double tp = bid - tpDistance;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA9 BB Dynamic ATR Sell");
      lastBarTime = currentBarTime;
   }
}