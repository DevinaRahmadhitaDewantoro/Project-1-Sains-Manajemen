//+------------------------------------------------------------------+
//|                                         EA1_Bollinger_Bands.mq5 |
//|                                  Copyright 2026, Sains Manajemen |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- Bollinger Bands Settings ---"
input int                  InpBBPeriod    = 20;          // Period
input double               InpBBDev       = 2.0;         // Deviation
input ENUM_APPLIED_PRICE   InpBBPrice     = PRICE_CLOSE; // Applied Price

input group "--- Risk & Execution Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 200;         // Stop Loss (Points)
input int                  InpTakeProfit  = 400;         // Take Profit (Points)
input ulong                InpMagicNumber = 2001;        // Magic Number

//--- Global Variables
CTrade         trade;
int            bbHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   // Inisialisasi Indikator Bollinger Bands
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
   // Hanya eksekusi pada candle baru
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   // Ambil buffer Upper Band (index 1) dan Lower Band (index 2)
   double upperBand[], lowerBand[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0)
   {
      return;
   }

   // Harga penutupan candle sebelumnya (Candle 1)
   double close1 = iClose(_Symbol, _Period, 1);

   // Cek apakah sedang ada posisi terbuka dengan Magic Number ini
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return; 
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Sinyal BUY (Mean Reversion): Harga tembus di bawah Lower Band
   if(close1 < lowerBand[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA1 BB Buy");
      lastBarTime = currentBarTime;
   }
   // Sinyal SELL (Mean Reversion): Harga tembus di atas Upper Band
   else if(close1 > upperBand[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA1 BB Sell");
      lastBarTime = currentBarTime;
   }
}