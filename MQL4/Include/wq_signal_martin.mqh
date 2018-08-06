#property strict

extern bool g_enable_open = true;	// [开首单]
extern bool g_enable_long = true;	// [方向] 做多
extern bool g_enable_short = true;	// [方向] 做空
extern double g_gap_atr = 2;		// [下注间隔]__*ATR
extern double g_gap_point = 100;	// [下注间隔]__点数
extern double g_goal_atr = 0.5;		// [盈利目标]__*ATR
extern double g_goal_point = 50;	// [盈利目标]__点数

extern bool g_stoploss_timeframe_enable = false; // [止损周期] 是否启用
extern ENUM_TIMEFRAMES g_stoploss_timeframe = PERIOD_H4;   // [止损周期]

extern bool g_filter_trend = true;				// [方向过滤] 总开关
extern bool g_filter_trend_PERIOD_M5 = true;	// [方向过滤:周期] M5
extern bool g_filter_trend_PERIOD_M15 = true;	// [方向过滤:周期] M15
extern bool g_filter_trend_PERIOD_M30 = true;	// [方向过滤:周期] M30
extern bool g_filter_trend_PERIOD_H1 = true;	// [方向过滤:周期] H1
extern bool g_filter_trend_PERIOD_H4 = true;	// [方向过滤:周期] H4
extern bool g_filter_trend_PERIOD_D1 = true;	// [方向过滤:周期] D1



// ===========================================================================

#include <wq_bars.mqh>
#include <wq_order.mqh>


class signal_martin
{
public:
	signal_martin(string symbol, int time_frame);
	~signal_martin();

	int check_trend();
	bool is_long();
	bool is_short();
	void check();

public:
	string _symbol;
	int _time_frame;

	double _long_stoploss;
	double _short_stoploss;
};

signal_martin* g_signal = NULL;

// ===========================================================================

signal_martin::signal_martin(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;

	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
}

signal_martin::~signal_martin()
{
}

// ===========================================================================

int signal_martin::check_trend()
{
	int ret = 0;
	int ret_D1 = 0;
	int ret_H4 = 0;
	int ret_H1 = 0;
	int ret_M30 = 0;
	int ret_M15 = 0;
	int ret_M5 = 0;
	if (g_filter_trend_PERIOD_D1)
	{
		if (g_bars_D1.check_trend_for_martin(OP_BUY))
		{
			ret_D1 = 1;
		}
		if (g_bars_D1.check_trend_for_martin(OP_SELL))
		{
			ret_D1 = -1;
		}
	}
	if (g_filter_trend_PERIOD_H4)
	{
		if (g_bars_H4.check_trend_for_martin(OP_BUY))
		{
			ret_H4 = 1;
		}
		if (g_bars_H4.check_trend_for_martin(OP_SELL))
		{
			ret_H4 = -1;
		}
	}
	if (g_filter_trend_PERIOD_H1)
	{
		if (g_bars_H1.check_trend_for_martin(OP_BUY))
		{
			ret_H1 = 1;
		}
		if (g_bars_H1.check_trend_for_martin(OP_SELL))
		{
			ret_H1 = -1;
		}
	}
	if (g_filter_trend_PERIOD_M30)
	{
		if (g_bars_M30.check_trend_for_martin(OP_BUY))
		{
			ret_M30 = 1;
		}
		if (g_bars_M30.check_trend_for_martin(OP_SELL))
		{
			ret_M30 = -1;
		}
	}
	if (g_filter_trend_PERIOD_M15)
	{
		if (g_bars_M15.check_trend_for_martin(OP_BUY))
		{
			ret_M15 = 1;
		}
		if (g_bars_M15.check_trend_for_martin(OP_SELL))
		{
			ret_M15 = -1;
		}
	}
	if (g_filter_trend_PERIOD_M5)
	{
		if (g_bars_M5.check_trend_for_martin(OP_BUY))
		{
			ret_M5 = 1;
		}
		if (g_bars_M5.check_trend_for_martin(OP_SELL))
		{
			ret_M5 = -1;
		}
	}
	if (ret == 0)
		ret = g_bars_H4.check_trend();
	if (ret == 0)
		ret = g_bars_H1.check_trend();
	if (ret == 0)
		ret = g_bars_M30.check_trend();
	if (ret == 0)
	{
		//if (ret_D1 == 1 && ret_H4 == 1 && ret_H1 == 1 && ret_M30 == 1 && ret_M15 == 1)
		if (ret_D1 == 1 || ret_H4 == 1 || ret_H1 == 1 || ret_M30 == 1 || ret_M15 == 1 || ret_M5 == 1)
		{
			ret = 1;
		}
		//if (ret_D1 == -1 && ret_H4 == -1 && ret_H1 == -1 && ret_M30 == -1 && ret_M15 == -1)
		if (ret_D1 == -1 || ret_H4 == -1 || ret_H1 == -1 || ret_M30 == -1 || ret_M15 == -1 || ret_M5 == -1)
		{
			ret = -1;
		}
	}
	return ret;
}

bool signal_martin::is_long()
{
	if (!g_enable_long)
	{
		return false;
	}
	if (!g_bars.is_bar_bull())
	{
		return false;
	}
	g_order.get_trade(OP_BUY);
	if (g_order._trade_get_size <= 0)
	{
		if (!g_enable_open)
		{
			return false;
		}
		if (g_filter_trend)
		{
			if (check_trend() == -1)
			{
				return false;
			}
		}
		if (false)
		{
			if (!g_bars_M15.is_ha_long())
			{
				return false;
			}
			if (!g_bars_M30.is_ha_long())
			{
				return false;
			}
			if (!g_bars_H1.is_ha_long())
			{
				return false;
			}
			if (!g_bars_H4.is_ha_long())
			{
				return false;
			}
			if (!g_bars_D1.is_ha_long())
			{
				return false;
			}
		}
		if (g_stoploss_timeframe_enable)
		{
			_long_stoploss = iLow(_symbol, g_stoploss_timeframe, iLowest(_symbol, g_stoploss_timeframe, MODE_LOW, 60, 0));
			if (MathAbs(g_bars_H4._bars_0._ma_trend - g_bars_H4._bars_0._ma_dragon_centre) > g_bars_H4._bars_1._atr * 2)
			{
				_long_stoploss = iLow(_symbol, PERIOD_H1, iLowest(_symbol, PERIOD_H1, MODE_LOW, 60, 0));
			}
		}
		return true;
	}
	else
	{
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		double gap = MathMax(g_bars._bars[1]._atr, g_spread * g_point * 2) * g_gap_atr;
		gap = MathMax(gap, g_gap_point * g_point);
		double f = 1.0;
		if (g_order._trade_get_size >= 6)
		{
			f = 1.3;
		}
		gap = gap * MathPow(f, g_order._trade_get_size - 1);
		if (Bid < g_order._trade[0]._open_price - gap)
		{
			if (g_order._trade_get_size >= 6)
			{
				if (g_order._trade_get_size == 1)
				{
					if (!g_bars_M15.is_ha_long())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size == 2)
				{
					if (!g_bars_M30.is_ha_long())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size == 3)
				{
					if (!g_bars_H1.is_ha_long())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size >= 4)
				{
					if (!g_bars_H4.is_ha_long())
					{
						return false;
					}
				}
			}
			if (g_order._trade_get_size >= 6)
			{
				if (g_bars_H4._bars_0._ha_close < g_bars_H4._bars_0._ma_dragon_low)
				{
					if (!g_bars_H4.is_ha_long())
					{
						return false;
					}
				}
				if (g_bars_H1._bars_0._ha_close < g_bars_H1._bars_0._ma_dragon_low)
				{
					if (!g_bars_H1.is_ha_long())
					{
						return false;
					}
				}
				if (g_bars_M30._bars_0._ha_close < g_bars_M30._bars_0._ma_dragon_low)
				{
					if (!g_bars_M30.is_ha_long())
					{
						return false;
					}
				}
				if (g_bars_M15._bars_0._ha_close < g_bars_M15._bars_0._ma_dragon_low)
				{
					if (!g_bars_M15.is_ha_long())
					{
						return false;
					}
				}
			}
			if (g_stoploss_timeframe_enable)
			{
				_long_stoploss = g_order._trade[0]._stoploss;
			}
			return true;
		}
	}
	return false;
}

bool signal_martin::is_short()
{
	if (!g_enable_short)
	{
		return false;
	}
	if (!g_bars.is_bar_bear())
	{
		return false;
	}
	g_order.get_trade(OP_SELL);
	if (g_order._trade_get_size <= 0)
	{
		if (!g_enable_open)	
		{
			return false;
		}
		if (g_filter_trend)
		{
			if (check_trend() == 1)
			{
				return false;
			}
		}
		if (false)
		{
			if (!g_bars_M15.is_ha_short())
			{
				return false;
			}
			if (!g_bars_M30.is_ha_short())
			{
				return false;
			}
			if (!g_bars_H1.is_ha_short())
			{
				return false;
			}
			if (!g_bars_H4.is_ha_short())
			{
				return false;
			}
			if (!g_bars_D1.is_ha_short())
			{
				return false;
			}
		}
		if (g_stoploss_timeframe_enable)
		{
			_short_stoploss = iHigh(_symbol, g_stoploss_timeframe, iHighest(_symbol, g_stoploss_timeframe, MODE_HIGH, 60, 0));
			if (MathAbs(g_bars_H4._bars_0._ma_trend - g_bars_H4._bars_0._ma_dragon_centre) > g_bars_H4._bars_1._atr * 2)
			{
				_short_stoploss = iHigh(_symbol, PERIOD_H1, iHighest(_symbol, PERIOD_H1, MODE_HIGH, 60, 0));
			}
		}
		return true;
	}
	else
	{
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		double gap = MathMax(g_bars._bars[1]._atr, g_spread * g_point * 2) * g_gap_atr;
		gap = MathMax(gap, g_gap_point * g_point);
		double f = 1.0;
		if (g_order._trade_get_size >= 6)
		{
			f = 1.3;
		}
		gap = gap * MathPow(f, g_order._trade_get_size - 1);
		if (Bid > g_order._trade[0]._open_price + gap)
		{
			if (g_order._trade_get_size >= 6)
			{
				if (g_order._trade_get_size == 1)
				{
					if (!g_bars_M15.is_ha_short())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size == 2)
				{
					if (!g_bars_M30.is_ha_short())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size == 3)
				{
					if (!g_bars_H1.is_ha_short())
					{
						return false;
					}
				}
				else if (g_order._trade_get_size >= 4)
				{
					if (!g_bars_H4.is_ha_short())
					{
						return false;
					}
				}
			}
			if (g_order._trade_get_size >= 6)
			{
				if (g_bars_H4._bars_0._ha_close > g_bars_H4._bars_0._ma_dragon_high)
				{
					if (!g_bars_H4.is_ha_short())
					{
						return false;
					}
				}
				if (g_bars_H1._bars_0._ha_close > g_bars_H1._bars_0._ma_dragon_high)
				{
					if (!g_bars_H1.is_ha_short())
					{
						return false;
					}
				}
				if (g_bars_M30._bars_0._ha_close > g_bars_M30._bars_0._ma_dragon_high)
				{
					if (!g_bars_M30.is_ha_short())
					{
						return false;
					}
				}
				if (g_bars_M15._bars_0._ha_close > g_bars_M15._bars_0._ma_dragon_high)
				{
					if (!g_bars_M15.is_ha_short())
					{
						return false;
					}
				}
			}
			if (g_stoploss_timeframe_enable)
			{
				_short_stoploss = g_order._trade[0]._stoploss;
			}
			return true;
		}
	}
	return false;
}

void signal_martin::check()
{
	g_spread = MarketInfo(g_symbol, MODE_SPREAD);
	double goal = MathMax(g_bars._bars[1]._atr, g_spread * g_point * 2) * g_goal_atr;
	goal = MathMax(goal, (g_spread + g_goal_point) * g_point);
	g_order.get_trade(OP_BUY);
	if (g_order._trade_get_size >= 1)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid > g_order._trade_cost_price + goal
			&& g_bars.is_bar_bear()
			)
		{
			if (!g_bars_D1.check_trend_for_martin(OP_BUY)
				|| !g_bars_H4.check_trend_for_martin(OP_BUY)
				|| !g_bars_H1.check_trend_for_martin(OP_BUY)
				|| !g_bars_M30.check_trend_for_martin(OP_BUY)
				|| !g_bars_M15.check_trend_for_martin(OP_BUY)
				|| !g_bars_M5.check_trend_for_martin(OP_BUY)
				)
			{
				g_order.close_all(OP_BUY);
			}
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars.is_bar_bear()
			&& g_order._trade_get_size >= 4
			)
		{
			g_order.close_all(OP_BUY);
		}
		if (g_order._trade_profit_sum > 0
			&& (g_order._trade_get_size >= 4
				|| (g_bars_H4._bars_0._ha_close < g_bars_H4._bars_0._ma_dragon_low)
				)
			&& (!g_bars_H4.check_trend_for_martin(OP_BUY)
				|| !g_bars_H1.check_trend_for_martin(OP_BUY)
				)
			)
		{
			g_order.close_all(OP_BUY);
		}
	}
	g_order.get_trade(OP_SELL);
	if (g_order._trade_get_size >= 1)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid < g_order._trade_cost_price - goal
			&& g_bars.is_bar_bull()
			)
		{
			if (!g_bars_D1.check_trend_for_martin(OP_SELL)
				|| !g_bars_H4.check_trend_for_martin(OP_SELL)
				|| !g_bars_H1.check_trend_for_martin(OP_SELL)
				|| !g_bars_M30.check_trend_for_martin(OP_SELL)
				|| !g_bars_M15.check_trend_for_martin(OP_SELL)
				|| !g_bars_M5.check_trend_for_martin(OP_SELL)
				)
			{
				g_order.close_all(OP_SELL);
			}
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars.is_bar_bull()
			&& g_order._trade_get_size >= 4
			)
		{
			g_order.close_all(OP_SELL);
		}
		if (g_order._trade_profit_sum > 0
			&& (g_order._trade_get_size >= 4
				|| (g_bars_H4._bars_0._ha_close > g_bars_H4._bars_0._ma_dragon_high)
				)
			&& (!g_bars_H4.check_trend_for_martin(OP_SELL)
				|| !g_bars_H1.check_trend_for_martin(OP_SELL)
				)
			)
		{
			g_order.close_all(OP_SELL);
		}
	}
}
