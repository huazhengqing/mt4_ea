#property strict

// ==========================================================================

extern const bool g_stop_enable = true;			// [止损]
extern const bool g_stop_for_all_order = true;	// [止损] 所有订单

extern bool g_stop_by_ha = false;		// [止损:策略] 用HA反转
extern bool g_stop_by_dragon = false;	// [止损:策略] 用dragon
extern bool g_stop_by_trend = false;	// [止损:策略] 用trend
extern bool g_stop_by_channel = true;	// [止损:策略] 用Donchian

extern const bool g_break_even = false;			// [止损:保本] (3 * ATR)
extern const bool g_break_even_clasp = false;	// [止损:保本] HA 跟随

// ==========================================================================

#include <wq_bars.mqh>
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

private:
	int _magic;
	string _symbol;
	int _time_frame;
	
	int _retry_count;
	int _sleep_time;
	int _last_err;
	
public:
	bars* g_bars;
	order2* g_order;
	
	//
	// 没有考虑 MODE_STOPLEVEL 的理想值
	//
	double _long_stoploss;
	double _short_stoploss;
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
	
	_long_stoploss = 0;
	_short_stoploss = 0;
	
	g_bars = NULL;
	g_order = NULL;
}

trailing_stop2::~trailing_stop2()
{
}

void trailing_stop2::set_trailing_stoploss()
{
	if (!g_stop_enable)
	{
		return;
	}
	if (!g_is_new_bar)	// 1根k线只计算1次
	{
		return;
	}

	const int order_total = OrdersTotal();
	if (order_total <= 0)    // 没有订单
	{
		_long_stoploss = 0;
		_short_stoploss = 0;
		return;
	}

	int calc_ticket = 0;
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
		//
		// 过滤没有成交的挂单
		//
		if (OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP 
			|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP
			)
		{
			continue;
		}
		if (calc_ticket <= 0)
		{
			calc_ticket = OrderTicket();
		}
		else
		{
			if (!g_stop_for_all_order)
			{
				break;    // 只操作最近1个订单
			}
			if (OrderType() == OP_BUY)
			{
				modify_order_long(_long_stoploss);
			}
			else if (OrderType() == OP_SELL)
			{
				modify_order_short(_short_stoploss);
			}
			continue;
		}
		if (OrderType() == OP_BUY)
		{
			//
			// 保本
			//
			double pre_long_stoploss = _long_stoploss;
			if (OrderStopLoss() < OrderOpenPrice())	// 止损线 < 成本价
			{
				if (g_break_even_clasp)
				{
					if (OrderProfit() > 0
						&& g_bars._bars[0]._ha_low > OrderOpenPrice()
						&& g_bars._bars[1]._ha_low > OrderOpenPrice()
						&& g_bars._bars[2]._ha_low > OrderOpenPrice()
						&& g_bars._bars[3]._ha_low > OrderOpenPrice()
						)
					{
						_long_stoploss = OrderOpenPrice();
					}
					else if (OrderProfit() > 0
						&& g_bars._bars[1].is_ha_bull() 
						&& g_bars._bars[2].is_ha_bull()
						&& g_bars._bars[1]._ha_low > g_bars._bars[2]._ha_low
						)
					{
						_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
						_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.5);
						if (g_time_frame <= PERIOD_H1
							|| (MathAbs(g_bars._bars[1]._ha_low - g_bars._bars[2]._ha_low) < ((g_bars._bars[2]._ha_high - g_bars._bars[2]._ha_low) * 0.15))
							)
						{
							_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
						}
						_long_stoploss = MathMin(_long_stoploss, OrderOpenPrice());
					}
				}
				else if (g_break_even)
				{
					if (Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3
						//|| (Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 2 && g_bars._bars[1]._ha_low > g_bars._bars[1]._ma_dragon_centre)
						)
					{
						_long_stoploss = OrderOpenPrice();
					}
				}
				if (pre_long_stoploss != _long_stoploss)
				{
					modify_order_long(_long_stoploss);
				}
			}
			
			pre_long_stoploss = _long_stoploss;
			if (g_stop_by_ha)    // 根据 ha 计算止损
			{
				if (g_ea_just_init)    // 程序刚启动
				{
				}
				if (g_bars._bars[1].is_ha_bull() 
					&& g_bars._bars[2].is_ha_bull()
					&& g_bars._bars[1]._ha_low > g_bars._bars[2]._ha_low 
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ha_low - g_bars._bars[1]._atr * 0.5);
					if (g_time_frame <= PERIOD_H1
						|| (MathAbs(g_bars._bars[1]._ha_low - g_bars._bars[2]._ha_low) < ((g_bars._bars[2]._ha_high - g_bars._bars[2]._ha_low) * 0.15))
						)
					{
						_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					}
				}
			}
			else if (g_stop_by_dragon)        // 根据 ma dragon 计算止损
			{
				//
				// 价格在短期均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_dragon_high
					&& Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_dragon_low);
				}
			}
			else if (g_stop_by_trend)	// 根据 ma trend 计算止损
			{
				//
				// 价格在均线上，才计算止损
				//
				if (Bid > g_bars._bars[0]._ma_trend
					&& Bid > OrderOpenPrice() + g_bars._bars[1]._atr * 3
					)
				{
					_long_stoploss = MathMin(g_bars._bars[1]._ha_low, g_bars._bars[2]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[3]._ha_low);
					_long_stoploss = MathMin(_long_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			if (pre_long_stoploss != _long_stoploss)
			{
				modify_order_long(_long_stoploss);
			}
			
			pre_long_stoploss = _long_stoploss;
			if (g_stop_by_channel)        // 根据 Donchian通道 计算止损
			{
				_long_stoploss = g_bars._bars[1]._tutle_long_low - g_bars._bars[1]._atr;
			}
			if (pre_long_stoploss != _long_stoploss)
			{
				modify_order_long(_long_stoploss);
			}
		}
		else if (OrderType() == OP_SELL)
		{
			double pre_short_stoploss = _short_stoploss;
			if (OrderStopLoss() > OrderOpenPrice())
			{
				if (g_break_even_clasp)
				{
					//Print("[DEBUG] g_break_even_clasp ");
					if (OrderProfit() > 0
						&& g_bars._bars[0]._ha_high < OrderOpenPrice()
						&& g_bars._bars[1]._ha_high < OrderOpenPrice()
						&& g_bars._bars[2]._ha_high < OrderOpenPrice()
						&& g_bars._bars[3]._ha_high < OrderOpenPrice()
						)
					{
						_short_stoploss = OrderOpenPrice();
						//Print("[DEBUG] g_break_even_clasp 1  _short_stoploss = ", OrderOpenPrice());
					}
					else if (OrderProfit() > 0
						&& g_bars._bars[1].is_ha_bear() 
						&& g_bars._bars[2].is_ha_bear()
						&& g_bars._bars[1]._ha_high < g_bars._bars[2]._ha_high
						)
					{
						_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
						_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.5);
						if (g_time_frame <= PERIOD_H1
							|| (MathAbs(g_bars._bars[1]._ha_high - g_bars._bars[2]._ha_high) < (MathAbs(g_bars._bars[2]._ha_high - g_bars._bars[2]._ha_low) * 0.15))
							)
						{
							_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
						}
						_short_stoploss = MathMax(_short_stoploss, OrderOpenPrice());
						//Print("[DEBUG] g_break_even_clasp 2   _short_stoploss = ", OrderOpenPrice());
					}
				}
				else if (g_break_even)
				{
					//Print("[DEBUG] g_break_even ");
					if ((Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3)
						//|| (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 2 && g_bars._bars[1]._ha_high < g_bars._bars[1]._ma_dragon_centre)
						)
					{
						_short_stoploss = OrderOpenPrice();
						//Print("[DEBUG] g_break_even _short_stoploss = ", OrderOpenPrice());
					}
				}
				if (pre_short_stoploss != _short_stoploss)
				{
					modify_order_short(_short_stoploss);
				}
			}
			
			pre_short_stoploss = _short_stoploss;
			if (g_stop_by_ha)       // ha
			{
				if (g_bars._bars[1].is_ha_bear() 
					&& g_bars._bars[2].is_ha_bear()
					&& g_bars._bars[1]._ha_high < g_bars._bars[2]._ha_high 
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ha_high + g_bars._bars[1]._atr * 0.5);
					if (g_time_frame <= PERIOD_H1
						|| (MathAbs(g_bars._bars[1]._ha_high - g_bars._bars[2]._ha_high) < (MathAbs(g_bars._bars[2]._ha_high - g_bars._bars[2]._ha_low) * 0.15))
						)
					{
						_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					}
				}
			}
			else if (g_stop_by_dragon)        // ma dragon
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_dragon_low
					&& (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_dragon_high);
				}
			}
			else if (g_stop_by_trend)        // ma trend
			{
				// 价格在短期均线下，才计算止损
				if (Bid < g_bars._bars[0]._ma_trend
					&& (Bid < OrderOpenPrice() - g_bars._bars[1]._atr * 3)
					)
				{
					_short_stoploss = MathMax(g_bars._bars[1]._ha_high, g_bars._bars[2]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[3]._ha_high);
					_short_stoploss = MathMax(_short_stoploss, g_bars._bars[1]._ma_trend);
				}
			}
			if (pre_short_stoploss != _short_stoploss)
			{
				modify_order_short(_short_stoploss);
			}
			
			pre_short_stoploss = _short_stoploss;
			if (g_stop_by_channel)        // 根据 Donchian通道 计算止损
			{
				_short_stoploss = g_bars._bars[1]._tutle_long_high + g_bars._bars[1]._atr;
			}
			if (pre_short_stoploss != _short_stoploss)
			{
				modify_order_short(_short_stoploss);
			}
		}
	}
}

void trailing_stop2::check_trailing_stoploss()
{
	if (!g_stop_enable)
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
	// MODE_STOPLEVEL 太大，直接操作平仓来止损。
	//
	if (_long_stoploss > 0)
	{
		//g_bars.calc();
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
		//g_bars.calc();
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

void trailing_stop2::modify_order_long(double sl)
{
	//
	// 没有打开 EA,不操作
	//
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (sl <= 0.00001)
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
	if (!IsTradeAllowed()) 
	{
		return;
	}
	if (sl <= 0.00001)
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
