#property strict

extern double g_take_profit = 0.0;	// [止赢] 

// ==========================================================================


#include <wq_bars.mqh>

class order_info 
{
public:
	order_info();
	~order_info();
	void reset();
	void assign(const order_info& r);
	
public:
	string _symbol;
	int _type;
	int _ticket;
	double _lots;
	double _open_price;
	double _close_price;
	double _stoploss;
	datetime _open_time;
	datetime _close_time;
	double _profit;
	double _profit_pip;
};

// ==========================================================================

order_info::order_info()
{
	reset();
}

order_info::~order_info()
{
}

void order_info::reset()
{
	_symbol = "";
	_type = 0;
	_ticket = 0;
	_lots = 0;
	_open_price = 0;
	_close_price = 0;
	_stoploss = 0;
	_open_time = 0;
	_close_time = 0;
	_profit = 0;
	_profit_pip = 0;
}

void order_info::assign(const order_info& r)
{
	_symbol = r._symbol;
	_type = r._type;
	_ticket = r._ticket;
	_lots = r._lots;
	_open_price = r._open_price;
	_close_price = r._close_price;
	_stoploss = r._stoploss;
	_open_time = r._open_time;
	_close_time = r._close_time;
	_profit = r._profit;
	_profit_pip = r._profit_pip;
}

// ==========================================================================

class order2
{
public:
	order2(int magic, string symbol, int time_frame);
	~order2();
	
	// order_type = [OP_BUY | OP_SELL]
	void open(int order_type, double lots, double sl, string comment = "");
	
	void close(int ticket, double lots, double price);
	int close(int order_type, bool all_order);
	int close_all(int order_type);
	
	void get_trade(int order_type);
	void get_history();

	bool is_cooldown();

public:
	int _magic;
	string _symbol;
	int _time_frame;

	int _retry_count;
	int _sleep_time;
	int _last_err;
	
	order_info* _history[1000];
	int _history_size;
	int _history_get_size;
	double _history_profit_sum;
	double _history_profit_pip_sum;
	double _history_loss_max;
	
	int _trade_size;
	order_info* _trade[300];
	int _pending_size;
	int _trade_get_size;
	double _trade_profit_sum;
	double _trade_lots_sum;
	double _trade_cost_price;
};

order2* g_order = NULL;

// ==========================================================================

order2::order2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_retry_count = 10;
	_sleep_time = 500;
	_last_err = 0;
	
	_history_size = 600;
	for (int i = 0; i < _history_size; ++i)
	{
		_history[i] = new order_info();
	}
	_history_get_size = 0;
	_history_profit_sum = 0;
	_history_profit_pip_sum = 0;
	_history_loss_max = 0;
	
	_trade_size = 50;
	for (int i = 0; i < _trade_size; ++i)
	{
		_trade[i] = new order_info();
	}
	_pending_size = 0;
	_trade_get_size = 0;
	_trade_profit_sum = 0;
	_trade_lots_sum = 0;
	_trade_cost_price = 0;
}

order2::~order2()
{
	for (int i = 0; i < _history_size; ++i)
	{
		delete _history[i];
	}
	for (int i = 0; i < _trade_size; ++i)
	{
		delete _trade[i];
	}
}

// ==========================================================================

void order2::open(int order_type, double lots, double sl, string comment)
{
	const string s1 = "[" + get_order_str(order_type) + "]" + comment + "[" + DoubleToString(lots, 2) + "][" + DoubleToString(Bid, g_digits) + "," + DoubleToString(sl, g_digits) + "]";
	alert(s1);
	send_msg(s1);
	
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (lots <= 0.000001)
	{
		Print("[ERROR] (lots <= 0)");
		return;
	}
	if (sl <= 0.000001)
	{
	//	Print("[ERROR] (sl <= 0)");
	//	return;
	}
	
	lots = NormalizeDouble(lots, 2);
	int i = 0;
	int ticket = 0;
	double tp = 0;
	switch (order_type)
	{
		case OP_BUY:
		{
			for (i = 0; i < _retry_count; i++)
			{
				RefreshRates();
				if (IsTesting() || IsDemo())
				{
				}
				else
				{
					g_spread = MarketInfo(g_symbol, MODE_SPREAD);
					if (g_spread >= g_limit_spread)
					{
						const string s2 = "[alert]spread=" + DoubleToString(g_spread, 2);
						Print("[DEBUG]", s2);
						alert(s2);
						break;
					}
				}
				//sl = MathMin(sl, sl - (g_spread) * g_point);
				if (sl > 0.0)
				{
					sl = MathMin(sl, Bid - (g_stop_level + g_spread) * g_point);
					sl = NormalizeDouble(sl, g_digits);
					sl = NormalizeDouble(sl, g_digits);
				}
				tp = 0;
				if (g_take_profit >= 2.0)
				{
					tp = Ask + (Ask - sl) * g_take_profit;
				}
				ticket = OrderSend(_symbol, OP_BUY, lots, Ask, 0, sl, tp, NULL, _magic);
				if (ticket < 0)
				{
					_last_err = GetLastError();
					if (_last_err == ERR_NO_ERROR 
						|| _last_err == ERR_SERVER_BUSY 
						|| _last_err == ERR_OFF_QUOTES 
						|| _last_err == ERR_BROKER_BUSY 
						|| _last_err == ERR_REQUOTE 
						|| _last_err == ERR_TRADE_CONTEXT_BUSY
						|| _last_err == ERR_TOO_FREQUENT_REQUESTS
						|| _last_err == ERR_TRADE_TIMEOUT
						)
					{
						Print("[WARN] OrderSend(OP_BUY)  BUSY   err=", _last_err);
						Sleep(_sleep_time);
						continue;
					}
					else
					{
						if (ERR_NOT_ENOUGH_MONEY == _last_err)
						{
							Print("[ERROR] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";sl=", sl, ";err=ERR_NOT_ENOUGH_MONEY;AccountFreeMargin()=", AccountFreeMargin());
						}
						if (ERR_TRADE_NOT_ALLOWED == _last_err)
						{
							//Print("[INFO] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";sl=", sl);
						}
						else
						{
							Print("[ERROR] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";sl=", sl, ";err=", _last_err, ";AccountFreeMargin()=", AccountFreeMargin());
						}
						break;
					}
				}
				else
				{
					break;
				}
			}
		}
		break;
		case OP_SELL:
		{
			for (i = 0; i < _retry_count; i++)
			{
				RefreshRates();
				if (IsTesting() || IsDemo())
				{
				}
				else
				{
					g_spread = MarketInfo(g_symbol, MODE_SPREAD);
					if (g_spread >= g_limit_spread)
					{
						const string s3 = "[alert]spread=" + DoubleToString(g_spread, 2);
						Print("[DEBUG]", s3);
						alert(s3);
						break;
					}
				}
				if (sl > 0.0)
				{
					sl = MathMax(sl, sl + (g_spread) * g_point);
					sl = MathMax(sl, Ask + (g_stop_level + g_spread) * g_point);
					sl = NormalizeDouble(sl, g_digits);
				}
				tp = 0;
				if (g_take_profit >= 2.0)
				{
					tp = Bid - (sl - Bid) * g_take_profit;
				}
				ticket = OrderSend(_symbol, OP_SELL, lots, Bid, 0, sl, tp, NULL, _magic);
				if (ticket < 0)
				{
					_last_err = GetLastError();
					if (_last_err == ERR_NO_ERROR 
						|| _last_err == ERR_SERVER_BUSY 
						|| _last_err == ERR_OFF_QUOTES 
						|| _last_err == ERR_BROKER_BUSY 
						|| _last_err == ERR_REQUOTE 
						|| _last_err == ERR_TRADE_CONTEXT_BUSY
						|| _last_err == ERR_TOO_FREQUENT_REQUESTS
						|| _last_err == ERR_TRADE_TIMEOUT
						)
					{
						Print("[WARN] OrderSend(OP_SELL)  BUSY   err=", _last_err);
						Sleep(_sleep_time);
						continue;
					}
					else
					{
						if (ERR_NOT_ENOUGH_MONEY == _last_err)
						{
							Print("[ERROR] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";sl=", sl, ";err=ERR_NOT_ENOUGH_MONEY;AccountFreeMargin()=", AccountFreeMargin());
						}
						if (ERR_TRADE_NOT_ALLOWED == _last_err)
						{
							//Print("[INFO] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";sl=", sl);
						}
						else
						{
							Print("[ERROR] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";sl=", sl, ";err=", _last_err, ";AccountFreeMargin()=", AccountFreeMargin());
						}
						break;
					}
				}
				else
				{
					break;
				}
			}
		}
		break;
	}
}

// ==========================================================================

void order2::close(int ticket, double lots, double price)
{
	if (!IsTradeAllowed()) 
	{
		return;
	}
	int ret = 0;
	for (int c = 0; c < _retry_count; c++)
	{
		RefreshRates();
		g_spread = MarketInfo(g_symbol, MODE_SPREAD);
		ret = OrderClose(ticket, lots, price, int(g_spread * 1.5));
		//ret = OrderClose(ticket, lots, price, int(g_limit_spread));
		if (ret) 
		{
			break;
		}
		else
		{
			_last_err = GetLastError();
			if (_last_err == ERR_NO_ERROR 
				|| _last_err == ERR_SERVER_BUSY 
				|| _last_err == ERR_OFF_QUOTES 
				|| _last_err == ERR_BROKER_BUSY 
				|| _last_err == ERR_REQUOTE 
				|| _last_err == ERR_TRADE_CONTEXT_BUSY
				|| _last_err == ERR_TOO_FREQUENT_REQUESTS
				|| _last_err == ERR_TRADE_TIMEOUT
				
				)
			{
				Print("[WARN] close()  err=", _last_err);
				Sleep(_sleep_time);
				continue;
			}
			else
			{
				Print("[ERROR] close() err=", _last_err);
				break;
			}
		}
	}
}

int order2::close(int order_type, bool all_order)
{
	if (!IsTradeAllowed()) 
	{
		return 0;
	}
	int close_count = 0;
	int c = 0;
	int ticket = 0;
	bool ret = false;
	const int order_total = OrdersTotal();
	for(int cnt = order_total - 1; cnt >= 0; cnt--)
	{
		if (!OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
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
		ticket = OrderTicket();
		switch (OrderType())
		{
		case OP_BUY:
			if (OP_BUY == order_type)
			{
				close(OrderTicket(), OrderLots(), Bid);
				++close_count;
				if (!all_order)
				{
					return close_count;
				}
			}
			break;
		case OP_SELL:
			if (OP_SELL == order_type)
			{
				close(OrderTicket(), OrderLots(), Ask);
				++close_count;
				if (!all_order)
				{
					return close_count;
				}
			}
			break;
		case OP_BUYLIMIT:
		case OP_BUYSTOP:
			if (OP_BUY == order_type || OP_BUYLIMIT == order_type || OP_BUYSTOP == order_type)
			{
				if (!OrderDelete(ticket))
				{
					Print("[ERROR] OrderDelete() err=", GetLastError());
				}
			}
			break;
		case OP_SELLLIMIT:
		case OP_SELLSTOP:
			if (OP_SELL == order_type || OP_SELLLIMIT == order_type || OP_SELLSTOP == order_type)
			{
				if (!OrderDelete(ticket))
				{
					Print("[ERROR] OrderDelete() err=", GetLastError());
				}
			}
			break;
		}
	}
	return close_count;
}

int order2::close_all(int order_type)
{
	int c = close(order_type, true);
	if (c > 0)
	{
		for (int i = 0; i < _trade_get_size; ++i)
		{
			_trade[i].reset();
		}
		_trade_get_size = 0;
		_trade_profit_sum = 0;
		_pending_size = 0;
		_trade_lots_sum = 0;
		_trade_cost_price = 0;
	}
	return c;
}

// ==========================================================================

void order2::get_trade(int order_type)
{
	for (int i = 0; i < _trade_get_size; ++i)
	{
		_trade[i].reset();
	}
	_trade_get_size = 0;
	_trade_profit_sum = 0;
	_pending_size = 0;
	_trade_lots_sum = 0;
	_trade_cost_price = 0;
	
	double t = 0;
	const int order_total = OrdersTotal();
	for (int i = order_total - 1; i >= 0; i--)
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
			++_pending_size;
			continue;
		}
		if (order_type != -1)
		{
		   if (order_type != OrderType())
	   		{
	   			continue;
	   		}
		}
		_trade[_trade_get_size]._symbol = OrderSymbol();
		_trade[_trade_get_size]._type = OrderType();
		_trade[_trade_get_size]._ticket = OrderTicket();
		_trade[_trade_get_size]._lots = OrderLots();
		_trade[_trade_get_size]._open_price = OrderOpenPrice();
		_trade[_trade_get_size]._close_price = OrderClosePrice();
		_trade[_trade_get_size]._stoploss = OrderStopLoss();
		_trade[_trade_get_size]._open_time = OrderOpenTime();
		_trade[_trade_get_size]._close_time = OrderCloseTime();
		_trade[_trade_get_size]._profit = OrderProfit();
		_trade[_trade_get_size]._profit_pip = OrderProfit() / OrderLots() / g_tick_value;
		_trade_profit_sum += OrderProfit();
		_trade_lots_sum += OrderLots();
		++_trade_get_size;
		t += OrderOpenPrice() * OrderLots();
		if (_trade_get_size >= _trade_size)
		{
			break;
		}
	}
	if (_trade_lots_sum > 0)
	{
		_trade_cost_price = t / _trade_lots_sum;
	}
/*
	if (_trade_get_size >= 2)
	{
		order_info t;
		for (int i = 0; i < _trade_get_size - 1; ++i)
		{
			for (int j = 0; j < _trade_get_size - i - 1; ++j)
			{
				if (_trade[j]._open_time < _trade[j+1]._open_time)
				{
					t.assign(_trade[j]);
					_trade[j].assign(_trade[j+1]);
					_trade[j+1].assign(t);
				}
			}
		}
	}
*/
}

void order2::get_history()
{
	for (int i = 0; i < _history_get_size; ++i)
	{
		_history[i].reset();
	}
	_history_get_size = 0;
	_history_profit_sum = 0;
	_history_profit_pip_sum = 0;
	_history_loss_max = 0;
	const int order_total = OrdersHistoryTotal();
	for (int i = order_total-1; i >= 0; --i)
	{
		if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
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
		if (OrderProfit() == 0)
		{
		   continue;
		}
		_history[_history_get_size]._symbol = OrderSymbol();
		_history[_history_get_size]._type = OrderType();
		_history[_history_get_size]._ticket = OrderTicket();
		_history[_history_get_size]._lots = OrderLots();
		_history[_history_get_size]._open_price = OrderOpenPrice();
		_history[_history_get_size]._close_price = OrderClosePrice();
		_history[_history_get_size]._stoploss = OrderStopLoss();
		_history[_history_get_size]._open_time = OrderOpenTime();
		_history[_history_get_size]._close_time = OrderCloseTime();
		_history[_history_get_size]._profit = OrderProfit();
		_history[_history_get_size]._profit_pip = OrderProfit() / OrderLots() / g_tick_value;
		if (_history_get_size >= 1)
		{
			if (g_lots_min == _history[_history_get_size-1]._lots
				&& _history[_history_get_size]._lots > g_lots_min
				)
			{
				break;    // 只计算最近的这1场战役
			}
		}
		++_history_get_size;
		if (_history_get_size >= _history_size)    // 只取 _history_size 这么多的订单
		{
			break;
		}
	}
	// 过滤
   while (_history_get_size >= 1 && _history[_history_get_size-1]._profit >= 0)
   {
      --_history_get_size;
   }
	double profit_sum = 0.0;
	double loss_max = 0;
	for (int i = _history_get_size-1; i >= 0; --i)
	{
	   if (_history[i]._lots > g_lots_min)
	   {
	      break;
	   }
	   profit_sum += _history[i]._profit;
		loss_max = MathMin(loss_max, profit_sum);
		if (profit_sum >= MathAbs(loss_max) * 1.5)
		{
		   _history_get_size = i;
      	profit_sum = 0.0;
      	loss_max = 0;
		}
	}
	_history_profit_sum = 0;
	_history_profit_pip_sum = 0;
	_history_loss_max = 0;
	for (int i = _history_get_size-1; i >= 0; --i)
	{
		_history_profit_sum += _history[i]._profit;
		_history_profit_pip_sum += _history[i]._profit_pip;
		_history_loss_max = MathMin(_history_loss_max, _history_profit_sum);
	}
/*
	if (_history_get_size >= 2)
	{
		order_info t;
		for (int i = 1; i < _history_get_size; ++i)
		{
			if (_history[i]._open_time > _history[0]._open_time)
			{
				t.assign(_history[0]);
				_history[0].assign(_history[i]);
				_history[i].assign(t);
			}
		}
	}
*/
}

bool order2::is_cooldown()
{
	if (_trade_get_size >= 1
		&& _trade[0]._open_time > 0
		)
	{
		//
		// ( / 刚下过单)
		//
		if (g_time_0 < _trade[0]._open_time + g_time_frame * 60 * 10
			)
		{
			return false;
		}
	}
	return true;
}

