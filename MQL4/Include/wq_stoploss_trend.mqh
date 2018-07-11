#property strict
#include <wq_stoploss.mqh>

extern bool g_break_even_3atr = false;		                        // [止损:保本] 赚 3*ATR
extern bool g_break_even_ha = false;		                        // [止损:保本] HA 跟随
extern bool g_break_even_ma = false;		                        // [止损:保本] 用慢均线
extern bool g_break_even_channel = true;		                     // [止损:保本] 用通道线
extern ENUM_TIMEFRAMES g_break_even_period = PERIOD_CURRENT;      // [止损:保本:通道] 时间周期


// ==========================================================================

class stoploss_trend : public stoploss
{
public:
	stoploss_trend(int magic, string symbol, int time_frame);
	~stoploss_trend();

	void update_long_stoploss();
	void update_short_stoploss();
	
	void update_trailing_stoploss();
};

stoploss_trend* g_stop = NULL;

// ==========================================================================

stoploss_trend::stoploss_trend(int magic, string symbol, int time_frame)
   : stoploss(magic, symbol, time_frame)
{
}

stoploss_trend::~stoploss_trend()
{
}

// ==========================================================================

void stoploss_trend::update_trailing_stoploss()
{
   update_long_stoploss();
   update_short_stoploss();
}

void stoploss_trend::update_long_stoploss()
{
	if (!g_stop_enable)
	{
		return;
	}
	if (!g_is_new_bar)	// 1根k线只计算1次
	{
		return;
	}
	const int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		return;
	}
	int calc_ticket = 0;
	_update_sl = false;
	for (int i = order_total - 1; i >= 0; --i)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
		{
			continue;
		}
		if (OrderSymbol() != _symbol)
		{
			continue;
		}
		if (0 != _magic && OrderMagicNumber() != _magic)
		{
			continue;
		}
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (OrderType() != OP_BUY)
		{
			continue;
		}
		if (calc_ticket <= 0)
		{
			calc_ticket = OrderTicket();
		}
		else
		{
		   if (_update_sl)
		   {
				modify_long_stoploss(_long_stoploss);
			}
			continue;
		}
		if (OrderType() == OP_BUY)
		{
			//
			// 保本
			//
			double pre_long_stoploss = _long_stoploss;
			if (OrderStopLoss() < OrderOpenPrice())	// 止损线 < 成本价
			{
				if (g_break_even_channel)
				{
			      double channel_long_low = iLow(g_symbol, g_break_even_period, iLowest(g_symbol, g_break_even_period, MODE_LOW, g_channel_long_period, 1));
				   if (channel_long_low >= OrderOpenPrice())
				   {
						_long_stoploss = OrderOpenPrice();
					}
				}
				if (g_break_even_ha)
				{
					if (g_bars._ha_top_reverse_threshold > OrderOpenPrice() && Bid > OrderOpenPrice() + g_stop_level * g_point)
					{
						_long_stoploss = OrderOpenPrice();
					}
					//_long_stoploss = g_bars._ha_top_reverse_threshold;
					//_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					//_long_stoploss = MathMin(_long_stoploss, OrderOpenPrice());
				}
				if (g_break_even_3atr)
				{
					if (Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3)
					{
						_long_stoploss = OrderOpenPrice();
					}
				}
				if (g_break_even_ma)
				{
					if (Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 0
					   && g_bars._bars[0]._ha_low > g_bars._bars[0]._ma_dragon_centre
					   && g_bars._bars[1]._ha_low > g_bars._bars[1]._ma_dragon_centre
					   && g_bars._bars[0]._ma_dragon_low > OrderOpenPrice()
					   )
					{
						_long_stoploss = OrderOpenPrice();
					}
				}
				if (pre_long_stoploss != _long_stoploss)
				{
   			   if (pre_long_stoploss > 0)
   			   {
   			      if (_long_stoploss > pre_long_stoploss)
   			      {
   					   modify_long_stoploss(_long_stoploss);
      					continue;
   			      }
   			   }
   				else if (_long_stoploss > OrderStopLoss())
					{
						modify_long_stoploss(_long_stoploss);
						continue;
					}
				}
			}
			
			pre_long_stoploss = _long_stoploss;
			if (g_stop_by_ha)    // 根据 ha 计算止损
			{
				double sl = 0;
			   if (g_stop_ha_period > _time_frame)
			   {
         		_bars_1.calc(1, NULL);
         		_bars_2.calc(2, NULL);
			      sl = MathMin(_bars_1._ha_low, _bars_2._ha_low);
			      sl = _bars_1._ha_low;
			   }
			   else
			   {
			      sl = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
			   }
			   if (sl >= OrderOpenPrice())
			   {
			      _long_stoploss = sl;
			   }
			}
			else if (g_stop_by_dragon)        // 根据 ma dragon 计算止损
			{
				//
				// 价格在短期均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_dragon_high
					&& Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_dragon_low);
				}
			}
			else if (g_stop_by_trend)	// 根据 ma trend 计算止损
			{
				//
				// 价格在均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_trend
					&& Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			else if (g_stop_by_profit > 0)
			{
			/*
			   if (Bid > OrderOpenPrice() + MathMax(g_stop_level * g_point, (g_stop_by_profit + g_spread) * g_point))
			   {
					_long_stoploss = Bid - (g_stop_by_profit + g_spread) * g_point;
					_long_stoploss = Bid - (0 + g_spread) * g_point;
			   }
			   if (OrderProfit() > 0)
			   {
					_long_stoploss = Bid - (0 + g_spread) * g_point;
					g_order.close(OP_BUY, true);
			   }
			  */
			}
			if (pre_long_stoploss != _long_stoploss)
			{
			   if (pre_long_stoploss > 0)
			   {
			      if (_long_stoploss > pre_long_stoploss)
			      {
					   modify_long_stoploss(_long_stoploss);
   					continue;
			      }
			   }
				else if (_long_stoploss > OrderStopLoss())
				{
					modify_long_stoploss(_long_stoploss);
					continue;
				}
			}
			
			pre_long_stoploss = _long_stoploss;
			if (g_stop_by_channel)        // 根据 Donchian通道 计算止损
			{
			   double channel_long_low = iLow(g_symbol, g_stop_channel_period, iLowest(g_symbol, g_stop_channel_period, MODE_LOW, g_channel_long_period, 1));
			   if (channel_long_low - g_bars._bars[1]._atr * 0 > OrderOpenPrice() + MathMax(g_stop_level * g_point, (g_spread) * g_point))
			   {
				   _long_stoploss = channel_long_low - g_bars._bars[1]._atr * 0;
				}
			}
			if (pre_long_stoploss != _long_stoploss)
			{
			   if (pre_long_stoploss > 0)
			   {
			      if (_long_stoploss > pre_long_stoploss)
			      {
					   modify_long_stoploss(_long_stoploss);
   					continue;
			      }
			   }
				else if (_long_stoploss > OrderStopLoss())
				{
					modify_long_stoploss(_long_stoploss);
					continue;
				}
			}
		}
	}
}

void stoploss_trend::update_short_stoploss()
{
	if (!g_stop_enable)
	{
		return;
	}
	if (!g_is_new_bar)	// 1根k线只计算1次
	{
		return;
	}
	const int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		return;
	}
	int calc_ticket = 0;
	_update_sl = false;
	for (int i = order_total - 1; i >= 0; --i)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
		{
			continue;
		}
		if (OrderSymbol() != _symbol)
		{
			continue;
		}
		if (0 != _magic && OrderMagicNumber() != _magic)
		{
			continue;
		}
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (OrderType() != OP_SELL)
		{
			continue;
		}
		if (calc_ticket <= 0)
		{
			calc_ticket = OrderTicket();
		}
		else
		{
		   if (_update_sl)
		   {
			   modify_short_stoploss(_short_stoploss);
			}
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			double pre_short_stoploss = _short_stoploss;
			if (OrderStopLoss() > OrderOpenPrice())
			{
				if (g_break_even_channel)
				{
   		      double channel_long_high = iHigh(g_symbol, g_break_even_period, iHighest(g_symbol, g_break_even_period, MODE_HIGH, g_channel_long_period, 1));
				   if (channel_long_high <= OrderOpenPrice())
				   {
						_short_stoploss = OrderOpenPrice();
					}
				}
				if (g_break_even_ha)
				{
					if (g_bars._ha_bottom_reverse_threshold < OrderOpenPrice() && Ask < OrderOpenPrice() - g_stop_level * g_point)
					{
						_short_stoploss = OrderOpenPrice();
					}
				}
				if (g_break_even_3atr)
				{
					if ((Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3))
					{
						_short_stoploss = OrderOpenPrice();
					}
				}
				if (g_break_even_ma)
				{
					if (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 0
					   && g_bars._bars[0]._ha_low < g_bars._bars[0]._ma_dragon_centre
					   && g_bars._bars[1]._ha_low < g_bars._bars[1]._ma_dragon_centre
					   && g_bars._bars[0]._ma_dragon_high < OrderOpenPrice()
					   )
					{
						_short_stoploss = OrderOpenPrice();
					}
				}
				if (pre_short_stoploss != _short_stoploss)
				{
   			   if (pre_short_stoploss > 0)
   			   {
   			      if (_short_stoploss < pre_short_stoploss)
   			      {
					      Print("[debug] modify_short_stoploss() 11 pre_short_stoploss=", pre_short_stoploss, ";_short_stoploss=", _short_stoploss);
      					modify_short_stoploss(_short_stoploss);
      					continue;
   			      }
   			   }
   				else if (_short_stoploss > 0 && _short_stoploss < OrderStopLoss())
					{
					   Print("[debug] modify_short_stoploss() 12 pre_short_stoploss=", pre_short_stoploss, ";_short_stoploss=", _short_stoploss);
						modify_short_stoploss(_short_stoploss);
						continue;
					}
				}
			}
			
			pre_short_stoploss = _short_stoploss;
			if (g_stop_by_ha)       // ha
			{
			   double sl = 0;
			   if (g_stop_ha_period > _time_frame)
			   {
         		_bars_1.calc(1, NULL);
         		_bars_2.calc(2, NULL);
			      sl = MathMax(_bars_1._ha_high, _bars_2._ha_high);
			      sl = _bars_1._ha_high;
			   }
			   else
			   {
			      sl = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[1]._ha_high);
			   }
			   if (sl <= OrderOpenPrice())
			   {
			      _short_stoploss = sl;
			   }
			}
			else if (g_stop_by_dragon)        // ma dragon
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_dragon_low
					&& (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_dragon_high);
				}
			}
			else if (g_stop_by_trend)        // ma trend
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_trend
					&& (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			else if (g_stop_by_profit > 0)
			{
			/*
			   if (Ask < OrderOpenPrice() - MathMax(g_stop_level * g_point, (g_stop_by_profit + g_spread) * g_point))
			   {
					_short_stoploss = Ask + (g_stop_by_profit + g_spread) * g_point;
			   }
			*/
			}
			if (pre_short_stoploss != _short_stoploss)
			{
			   if (pre_short_stoploss > 0)
			   {
			      if (_short_stoploss < pre_short_stoploss)
			      {
   					modify_short_stoploss(_short_stoploss);
   					continue;
			      }
			   }
				else if (_short_stoploss > 0 && _short_stoploss < OrderStopLoss())
				{
					Print("[ERROR] modify_short_stoploss() 2 _short_stoploss=", _short_stoploss);
					modify_short_stoploss(_short_stoploss);
					continue;
				}
			}
			
			pre_short_stoploss = _short_stoploss;
			if (g_stop_by_channel)        // 根据 Donchian通道 计算止损
			{
		      double channel_long_high = iHigh(g_symbol, g_stop_channel_period, iHighest(g_symbol, g_stop_channel_period, MODE_HIGH, g_channel_long_period, 1));
			   if (channel_long_high + g_bars._bars[1]._atr * 0 < OrderOpenPrice() - MathMax(g_stop_level * g_point, (g_spread) * g_point))
			   {
				   _short_stoploss = channel_long_high + g_bars._bars[1]._atr * 0;
				}
			}
			if (pre_short_stoploss != _short_stoploss)
			{
			   if (pre_short_stoploss > 0)
			   {
			      if (_short_stoploss < pre_short_stoploss)
			      {
					   Print("[debug] modify_short_stoploss() 31 pre_short_stoploss=", pre_short_stoploss, ";_short_stoploss=", _short_stoploss);
   					modify_short_stoploss(_short_stoploss);
   					continue;
			      }
			   }
				else if (_short_stoploss > 0 && _short_stoploss < OrderStopLoss())
				{
					Print("[debug] modify_short_stoploss() 32 _short_stoploss=", _short_stoploss);
					modify_short_stoploss(_short_stoploss);
					continue;
				}
			}
		}
	}
}

