#property strict

extern bool g_enable_open = true;	// [开首单]
extern bool g_enable_long = true;	// [方向] 做多
extern bool g_enable_short = true;	// [方向] 做空
extern double g_gap_atr = 2;        // [下注间隔]__*ATR
extern double g_gap_point = 200;    // [下注间隔]__点数
extern double g_goal_atr = 0.5;     // [盈利目标]__*ATR
extern double g_goal_point = 600;   // [盈利目标]__点数
extern ENUM_TIMEFRAMES g_stoploss_timeframe = PERIOD_H4;   // [止损周期]
extern bool g_filter_trend = true;                             // [方向过滤]
extern ENUM_TIMEFRAMES g_filter_trend_timeframe = PERIOD_H4;   // [方向过滤] 周期


// ===========================================================================

#include <wq_bars.mqh>
#include <wq_order.mqh>


class signal_martin
{
public:
	signal_martin(string symbol, int time_frame);
	~signal_martin();

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
   	   if (!g_bars_big.check_trend_for_martin(OP_BUY))
      	{
         	return false;
      	}
      	int tf = get_large_time_frame(_time_frame);
         double ma_0 = iMA(_symbol, tf, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 0);
         double ma_1 = iMA(_symbol, tf, g_ma_trend_period, 0, g_ma_mode, PRICE_TYPICAL, 1);
         if (ma_1 > ma_0)
         {
            return false;
         }
   	}
      _long_stoploss = iLow(_symbol, g_stoploss_timeframe, iLowest(_symbol, g_stoploss_timeframe, MODE_LOW, 60, 0));
		return true;
	}
	else
	{
	   g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		double gap = MathMax(g_bars._bars[1]._atr, g_spread * g_point * 2) * g_gap_atr;
		gap = MathMax(gap, g_gap_point * g_point);
	   if (g_order._trade_get_size >= 5)
	   {
	      gap = gap * 2;
	   }
	   if (g_order._trade_get_size >= 10)
	   {
	      gap = gap * 3;
	   }
	   if (g_order._trade_get_size >= 15)
	   {
	      gap = gap * 4;
	   }
		if (Bid < g_order._trade[0]._open_price - gap)
		{
         _long_stoploss = g_order._trade[0]._stoploss;
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
			if (!g_bars_big.check_trend_for_martin(OP_SELL))
			{
				return false;
			}
			int tf = get_large_time_frame(_time_frame);
			double ma_0 = iMA(_symbol, tf, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 0);
			double ma_1 = iMA(_symbol, tf, g_ma_trend_period, 0, g_ma_mode, PRICE_TYPICAL, 1);
			if (ma_1 < ma_0)
			{
				return false;
			}
		}
		_short_stoploss = iHigh(_symbol, g_stoploss_timeframe, iHighest(_symbol, g_stoploss_timeframe, MODE_HIGH, 60, 0));
		return true;
	}
	else
	{
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		double gap = MathMax(g_bars._bars[1]._atr, g_spread * g_point * 2) * g_gap_atr;
		gap = MathMax(gap, g_gap_point * g_point);
		if (g_order._trade_get_size >= 5)
		{
			gap = gap * 2;
		}
		if (g_order._trade_get_size >= 10)
		{
			gap = gap * 3;
		}
		if (g_order._trade_get_size >= 15)
		{
			gap = gap * 4;
		}
		if (Bid > g_order._trade[0]._open_price + gap)
		{
			_short_stoploss = g_order._trade[0]._stoploss;
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
			g_order.close_all(OP_BUY);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars.is_bar_bear()
			&& g_order._trade_lots_sum > g_lots_min * 30
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
			g_order.close_all(OP_SELL);
		}
		if (g_order._trade_profit_sum > 0
			&& g_bars.is_bar_bull()
			&& g_order._trade_lots_sum > g_lots_min * 30
			)
		{
			g_order.close_all(OP_SELL);
		}
	}
}
