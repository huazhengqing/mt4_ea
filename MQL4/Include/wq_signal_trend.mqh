#property strict

extern bool g_enable_long = true;		// [方向] 做多
extern bool g_enable_short = true;		// [方向] 做空
extern bool g_enable_switch = false;		// [方向] 自动反转开仓

extern bool g_signal_channel_breakout = true;	// [信号] 通道突破
extern bool g_signal_ha_reverse = false;		// [信号] HA 反转
extern bool g_signal_ma_reverse = false;		// [信号] 快均线反转
extern bool g_signal_wave_breakout = false;		// [信号] 波浪突破

extern bool g_filter_trend = true;				// [方向过滤] 总开关
extern bool g_filter_trend_PERIOD_M15 = true;	// [方向过滤:周期] M15
extern bool g_filter_trend_PERIOD_M30 = true;	// [方向过滤:周期] M30
extern bool g_filter_trend_PERIOD_H1 = true;	// [方向过滤:周期] H1
extern bool g_filter_trend_PERIOD_H4 = true;	// [方向过滤:周期] H4
extern bool g_filter_trend_PERIOD_D1 = true;	// [方向过滤:周期] D1

extern bool g_signal_ha_filter_by_dragon = false;	// [信号HA:过滤] 价格回调快均线
extern bool g_signal_ha_filter_by_trend = false;	// [信号HA:过滤] 价格回调慢均线
extern double g_signal_ha_filter_greater = 0.0;		// [信号HA:过滤] 价格 > (__)
extern double g_signal_ha_filter_less = 0.0;		// [信号HA:过滤] 价格 < (__)

// ===========================================================================

#include <wq_bars.mqh>
#include <wq_order.mqh>


class signal_trend
{
public:
	signal_trend(string symbol, int time_frame);
	~signal_trend();

	bool is_long();
	bool is_short();
	void check();
	
private:
	bool is_ha_long();
	bool is_ha_short();
	
public:
	string _symbol;
	int _time_frame;

	double _long_stoploss;
	double _short_stoploss;

	string _signal_type;
	
	int _tf_big_count;
};

signal_trend* g_signal = NULL;

// ===========================================================================

signal_trend::signal_trend(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
	
	_tf_big_count = 0;
}

signal_trend::~signal_trend()
{
}

// ===========================================================================

bool signal_trend::is_ha_long()
{
	if (g_bars.is_ha_bottom_reverse())
	{
		bool f = true;
		if (g_signal_ha_filter_by_dragon)
		{
			if (g_bars._ha_bottom_low > g_bars._bars[0]._ma_dragon_centre)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_by_trend)
		{
			if (g_bars._ha_bottom_low > g_bars._bars[0]._ma_trend)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_greater > 0)
		{
			if (g_bars._ha_bottom_low < g_signal_ha_filter_greater)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_less > 0)
		{
			if (g_bars._ha_bottom_low > g_signal_ha_filter_less)
			{
				f = false;
			}
		}
		if (f)
		{
			_long_stoploss = MathMin(g_bars._ha_bottom_low, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr * 1;
			_signal_type = "[ha反转]";
			return true;
		}
	}
	return false;
}

bool signal_trend::is_ha_short()
{
	if (g_bars.is_ha_top_reverse())
	{
		bool f = true;
		if (g_signal_ha_filter_by_dragon)
		{
			if (g_bars._ha_top_high < g_bars._bars[0]._ma_dragon_centre)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_by_trend)
		{
			if (g_bars._ha_top_high < g_bars._bars[0]._ma_trend)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_greater > 0)
		{
			if (g_bars._ha_top_high < g_signal_ha_filter_greater)
			{
				f = false;
			}
		}
		if (g_signal_ha_filter_less > 0)
		{
			if (g_bars._ha_top_high > g_signal_ha_filter_less)
			{
				f = false;
			}
		}
		if (f)
		{
			_short_stoploss = MathMax(g_bars._ha_top_high, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr * 1;
			_signal_type = "[ha反转]";
			return true;
		}
	}
	return false;
}

// ===========================================================================

bool signal_trend::is_long()
{
	_signal_type = "";
	if (!g_enable_long)
	{
		return false;
	}
	if (!g_enable_switch)
	{
		g_order.get_trade(OP_SELL);
		if (g_order._trade_get_size >= 1)
		{
			return false;
		}
	}
	if (!g_bars.is_bar_bull())
	{
		return false;
	}
	g_order.get_trade(OP_BUY);
	if (g_order._trade_get_size >= g_lots_order_max)
	{
		return false;
	}
	if (g_filter_trend)
	{
		if (g_filter_trend_PERIOD_D1)
		{
			if (g_bars_D1.check_trend_for_trend() != 1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_H4)
		{
			if (g_bars_H4.check_trend_for_trend() != 1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_H1)
		{
			if (g_bars_H1.check_trend_for_trend() != 1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_M30)
		{
			if (g_bars_M30.check_trend_for_trend() != 1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_M15)
		{
			if (g_bars_M15.check_trend_for_trend() != 1)
			{
				return false;
			}
		}
	}
	if (g_signal_channel_breakout)
	{
		if (g_bars.is_breakout_long(0) == 1)
		{
			//_long_stoploss = MathMin(g_bars._bars[0]._bolling_main, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr * 1.5;
			_long_stoploss = g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * 1.5;
			if (MathAbs(Ask - _long_stoploss) > g_bars_H4._bars_1._atr * 10)
			{
				return false;
			}
			_signal_type = "[通道突破]";
			return true;
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_bottom_reverse())
		{
			//_long_stoploss = MathMin(g_bars._ma_bottom_low, g_bars._bars[1]._ma_dragon_low) - g_bars._bars[1]._atr * 1;
			_long_stoploss = g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * 1.5;
			_signal_type = "[ma反转]";
			return true;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (is_ha_long())
		{
			_long_stoploss = g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * 1;
			_signal_type = "[ha反转]";
			return true;
		}
	}
	if (g_signal_wave_breakout)
	{
		if (g_bars.is_wave_breakout_long(0))
		{
			//_long_stoploss = MathMin(g_bars._wave_long_low, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr * 1;
			_long_stoploss = g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * 1.5;
			_signal_type = "[wave突破]";
			return true;
		}
	}
	return false;
}

bool signal_trend::is_short()
{
	_signal_type = "";
	if (!g_enable_short)
	{
		return false;
	}
	if (!g_enable_switch)
	{
		g_order.get_trade(OP_BUY);
		if (g_order._trade_get_size >= 1)
		{
			return false;
		}
	}
	if (!g_bars.is_bar_bear())
	{
		return false;
	}
	g_order.get_trade(OP_SELL);
	if (g_order._trade_get_size >= g_lots_order_max)
	{
		return false;
	}
	if (g_filter_trend)
	{
		if (g_filter_trend_PERIOD_D1)
		{
			if (g_bars_D1.check_trend_for_trend() != -1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_H4)
		{
			if (g_bars_H4.check_trend_for_trend() != -1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_H1)
		{
			if (g_bars_H1.check_trend_for_trend() != -1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_M30)
		{
			if (g_bars_M30.check_trend_for_trend() != -1)
			{
				return false;
			}
		}
		if (g_filter_trend_PERIOD_M15)
		{
			if (g_bars_M15.check_trend_for_trend() != -1)
			{
				return false;
			}
		}
	}
	if (g_signal_channel_breakout)
	{
		if (g_bars.is_breakout_short(0) == 1)
		{
			//_short_stoploss = MathMax(g_bars._bars[0]._bolling_main, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr * 1.5;
			_short_stoploss = g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * 1.5;
			if (MathAbs(Bid - _short_stoploss) > g_bars_H4._bars_1._atr * 10)
			{
				return false;
			}
			_signal_type = "[通道突破]";
			return true;
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_top_reverse())
		{
			//_short_stoploss = MathMax(g_bars._ma_top_high, g_bars._bars[1]._ma_dragon_high) + g_bars._bars[1]._atr * 1;
			_short_stoploss = g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * 1.5;
			_signal_type = "[ma反转]";
			return true;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (is_ha_short())
		{
			_short_stoploss = g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * 1;
			_signal_type = "[ha反转]";
			return true;
		}
	}
	if (g_signal_wave_breakout)
	{
		if (g_bars.is_wave_breakout_short(0))
		{
			//_short_stoploss = MathMax(g_bars._wave_short_high, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr * 1;
			_short_stoploss = g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * 1.5;
			_signal_type = "[wave突破]";
			return true;
		}
	}
	return false;
}

void signal_trend::check()
{
	g_order.get_trade(OP_BUY);
	if (g_order._trade_get_size >= 1)
	{
	   if (!g_stop_enable)
	   {
			double p = MathMax(g_order._trade_cost_price, g_order._trade[0]._open_price);
			double channel_long_low = iLow(g_symbol, g_stop_channel_period, iLowest(g_symbol, g_stop_channel_period, MODE_LOW, g_channel_long_period, 0));
			if (g_break_even_channel)
			{
				channel_long_low = iLow(g_symbol, g_break_even_period, iLowest(g_symbol, g_break_even_period, MODE_LOW, g_channel_long_period, 0));
			}
			if (!g_stop_enable
				&& g_order._trade_profit_sum > 0
				&& g_order._trade[0]._profit > 0
				&& Bid > p + g_bars._bars[1]._atr * 3
				&& channel_long_low > p + g_bars._bars[1]._atr * 0.5
				&& 1 == g_bars._breakout_trend
				)
			{
				g_stop_enable = true;
			}
		}
	}
	g_order.get_trade(OP_SELL);
	if (g_order._trade_get_size >= 1)
	{
	   if (!g_stop_enable)
	   {
			double p = MathMin(g_order._trade_cost_price, g_order._trade[0]._open_price);
			double channel_long_high = iHigh(g_symbol, g_stop_channel_period, iHighest(g_symbol, g_stop_channel_period, MODE_HIGH, g_channel_long_period, 0));
			if (g_break_even_channel)
			{
				channel_long_high = iHigh(g_symbol, g_break_even_period, iHighest(g_symbol, g_break_even_period, MODE_HIGH, g_channel_long_period, 0));
			}
			if (!g_stop_enable
				&& g_order._trade_profit_sum > 0 
				&& g_order._trade[0]._profit > 0
				&& Bid < p - g_bars._bars[1]._atr * 3
				&& channel_long_high > 0
				&& channel_long_high < p - g_bars._bars[1]._atr * 0.5
				&& -1 == g_bars._breakout_trend
				)
			{
				g_stop_enable = true;
			}
		}
	}
}
