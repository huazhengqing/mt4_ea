#property strict
#include <wq_util.mqh>
#include <wq_ind.mqh>




// ==========================================================================

class order_info 
{
public:
	order_info();
	~order_info();
	void reset();
	
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
	double _profile;
	double _profile_pip;
	
	double _stoploss_calc;
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
	_profile = 0;
	_profile_pip = 0;
	
	_stoploss_calc = 0;
}

// ==========================================================================


class order2
{
public:
	order2(int magic, string symbol, int time_frame);
	~order2();
	
	// order_type = [OP_BUY | OP_SELL]
	void open(int order_type, double lots, double sl);
	
	void close(int order_type, bool all_order);
	void close_all(int order_type);
	
	void get_trade();
	void calc_lots();
	
private:
	void get_history();
	
public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	int _retry_count;
	int _sleep_time;
	int _last_err;
	
	order_info* _history[30];
	int _history_size;
	int _history_get_size;
	double _history_profit;
	
	order_info* _trade[50];
	int _trade_size;
	int _trade_get_size;
	double _trade_profit;
	
	int _pending_size;
	
	double _lots_tudo;
};

// ==========================================================================

order2::order2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_retry_count = 10;
	_sleep_time = 500;
	_last_err = 0;
	
	_history_size = 30;
	for (int i = 0; i < _history_size; ++i)
	{
		_history[i] = new order_info();
	}
	_history_get_size = 0;
	_history_profit = 0;
	
	_trade_size = 50;
	for (int i = 0; i < _trade_size; ++i)
	{
		_trade[i] = new order_info();
	}
	_trade_get_size = 0;
	_trade_profit = 0;
	
	_pending_size = 0;
	
	_lots_tudo = g_lots_min;
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

void order2::open(int order_type, double lots, double stoploss)
{
	//Print("[INFO] ", _symbol, ";", get_time_frame_str(_time_frame), ";", get_order_str(order_type), ";lots=", lots, ";ask=", DoubleToString(Ask, g_digits), ";stoploss=", DoubleToString(stoploss, g_digits));
	
	//
	// 通知
	//
	const string s = "[" + get_order_str(order_type) + "][" + DoubleToString(lots, 2) + "][" + DoubleToString(Bid, g_digits) + "," + DoubleToString(stoploss, g_digits) + "]";
	alert(s);
	send_msg(s);
	
	//
	// 没有打开 EA,不操作
	//
	if (!IsTradeAllowed()) 
	{
		return;
	}
	
	if (lots <= 0)
	{
		Print("[ERROR] (lots <= 0)");
		return;
	}
	if (stoploss <= 0)
	{
		Print("[ERROR] (stoploss <= 0)");
		return;
	}
	
	lots = NormalizeDouble(lots, 2);
	int i = 0;
	int ticket = 0;
	switch (order_type)
	{
		case OP_BUY:
		{
			close_all(OP_SELL);
			
			for (i = 0; i < _retry_count; i++)
			{
				RefreshRates();
				g_spread = MarketInfo(g_symbol, MODE_SPREAD);
				stoploss = MathMin(stoploss, stoploss - (g_spread) * g_point);
				stoploss = MathMin(stoploss, Bid - (g_stop_level + g_spread) * g_point);
				stoploss = NormalizeDouble(stoploss, g_digits);
				ticket = OrderSend(_symbol, OP_BUY, lots, Ask, 0, stoploss, 0, NULL, _magic);
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
							Print("[ERROR] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";stoploss=", stoploss, ";err=ERR_NOT_ENOUGH_MONEY;AccountFreeMargin()=", AccountFreeMargin());
						}
						if (ERR_TRADE_NOT_ALLOWED == _last_err)
						{
							Print("[INFO] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";stoploss=", stoploss);
						}
						else
						{
							Print("[ERROR] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";stoploss=", stoploss, ";err=", _last_err, ";AccountFreeMargin()=", AccountFreeMargin());
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
			close_all(OP_BUY);
			
			for (i = 0; i < _retry_count; i++)
			{
				RefreshRates();
				g_spread = MarketInfo(g_symbol, MODE_SPREAD);
				stoploss = MathMax(stoploss, stoploss + (g_spread) * g_point);
				stoploss = MathMax(stoploss, Ask + (g_stop_level + g_spread) * g_point);
				stoploss = NormalizeDouble(stoploss, g_digits);
				ticket = OrderSend(_symbol, OP_SELL, lots, Bid, 0, stoploss, 0, NULL, _magic);
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
							Print("[ERROR] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";stoploss=", stoploss, ";err=ERR_NOT_ENOUGH_MONEY;AccountFreeMargin()=", AccountFreeMargin());
						}
						if (ERR_TRADE_NOT_ALLOWED == _last_err)
						{
							Print("[INFO] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";stoploss=", stoploss);
						}
						else
						{
							Print("[ERROR] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";stoploss=", stoploss, ";err=", _last_err, ";AccountFreeMargin()=", AccountFreeMargin());
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

void order2::close(int order_type, bool all_order)
{
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
				for(c = 0; c < _retry_count; c++)
				{
					RefreshRates();
					g_spread = MarketInfo(g_symbol, MODE_SPREAD);
					ret = OrderClose(ticket, OrderLots(), Bid, int(g_spread * 1.5));
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
							Print("[WARN] OrderClose(OP_BUY): BUSY err=", _last_err);
							Sleep(_sleep_time);
							continue;
						}
						else
						{
							Print("[ERROR] OrderClose(OP_BUY): err=", _last_err);
							break;
						}
					}
				}
				if (!all_order)
				{
					return;
				}
			}
			break;
		case OP_SELL:
			if (OP_SELL == order_type)
			{
				for(c = 0; c < _retry_count; c++)
				{
					RefreshRates();
					g_spread = MarketInfo(g_symbol, MODE_SPREAD);
					ret = OrderClose(OrderTicket(), OrderLots(), Ask, int(g_spread * 1.5));
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
							Print("[WARN] OrderClose(OP_SELL): BUSY err=", _last_err);
							Sleep(_sleep_time);
							continue;
						}
						else
						{
							Print("[ERROR] OrderClose(OP_SELL): err=", _last_err);
							break;
						}
					}
				}
				if (!all_order)
				{
					return;
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
}

void order2::close_all(int order_type)
{
	close(order_type, true);
}

void order2::get_trade()
{
	for (int i = 0; i < _trade_size; ++i)
	{
		_trade[i].reset();
	}
	_trade_get_size = 0;
	_trade_profit = 0;
	_pending_size = 0;
	
	const int order_total = OrdersTotal();
	for(int i = order_total - 1; i >= 0; i--)
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
		//
		// 过滤没有成交的挂单
		//
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			++_pending_size;
			continue;
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
		_trade[_trade_get_size]._profile = OrderProfit();
		_trade[_trade_get_size]._profile_pip = OrderProfit() / OrderLots() / g_tick_value;
		_trade_profit += OrderProfit();
		++_trade_get_size;
	}
}

void order2::get_history()
{
	for (int i = 0; i < _history_size; ++i)
	{
		_history[i].reset();
	}
	_history_get_size = 0;
	_history_profit = 0;
	
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
		//
		// 过滤没有成交的挂单
		//
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (_trade_get_size >= 1)    // 有正在交易的单
		{
			if (OrderOpenTime() < _trade[0]._open_time)    // 取最近正交易的订单之后的历史单
			{
				continue;
			}
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
		_history[_history_get_size]._profile = OrderProfit();
		_history[_history_get_size]._profile_pip = OrderProfit() / OrderLots() / g_tick_value;
		
		if (_history_get_size < 1)    // 最近的1单
		{
			_history_profit += OrderProfit();
		}
		else    // 更早的订单
		{
			if (_history[_history_get_size]._lots <= _history[_history_get_size-1]._lots)    // 下单数量小，说明还是一个战役
			{
				_history_profit += OrderProfit();
			}
			else
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
}

void order2::calc_lots()
{
	get_history();
	
	if (g_lots_martin)    // 亏损加仓策略
	{
		// 前2笔都亏损
		if (_history[0]._profile < 0
			&& _history[1]._profile < 0
			)
		{
			_lots_tudo = MathMax(g_lots_min, _history[0]._lots);
			_lots_tudo = _lots_tudo + _history[1]._lots;    // 下单数量，为前2笔之和
		}
		else
		{
			if ((_history_profit) < 0)    // 本场战役亏损，说明还没有结束
			{
				_lots_tudo = MathMax(g_lots_min, _history[0]._lots);
			}
			else
			{
				_lots_tudo = g_lots_min;
			}
		}
	}
	else    // 不用亏损加仓的策略
	{
		//
		// 可能是人为操作，下单数量是上一次下单数量
		//
		_lots_tudo = MathMax(g_lots_min, _history[0]._lots);
	}
	
	if (_lots_tudo > g_lots_max)
	{
		Print("[WARN] calc_lots() _lots_tudo=", _lots_tudo);
		
		const string s = "[WARN]lots=" + DoubleToString(_lots_tudo, 2);
		alert(s);
		send_msg(s);
	
		_lots_tudo = g_lots_max;
	}
}


