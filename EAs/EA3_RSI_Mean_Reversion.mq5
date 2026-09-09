//+------------------------------------------------------------------+
//|                                   EA3_RSI_Mean_Reversion.mq5     |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- RSI Settings ---"
input int                  InpRSIPeriod   = 14;          // RSI Period (Opt: 7 - 21, step 7)
input double               InpRSIOverSold = 30.0;        // RSI Oversold Level (Opt: 20 - 35, step 5)
input double               InpRSIOverBought= 70.0;       // RSI Overbought Level (Opt: 65 - 80, step 5)
input ENUM_APPLIED_PRICE   InpRSIPrice    = PRICE_CLOSE; // RSI Applied Price

input group "--- Risk & Trade Settings ---"
input double               InpLotSize     = 0.1;         // Lot Size
input int                  InpStopLoss    = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit  = 600;         // Take Profit in Points (Opt: 200 - 1000, step 100)
input ulong                InpMagicNumber = 3003;        // Magic Number EA 3

//--- Global Handles & Variables
CTrade         trade;
int            rsiHandle;
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

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(rsiHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime) return;

   double rsi[];
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(rsiHandle, 0, 1, 1, rsi) <= 0) return;

   // Cek posisi terbuka dari EA ini
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         return; 
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Buy: RSI di bawah level Oversold (misal < 30) -> Ekspektasi pembalikan arah naik
   if(rsi[0] < InpRSIOverSold)
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA3 RSI Buy");
      lastBarTime = currentBarTime;
   }
   // Sell: RSI di atas level Overbought (misal > 70) -> Ekspektasi pembalikan arah turun
   else if(rsi[0] > InpRSIOverBought)
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA3 RSI Sell");
      lastBarTime = currentBarTime;
   }
}