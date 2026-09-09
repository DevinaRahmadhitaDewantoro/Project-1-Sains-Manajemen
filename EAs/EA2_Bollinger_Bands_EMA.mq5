//+------------------------------------------------------------------+
//|                                    EA2_Bollinger_Bands_EMA.mq5 |
//|                               Reference: René Balke (BM Trading)|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- Bollinger Bands Settings ---"
input int                  InpBBPeriod    = 20;          // BB Period (Opt: 10 - 40, step 5)
input double               InpBBDev       = 2.0;         // BB Standard Deviation (Opt: 1.5 - 3.0, step 0.5)
input ENUM_APPLIED_PRICE   InpBBPrice     = PRICE_CLOSE; // BB Applied Price

input group "--- EMA Trend Filter Settings ---"
input int                  InpEMAPeriod   = 200;         // EMA Period / Filter (Opt: 50 - 200, step 50)
input ENUM_APPLIED_PRICE   InpEMAPrice    = PRICE_CLOSE; // EMA Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 300;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 600;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 2002;        // Magic Number EA 2

//--- Global Handles & Variables
CTrade         trade;
int            bbHandle;
int            emaHandle;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);

   // Inisialisasi Indikator BB & EMA
   bbHandle = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDev, InpBBPrice);
   if(bbHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle Bollinger Bands.");
      return(INIT_FAILED);
   }

   emaHandle = iMA(_Symbol, _Period, InpEMAPeriod, 0, MODE_EMA, InpEMAPrice);
   if(emaHandle == INVALID_HANDLE)
   {
      Print("Error: Gagal membuat handle EMA Trend Filter.");
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
   IndicatorRelease(emaHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Hanya eksekusi pada penutupan candle baru (Bar Close)
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double upperBand[], lowerBand[], ema[];
   ArraySetAsSeries(upperBand, true);
   ArraySetAsSeries(lowerBand, true);
   ArraySetAsSeries(ema, true);

   if(CopyBuffer(bbHandle, 1, 1, 1, upperBand) <= 0 ||
      CopyBuffer(bbHandle, 2, 1, 1, lowerBand) <= 0 ||
      CopyBuffer(emaHandle, 0, 1, 1, ema) <= 0)
   {
      return;
   }

   double close1 = iClose(_Symbol, _Period, 1);

   // Cek apakah ada posisi terbuka dari EA ini
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return; 
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Sinyal BUY (René Balke Rules): Harga < Lower Band DAN Harga di atas EMA (Uptrend Only)
   if(close1 < lowerBand[0] && close1 > ema[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA2 BB+EMA Buy");
      lastBarTime = currentBarTime;
   }
   // Sinyal SELL (René Balke Rules): Harga > Upper Band DAN Harga di bawah EMA (Downtrend Only)
   else if(close1 > upperBand[0] && close1 < ema[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA2 BB+EMA Sell");
      lastBarTime = currentBarTime;
   }
}