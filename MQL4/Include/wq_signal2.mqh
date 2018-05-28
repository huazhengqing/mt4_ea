#property strict

// ===============================================================

bool g_enable_long = false;
bool g_enable_short = false;

extern bool g_strategy_reverse_bottom_long = false;	// [策略1:抄底] 做多
extern bool g_strategy_reverse_top_short = false;		// [策略1:抄顶] 做空

extern int i1;// =========================================

extern bool g_strategy_trend_long = false;		// [策略2:单边] 做多
extern bool g_strategy_trend_short = false;		// [策略2:单边] 做空
extern double g_strategy_trend_gap = 2;			// [策略2:单边] 下注间隔__*ATR
extern double g_strategy_trend_stop_long = 0;	// [策略2:单边] 做多止损
extern double g_strategy_trend_stop_short = 0;	// [策略2:单边] 做空止损

extern int i2;// =========================================

extern bool g_strategy_straddle = true;		// [策略3:跨式（双向)下注] 

extern int i3;// =========================================

extern bool g_strategy_scalp = false;				// [策略4:盘整] 剥头皮
extern double g_strategy_scalp_gap = 2;			// [策略4:盘整] 下注间隔__*ATR
extern double g_strategy_scalp_goal = 0.5;		// [策略4:盘整] 目标__*ATR
extern double g_strategy_scalp_stop = 20;			// [策略4:盘整] 止损__*ATR
extern double g_strategy_scalp_stop_long = 0;	// [策略4:盘整] 做多止损
extern double g_strategy_scalp_stop_short = 0;	// [策略4:盘整] 做空止损

extern int i4;// =========================================

extern bool g_strategy_martin = false;				// [策略5:martin] Martingale
extern int g_strategy_martin_direction = 0;		// [策略5:martin] 方向[0:自动|1:buy|-1:sell]
extern double g_strategy_martin_gap = 2;			// [策略5:martin] 下注间隔__*ATR
extern double g_strategy_martin_goal = 0.5;		// [策略5:martin] 目标__*ATR
extern double g_strategy_martin_stop = 20;		// [策略5:martin] 止损__*ATR
extern double g_strategy_martin_stop_long = 0;	// [策略5:martin] 做多止损
extern double g_strategy_martin_stop_short = 0;	// [策略5:martin] 做空止损

extern int i5;// =========================================

extern bool g_signal_ha_reverse = true;			// [信号] HA 反转
extern bool g_signal_ma_reverse = true;			// [信号] 快均线反转
extern bool g_signal_wave_breakout = false;		// [信号] 波浪突破
extern bool g_signal_channel_breakout = false;	// [信号] 通道突破

extern int i6;// =========================================

extern bool g_signal_filter_trend = true;			// [信号:过滤] 方向
extern bool g_signal_filter_sideways = true;		// [信号:过滤] 横盘
extern bool g_signal_filter_volatility = false;	// [信号:过滤] 波动性

extern int i7;// =========================================

extern bool g_signal_ha_filter_by_dragon = false;	// [信号HA:过滤] 价格回调快均线
extern bool g_signal_ha_filter_by_trend = false;   // [信号HA:过滤] 价格回调慢均线
extern double g_signal_ha_filter_greater = 0.0;    // [信号HA:过滤] 价格 > (__)
extern double g_signal_ha_filter_less = 0.0;    	// [信号HA:过滤] 价格 < (__)

extern int i8;// =========================================


// ===============================================================

#include <wq_bars.mqh>
#include <wq_order.mqh>
#include <wq_trailing_stop2.mqh>

// ===============================================================

class signal2
{
public:
	signal2(string symbol, int time_frame);
	~signal2();
	
	bool is_ha_bottom_reverse();
	bool is_ha_top_reverse();
	
	bool strategy_reverse_bottom_long();
	bool strategy_reverse_top_short();
	void strategy_reverse_check();
	static void strategy_reverse_set();
	
	bool strategy_trend_long();
	bool strategy_trend_short();
	void strategy_trend_check();
	static void strategy_trend_set();
	
	bool strategy_straddle_long();
	bool strategy_straddle_short();
	void strategy_straddle_check();
	static void strategy_straddle_set();
	
	bool strategy_scalp_long();
	bool strategy_scalp_short();
	void strategy_scalp_check();
	static void strategy_scalp_set(bool enable_scalp);
	
	bool strategy_martin_long();
	bool strategy_martin_short();
	void strategy_martin_check();
	static void strategy_martin_set(bool enable_martin);

public:
	string _symbol;
	int _time_frame;

	bars_big_period* g_bars_big_period;
	bars* g_bars;
	order2* g_order;
	trailing_stop2* g_stop;
	
	double _long_stoploss;
	double _short_stoploss;
	
	int _strategy_martin_direction;
};

// ===============================================================

signal2::signal2(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;

	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
	
	_strategy_martin_direction = 0;
}

signal2::~signal2()
{
}

// ===============================================================

bool signal2::is_ha_bottom_reverse()
{
	if (!g_signal_ha_reverse)
	{
		return false;
	}
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
			_long_stoploss = MathMin(g_bars._ha_bottom_low, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr;
			return true;
		}
	}
	return false;
}

bool signal2::is_ha_top_reverse()
{
	if (!g_signal_ha_reverse)
	{
		return false;
	}
	if (g_bars.is_ha_top_reverse())
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
			_short_stoploss = MathMax(g_bars._ha_top_high, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr;
			return true;
		}
	}
	return false;
}

// ===============================================================

bool signal2::strategy_reverse_bottom_long()
{
	if (!g_strategy_reverse_bottom_long && !g_strategy_straddle)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	if (g_signal_filter_trend)
	{
		if (g_bars.check_trend() <= 0)
		{
			return false;
		}
	}
	if (g_signal_filter_sideways)
	{
		if (g_bars.is_sideways())
		{
			return false;
		}
	}
	if (g_signal_filter_volatility)
	{
		if (g_bars.check_volatility() <= 0)
		{
			return false;
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_bottom_reverse())
		{
			_long_stoploss = MathMin(g_bars._ma_bottom_low, g_bars._bars[1]._ma_dragon_low) - g_bars._bars[1]._atr;
			return true;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (is_ha_bottom_reverse())
		{
			return true;
		}
	}
	if (g_signal_wave_breakout)
	{
		if (g_bars.is_wave_breakout_long(0))
		{
			_long_stoploss = MathMin(g_bars._wave_long_low, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr;
			return true;
		}
	}
	if (g_signal_channel_breakout)
	{
		if (g_bars.is_breakout_long(0) == 1)
		{
			_long_stoploss = MathMin(g_bars._bars[0]._bolling_main, g_bars._bars[1]._ha_low) - g_bars._bars[1]._atr;
			return true;
		}
	}
	return false;
}

bool signal2::strategy_reverse_top_short()
{
	if (!g_strategy_reverse_top_short && !g_strategy_straddle)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	if (g_signal_filter_trend)
	{
		if (g_bars.check_trend() >= 0)
		{
			return false;
		}
	}
	if (g_signal_filter_sideways)
	{
		if (g_bars.is_sideways())
		{
			return false;
		}
	}
	if (g_signal_filter_volatility)
	{
		if (g_bars.check_volatility() <= 0)
		{
			return false;
		}
	}
	if (g_signal_ma_reverse)
	{
		if (g_bars.is_ma_top_reverse())
		{
			_short_stoploss = MathMax(g_bars._ma_top_high, g_bars._bars[1]._ma_dragon_high) + g_bars._bars[1]._atr;
			return true;
		}
	}
	if (g_signal_ha_reverse)
	{
		if (is_ha_top_reverse())
		{
			return true;
		}
	}
	if (g_signal_wave_breakout)
	{
		if (g_bars.is_wave_breakout_short(0))
		{
			_short_stoploss = MathMax(g_bars._wave_short_high, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr;
			return true;
		}
	}
	if (g_signal_channel_breakout)
	{
		if (g_bars.is_breakout_short(0) == 1)
		{
			_short_stoploss = MathMax(g_bars._bars[0]._bolling_main, g_bars._bars[1]._ha_high) + g_bars._bars[1]._atr;
			return true;
		}
	}
	return false;
}

void signal2::strategy_reverse_check()
{
	if (!g_strategy_reverse_bottom_long && !g_strategy_reverse_top_short && !g_strategy_straddle)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		strategy_reverse_set();
		return;
	}
	if (OP_BUY == g_order._trade[0]._type)
	{
		double p = MathMax(g_order._trade_cost_price, g_order._trade[0]._open_price);
		if (!g_stop_enable
			&& g_order._trade_profit_sum > 0
			&& g_order._trade[0]._profile > 0
			&& Bid > p + g_bars._bars[1]._atr * 3
			&& g_bars._bars[1]._channel_long_low > p + g_bars._bars[1]._atr * 1
			&& 1 == g_bars._breakout_trend
			)
		{
			g_stop_enable = true;
			g_stop_by_channel = true;
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		double p = MathMin(g_order._trade_cost_price, g_order._trade[0]._open_price);
		if (!g_stop_enable
			&& g_order._trade_profit_sum > 0 
			&& g_order._trade[0]._profile > 0
			&& Bid < p - g_bars._bars[1]._atr * 3
			&& g_bars._bars[1]._channel_long_high < p - g_bars._bars[1]._atr * 1
			&& -1 == g_bars._breakout_trend
			)
		{
			g_stop_enable = true;
			g_stop_by_channel = true;
		}
	}
}

void signal2::strategy_reverse_set()
{
	if (g_strategy_reverse_bottom_long)
	{
		g_enable_long = true;
		g_enable_short = false;
		//g_signal_ha_reverse = true;
		g_signal_ma_reverse = true;
		//g_signal_wave_breakout = true;
		//g_signal_channel_breakout = true;
		g_signal_filter_trend = true;
		//g_signal_filter_sideways = true;
		//g_signal_filter_volatility = true;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 1);
		g_stop_enable = false;
		
		g_strategy_scalp = false;				// [策略4:盘整] 剥头皮
		g_strategy_martin = false;				// [策略5:martin] Martingale
	}
	if (g_strategy_reverse_top_short)
	{
		g_enable_long = false;
		g_enable_short = true;
		//g_signal_ha_reverse = true;
		g_signal_ma_reverse = true;
		//g_signal_wave_breakout = true;
		//g_signal_channel_breakout = true;
		g_signal_filter_trend = true;
		//g_signal_filter_sideways = true;
		//g_signal_filter_volatility = true;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 1);
		g_stop_enable = false;
		
		g_strategy_scalp = false;				// [策略4:盘整] 剥头皮
		g_strategy_martin = false;				// [策略5:martin] Martingale
	}
}

// ===============================================================

bool signal2::strategy_trend_long()
{
	if (!g_strategy_trend_long)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		if (g_bars.is_ma_bottom_reverse()
			|| is_ha_bottom_reverse()
			|| g_bars.is_wave_breakout_long(0)
			|| (g_bars.is_breakout_long(0) == 1)
			)
		{
			if (g_strategy_trend_stop_long > 0)
			{
				_long_stoploss = g_strategy_trend_stop_long;
			}
			else
			{
				_long_stoploss = MathMin(g_bars._bars[1]._channel_long_low, g_bars_big_period._bars_0._channel_long_low) - g_bars._bars[1]._atr;
			}
			return true;
		}
	}
	else
	{
		double gap = MathMax(g_bars._bars[1]._atr * g_strategy_trend_gap, g_spread * g_point * 2);
		if (g_order._trade_get_size >= 2)
		{
		//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
		}
		if (Bid < g_order._trade[0]._open_price - gap)
		{
			if (g_bars.is_ma_bottom_reverse()
				|| is_ha_bottom_reverse()
				|| g_bars.is_wave_breakout_long(0)
				|| (g_bars.is_breakout_long(0) == 1)
				)
			{
				_long_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

bool signal2::strategy_trend_short()
{
	if (!g_strategy_trend_short)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		if (g_bars.is_ma_top_reverse()
			|| is_ha_top_reverse()
			|| g_bars.is_wave_breakout_short(0)
			|| (g_bars.is_breakout_short(0) == 1)
			)
		{
			if (g_strategy_trend_stop_short > 0)
			{
				_short_stoploss = g_strategy_trend_stop_short;
			}
			else
			{
				_short_stoploss = MathMax(g_bars._bars[1]._channel_long_high, g_bars_big_period._bars_0._channel_long_high) + g_bars._bars[1]._atr;
			}
			return true;
		}
	}
	else
	{
		double gap = MathMax(g_bars._bars[1]._atr * g_strategy_trend_gap, g_spread * g_point * 2);
		if (g_order._trade_get_size >= 2)
		{
		//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
		}
		if (Bid > g_order._trade[0]._open_price + gap)
		{
			if (g_bars.is_ma_top_reverse()
				|| is_ha_top_reverse()
				|| g_bars.is_wave_breakout_short(0)
				|| (g_bars.is_breakout_short(0) == 1)
				)
			{
				_short_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

void signal2::strategy_trend_check()
{
	if (!g_strategy_trend_long && !g_strategy_trend_short)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		strategy_trend_set();
		return;
	}
	double goal = MathMax(g_bars._bars[1]._atr * g_lots_martin_goal, g_spread * g_point * 2);
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (g_lots_martin && g_lots_martin_goal > 0.1)
		{
			if (g_bars._bars[0].is_ha_bear()
				&& g_order._trade_profit_sum > 0
				&& Bid > g_order._trade_cost_price + goal
				)
			{
				g_order.close_all(OP_BUY);
			}
		}
		else if (g_order._trade_profit_sum > 0
			&& Bid > g_order._trade_cost_price + g_bars._bars[1]._atr * 3
			&& g_bars._bars[1]._channel_long_low > g_order._trade_cost_price + g_bars._bars[1]._atr * 1
			&& 1 == g_bars._breakout_trend
			)
		{
			g_stop_enable = true;
			g_stop_by_channel = true;
		}
		if (g_strategy_trend_stop_long > 0
			&& !g_inited
			)
		{
			g_stop.update_all_long_stop(g_strategy_trend_stop_long);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (g_lots_martin && g_lots_martin_goal > 0.1)
		{
			if (g_bars._bars[0].is_ha_bull()
				&& g_order._trade_profit_sum > 0
				&& Bid < g_order._trade_cost_price - goal
				)
			{
				g_order.close_all(OP_SELL);
			}
		}
		else if (g_order._trade_profit_sum > 0
			&& Bid < g_order._trade_cost_price - g_bars._bars[1]._atr * 3
			&& g_bars._bars[1]._channel_long_high < g_order._trade_cost_price - g_bars._bars[1]._atr * 1
			&& -1 == g_bars._breakout_trend
			)
		{
			g_stop_enable = true;
			g_stop_by_channel = true;
		}
		if (g_strategy_trend_stop_short > 0
			&& !g_inited
			)
		{
			g_stop.update_all_short_stop(g_strategy_trend_stop_short);
		}
	}
}

void signal2::strategy_trend_set()
{
	if (g_strategy_trend_long)
	{
		g_enable_long = true;
		g_enable_short = false;
		//g_signal_ha_reverse = true;
		g_signal_ma_reverse = true;
		//g_signal_wave_breakout = true;
		//g_signal_channel_breakout = true;
		g_signal_filter_trend = false;
		g_signal_filter_sideways = false;
		g_signal_filter_volatility = false;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 10);
		g_lots_martin_order_max = MathMax(g_lots_martin_order_max, 4);
		g_stop_enable = false;
		
		g_strategy_straddle = false;		// [策略3:跨式（双向)下注]
		g_strategy_straddle = false;		// [策略3:跨式（双向)下注] 
		g_strategy_scalp = false;				// [策略4:盘整] 剥头皮 
	}
	if (g_strategy_trend_short)
	{
		g_enable_long = false;
		g_enable_short = true;
		//g_signal_ha_reverse = true;
		g_signal_ma_reverse = true;
		//g_signal_wave_breakout = true;
		//g_signal_channel_breakout = true;
		g_signal_filter_trend = false;
		g_signal_filter_sideways = false;
		g_signal_filter_volatility = false;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 10);
		g_lots_martin_order_max = MathMax(g_lots_martin_order_max, 4);
		g_stop_enable = false;
		
		g_strategy_straddle = false;		// [策略3:跨式（双向)下注] 
		g_strategy_straddle = false;		// [策略3:跨式（双向)下注] 
		g_strategy_scalp = false;				// [策略4:盘整] 剥头皮
	}
}

// ===============================================================

bool signal2::strategy_straddle_long()
{
	if (!g_strategy_straddle)
	{
		return false;
	}
	return strategy_reverse_bottom_long();
}

bool signal2::strategy_straddle_short()
{
	if (!g_strategy_straddle)
	{
		return false;
	}
	return strategy_reverse_top_short();
}

void signal2::strategy_straddle_check()
{
	if (!g_strategy_straddle)
	{
		return;
	}
	strategy_reverse_check();
}

void signal2::strategy_straddle_set()
{
	if (g_strategy_straddle)
	{
		g_enable_long = true;
		g_enable_short = true;
		//g_signal_ha_reverse = true;
		g_signal_ma_reverse = true;
		//g_signal_wave_breakout = true;
		//g_signal_channel_breakout = true;
		g_signal_filter_trend = true;
		//g_signal_filter_sideways = true;
		//g_signal_filter_volatility = true;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 1);
		g_stop_enable = false;
		
		g_strategy_scalp = false;				// [策略4:盘整] 剥头皮
		g_strategy_martin = false;				// [策略5:martin] Martingale
	}
}

// ===============================================================

bool signal2::strategy_scalp_long()
{
	if (!g_strategy_scalp)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size >= 1 && (OP_SELL == g_order._trade[0]._type))
	{
		return false;
	}
	if (Bid < g_bars._bars[0]._bolling_main - g_bars._bars[1]._atr * 0.5
		&& Bid < g_bars._bars[0]._bolling_main - g_bars._bars[1].bolling_width() * 0.25
		&& Bid < g_bars._bars[0]._ma_dragon_low
		&& g_bars._bars[0]._kdj_main < 30
		)
	{
		if (g_order._trade_get_size <= 0)
		{
			if (g_strategy_scalp_stop_long > 0.0001)
			{
				_long_stoploss = g_strategy_scalp_stop_long;
			}
			else
			{
				_long_stoploss = MathMin(g_bars_big_period._bars_0._channel_long_low, g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * g_strategy_scalp_stop);
			}
			return true;
		}
		else
		{
			double gap = MathMax(g_bars._bars[1]._atr * g_strategy_scalp_gap, g_spread * g_point * g_strategy_scalp_gap);
			if (g_order._trade_get_size >= 2)
			{
			//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
			}
			if (Bid < g_order._trade[0]._open_price - gap)
			{
				_long_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

bool signal2::strategy_scalp_short()
{
	if (!g_strategy_scalp)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size >= 1 && (OP_BUY == g_order._trade[0]._type))
	{
		return false;
	}
	if (Bid > g_bars._bars[0]._bolling_main + g_bars._bars[1]._atr * 0.5
		&& Bid > g_bars._bars[0]._bolling_main + g_bars._bars[1].bolling_width() * 0.25
		&& Bid > g_bars._bars[0]._ma_dragon_high
		&& g_bars._bars[0]._kdj_main > 70
		)
	{
		if (g_order._trade_get_size <= 0)
		{
			if (g_strategy_scalp_stop_short > 0.0001)
			{
				_short_stoploss = g_strategy_scalp_stop_short;
			}
			else
			{
				_short_stoploss = MathMax(g_bars_big_period._bars_0._channel_long_high, g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * g_strategy_scalp_stop);
			}
			return true;
		}
		else
		{
			double gap = MathMax(g_bars._bars[1]._atr * g_strategy_scalp_gap, g_spread * g_point * g_strategy_scalp_gap);
			if (g_order._trade_get_size >= 2)
			{
			//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
			}
			if (Bid > g_order._trade[0]._open_price + gap)
			{
				_short_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

void signal2::strategy_scalp_check()
{
	if (!g_strategy_scalp)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		if (g_bars.check_trend() <= -1
			&& g_bars_big_period.check_trend() <= -1
			&& g_bars._bars[0]._low < g_bars_big_period._bars_0._bolling_low
			)
		{
			strategy_scalp_set(false);
		}
		if (g_bars.check_trend() >= 1
			&& g_bars_big_period.check_trend() >= 1
			&& g_bars._bars[0]._high > g_bars_big_period._bars_0._bolling_up
			)
		{
			strategy_scalp_set(false);
		}
		return;
	}
	double goal = MathMax(g_bars._bars[1]._atr * g_strategy_scalp_goal, g_spread * g_point * 2);
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid > g_order._trade_cost_price + goal
			&& g_bars._bars[0].is_ha_bear()
			)
		{
			g_order.close_all(OP_BUY);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars._bars[0].is_ha_bear()
			&& g_order._trade_lots_sum > g_lots_martin_min
			)
		{
			g_order.close_all(OP_BUY);
		}
		if (g_strategy_scalp_stop_long > 0
			&& !g_inited
			)
		{
			g_stop.update_all_long_stop(g_strategy_scalp_stop_long);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid < g_order._trade_cost_price - goal
			&& g_bars._bars[0].is_ha_bull()
			)
		{
			g_order.close_all(OP_SELL);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars._bars[0].is_ha_bull()
			&& g_order._trade_lots_sum > g_lots_martin_min
			)
		{
			g_order.close_all(OP_SELL);
		}
		if (g_strategy_scalp_stop_short > 0
			&& !g_inited
			)
		{
			g_stop.update_all_short_stop(g_strategy_scalp_stop_short);
		}
	}
}

void signal2::strategy_scalp_set(bool enable_scalp)
{
	if (enable_scalp)
	{
		g_strategy_scalp = true;
		g_enable_long = true;
		g_enable_short = true;
		g_signal_filter_trend = false;
		g_signal_filter_sideways = false;
		g_signal_filter_volatility = false;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 10);
		g_lots_martin_order_max = MathMax(g_lots_martin_order_max, 4);
		g_lots_martin = true;
		g_stop_enable = false;
	}
	else
	{
		g_strategy_scalp = false;
	}
}


// ===============================================================

bool signal2::strategy_martin_long()
{
	if (!g_strategy_martin)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size >= 1 && (OP_SELL == g_order._trade[0]._type))
	{
		return false;
	}
	bool d = true;
	if (g_order._trade_get_size <= 0)
	{
		d = (_strategy_martin_direction >= 1);
	}
	if (d)
	{
		if (g_order._trade_get_size <= 0)
		{
			if (g_strategy_martin_stop_long > 0.0001)
			{
				_long_stoploss = g_strategy_martin_stop_long;
			}
			else
			{
				_long_stoploss = MathMin(g_bars_big_period._bars_0._channel_long_low, g_bars._bars[0]._channel_long_low - g_bars._bars[1]._atr * g_strategy_martin_stop);
			}
			return true;
		}
		else
		{
			double gap = MathMax(g_bars._bars[1]._atr * g_strategy_martin_gap, g_spread * g_point * g_strategy_martin_gap);
			if (g_order._trade_get_size >= 2)
			{
			//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
			}
			if (Bid < g_order._trade[0]._open_price - gap)
			{
				_long_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

bool signal2::strategy_martin_short()
{
	if (!g_strategy_martin)
	{
		return false;
	}
	if (!g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	g_order.get_trade();
	if (g_order._trade_get_size >= 1 && (OP_BUY == g_order._trade[0]._type))
	{
		return false;
	}
	bool d = true;
	if (g_order._trade_get_size <= 0)
	{
		d = (_strategy_martin_direction <= -1);
	}
	if (d)
	{
		if (g_order._trade_get_size <= 0)
		{
			if (g_strategy_martin_stop_short > 0.0001)
			{
				_short_stoploss = g_strategy_martin_stop_short;
			}
			else
			{
				_short_stoploss = MathMax(g_bars_big_period._bars_0._channel_long_high, g_bars._bars[0]._channel_long_high + g_bars._bars[1]._atr * g_strategy_martin_stop);
			}
			return true;
		}
		else
		{
			double gap = MathMax(g_bars._bars[1]._atr * g_strategy_martin_gap, g_spread * g_point * g_strategy_martin_gap);
			if (g_order._trade_get_size >= 2)
			{
			//	gap = MathMax(gap, MathAbs(g_order._trade[1]._open_price - g_order._trade[0]._open_price));
			}
			if (Bid > g_order._trade[0]._open_price + gap)
			{
				_short_stoploss = g_order._trade[0]._stoploss;
				return true;
			}
		}
	}
	return false;
}

void signal2::strategy_martin_check()
{
	if (!g_strategy_martin)
	{
		return;
	}
	_strategy_martin_direction = g_strategy_martin_direction;
	if (0 == _strategy_martin_direction)
	{
		_strategy_martin_direction = g_bars_big_period.check_trend();
		if (0 == _strategy_martin_direction)
		{
			_strategy_martin_direction = g_bars.check_trend();
			if (0 == _strategy_martin_direction)
			{
				_strategy_martin_direction = _strategy_martin_direction;
			}
		}
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		return;
	}
	double goal = MathMax(g_bars._bars[1]._atr * g_strategy_martin_goal, g_spread * g_point * 2);
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid > g_order._trade_cost_price + goal
			&& g_bars._bars[0].is_ha_bear()
			)
		{
			g_order.close_all(OP_BUY);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars._bars[0].is_ha_bear()
			&& g_order._trade_lots_sum > g_lots_martin_min
			)
		{
			g_order.close_all(OP_BUY);
		}
		if (_strategy_martin_direction <= -1)
		{
			if (g_order._trade_profit_sum > 0)
			{
				g_order.close_all(OP_BUY);
			}
			else if (g_bars.check_trend() <= -1
				&& g_bars_big_period.check_trend() <= -1
				&& g_bars._bars[0]._low < g_bars_big_period._bars_0._bolling_low
				)
			{
				g_order.close_all(OP_BUY);
			}
		}
		if (g_strategy_martin_stop_long > 0
			&& !g_inited
			)
		{
			g_stop.update_all_long_stop(g_strategy_martin_stop_long);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (g_order._trade_profit_sum > 0
			&& Bid < g_order._trade_cost_price - goal
			&& g_bars._bars[0].is_ha_bull()
			)
		{
			g_order.close_all(OP_SELL);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars._bars[0].is_ha_bull()
			&& g_order._trade_lots_sum > g_lots_martin_min
			)
		{
			g_order.close_all(OP_SELL);
		}
		if (_strategy_martin_direction >= 1)
		{
			if (g_order._trade_profit_sum > 0)
			{
				g_order.close_all(OP_SELL);
			}
			else if (g_bars.check_trend() >= 1
				&& g_bars_big_period.check_trend() >= 1
				&& g_bars._bars[0]._high > g_bars_big_period._bars_0._bolling_up
				)
			{
				g_order.close_all(OP_SELL);
			}
		}
		if (g_strategy_martin_stop_short > 0
			&& !g_inited
			)
		{
			g_stop.update_all_short_stop(g_strategy_martin_stop_short);
		}
	}
}

void signal2::strategy_martin_set(bool enable_martin)
{
	if (enable_martin)
	{
		g_strategy_martin = true;
		g_enable_long = true;
		g_enable_short = true;
		g_signal_filter_trend = true;
		g_signal_filter_sideways = false;
		g_signal_filter_volatility = false;
		g_lots_martin_order_max = MathMin(g_lots_martin_order_max, 10);
		g_lots_martin_order_max = MathMax(g_lots_martin_order_max, 4);
		g_lots_martin = true;
		g_stop_enable = false;
	}
	else
	{
		g_strategy_martin = false;
	}
}

// ===============================================================

/*

void signal2::check_break_even()
{
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		return;
	}
	if (g_order._trade[0]._lots <= g_lots_martin_min * 4)
	{
		return;
	}
	g_order.get_history();
	g_order.get_cost();
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (Bid > g_order._cost_price + g_bars._bars[1]._atr * 0
			&& long_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Bid);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (Ask < g_order._cost_price - g_bars._bars[1]._atr * 0
			&& short_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Ask);
		}
	}
}

void signal2::check_martin()
{
	if (!g_lots_martin)
	{
		return;
	}
	if (g_lots_martin_goal <= 0.01)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		return;
	}
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (Bid > g_order._trade[0]._open_price + g_bars._bars[1]._atr * g_lots_martin_goal
			&& long_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Bid);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (Ask < g_order._trade[0]._open_price - g_bars._bars[1]._atr * g_lots_martin_goal
			&& short_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Ask);
		}
	}
}

void signal2::check_grid()
{
	if (!g_lots_grid)
	{
		return;
	}
	g_order.get_trade();
	if (g_order._trade_get_size <= 0)
	{
		return;
	}
	g_order.get_history();
	g_order.get_cost();
	if (OP_BUY == g_order._trade[0]._type)
	{
		if (Bid > g_order._cost_price + g_bars._bars[1]._atr * g_lots_grid_goal
			&& long_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Bid);
		}
	}
	else if (OP_SELL == g_order._trade[0]._type)
	{
		if (Ask < g_order._cost_price - g_bars._bars[1]._atr * g_lots_grid_goal
			&& short_close_condition()
			)
		{
			g_order.close(g_order._trade[0]._ticket, g_order._trade[0]._lots, Ask);
		}
	}
}

// ===============================================================
/*
void signal2::check_balance()
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
*/
// ===============================================================



