
// ===========================================================================

extern const bool g_enable_long = true; 	// [下单方向] 做多
extern const bool g_enable_short = true; 	// [下单方向] 做空

extern int g_order_max = 1;	// [订单数量] 最大订单数量


// ===========================================================================

#include <wq_signal2.mqh>
#include <wq_trailing_stop2.mqh>
#include <wq_order.mqh>

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
	
	g_magic = get_magic(g_symbol, g_time_frame);
	
	g_ea_just_init = true;
	
	g_is_new_bar = false;
	g_time_0 = 0;
	
	g_msg_time = 0;
	g_alert_time = 0;
	
	if (g_order_max > 50)
	{
		g_order_max = 50;
	}
	
	if ("UKOIL" == g_symbol || "USOIL" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 28.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAUUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 30.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XAGUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 1);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("AUDUSD" == g_symbol || "EURUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 6.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDJPY" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 7.0 * 2;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCHF" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 15.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("NZDUSD" == g_symbol || "GBPUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 20.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDCAD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 25.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("USDindex" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_limit_spread = 50.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.01);
		g_lots_max = 0.21;
		g_limit_spread = 6500.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("ETHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_limit_spread = 600.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BCHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_limit_spread = 1200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("LTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.5);
		g_lots_max = 10.5;
		g_limit_spread = 300.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("XRPUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_limit_spread = 10.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else if ("BTGUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_limit_spread = 200.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
	else
	{
		g_limit_spread = 7.0 * 1.5;
		g_limit_stoploss = 0.0;
	}
}

// ===========================================================================

bars* g_bars = NULL;
order2* g_order = NULL;
signal2* g_signal = NULL;
trailing_stop2* g_stop = NULL;

// ===========================================================================

int OnInit()
{
	//ObjectsDeleteAll(0, OBJ_TEXT);
	//MathSrand(LocalTime());
	
	init_g_para();
	g_magic = 0;
	
	if (false)
	{
		g_ma_dragon_period = 34;	// 34  
		g_ma_trend_period = 89;	// 89  
		g_lots_martin = true;
		//g_stop_by_trend = true;
		g_lots_balance = true;
	}
	
	

	g_bars = new bars(g_symbol, g_time_frame);
	
	g_order = new order2(g_magic, g_symbol, g_time_frame);
	g_order.g_bars = g_bars;
	
	g_signal = new signal2(g_magic, g_symbol, g_time_frame);
	g_signal.g_bars = g_bars;
	g_signal.g_order = g_order;
	
	g_stop = new trailing_stop2(g_magic, g_symbol, g_time_frame);
	g_stop.g_bars = g_bars;
	g_stop.g_order = g_order;
	
	print_mt4_info();
	print_account_info();
	print_market_info();

	return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
	delete g_stop;
	delete g_signal;
	delete g_order;
	delete g_bars;
}

// ===========================================================================

void OnTick()
{
	//MathSrand(TimeLocal());
	is_new_bar();	// 计算是不是新的k线
	g_bars.tick_start();
	g_bars.calc();
	g_order.get_trade();	// 正在交易的订单
	if (g_order._trade_get_size >= 1) 	// 有成交的订单
	{
		// 跟随止损
		g_stop.set_trailing_stoploss();	// 每个新的k线，设置止损线
			
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
	if (g_order_max > g_order._trade_get_size + 1)
	{
		g_order_max = g_order._trade_get_size + 1;	// 1次只加1单
	}
	if (g_enable_long)    // 允许作多
	{
		if ((g_order._trade_get_size < g_order_max)
			|| (OP_SELL == g_order._trade[0]._type))
		{
			if (g_signal.long_condition())
			{
				g_stop._long_stoploss = g_signal._long_stoploss;    // 更新理想的止损，防止交易平台 MODE_STOPLEVEL 太大。
				g_order.close_all(OP_SELL);
				g_order.calc_lots();
				g_order.open(OP_BUY, g_order._lots_tudo, g_signal._long_stoploss);

				//Print("[DEBUG][", g_symbol, "][", get_time_frame_str(g_time_frame), "][BUY]", lots, ":", DoubleToString(Ask, g_digits), ";", DoubleToString(stoploss, g_digits));
				//Print("[DEBUG][", g_symbol, "][", get_time_frame_str(g_time_frame), "][BUY]", g_bars._bars[0]._ha_open, ";", g_bars._bars[0]._ha_close, ";");
			}
		}
	}
	if (g_enable_short)    // 允许作空
	{
		if ((g_order._trade_get_size < g_order_max)
			|| (OP_BUY == g_order._trade[0]._type))
		{
			if (g_signal.short_condition())
			{
				g_stop._short_stoploss = g_signal._short_stoploss;
				g_order.close_all(OP_BUY);
				g_order.calc_lots();
				g_order.open(OP_SELL, g_order._lots_tudo, g_signal._short_stoploss);
			}
		}
	}
	g_signal.lots_balance();
	g_ea_just_init = false;
}


// ===========================================================================





