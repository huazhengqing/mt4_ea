#property strict

// ===============================================================

extern bool g_signal_breakout = false;	// [信号策略] 突破
extern bool g_signal_grid = false;		// [信号策略] 网格

extern bool g_signal_check_trend = true;			// [信号过滤] 趋势方向
extern bool g_signal_check_volatile = false;		// [信号过滤] 波动性
extern bool g_signal_check_by_dragon = false;	// [信号过滤] 价格回调短期均线
extern bool g_signal_check_by_trend = false;    // [信号过滤] 价格回调长期均线
extern double g_signal_check_greater = 0.0;    	// [信号过滤] 价格 > (__)
extern double g_signal_check_less = 0.0;    		// [信号过滤] 价格 < (__)


// ===============================================================

#include <wq_bars.mqh>
#include <wq_order.mqh>

// ===============================================================

class signal2
{
public:
	signal2(int magic, string symbol, int time_frame);
	~signal2();
	
	bool long_condition();
	bool short_condition();
	
	bool long_close_condition();
	bool short_close_condition();
	
	bool check_stoploss_long(double long_stoploss);
	bool check_stoploss_short(double short_stoploss);
	
	void lots_balance();

public:
	int _magic;
	string _symbol;
	int _time_frame;

	bars* g_bars;
	order2* g_order;
	
	double _long_stoploss;
	double _short_stoploss;
	
	double _stoploss_max_atr;
};

// ===============================================================

signal2::signal2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;

	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
	
	_stoploss_max_atr = 10;
}

signal2::~signal2()
{
}

bool signal2::long_condition()
{
	if (g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	if (g_signal_check_trend)
	{
		if (g_bars.check_trend() <= 0)
		{
			return false;
		}
	}
	if (g_signal_check_volatile)
	{
		if (g_bars.check_volatile() <= 0)
		{
			return false;
		}
	}
	if (g_signal_breakout)
	{
		if (g_bars.is_breakout_long(0) == 1)
		{
			_long_stoploss = MathMin(g_bars._bars[0]._ha_low, g_bars._bars[1]._ha_low);
			_long_stoploss = MathMin(_long_stoploss - g_bars._bars[1]._atr, Bid - g_bars._bars[1]._atr * 3);
			return check_stoploss_long(_long_stoploss);
		}
		if (IsTradeAllowed()) 
		{
		//	return false;
		}
	}
	if (g_bars.is_bottom_reverse())
	{
		if (g_signal_check_by_dragon)
		{
			if (g_bars._bottom_low > g_bars._bottom_bar._ma_dragon_high)
			{
				return false;
			}
		}
		if (g_signal_check_by_trend)
		{
			if (g_bars._bottom_low > g_bars._bottom_bar._ma_trend)
			{
				return false;
			}
		}
		if (g_signal_check_greater > 0.0001)
		{
			if (g_bars._bottom_low < g_signal_check_greater) 
			{
				return false;
			}
		}
		if (g_signal_check_less > 0.0001)
		{
			if (g_bars._bottom_low > g_signal_check_less) 
			{
				return false;
			}
		}
		_long_stoploss = MathMin(g_bars._bottom_low - g_bars._bars[1]._atr, Bid - g_bars._bars[1]._atr * 2);
		return check_stoploss_long(_long_stoploss);
	}
	return false;
}

bool signal2::check_stoploss_long(double long_stoploss)
{
	if (Bid - long_stoploss > g_bars._bars[1]._atr * _stoploss_max_atr)
	{
		return false;
	}
	if (g_limit_stoploss > 0)
	{
		if (Bid - long_stoploss > g_limit_stoploss * g_point)
		{
			return false;
		}
	}
	return true;
}

bool signal2::short_condition()
{
	if (g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	if (g_signal_check_trend)
	{
		if (g_bars.check_trend() >= 0)
		{
			return false;
		}
	}
	if (g_signal_check_volatile)
	{
		if (g_bars.check_volatile() <= 0)
		{
			return false;
		}
	}
	if (g_signal_breakout)
	{
		if (g_bars.is_breakout_short(0) == 1)
		{
			_short_stoploss = MathMax(g_bars._bars[0]._ha_high, g_bars._bars[1]._ha_high);
			_short_stoploss = MathMax(_short_stoploss + g_bars._bars[1]._atr, Bid + g_bars._bars[1]._atr * 3);
			return check_stoploss_short(_short_stoploss);
		}
		if (IsTradeAllowed()) 
		{
		//	return false;
		}
	}
	if (g_bars.is_top_reverse())
	{
		if (g_signal_check_by_dragon)
		{
			if (g_bars._top_high < g_bars._top_bar._ma_dragon_low)
			{
				return false;
			}
		}
		if (g_signal_check_by_trend)    
		{
			if (g_bars._top_high < g_bars._top_bar._ma_trend)
			{
				return false;
			}
		}
		if (g_signal_check_greater > 0.0001)    
		{
			if (g_bars._top_high < g_signal_check_greater) 
			{
				return false;
			}
		}
		if (g_signal_check_less > 0.0001)    
		{
			if (g_bars._top_high > g_signal_check_less) 
			{
				return false;
			}
		}
		_short_stoploss = MathMax(g_bars._top_high + g_bars._bars[1]._atr, Bid + g_bars._bars[1]._atr * 2);
		return check_stoploss_short(_short_stoploss);
	}
	return false;
}

bool signal2::check_stoploss_short(double short_stoploss)
{
	if (short_stoploss - Bid > g_bars._bars[1]._atr * _stoploss_max_atr)
	{
		return false;
	}
	if (g_limit_stoploss > 0)
	{
		if (short_stoploss - Ask > g_limit_stoploss * g_point)
		{
			return false;
		}
	}
	//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "][short]short_stoploss=", DoubleToString(short_stoploss, g_digits), ";ha_close=", DoubleToString(g_bars._bars[0]._ha_close, g_digits), ";Bid=", DoubleToString(Bid, g_digits), ";_short_stoploss=", DoubleToString(_short_stoploss, g_digits));
	return true;
}

bool signal2::long_close_condition()
{
	if (g_bars.is_top_reverse())
	{
		return true;
	}
	return false;
}

bool signal2::short_close_condition()
{
	if (g_bars.is_bottom_reverse())
	{
		return true;
	}
	return false;
}

void signal2::lots_balance()
{
	if (!g_lots_balance)
	{
		return;
	}
	if (g_bars.check_trend() >= 1) // bull
	{
		if (g_order.close_all(OP_SELL) > 0)
		{
			g_order.get_trade();
		}
		// bull
		if (g_bars._bars[1].is_ha_bear() 
			&& g_bars._bars[0].is_ha_bull() 
			&& (g_bars._bars[0]._ha_high > g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close > g_bars._bars[1]._ha_high)
			)
		{
			g_order.open(OP_BUY, g_lots_min, g_bars._bars[1]._tutle_long_low);
			//g_order.get_trade();
		}
		// bear
		else if (g_bars._bars[1].is_ha_bull() 
			&& g_bars._bars[0].is_ha_bear() 
			&& (g_bars._bars[0]._ha_low < g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close < g_bars._bars[1]._ha_low)
			)
		{
			if (g_order._trade_get_size >= 1 && OP_BUY == g_order._trade[0]._type)
			{
				double f = 1;
				if (Bid > g_order._trade[0]._open_price)
				{
					f = (Bid - g_order._trade[0]._open_price) / g_bars._bars[1]._atr;
				}
				double lots_todu = g_lots_min * f;
				for (int i = 0; i < g_order._trade_get_size; ++i)
				{
					if (lots_todu > 0)
					{
						double lots = MathMin(g_order._trade[i]._lots, lots_todu);
						bool r = OrderClose(g_order._trade[i]._ticket, lots, Bid, int(g_limit_spread));
						lots_todu = lots_todu - lots;
					}
				}
				//g_order.get_trade();
			}
		}
	}
	else if (g_bars.check_trend() <= -1) // bear
	{
		if (g_order.close_all(OP_BUY) > 0)
		{
			g_order.get_trade();
		}
		// bull
		if (g_bars._bars[1].is_ha_bear() 
			&& g_bars._bars[0].is_ha_bull() 
			&& (g_bars._bars[0]._ha_high > g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close > g_bars._bars[1]._ha_high)
			)
		{
			if (g_order._trade_get_size >= 1 && OP_SELL == g_order._trade[0]._type)
			{
				double f = 1;
				if (Ask < g_order._trade[0]._open_price)
				{
					f = (g_order._trade[0]._open_price - Ask) / g_bars._bars[1]._atr;
				}
				double lots_todu = g_lots_min * f;
				for (int i = 0; i < g_order._trade_get_size; ++i)
				{
					if (lots_todu > 0)
					{
						double lots = MathMin(g_order._trade[i]._lots, lots_todu);
						bool r = OrderClose(g_order._trade[0]._ticket, lots, Ask, int(g_limit_spread));
						lots_todu = lots_todu - lots;
					}
				}
				//g_order.get_trade();
			}
		}
		// bear
		else if (g_bars._bars[1].is_ha_bull() 
			&& g_bars._bars[0].is_ha_bear() 
			&& (g_bars._bars[0]._ha_low < g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close < g_bars._bars[1]._ha_low)
			)
		{
			g_order.open(OP_SELL, g_lots_min, g_bars._bars[1]._tutle_long_low);
			//g_order.get_trade();
		}
	}
}


/*
void signal3::lots_balance()
{
	if (!g_lots_balance)
	{
		return;
	}
	g_order.get_trade();
	g_order.get_history();
	// bull
	if (g_order._trade_get_size >= 1 && (OP_BUY == g_order._trade[0]._type))
	{
		if (g_bars.is_top_reverse()
			&& g_order._trade_profit > 0
			&& (g_order._history_get_size <= 0 || (g_order._history_get_size >= 1 && g_time_0 > g_order._history[0]._close_time + g_time_frame * 60 * 3))
			)
		{
			double f = 1;
			if (Bid > g_order._trade[0]._open_price)
			{
				f = (Bid - g_order._trade[0]._open_price) / g_bars._bars[1]._atr;
			}
			if (f > 1)
			{
				double lots_todu = g_lots_min * f;
				for (int i = 0; i < g_order._trade_get_size; ++i)
				{
					if (lots_todu > 0)
					{
						double lots = MathMin(g_order._trade[i]._lots, lots_todu);
						OrderClose(g_order._trade[i]._ticket, lots, Bid, g_limit_spread);
						lots_todu = lots_todu - lots;
					}
				}
			}
		}
	}
	if (g_order._trade_get_size >= 1 && (OP_SELL == g_order._trade[0]._type))
	{
		if (g_bars.is_bottom_reverse()
			&& g_order._trade_profit > 0
			&& (g_order._history_get_size <= 0 || (g_order._history_get_size >= 1 && g_time_0 > g_order._history[0]._close_time + g_time_frame * 60 * 3))
			)
		{
			double f = 1;
			if (Ask < g_order._trade[0]._open_price)
			{
				f = (g_order._trade[0]._open_price - Ask) / g_bars._bars[1]._atr;
			}
			if (f > 1)
			{
				double lots_todu = g_lots_min * f;
				for (int i = 0; i < g_order._trade_get_size; ++i)
				{
					if (lots_todu > 0)
					{
						double lots = MathMin(g_order._trade[i]._lots, lots_todu);
						OrderClose(g_order._trade[i]._ticket, lots, Ask, g_limit_spread);
						lots_todu = lots_todu - lots;
					}
				}
			}
		}
	}
}
*/

/*
	// bull
	if (//g_bars._bars[1]._ma_dragon_centre < g_bars._bars[0]._ma_dragon_centre
		//&& Bid > g_bars._bars[1]._ma_dragon_high
		g_bars._bars[1]._bolling_main < g_bars._bars[0]._bolling_main
		) 
	{
		//if (g_order.is_cooldown())
		{
			if (g_order.close_all(OP_SELL) > 0)
			{
				g_order.get_trade();
			}
		}
		if (g_order._trade_get_size <= 0)
		{
			g_order.open(OP_BUY, (g_lots_min + g_lots_max) / 2, g_bars._bars[1]._tutle_long_low);
			//g_order.get_trade();
		}
		// bull
		else if ((g_bars._bars[2].is_ha_bear() && g_bars._bars[1].is_ha_bull())
			//|| (g_bars._bars[1].is_ha_bear() && g_bars._bars[0].is_ha_bull() && (g_bars._bars[0]._ha_high > g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close > g_bars._bars[1]._ha_high))
			)
		{
			if (g_order._trade_lots_sum < (g_lots_min + g_lots_max) / 2
				&& g_order.is_cooldown()
				)
			{
				g_order.open(OP_BUY, g_lots_min, g_bars._bars[1]._tutle_long_low);
				//g_order.get_trade();
			}
		}
		// bear
		else if ((g_bars._bars[2].is_ha_bull() && g_bars._bars[1].is_ha_bear())
			//|| (g_bars._bars[1].is_ha_bull() && g_bars._bars[0].is_ha_bear() && (g_bars._bars[0]._ha_low < g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close < g_bars._bars[1]._ha_low))
			)
		{
			if (g_order._trade_get_size >= 1 
				&& OP_BUY == g_order._trade[0]._type 
				&& g_order._trade_profit > 0
				&& (g_order._history_get_size <= 0 || (g_order._history_get_size >= 1 && g_time_0 > g_order._history[0]._close_time + g_time_frame * 60 * 2))
				)
			{
				double f = 1;
				if (Bid > g_order._trade[0]._open_price)
				{
					f = (Bid - g_order._trade[0]._open_price) / g_bars._bars[1]._atr;
				}
				if (f > 1)
				{
					double lots_todu = g_lots_min * f;
					for (int i = 0; i < g_order._trade_get_size; ++i)
					{
						if (lots_todu > 0)
						{
							double lots = MathMin(g_order._trade[i]._lots, lots_todu);
							OrderClose(g_order._trade[i]._ticket, lots, Bid, g_limit_spread);
							lots_todu = lots_todu - lots;
						}
					}
				}
				//g_order.get_trade();
			}
		}
	}
	// bear
	else if (//g_bars._bars[1]._ma_dragon_centre > g_bars._bars[0]._ma_dragon_centre
		//&& Bid < g_bars._bars[1]._ma_dragon_low
		g_bars._bars[1]._bolling_main > g_bars._bars[0]._bolling_main
		)
	{
		//if (g_order.is_cooldown())
		{
			if (g_order.close_all(OP_BUY) > 0)
			{
				g_order.get_trade();
			}
		}
		if (g_order._trade_get_size <= 0)
		{
			g_order.open(OP_SELL, (g_lots_min + g_lots_max) / 2, g_bars._bars[1]._tutle_long_high);
			//g_order.get_trade();
		}
		// bull
		else if (g_bars._bars[1].is_ha_bear() 
			&& g_bars._bars[0].is_ha_bull() 
			//&& (g_bars._bars[0]._ha_high > g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close > g_bars._bars[1]._ha_high)
			)
		{
			if (g_order._trade_get_size >= 1 
				&& OP_SELL == g_order._trade[0]._type 
				&& g_order._trade_profit > 0
				&& (g_order._history_get_size <= 0 || (g_order._history_get_size >= 1 && g_time_0 > g_order._history[0]._close_time + g_time_frame * 60 * 2))
				)
			{
				double f = 1;
				if (Ask < g_order._trade[0]._open_price)
				{
					f = (g_order._trade[0]._open_price - Ask) / g_bars._bars[1]._atr;
				}
				if (f > 1)
				{
					double lots_todu = g_lots_min * f;
					for (int i = 0; i < g_order._trade_get_size; ++i)
					{
						if (lots_todu > 0)
						{
							double lots = MathMin(g_order._trade[i]._lots, lots_todu);
							OrderClose(g_order._trade[0]._ticket, lots, Ask, g_limit_spread);
							lots_todu = lots_todu - lots;
						}
					}
				}
				//g_order.get_trade();
			}
		}
		// bear
		else if (g_bars._bars[1].is_ha_bull() 
			&& g_bars._bars[0].is_ha_bear() 
			//&& (g_bars._bars[0]._ha_low < g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.3 || g_bars._bars[0]._ha_close < g_bars._bars[1]._ha_low)
			)
		{
			if (g_order._trade_lots_sum < (g_lots_min + g_lots_max) / 2
				&& g_order.is_cooldown()
				)
			{
				g_order.open(OP_SELL, g_lots_min, g_bars._bars[1]._tutle_long_low);
				//g_order.get_trade();
			}
		}
	}
*/



