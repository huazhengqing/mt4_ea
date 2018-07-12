#property strict
#include <wq_stoploss.mqh>


// ==========================================================================


class stoploss_martin : public stoploss
{
public:
	stoploss_martin(int magic, string symbol, int time_frame);
	~stoploss_martin();

	void update_long_stoploss();
	void update_short_stoploss();
	
	void update_trailing_stoploss();
};

stoploss_martin* g_stop = NULL;

// ==========================================================================

stoploss_martin::stoploss_martin(int magic, string symbol, int time_frame)
   : stoploss(magic, symbol, time_frame)
{
}

stoploss_martin::~stoploss_martin()
{
}

// ==========================================================================

void stoploss_martin::update_trailing_stoploss()
{
   update_long_stoploss();
   update_short_stoploss();
}

void stoploss_martin::update_long_stoploss()
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
	g_order.get_trade(OP_BUY);
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
			double pre_long_stoploss = _long_stoploss;
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
			   if (sl >= g_order._trade_cost_price + g_bars._bars[1]._atr * 2)
			   {
			      _long_stoploss = sl;
			   }
			}
			if (g_stop_by_dragon)        // 根据 ma dragon 计算止损
			{
				//
				// 价格在短期均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_dragon_high
					&& Bid > g_order._trade_cost_price + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_dragon_low);
				}
			}
			if (g_stop_by_trend)	// 根据 ma trend 计算止损
			{
				//
				// 价格在均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_trend
					&& Bid > g_order._trade_cost_price + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			if (g_stop_by_profit_pip > 0)
			{
/*
			   if (Bid > g_order._trade_cost_price + MathMax(g_stop_level * g_point, (g_stop_by_profit_pip + g_spread) * g_point))
			   {
					_long_stoploss = Bid - (g_stop_by_profit_pip + g_spread) * g_point;
					_long_stoploss = Bid - (0 + g_spread) * g_point;
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
				if (channel_long_low - g_bars._bars[1]._atr * 0 > g_order._trade_cost_price + MathMax(g_stop_level * g_point, (g_spread) * g_point))
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

void stoploss_martin::update_short_stoploss()
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
	g_order.get_trade(OP_SELL);
	int calc_ticket = 0;
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
				if (sl <= g_order._trade_cost_price - g_bars._bars[1]._atr * 2)
				{
					_short_stoploss = sl;
				}
			}
			if (g_stop_by_dragon)        // ma dragon
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_dragon_low
					&& (Bid < g_order._trade_cost_price - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_dragon_high);
				}
			}
			if (g_stop_by_trend)        // ma trend
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_trend
					&& (Bid < g_order._trade_cost_price - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			if (g_stop_by_profit_pip > 0)
			{
/*
			   if (Ask < g_order._trade_cost_price - MathMax(g_stop_level * g_point, (g_stop_by_profit_pip + g_spread) * g_point))
			   {
					_short_stoploss = Ask + (g_stop_by_profit_pip + g_spread) * g_point;
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
					modify_short_stoploss(_short_stoploss);
					continue;
				}
			}
			
			pre_short_stoploss = _short_stoploss;
			if (g_stop_by_channel)        // 根据 Donchian通道 计算止损
			{
				double channel_long_high = iHigh(g_symbol, g_stop_channel_period, iHighest(g_symbol, g_stop_channel_period, MODE_HIGH, g_channel_long_period, 1));
				if (channel_long_high + g_bars._bars[1]._atr * 0 < g_order._trade_cost_price - MathMax(g_stop_level * g_point, (g_spread) * g_point))
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
						modify_short_stoploss(_short_stoploss);
						continue;
					}
				}
				else if (_short_stoploss > 0 && _short_stoploss < OrderStopLoss())
				{
					modify_short_stoploss(_short_stoploss);
					continue;
				}
			}
		}
	}
}
