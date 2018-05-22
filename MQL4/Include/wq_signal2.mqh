#property strict

// ===============================================================

extern bool g_signal_ha_reverse = true;	// [信号:策略] ha 反转
extern bool g_signal_ma_reverse = true;	// [信号:策略] ma 反转
extern bool g_signal_breakout = false;		// [信号:策略] 突破通道
//extern bool g_signal_grid = false;			// [信号:策略] 网格

extern bool g_signal_check_trend = true;			// [信号:过滤] 方向
extern bool g_signal_check_volatile = true;		// [信号:过滤] 波动性
extern bool g_signal_check_by_dragon = false;	// [信号:过滤] 价格回调短期均线
extern bool g_signal_check_by_trend = false;    // [信号:过滤] 价格回调长期均线
extern double g_signal_check_greater = 0.0;    	// [信号:过滤] 价格 > (__)
extern double g_signal_check_less = 0.0;    		// [信号:过滤] 价格 < (__)


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

// ===============================================================

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
			_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_dragon_low);
			_long_stoploss = MathMin(_long_stoploss - g_bars._bars[1]._atr, Bid - g_bars._bars[1]._atr * 3);
			_long_stoploss = MathMax(_long_stoploss, g_bars._bars[0]._tutle_long_low - g_bars._bars[1]._atr);
			return check_stoploss_long(_long_stoploss);
		}
		if (IsTradeAllowed()) 
		{
		//	return false;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (g_bars.is_ha_bottom_reverse())
		{
			if (g_signal_check_by_dragon)
			{
				if (g_bars._ha_bottom_low > g_bars._ha_bottom_bar._ma_dragon_high)
				{
					return false;
				}
			}
			if (g_signal_check_by_trend)
			{
				if (g_bars._ha_bottom_low > g_bars._ha_bottom_bar._ma_trend)
				{
					return false;
				}
			}
			if (g_signal_check_greater > 0.0001)
			{
				if (g_bars._ha_bottom_low < g_signal_check_greater) 
				{
					return false;
				}
			}
			if (g_signal_check_less > 0.0001)
			{
				if (g_bars._ha_bottom_low > g_signal_check_less) 
				{
					return false;
				}
			}
			_long_stoploss = MathMin(g_bars._ha_bottom_low, g_bars._bars[1]._ma_dragon_low);
			_long_stoploss = MathMin(_long_stoploss - g_bars._bars[1]._atr, Bid - g_bars._bars[1]._atr * 2);
			_long_stoploss = MathMax(_long_stoploss, g_bars._bars[0]._tutle_long_low - g_bars._bars[1]._atr);
			return check_stoploss_long(_long_stoploss);
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_bottom_reverse())
		{
			_long_stoploss = MathMin(g_bars._ma_bottom_low, g_bars._bars[1]._ma_dragon_low);
			_long_stoploss = MathMin(_long_stoploss - g_bars._bars[1]._atr, Bid - g_bars._bars[1]._atr * 2);
			_long_stoploss = MathMax(_long_stoploss, g_bars._bars[0]._tutle_long_low - g_bars._bars[1]._atr);
			return check_stoploss_long(_long_stoploss);
		}
	}
	return false;
}

bool signal2::check_stoploss_long(double long_stoploss)
{
	//return true;
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

// ===============================================================

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
			_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_dragon_high);
			_short_stoploss = MathMax(_short_stoploss + g_bars._bars[1]._atr, Bid + g_bars._bars[1]._atr * 3);
			_short_stoploss = MathMin(_short_stoploss, g_bars._bars[0]._tutle_long_high + g_bars._bars[1]._atr);
			return check_stoploss_short(_short_stoploss);
		}
		if (IsTradeAllowed()) 
		{
		//	return false;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (g_bars.is_ha_top_reverse())
		{
			if (g_signal_check_by_dragon)
			{
				if (g_bars._ha_top_high < g_bars._ha_top_bar._ma_dragon_low)
				{
					return false;
				}
			}
			if (g_signal_check_by_trend)    
			{
				if (g_bars._ha_top_high < g_bars._ha_top_bar._ma_trend)
				{
					return false;
				}
			}
			if (g_signal_check_greater > 0.0001)    
			{
				if (g_bars._ha_top_high < g_signal_check_greater) 
				{
					return false;
				}
			}
			if (g_signal_check_less > 0.0001)    
			{
				if (g_bars._ha_top_high > g_signal_check_less) 
				{
					return false;
				}
			}
			_short_stoploss = MathMax(g_bars._ha_top_high, g_bars._bars[1]._ma_dragon_high);
			_short_stoploss = MathMax(_short_stoploss + g_bars._bars[1]._atr, Bid + g_bars._bars[1]._atr * 2);
			_short_stoploss = MathMin(_short_stoploss, g_bars._bars[0]._tutle_long_high + g_bars._bars[1]._atr);
			return check_stoploss_short(_short_stoploss);
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_top_reverse())
		{
			_short_stoploss = MathMax(g_bars._ma_top_high, g_bars._bars[1]._ma_dragon_high);
			_short_stoploss = MathMax(_short_stoploss + g_bars._bars[1]._atr, Bid + g_bars._bars[1]._atr * 2);
			_short_stoploss = MathMin(_short_stoploss, g_bars._bars[0]._tutle_long_high + g_bars._bars[1]._atr);
			return check_stoploss_short(_short_stoploss);
		}
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

// ===============================================================

bool signal2::long_close_condition()
{
	if (g_bars.is_ha_top_reverse())
	{
		return true;
	}
	return false;
}

bool signal2::short_close_condition()
{
	if (g_bars.is_ha_bottom_reverse())
	{
		return true;
	}
	return false;
}

// ===============================================================

void signal2::lots_balance()
{
	if (!g_lots_balance)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		return;
	}
	if (iTime(_symbol, _time_frame, 0) < g_order._trade[0]._open_time + _time_frame * 60 * 15)	// 过几个k线才继续操作
	{
		return;
	}
	g_order.get_history();
	if (g_order._history_get_size >= 1 && iTime(_symbol, _time_frame, 0) < g_order._history[0]._close_time + _time_frame * 60 * 15)	// 过几个k线才继续操作
	{
		return;
	}
	if (OP_BUY == g_order._trade[0]._type)
	{
		double last_price = g_order._trade[0]._open_price;
		if (g_order._history_get_size >= 1 && g_order._history[0]._close_time > g_order._trade[0]._open_time)
		{
			last_price = MathMax(g_order._trade[0]._open_price, g_order._history[0]._close_price);
		}
		if (g_order._trade_lots_sum > g_lots_balance_reduce
			&& long_close_condition()
			)
		{
			double lots = MathMin(g_order._trade[0]._lots, g_lots_balance_unit);
			bool r = OrderClose(g_order._trade[0]._ticket, lots, Bid, int(g_limit_spread));
		}
		if (g_order._trade_lots_sum < g_lots_balance_sum_max
			&& long_condition()
			//&& MathAbs(Bid - g_order._trade[0]._open_price) > g_bars._bars[1]._atr * 1.5
			)
		{
			g_order.open(OP_BUY, g_lots_balance_unit, _long_stoploss);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		double last_price = g_order._trade[0]._open_price;
		if (g_order._history_get_size >= 1 && g_order._history[0]._close_time > g_order._trade[0]._open_time)
		{
			last_price = MathMin(g_order._trade[0]._open_price, g_order._history[0]._close_price);
		}
		if (g_order._trade_lots_sum > g_lots_balance_reduce
			&& short_close_condition()
			)
		{
			double lots = MathMin(g_order._trade[0]._lots, g_lots_balance_unit);
			bool r = OrderClose(g_order._trade[0]._ticket, lots, Ask, int(g_limit_spread));
		}
		if (g_order._trade_lots_sum < g_lots_balance_sum_max
			&& short_condition()
			//&& MathAbs(Bid - g_order._trade[0]._open_price) > g_bars._bars[1]._atr * 1.5
			)
		{
			g_order.open(OP_SELL, g_lots_balance_unit, _short_stoploss);
		}
	}
}

// ===============================================================


