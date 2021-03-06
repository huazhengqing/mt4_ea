extern int g_magic = 0;	// [magic] EA识别标记


#include <wq_signal_trend.mqh>
#include <wq_lots_trend.mqh>
#include <wq_stoploss_trend.mqh>


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
	
	g_limit_spread = 15.0 * 1.5;
	g_limit_stoploss = 0.0;
	
	
	if ("UKOIL" == g_symbol || "USOIL" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 28.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAUUSD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 30.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAGUSD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("GBPJPY" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 25.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("GBPAUD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 25.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("AUDUSD" == g_symbol || "EURUSD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 6.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDJPY" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 7.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCHF" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 15.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("NZDUSD" == g_symbol || "GBPUSD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCAD" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 25.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDindex" == g_symbol)
	{
		//g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 50.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.01);
		g_lots_max = 0.21;
		g_lots_sum_max = 0.6;			// [下注:martin] 最大总下注数量
		g_limit_spread = 6500.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("ETHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_lots_sum_max = 6;			// [下注:martin] 最大总下注数量
		g_limit_spread = 600.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BCHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_lots_sum_max = 5;			// [下注:martin] 最大总下注数量
		g_limit_spread = 1200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("LTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.5);
		g_lots_max = 10.5;
		g_lots_sum_max = 30;			// [下注:martin] 最大总下注数量
		g_limit_spread = 300.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XRPUSD" == g_symbol)
	{
		//g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_lots_sum_max = 60;			// [下注:martin] 最大总下注数量
		g_limit_spread = 10.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTGUSD" == g_symbol)
	{
		//g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_lots_sum_max = 60;			// [下注:martin] 最大总下注数量
		g_limit_spread = 200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
}

void check_para()
{
	if (g_time_frame >= PERIOD_H1)
	{
		g_break_even_period = PERIOD_H4;
	}
	
	if (g_time_frame >= PERIOD_M15)
	{
		g_filter_trend_PERIOD_M15 = false;
	}
	if (g_time_frame >= PERIOD_M30)
	{
		g_filter_trend_PERIOD_M30 = false;
	}
	if (g_time_frame >= PERIOD_H1)
	{
		g_filter_trend_PERIOD_H1 = false;
	}
	if (g_time_frame >= PERIOD_H4)
	{
		g_filter_trend_PERIOD_H4 = false;
	}
}

int OnInit()
{
	g_lots_profit_f = MathMax(g_lots_profit_f, 1.01);
	init_g_para();
	check_para();
	
	g_bars_D1 = new bars_big_period(g_symbol, PERIOD_D1);
	g_bars_H4 = new bars_big_period(g_symbol, PERIOD_H4);
	g_bars_H1 = new bars_big_period(g_symbol, PERIOD_H1);
	g_bars_M30 = new bars_big_period(g_symbol, PERIOD_M30);
	g_bars_M15 = new bars_big_period(g_symbol, PERIOD_M15);
	
	g_bars = new bars(g_symbol, g_time_frame);
	g_order = new order2(g_magic, g_symbol, g_time_frame);
	g_lots = new lots_trend();
	g_stop = new stoploss_trend(g_magic, g_symbol, g_time_frame);
	g_signal = new signal_trend(g_symbol, g_time_frame);
	
	if (true)
	{
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
	delete g_lots;
	delete g_order;
	delete g_bars;
	delete g_bars_D1;
	delete g_bars_H4;
	delete g_bars_H1;
	delete g_bars_M30;
	delete g_bars_M15;
}

// ===========================================================================

void OnTick()
{
/*
	if (!IsTradeAllowed())	// 不交易，只提示
	{
		g_signal_channel_breakout = true;	// [信号] 通道突破
		g_signal_ha_reverse = true;			// [信号] HA 反转
		g_signal_ma_reverse = true;			// [信号] 快均线反转
		g_signal_wave_breakout = true;		// [信号] 波浪突破
	}
*/
	is_new_bar(0);	// 计算是不是新的k线
	if (g_bars_D1 != NULL)
	{
		g_bars_D1.calc();
	}
	if (g_bars_H4 != NULL)
	{
		g_bars_H4.calc();
	}
	if (g_bars_H1 != NULL)
	{
		g_bars_H1.calc();
	}
	if (g_bars_M30 != NULL)
	{
		g_bars_M30.calc();
	}
	if (g_bars_M15 != NULL)
	{
		g_bars_M15.calc();
	}
	g_bars.tick_start();
	g_bars.calc(0);
	g_stop.update_trailing_stoploss();
	if (g_signal.is_long())
	{
		g_order.close_all(OP_SELL);
		g_stop._long_stoploss = g_signal._long_stoploss;
		g_lots.calc_lots_martin_by_history();
		g_order.open(OP_BUY, g_lots._calc_lots_tudo, g_signal._long_stoploss, g_signal._signal_type);
	}
	if (g_signal.is_short())
	{
		g_order.close_all(OP_BUY);
		g_stop._short_stoploss = g_signal._short_stoploss;
		g_lots.calc_lots_martin_by_history();
		g_order.open(OP_SELL, g_lots._calc_lots_tudo, g_signal._short_stoploss, g_signal._signal_type);
	}
	g_signal.check();
	g_inited = true;
}
