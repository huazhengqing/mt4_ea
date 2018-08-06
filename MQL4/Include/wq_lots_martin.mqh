#property strict

extern double g_lots_factor = 2;          // [下注] 倍数
extern double g_lots_min = 0.01;			   // [下注] 最小注
extern double g_lots_max = 10.0;			   // [下注] 最大注
extern int g_lots_order_max = 15;         // [下注] 最大下注次数
extern double g_lots_sum_max = 20;        // [下注] 最大下注总量
extern bool g_lots_reset = false;			// [下注] 重新开始

// ==========================================================================

#include <wq_order.mqh>

class lots_martin
{
public:
   double calc_lots_martin_by_trade(int order_type);
   
public:
   double _calc_lots_tudo;
};

lots_martin* g_lots = NULL;

// ==========================================================================

double lots_martin::calc_lots_martin_by_trade(int order_type)
{
	g_order.get_trade(order_type);
	if (g_order._trade_lots_sum > g_lots_sum_max
		|| g_order._trade_get_size >= g_lots_order_max
		)
	{
		_calc_lots_tudo = 0;
		return 0;
	}
	_calc_lots_tudo = g_lots_min;
	if (g_lots_reset)
	{
		g_lots_reset = false;
		_calc_lots_tudo = g_lots_min;
	}
	else
	{
		if (g_order._trade_get_size <= 0)
		{
			_calc_lots_tudo = g_lots_min;
		}
		else
		{
			if (g_lots_factor >= 1)
			{
				if (g_order._trade[0]._lots <= 0.01)
				{
					_calc_lots_tudo = g_order._trade[0]._lots * 2;
				}
				else
				{
					_calc_lots_tudo = g_order._trade[0]._lots * g_lots_factor;
				}
			}
			else
			{
				_calc_lots_tudo = g_order._trade[0]._lots;
			}
		}
	}
	if (g_order._trade_get_size >= 7)
	{
		_calc_lots_tudo = g_order._trade[0]._lots;
	}
	if (_calc_lots_tudo > g_lots_max)
	{
		_calc_lots_tudo = g_lots_max;
		//g_lots_reset = true;
	}
	return _calc_lots_tudo;
}

