// ===========================================================================

extern int g_magic = 0;	// [magic] EA识别标记

extern int i0;// ============================

// ===========================================================================

#include <wq_signal2.mqh>

// ===========================================================================

void init_g_para()
{
	g_symbol = Symbol();
	g_time_frame = Period();
	
	g_tick_value = MarketInfo(g_symbol, MODE_TICKVALUE);
	g_stop_level = MarketInfo(g_symbol, MODE_STOPLEVEL);
	g_spread = MarketInfo(g_symbol, MODE_SPREAD);
	g_digits = (int)MarketInfo(g_symbol, MODE_DIGITS);
	g_point = MarketInfo(g_symbol, MODE_POINT);
	
	g_is_new_bar = false;
	g_time_0 = 0;
	
	g_msg_time = 0;
	g_alert_time = 0;
	
	g_limit_spread = 7.0 * 1.5;
	g_limit_stoploss = 0.0;
	
	if ("UKOIL" == g_symbol || "USOIL" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 28.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAUUSD" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 30.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAGUSD" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("AUDUSD" == g_symbol || "EURUSD" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 6.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDJPY" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 7.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCHF" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 15.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("NZDUSD" == g_symbol || "GBPUSD" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCAD" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 25.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDindex" == g_symbol)
	{
		g_lots_martin_max = MathMin(g_lots_martin_max, 1);
		g_limit_spread = 50.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTCUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 0.01);
		g_lots_martin_max = 0.21;
		g_lots_martin_sum_max = 0.6;			// [下注:martin] 最大总下注数量
		g_limit_spread = 6500.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("ETHUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 0.1);
		g_lots_martin_max = 2.1;
		g_lots_martin_sum_max = 6;			// [下注:martin] 最大总下注数量
		g_limit_spread = 600.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BCHUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 0.1);
		g_lots_martin_max = 2.1;
		g_lots_martin_sum_max = 5;			// [下注:martin] 最大总下注数量
		g_limit_spread = 1200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("LTCUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 0.5);
		g_lots_martin_max = 10.5;
		g_lots_martin_sum_max = 30;			// [下注:martin] 最大总下注数量
		g_limit_spread = 300.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XRPUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 1);
		g_lots_martin_max = 21;
		g_lots_martin_sum_max = 60;			// [下注:martin] 最大总下注数量
		g_limit_spread = 10.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTGUSD" == g_symbol)
	{
		g_lots_martin_min = MathMax(g_lots_martin_min, 1);
		g_lots_martin_max = 21;
		g_lots_martin_sum_max = 60;			// [下注:martin] 最大总下注数量
		g_limit_spread = 200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	
	signal2::strategy_reverse_set();
	signal2::strategy_trend_set();
	signal2::strategy_straddle_set();
	signal2::strategy_scalp_set(g_strategy_scalp);
	signal2::strategy_martin_set(g_strategy_martin);
}

// ===========================================================================

bars_big_period* g_bars_big_period = NULL;
bars* g_bars = NULL;
order2* g_order = NULL;
signal2* g_signal = NULL;
trailing_stop2* g_stop = NULL;

// ===========================================================================

int OnInit()
{
	//ObjectsDeleteAll(0, OBJ_TEXT);
	//MathSrand(LocalTime());
	
	g_test = IsTesting();
	
	init_g_para();
	
	//int p = get_large_time_frame(g_time_frame);
	//p = get_large_time_frame(p);
	//p = MathMin(p, PERIOD_H4);
	g_bars_big_period = new bars_big_period(g_symbol, PERIOD_H4);
	
	g_bars = new bars(g_symbol, g_time_frame);
	g_bars.g_bars_big_period = g_bars_big_period;
	g_bars._filter_volatility = g_signal_filter_volatility;
	
	g_order = new order2(g_magic, g_symbol, g_time_frame);
	g_order.g_bars_big_period = g_bars_big_period;
	g_order.g_bars = g_bars;
	
	g_stop = new trailing_stop2(g_magic, g_symbol, g_time_frame);
	g_stop.g_bars_big_period = g_bars_big_period;
	g_stop.g_bars = g_bars;
	g_stop.g_order = g_order;
	
	g_signal = new signal2(g_symbol, g_time_frame);
	g_signal.g_bars_big_period = g_bars_big_period;
	g_signal.g_bars = g_bars;
	g_signal.g_order = g_order;
	g_signal.g_stop = g_stop;
	
	if (g_debug)
	{
		Print("[DEBUG]g_magic=", g_magic);
		print_mt4_info();
		print_account_info();
		print_market_info();
	}
	return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
	delete g_signal;
	delete g_stop;
	delete g_order;
	delete g_bars;
	delete g_bars_big_period;
}

// ===========================================================================

void OnTick()
{
	//MathSrand(TimeLocal());
	is_new_bar(0);	// 计算是不是新的k线
	g_bars_big_period.calc();
	g_bars.tick_start();
	g_bars.calc(0);
	g_order.get_trade();	// 正在交易的订单
	if (g_order._trade_get_size >= 1) 	// 有成交的订单
	{
		// 跟随止损
		g_stop.update_trailing_stoploss();	// 每个新的k线，设置止损线
			
		//
		// 实时检查止损线，根据理想的止损位置，可以即时平仓。
		// 有时平台的 MODE_STOPLEVEL 太大，需要即时操作。
		//
		//g_stop.check_trailing_stoploss();
	}
	if (g_order._pending_size >= 1)	// 有挂单，就不开仓/加仓
	{
		//Print("[DEBUG] g_order._pending_size=", g_order._pending_size);
		return;
	}
	if (g_enable_long)    // 允许作多
	{
		if ((g_order._trade_get_size < g_lots_martin_order_max)
			|| (OP_SELL == g_order._trade[0]._type))
		{
			if (g_signal.strategy_reverse_bottom_long()
				|| g_signal.strategy_trend_long()
				|| g_signal.strategy_scalp_long()
				|| g_signal.strategy_martin_long()
				)
			{
				g_stop._long_stoploss = g_signal._long_stoploss;    // 更新理想的止损，防止交易平台 MODE_STOPLEVEL 太大。
				g_order.close_all(OP_SELL);
				if (g_strategy_scalp
					|| g_strategy_martin != d3_x
					|| g_strategy_trend != d2_x
					)
				{
					g_order.calc_lots_martin_by_trade();
				}
				else
				{
					g_order.calc_lots_martin_by_history();
					if (g_strategy_reverse_bottom_long || g_strategy_reverse_top_short)
					{
						g_signal.strategy_reverse_set();
					}
				}
				g_order.open(OP_BUY, g_order._calc_lots_tudo, g_signal._long_stoploss, g_signal._signal_type);
			}
		}
	}
	if (g_enable_short)    // 允许作空
	{
		if ((g_order._trade_get_size < g_lots_martin_order_max)
			|| (OP_BUY == g_order._trade[0]._type))
		{
			if (g_signal.strategy_reverse_top_short()
				|| g_signal.strategy_trend_short()
				|| g_signal.strategy_scalp_short()
				|| g_signal.strategy_martin_short()
				)
			{
				g_stop._short_stoploss = g_signal._short_stoploss;
				g_order.close_all(OP_BUY);
				if (g_strategy_scalp
					|| g_strategy_martin != d3_x
					|| g_strategy_trend != d2_x
					)
				{
					g_order.calc_lots_martin_by_trade();
				}
				else
				{
					g_order.calc_lots_martin_by_history();
					if (g_strategy_reverse_bottom_long || g_strategy_reverse_top_short)
					{
						g_signal.strategy_reverse_set();
					}
				}
				g_order.open(OP_SELL, g_order._calc_lots_tudo, g_signal._short_stoploss, g_signal._signal_type);
			}
		}
	}
	if (g_strategy_reverse_bottom_long || g_strategy_reverse_top_short)
	{
		g_signal.strategy_reverse_check();
	}
	if (g_strategy_trend != d2_x)
	{
		g_signal.strategy_trend_check();
	}
	if (g_strategy_scalp)
	{
		g_signal.strategy_scalp_check();
	}
	if (g_strategy_martin != d3_x)
	{
		g_signal.strategy_martin_check();
	}
	
	g_inited = true;
}


// ===========================================================================





