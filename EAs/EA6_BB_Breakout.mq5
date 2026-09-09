//+------------------------------------------------------------------+
//|                                       EA6_BB_Breakout.mq5        |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- Bollinger Bands Settings ---"
input int                  InpBBPeriod    = 20;          // BB Period (Opt: 10 - 40, step 5)
input double               InpBBDev       = 2.0;         // BB Deviation (Opt: 1.5 - 3.0, step 0.5)
input ENUM_APPLIED_PRICE   InpBBPrice     = PRICE_CLOSE; // BB Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 700;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 6006;        // Magic Number EA 6

//--- Global Handles & Variables
CTrade         trade;
int            bbHandle;
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

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(bbHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double upperBand[], lowerBand[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0)
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

   // Buy Breakout: Penutupan candle di ATAS Upper Band (Ikut Tren Naik)
   if(close1 > upperBand[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA6 BB Breakout Buy");
      lastBarTime = currentBarTime;
   }
   // Sell Breakout: Penutupan candle di BAWAH Lower Band (Ikut Tren Turun)
   else if(close1 < lowerBand[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA6 BB Breakout Sell");
      lastBarTime = currentBarTime;
   }
}