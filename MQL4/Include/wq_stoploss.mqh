#property strict
#include <wq_bars.mqh>
#include <wq_order.mqh>

extern bool g_stop_enable = true;   // [止损]

// ==========================================================================

class stoploss
{
public:
	stoploss(int magic, string symbol, int time_frame);
	~stoploss();
	
   void check_trailing_stoploss();
   
	void modify_long_stoploss(double sl);
	void modify_short_stoploss(double sl);
	
	void update_all_long_stop(double sl);
	void update_all_short_stop(double sl);

public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	int _retry_count;
	int _sleep_time;
	int _last_err;
	
public:
	double _long_stoploss;
	double _short_stoploss;
	
	indicator* _bars_1;
	indicator* _bars_2;
	
	bool _update_sl_long;
	bool _update_sl_short;
};

// ==========================================================================

stoploss::stoploss(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_retry_count = 10;
	_sleep_time = 1000;
	_last_err = 0;
	
	_long_stoploss = 0;
	_short_stoploss = 0;

	_bars_1 = new indicator(_symbol, g_stop_ha_period);
	_bars_2 = new indicator(_symbol, g_stop_ha_period);
	
	_update_sl_long = false;
	_update_sl_short = false;
}

stoploss::~stoploss()
{
	delete _bars_1;
	delete _bars_2;
}

// ==========================================================================

void stoploss::check_trailing_stoploss()
{
	if (!g_stop_enable)
	{
		return;
	}
	int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		return;
	}
	
	//
	// MODE_STOPLEVEL 太大，直接操作平仓来止损。
	//
	if (_long_stoploss > 0)
	{
		if (g_bars._bars[0]._ha_close < _long_stoploss)
		{
			if (g_order)
			{
				string s = "stoploss(OP_BUY);sl=" + DoubleToString(_long_stoploss, g_digits);
				Print("[DEBUG] check_trailing_stoploss() ", s);
				
				g_order.close(OP_BUY, false);
				_long_stoploss = 0;
			}
		}
	}
	if (_short_stoploss > 0)
	{
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		if (g_bars._bars[0]._ha_close > _short_stoploss + g_spread * g_point)
		{
			if (g_order)
			{
				string s = "stoploss(OP_SELL);sl=" + DoubleToString(_short_stoploss, g_digits);
				Print("[DEBUG] check_trailing_stoploss() ", s);
				
				g_order.close(OP_SELL, false);
				_short_stoploss = 0;
			}
		}
	}
}

// ==========================================================================

void stoploss::modify_long_stoploss(double sl)
{
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (sl <= 0.00001)
	{
		return;
	}
	if (OrderStopLoss() == sl)
	{
		return;
	}
	for (int i = 0; i < _retry_count; i++)
	{
		RefreshRates();
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		sl = MathMin(sl, Bid - (g_stop_level + 0) * g_point);
		sl = NormalizeDouble(sl, g_digits);
		if (sl > OrderStopLoss() || OrderStopLoss() <= 0)
		{
			bool r = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), OrderExpiration());
			 _update_sl_long = true;
			if (r)
			{
				break;
			}
			else
			{
				_last_err = GetLastError();
				if (_last_err == ERR_NO_ERROR 
					|| _last_err ==  ERR_NO_RESULT 
					)
				{
					break;
				}
				else if (_last_err==ERR_SERVER_BUSY 
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

void stoploss::modify_short_stoploss(double sl)
{
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (sl <= 0.00001)
	{
		return;
	}
	if (OrderStopLoss() == sl)
	{
		return;
	}
	for (int i = 0; i < _retry_count; i++)
	{
		RefreshRates();
		if (MathAbs(sl - OrderOpenPrice()) > 0.00001)
		{
			g_spread = MarketInfo(g_symbol, MODE_SPREAD);
			sl = sl + g_spread * g_point;
		}
		sl = MathMax(sl, Ask + (g_stop_level + g_spread) * g_point);
		sl = NormalizeDouble(sl, g_digits);
		if (sl < OrderStopLoss() || OrderStopLoss() <= 0)
		//if (sl != OrderStopLoss())
		{
			bool r = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), OrderExpiration());
			_update_sl_short = true;
			if (r)
			{
				break;
			}
			else
			{
				_last_err = GetLastError();
				if (_last_err == ERR_NO_ERROR 
					|| _last_err ==  ERR_NO_RESULT 
					)
				{
					break;
				}
				else if (_last_err == ERR_NO_ERROR 
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

// ==========================================================================

void stoploss::update_all_long_stop(double sl)
{
	if (sl <= 0.00001)
	{
		return;
	}
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (!g_is_new_bar)
	{
		return;
	}
	const int order_total = OrdersTotal();
	if (order_total <= 0)
	{
		return;
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
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (OrderType() == OP_BUY)
		{
			modify_long_stoploss(sl);
		}
	}
}

void stoploss::update_all_short_stop(double sl)
{
	if (sl <= 0.00001)
	{
		return;
	}
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (!g_is_new_bar)
	{
		return;
	}
	const int order_total = OrdersTotal();
	if (order_total <= 0)
	{
		return;
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
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (OrderType() == OP_SELL)
		{
			modify_short_stoploss(sl);
		}
	}
}
