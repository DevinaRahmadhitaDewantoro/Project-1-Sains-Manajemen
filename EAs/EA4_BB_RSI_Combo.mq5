//+------------------------------------------------------------------+
//|                                     EA4_BB_RSI_Combo.mq5         |
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

input group "--- RSI Confluence Settings ---"
input int                  InpRSIPeriod   = 14;          // RSI Period (Opt: 7 - 21, step 7)
input double               InpRSIOverSold = 30.0;        // RSI Oversold (Opt: 20 - 35, step 5)
input double               InpRSIOverBought= 70.0;       // RSI Overbought (Opt: 65 - 80, step 5)
input ENUM_APPLIED_PRICE   InpRSIPrice    = PRICE_CLOSE; // RSI Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 600;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 4004;        // Magic Number EA 4

//--- Global Handles & Variables
CTrade         trade;
int            bbHandle;
int            rsiHandle;
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

   rsiHandle = iRSI(_Symbol, _Period, InpRSIPeriod, InpRSIPrice);
   if(rsiHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle RSI.");
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
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double upperBand[], lowerBand[], rsi[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0 ||
      CopyBuffer(rsiHandle, 0, 1, 1, rsi) <= 0)
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

   // Buy: Harga menembus Lower Band DAN RSI < Oversold
   if(close1 < lowerBand[0] && rsi[0] < InpRSIOverSold)
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA4 BB+RSI Buy");
      lastBarTime = currentBarTime;
   }
   // Sell: Harga menembus Upper Band DAN RSI > Overbought
   else if(close1 > upperBand[0] && rsi[0] > InpRSIOverBought)
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA4 BB+RSI Sell");
      lastBarTime = currentBarTime;
   }
}