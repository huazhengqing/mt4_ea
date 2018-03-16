#property strict
#include <wq_util.mqh>
#include <wq_ind.mqh>
#include <wq_order.mqh>



// ==========================================================================

class trailing_stop2
{
public:
	trailing_stop2(int magic, string symbol, int time_frame);
	~trailing_stop2();
	
	//
	// 每个新的k线，设置止损线
	//
	void set_trailing_stoploss();    
	
	//
	// 实时检查止损线
	//
	void check_trailing_stoploss();    

private:
	void modify_order_long(double sl);
	void modify_order_short(double sl);

public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	int _retry_count;
	int _sleep_time;
	int _last_err;
	
	indicator* _bars[15];
	int _bars_size;
	
	//
	// 没有考虑 MODE_STOPLEVEL 的理想值
	//
	double _long_stoploss;
	double _short_stoploss;
	
	order2* _order;
};

// ==========================================================================

trailing_stop2::trailing_stop2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_retry_count = 10;
	_sleep_time = 1000;
	_last_err = 0;
	
	_bars_size = 10;
	for (int i = 0; i < _bars_size; ++i)
	{
		_bars[i] = new indicator(_symbol, _time_frame);
	}
	
	_long_stoploss = 0;
	_short_stoploss = 0;
	
	_order = NULL;
}

trailing_stop2::~trailing_stop2()
{
	for (int i = 0; i < _bars_size; ++i)
	{
		delete _bars[i];
	}
}

void trailing_stop2::set_trailing_stoploss()
{
	//
	// 1根k线只计算1次
	//
	if (!g_is_new_bar)    
	{
		return;
	}
	
	int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		_long_stoploss = 0;
		_short_stoploss = 0;
		return;
	}
	
	//
	// 计算k线参数
	//
	for (int i = 0; i < _bars_size; ++i)    
	{
		_bars[i].calc(i);
		//Print("[DEBUG] set_trailing_stoploss() i=", i, ";ma_dragon_high=", _bars[i]._ma_dragon_high, ";ma_dragon_low=", _bars[i]._ma_dragon_low);
	}

	for (int i = order_total - 1; i >= 0; --i)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
		{
			continue;
		}
		if (OrderSymbol() != _symbol)
		{
			continue;
		}
		if (0 != _magic && OrderMagicNumber() != _magic)
		{
			continue;
		}
		if (OrderOpenTime() <= 0)    // 挂单，还没有成交
		{
			continue;
		}
		if (g_trailing_stop_for_profit_order)
		{
			if (OrderProfit() <= 0)    // 这一单，还没有赚钱。这时止损还是下单时的止损，不计算新的止损。
			{
				continue;
			}
		}
		int order_type = OrderType();
		if (order_type == OP_BUY || order_type == OP_BUYLIMIT || order_type == OP_BUYSTOP)
		{
			//
			// 根据 ha 计算止损
			//
			if (g_trailing_stop_by_ha)       
			{
				if (_bars[1].is_ha_bull() 
					&& _bars[2].is_ha_bull()
					&& _bars[1]._ha_open > _bars[2]._ha_open 
					&& _bars[1]._ha_low > _bars[2]._ha_low 
					)
				{
					_long_stoploss = MathMin(_bars[1]._ha_low, _bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, _bars[3]._ha_low);
					modify_order_long(_long_stoploss);
				}
			}
			else if (g_trailing_stop_by_ma)        // 根据 ma 计算止损
			{
				//
				// 价格在短期均线上，才计算止损
				//
				if (_bars[1]._ha_close > _bars[1]._ma_dragon_high 
					&& _bars[2]._ha_close > _bars[2]._ma_dragon_high 
					&& _bars[3]._ha_close > _bars[3]._ma_dragon_high
					&& Bid > _bars[0]._ma_dragon_high
					&& Ask > _bars[0]._ma_dragon_high
					)
				{
					_long_stoploss = MathMin(_bars[1]._ha_low, _bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, _bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, _bars[1]._ma_dragon_low);
					modify_order_long(_long_stoploss);
				}
			}
		}
		else if (order_type == OP_SELL || order_type == OP_BUYLIMIT || order_type == OP_BUYSTOP)
		{
			if (g_trailing_stop_by_ha)       // ha
			{
				if (_bars[1].is_ha_bear() 
					&& _bars[2].is_ha_bear()
					&& _bars[1]._ha_open < _bars[2]._ha_open 
					&& _bars[1]._ha_high < _bars[2]._ha_high 
					)
				{
					_short_stoploss = MathMax(_bars[1]._ha_high, _bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, _bars[3]._ha_high);
					modify_order_short(_short_stoploss);
				}
			}
			else if (g_trailing_stop_by_ma)        // ma
			{
				// 价格在短期均线下，才计算止损
				if (_bars[1]._ha_close < _bars[1]._ma_dragon_low 
					&& _bars[2]._ha_close < _bars[2]._ma_dragon_low 
					&& _bars[3]._ha_close < _bars[3]._ma_dragon_low 
					&& Ask < _bars[0]._ma_dragon_low
					&& Bid < _bars[0]._ma_dragon_low
					)
				{
					_short_stoploss = MathMax(_bars[1]._ha_high, _bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, _bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, _bars[1]._ma_dragon_high);
					modify_order_short(_short_stoploss);
				}
			}
		}
		if (!g_trailing_stop_for_all_order)
		{
			break;    // 只操作最近1个订单
		}
	}
	
}

void trailing_stop2::check_trailing_stoploss()
{
	int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		_long_stoploss = 0;
		_short_stoploss = 0;
		return;
	}
	
	//
	// MODE_STOPLEVEL 太大，直接操作平仓来止损。
	//
	if (_long_stoploss > 0)
	{
		_bars[0].calc(0);
		if (_bars[0]._ha_close < _long_stoploss)
		{
			if (_order)
			{
				string s = "stoploss(OP_BUY);sl=" + DoubleToString(_long_stoploss, g_digits);
				alert(s);
				send_msg(s);
				
				_order.close(OP_BUY);
				_long_stoploss = 0;
			}
		}
	}
	
	if (_short_stoploss > 0)
	{
		_bars[0].calc(0);
		if (_bars[0]._ha_close > _short_stoploss)
		{
			if (_order)
			{
				string s = "stoploss(OP_BUY);sl=" + DoubleToString(_short_stoploss, g_digits);
				alert(s);
				send_msg(s);
				
				_order.close(OP_SELL);
				_short_stoploss = 0;
			}
		}
	}
}

void trailing_stop2::modify_order_long(double sl)
{
	for (int i = 0; i < _retry_count; i++)
	{
		RefreshRates();
		sl = MathMin(sl, Bid - (g_stop_level + 0) * g_point);
		sl = NormalizeDouble(sl, g_digits);
		if (sl > OrderStopLoss() || OrderStopLoss() <= 0)
		{
			bool r = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), OrderExpiration());
			if (r)
			{
				break;
			}
			else
			{
				_last_err = GetLastError();
				if (_last_err == ERR_NO_ERROR 
					|| _last_err==ERR_SERVER_BUSY 
					|| _last_err==ERR_OFF_QUOTES 
					|| _last_err==ERR_BROKER_BUSY 
					|| _last_err==ERR_REQUOTE 
					|| _last_err==ERR_TRADE_CONTEXT_BUSY
					)
				{
					Print("[ERROR] OrderModify(OP_BUY) BUSY  Bid=", Bid,";sl=", sl, ";err=", _last_err);
					Sleep(_sleep_time);
					continue;
				}
				else
				{
					Print("[ERROR] OrderModify(OP_BUY)  Bid=", Bid,";sl=", sl, ";err=", _last_err);
					Sleep(_sleep_time);
					continue;
				}
			}
		}
	}
}

void trailing_stop2::modify_order_short(double sl)
{
	for (int i = 0; i < _retry_count; i++)
	{
		RefreshRates();
		sl = MathMax(sl, Ask + (g_stop_level + 0) * g_point);
		sl = NormalizeDouble(sl, g_digits);
		if (sl < OrderStopLoss() || OrderStopLoss() <= 0)
		{
			bool r = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), OrderExpiration());
			if (r)
			{
				break;
			}
			else
			{
				_last_err = GetLastError();
				if (_last_err == ERR_NO_ERROR 
					|| _last_err==ERR_SERVER_BUSY 
					|| _last_err==ERR_OFF_QUOTES 
					|| _last_err==ERR_BROKER_BUSY 
					|| _last_err==ERR_REQUOTE 
					|| _last_err==ERR_TRADE_CONTEXT_BUSY
					)
				{
					Print("[ERROR] OrderModify(OP_SELL) BUSY  Ask=", Ask,";sl=", sl, ";err=", _last_err);
					Sleep(_sleep_time);
					continue;
				}
				else
				{
					Print("[ERROR] OrderModify(OP_SELL)  Ask=", Ask,";sl=", sl, ";err=", _last_err);
					Sleep(_sleep_time);
					continue;
				}
			}
		}
	}
}







