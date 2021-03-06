#property strict

extern double g_lots_factor = 1.5;			// [下注] 倍数
extern double g_lots_profit_f = 1.5;		// [下注] 盈亏比
extern double g_lots_min = 0.01;			   // [下注] 最小注
extern double g_lots_max = 10.0;			   // [下注] 最大注
extern int g_lots_order_max = 1;          // [下注] 最大下注次数
extern double g_lots_sum_max = 10;        // [下注] 最大下注总量
extern bool g_lots_reset = false;			// [下注] 重新开始

// ==========================================================================

#include <wq_order.mqh>

class lots_trend
{
public:
	lots_trend();
	
	double calc_lots_martin_by_history();
	
	bool is_profit();
	
public:
   double _calc_lots_tudo;
   int _count;
};

lots_trend* g_lots = NULL;

// ==========================================================================

lots_trend::lots_trend()
{
	_calc_lots_tudo = 0;
	_count = 0;
}

double lots_trend::calc_lots_martin_by_history()
{
	_calc_lots_tudo = g_lots_min;
	g_order.get_history();
	if (g_lots_reset)
	{
		g_lots_reset = false;
		_calc_lots_tudo = g_lots_min;
	}
	else
	{
		if (g_order._history_profit_sum >= 0)  // 赚钱
		{
			if (g_order._history_profit_sum < MathAbs(g_order._history_loss_max) * (g_lots_profit_f - 1)) // 赚钱，但没有达到目标
			{
				_calc_lots_tudo = g_order._history[0]._lots;
			}
			else // 赚钱，达到目标，一场战役结束
			{
				_calc_lots_tudo = g_lots_min;
			}
		}
		else // 亏损
		{
			if (g_order._history_loss_max < g_order._history_profit_sum) // 亏损好转
			{
				_calc_lots_tudo = g_order._history[0]._lots;
			}
	   		else // 新增亏损
	   		{
				if (g_lots_factor >= 1)
				{
					if (g_order._history[0]._lots <= 0.01)
					{
						_calc_lots_tudo = g_order._history[0]._lots * 2;
					}
					else
					{
						_calc_lots_tudo = g_order._history[0]._lots * g_lots_factor;
					}
				}
				else
				{
					_calc_lots_tudo = g_order._history[0]._lots;
				}
				++_count;
			}
		}
	}
	if (_calc_lots_tudo > g_lots_max)
	{
		_calc_lots_tudo = g_lots_max;
		g_lots_reset = true;
	}
	if (_calc_lots_tudo <= g_lots_min)
	{
		_count = 1;
	}
	return _calc_lots_tudo;
}

bool lots_trend::is_profit()
{
	g_order.get_history();
	if (g_order._history_profit_sum >= 0)
	{
		if (g_order._history_profit_sum >= MathAbs(g_order._history_loss_max) * (g_lots_profit_f - 1))
		{
			return true;
		}
	}
	return false;
}
