#include <wq_util.mqh>
#include <wq_trailing_stop2.mqh>
#include <wq_signal2.mqh>
#include <wq_order.mqh>



// ===========================================================================

order2* g_order = NULL;
signal2* g_signal = NULL;
trailing_stop2* g_trailing_stop = NULL;


// ===========================================================================

int OnInit()
{
	//ObjectsDeleteAll(0, OBJ_TEXT);
	
	//MathSrand(LocalTime());
	
	
	g_symbol = Symbol();
	g_time_frame = Period();
	
	//int m = get_magic(g_magic_number, g_symbol, g_time_frame);
	int m = 0;

	init_g_para(g_symbol, g_time_frame);
	
	g_order = new order2(m, g_symbol, g_time_frame);
	g_signal = new signal2(m, g_symbol, g_time_frame);
	g_trailing_stop = new trailing_stop2(m, g_symbol, g_time_frame);
	g_trailing_stop._order = g_order;
	
	print_mt4_info();
	//print_account_info();
	//print_market_info();


	return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
	delete g_trailing_stop;
	delete g_signal;
	delete g_order;
}

void OnTick()
{
/*
	if (!IsTradeAllowed()) 
	{
		return;
	}
	
	MathSrand(TimeLocal());
*/
	//
	// 计算是不是新的k线
	//
	is_new_bar();
	
	//
	// 是否有正在交易的订单或挂单
	//
	bool is_have_trade = g_order.is_have_trade();
	
	bool is_multi_order = false;
	if (is_have_trade)    // 有订单
	{
		//
		// 跟随止损
		//
		if (g_enable_trailing_stop)    
		{
			//
			// 每个新的k线，设置止损线
			//
			g_trailing_stop.set_trailing_stoploss();    
			
			//
			// 实时检查止损线，根据理想的止损位置，可以即时平仓。
			// 有时平台的 MODE_STOPLEVEL 太大，需要即时操作。
			//
			g_trailing_stop.check_trailing_stoploss();    
		}
		
		//
		// 支持多张订单
		//
		if (g_enable_multi_order)    
		{
			if (g_order._trade_get_size >= 1        // 已经有开仓
				&& g_order._trade_get_size < g_multi_order_max    // 最多只能开 g_multi_order_max 这么多订单
				&& g_order._trade[0]._open_time > 0
				&& g_order._trade[0]._profile > 0
				&& g_time_0 > g_order._trade[0]._open_time + g_time_frame * 60 * g_tutle_medium_period
				)
			{
				is_multi_order = true;
			}
		}
	}
	
	//
	// 没有订单 || 可以下多张订单加仓
	//
	if (!is_have_trade || is_multi_order)
	{
		if (g_enable_long)    // 允许作多
		{
			if (g_signal.long_condition())    // 作多信号
			{
				g_trailing_stop._long_stoploss = g_signal._long_stoploss;    // 更新理想的止损，防止交易平台 MODE_STOPLEVEL 太大。
				g_order.calc_lots();
				g_order.open(OP_BUY, g_order._lots_tudo, g_signal._long_stoploss);
			}
		}
		if (g_enable_short)    // 允许作空
		{
			if (g_signal.short_condition())
			{
				g_trailing_stop._short_stoploss = g_signal._short_stoploss;
				g_order.calc_lots();
				g_order.open(OP_SELL, g_order._lots_tudo, g_signal._short_stoploss);
			}
		}
	}

	return;
}


// ===========================================================================





