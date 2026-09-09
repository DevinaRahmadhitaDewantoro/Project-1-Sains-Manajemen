//+------------------------------------------------------------------+
//|                                    EA5_BB_Trailing_Stop.mq5      |
//|                               Reference: René Balke (BM Trading) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sains Manajemen"
#property link      "https://bmtrading.de"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Parameter Inputs
input group "--- Bollinger Bands Settings ---"
input int                  InpBBPeriod      = 20;          // BB Period (Opt: 10 - 40, step 5)
input double               InpBBDev         = 2.0;         // BB Deviation (Opt: 1.5 - 3.0, step 0.5)
input ENUM_APPLIED_PRICE   InpBBPrice       = PRICE_CLOSE; // BB Applied Price

input group "--- Dynamic Risk Management ---"
input double               InpLotSize       = 0.1;         // Lot Size
input int                  InpStopLoss      = 250;         // Stop Loss in Points (Opt: 100 - 500, step 50)
input int                  InpTakeProfit    = 800;         // Take Profit in Points (Opt: 300 - 1000, step 100)
input int                  InpTrailingStop  = 150;         // Trailing Stop in Points (Opt: 50 - 300, step 50)
input int                  InpTrailingStep  = 20;          // Trailing Step in Points
input ulong                InpMagicNumber   = 5005;        // Magic Number EA 5

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
//| Manage Trailing Stop for Open Positions                          |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(InpTrailingStop <= 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
      {
         ulong ticket = PositionGetTicket(i);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL = PositionGetDouble(POSITION_SL);

         if(type == POSITION_TYPE_BUY)
         {
            if(bid - openPrice > InpTrailingStop * _Point)
            {
               double newSL = bid - (InpTrailingStop * _Point);
               if(newSL > currentSL + (InpTrailingStep * _Point))
               {
                  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(openPrice - ask > InpTrailingStop * _Point)
            {
               double newSL = ask + (InpTrailingStop * _Point);
               if(currentSL == 0 || newSL < currentSL - (InpTrailingStep * _Point))
               {
                  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Trailing stop diperbarui pada setiap pergerakan harga (tick)
   ManageTrailingStop();

   // Eksekusi entry hanya pada bar baru
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

   // Buy Condition
   if(close1 < lowerBand[0])
   {
      double sl = (InpStopLoss > 0) ? ask - (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? ask + (InpTakeProfit * _Point) : 0;
      trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EA5 BB Trailing Buy");
      lastBarTime = currentBarTime;
   }
   // Sell Condition
   else if(close1 > upperBand[0])
   {
      double sl = (InpStopLoss > 0) ? bid + (InpStopLoss * _Point) : 0;
      double tp = (InpTakeProfit > 0) ? bid - (InpTakeProfit * _Point) : 0;
      trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EA5 BB Trailing Sell");
      lastBarTime = currentBarTime;
   }
}