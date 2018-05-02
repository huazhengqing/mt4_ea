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
	
	init_g_para();
	
	
	//int m = get_magic(g_magic_number, g_symbol, g_time_frame);
	int m = 0;

	
	g_order = new order2(m, g_symbol, g_time_frame);
	g_signal = new signal2(m, g_symbol, g_time_frame);
	g_trailing_stop = new trailing_stop2(m, g_symbol, g_time_frame);
	g_trailing_stop._order = g_order;
	
	print_mt4_info();
	print_account_info();
	print_market_info();


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
	is_new_bar();	// 计算是不是新的k线
	
	g_order.get_trade();	// 正在交易的订单
	
	if (g_order._trade_get_size >= 1) 	// 有成交的订单
	{
		if (g_trailing_stop_enable)	// 跟随止损
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
	}
	
	if (g_order._pending_size >= 1)	// 有挂单，就不开仓/加仓
	{
		return;
	}
/*
	if (g_order._trade_get_size < g_order_max)
	{
		if (g_order._trade_get_size >= 1
			&& g_order._trade[0]._open_time > 0
			)
		{
			//
			// 如果(还没有盈利 / 刚下过单)，就暂时不加仓
			//
			if (g_order._trade[0]._profile < 0
				|| g_order._trade[0]._profile_pip < (g_stop_level + g_spread)
				|| g_time_0 < g_order._trade[0]._open_time + g_time_frame * 60 * g_tutle_long_period
				)
			{
				//
				// 加仓时，人工来增加 g_order_max 值，不用此判断
				//
				//return;
			}
		}
	}
*/
	if (g_enable_long)    // 允许作多
	{
		if ((g_order._trade_get_size < g_order_max)
			|| (OP_SELL == g_order._trade[g_order._trade_get_size - 1]._type))
		{
			if (g_signal.long_condition())    // 作多信号
			{
				g_trailing_stop._long_stoploss = g_signal._long_stoploss;    // 更新理想的止损，防止交易平台 MODE_STOPLEVEL 太大。
				g_order.close_all(OP_SELL);
				g_order.calc_lots();
				g_order.open(OP_BUY, g_order._lots_tudo, g_signal._long_stoploss);
			}
		}
	}
	
	if (g_enable_short)    // 允许作空
	{
		if ((g_order._trade_get_size < g_order_max)
			|| (OP_BUY == g_order._trade[g_order._trade_get_size - 1]._type))
		{
			if (g_signal.short_condition())
			{
				g_trailing_stop._short_stoploss = g_signal._short_stoploss;
				g_order.close_all(OP_BUY);
				g_order.calc_lots();
				g_order.open(OP_SELL, g_order._lots_tudo, g_signal._short_stoploss);
			}
		}
	}
	g_init = false;
}


// ===========================================================================





