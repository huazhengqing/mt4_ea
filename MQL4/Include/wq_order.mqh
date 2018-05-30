#property strict

// ==========================================================================

extern bool g_lots_martin = true;					// [下注:martin] Martingale
extern double g_lots_martin_min = 0.05;			// [下注:martin] 最小注
extern double g_lots_martin_max = 0.65;			// [下注:martin] 最大注
extern int g_lots_martin_order_max = 7;			// [下注:martin] 最大下注次数
extern double g_lots_martin_sum_max = 1;			// [下注:martin] 最大总下注数量
extern double g_lots_martin_goal_atr = 0;			// [下注:martin] 目标__*ATR
extern double g_lots_martin_goal_point = 100;	// [下注:martin] 目标点数
extern double g_lots_martin_stop = 16;				// [下注:martin] 止损__*ATR
extern double g_lots_martin_stop_long = 0;		// [下注:martin] 做多止损
extern double g_lots_martin_stop_short = 0;		// [下注:martin] 做空止损
extern bool g_lots_martin_reset = false;			// [下注:martin] 重新开始


extern int i9;// ============================

// ==========================================================================

#include <wq_bars.mqh>

// ==========================================================================

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
	double _profile;
	double _profile_pip;
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
	_profile = r._profile;
	_profile_pip = r._profile_pip;
}

// ==========================================================================

class order2
{
public:
	order2(int magic, string symbol, int time_frame);
	~order2();
	
	// order_type = [OP_BUY | OP_SELL]
	void open(int order_type, double lots, double sl, string comment);
	
	void close(int ticket, double lots, double price);
	int close(int order_type, bool all_order);
	int close_all(int order_type);
	
	void get_trade();
	void get_history();
	//void get_cost();
	
	double calc_lots_martin_by_trade();
	double calc_lots_martin_by_history();
	
	bool is_cooldown();

public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	bars_big_period* g_bars_big_period;
	bars* g_bars;
	
	int _retry_count;
	int _sleep_time;
	int _last_err;
	
	order_info* _history[1000];
	int _history_size;
	int _history_get_size;
	double _history_profit_sum;
	
	int _trade_size;
	order_info* _trade[300];
	int _pending_size;
	int _trade_get_size;
	double _trade_profit_sum;
	double _trade_lots_sum;
	double _trade_cost_price;
	
	double _calc_lots_tudo;
	
	double _cost_price;
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
	
	_history_size = 600;
	for (int i = 0; i < _history_size; ++i)
	{
		_history[i] = new order_info();
	}
	_history_get_size = 0;
	_history_profit_sum = 0;
	
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
	
	
	_calc_lots_tudo = g_lots_martin_min;
	
	_cost_price = 0;
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

void order2::open(int order_type, double lots, double stoploss, string comment)
{
	const string s1 = "[" + get_order_str(order_type) + "]" + comment + "[" + DoubleToString(lots, 2) + "][" + DoubleToString(Bid, g_digits) + "," + DoubleToString(stoploss, g_digits) + "]";
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
	if (stoploss <= 0.000001)
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
						//Print("[DEBUG]", s2);
						alert(s2);
						break;
					}
				}
				//stoploss = MathMin(stoploss, stoploss - (g_spread) * g_point);
				stoploss = MathMin(stoploss, Bid - (g_stop_level + g_spread) * g_point);
				stoploss = NormalizeDouble(stoploss, g_digits);
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
							//Print("[INFO] OrderSend(OP_BUY):lots=", lots, ";Ask=", Ask,";stoploss=", stoploss);
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
						//Print("[DEBUG]", s3);
						alert(s3);
						break;
					}
				}
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
							//Print("[INFO] OrderSend(OP_SELL):lots=", lots, ";Bid=", Bid,";stoploss=", stoploss);
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

void order2::get_trade()
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

		if (g_lots_martin_order_max >= 2)
		{
			if (_trade_get_size >= 1)    // 有正在交易的单
			{
				if (OrderOpenTime() < _trade[0]._open_time)    // 取最近正交易的订单之后的历史单
				{
					//Print("[DEBUG] 有正在交易的单   _trade_get_size=", _trade_get_size, ";_history_get_size=", _history_get_size);
					continue;
				}
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
			_history_profit_sum += OrderProfit();
		}
		else    // 更早的订单
		{
			if (_history[_history_get_size]._lots <= _history[_history_get_size-1]._lots)    // 下单数量小，说明还是一个战役
			{
				_history_profit_sum += OrderProfit();
			}
			else
			{
				
				//Print("[DEBUG] 只计算最近的这1场战役   _history_profit_sum=", _history_profit_sum, ";_history_get_size=", _history_get_size);
				break;    // 只计算最近的这1场战役
			}
		}
		
		++_history_get_size;
		if (_history_get_size >= _history_size)    // 只取 _history_size 这么多的订单
		{
			//Print("[DEBUG] 只取 _history_size 这么多的订单   _history_profit_sum=", _history_profit_sum, ";_history_get_size=", _history_get_size);
			break;
		}
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
/*
void order2::get_cost()
{
	_cost_price = 0;
	if (_trade_get_size <= 0)
	{
		return;
	}
	_cost_price = _trade[0]._open_price;
	if (_history_get_size <= 0 || _history_profit_sum >= 0)
	{
		return;
	}
	double pip = MathAbs(_history_profit_sum) / _trade[0]._lots / g_tick_value * g_point;
	if (OP_BUY == _trade[0]._type)
	{
		_cost_price = _trade[0]._open_price + pip;
	}
	else if (OP_SELL == _trade[0]._type)
	{
		_cost_price = _trade[0]._open_price - pip;
	}
}
*/
// ==========================================================================

double order2::calc_lots_martin_by_trade()
{
	get_trade();
	if (_trade_lots_sum > g_lots_martin_sum_max
		|| _trade_get_size >= g_lots_martin_order_max
		)
	{
		_calc_lots_tudo = 0;
		return 0;
	}
	_calc_lots_tudo = g_lots_martin_min;
	if (!g_lots_martin)
	{
		return 0;
	}
	if (g_lots_martin_reset)
	{
		g_lots_martin_reset = false;
		_calc_lots_tudo = g_lots_martin_min;
	}
	else
	{
		if (_trade_get_size >= 2
			&& _trade[0]._profile < 0
			&& _trade[1]._profile < 0
			)
		{
			_calc_lots_tudo = _trade[0]._lots + _trade[1]._lots;    // 下单数量，为前2笔之和
		}
		else
		{
			if (_trade_profit_sum < 0)
			{
				_calc_lots_tudo = _trade[0]._lots;
			}
			else
			{
				_calc_lots_tudo = g_lots_martin_min;
			}
		}
	}
	if (_calc_lots_tudo > g_lots_martin_max)
	{
		_calc_lots_tudo = g_lots_martin_max;
		g_lots_martin_reset = true;
	}
	return _calc_lots_tudo;
}

double order2::calc_lots_martin_by_history()
{
	_calc_lots_tudo = g_lots_martin_min;
	if (!g_lots_martin)
	{
		return 0;
	}
	get_history();
	if (g_lots_martin_reset)
	{
		g_lots_martin_reset = false;
		_calc_lots_tudo = g_lots_martin_min;
	}
	else
	{
		if (_history_get_size >= 2
			&& _history[0]._profile < 0
			&& _history[1]._profile < 0
			)
		{
			_calc_lots_tudo = _history[0]._lots + _history[1]._lots;    // 下单数量，为前2笔之和
		}
		else
		{
			if (_history_profit_sum < 0)    // 本场战役亏损，说明还没有结束
			{
				_calc_lots_tudo = _history[0]._lots;
			}
			else
			{
				_calc_lots_tudo = g_lots_martin_min;
			}
		}
	}
	if (_calc_lots_tudo > g_lots_martin_max)
	{
		_calc_lots_tudo = g_lots_martin_max;
		g_lots_martin_reset = true;
	}
	return _calc_lots_tudo;
}

// ==========================================================================

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


