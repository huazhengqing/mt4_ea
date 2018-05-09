#property strict
#include <wq_util.mqh>
#include <wq_ind.mqh>
#include <wq_bars.mqh>


// ===============================================================

class signal2
{
public:
	signal2(int magic, string symbol, int time_frame);
	~signal2();
	
	bool long_condition();
	bool short_condition();
	
private:
	int estimate_trend();

	bool is_long_breakout(double find, int i);
	bool is_short_breakout(double find, int i);

private:
	int _magic;
	string _symbol;
	int _time_frame;
	
	int _find_long_id;
	int _find_short_id;
	
	double _stoploss_atr_factor;
	
public:
	bars* g_bars;
	
	double _long_stoploss;
	double _short_stoploss;
	
};

// ===============================================================

signal2::signal2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_find_long_id = 0;
	_find_short_id = 0;
	
	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
	
	_stoploss_atr_factor = 1.5;
}

signal2::~signal2()
{
}

int signal2::estimate_trend()
{
	if (g_bars._bars[1]._ma_dragon_centre > g_bars._bars[1]._ma_trend    // 均线多头
		&& g_bars._bars[2]._ma_dragon_centre < g_bars._bars[1]._ma_dragon_centre    // 均线涨
		&& g_bars._bars[2]._ma_trend < g_bars._bars[1]._ma_trend    // 均线涨
		)
	{
		return 1;
	}
	else if (g_bars._bars[1]._ma_dragon_centre < g_bars._bars[1]._ma_trend    // 均线空头
		&& g_bars._bars[2]._ma_dragon_centre > g_bars._bars[1]._ma_dragon_centre    // 均线跌
		&& g_bars._bars[2]._ma_trend > g_bars._bars[1]._ma_trend    // 均线跌
		)
	{
		return -1;
	}
	if (g_rsi_ac_bull && (g_bars._bars[2]._ma_trend < g_bars._bars[1]._ma_trend))
	{
		return 1;
	}
	if (g_rsi_ac_bear && (g_bars._bars[2]._ma_trend > g_bars._bars[1]._ma_trend))
	{
		return -1;
	}
/*
	if (g_rsi_ac_bull
		&& g_bars._bars[0]._ha_low > g_bars._bars[0]._ma_trend
		&& g_bars._bars[1]._ha_low > g_bars._bars[1]._ma_trend
		&& g_bars._bars[2]._ha_low > g_bars._bars[2]._ma_trend
		&& g_bars._bars[3]._ha_low > g_bars._bars[3]._ma_trend
		)
	{
		return 1;
	}
	if (g_rsi_ac_bear
		&& g_bars._bars[0]._ha_high < g_bars._bars[0]._ma_trend
		&& g_bars._bars[1]._ha_high < g_bars._bars[1]._ma_trend
		&& g_bars._bars[2]._ha_high < g_bars._bars[2]._ma_trend
		&& g_bars._bars[3]._ha_high < g_bars._bars[3]._ma_trend
		)
	{
		return -1;
	}
*/

	if (g_bars._bars[2]._ma_trend < g_bars._bars[1]._ma_trend)
	{
		return 1;
	}
	else if (g_bars._bars[2]._ma_trend > g_bars._bars[1]._ma_trend)
	{
		return -1;
	}
	else
	{
		if (g_bars._bars[3]._ma_trend < g_bars._bars[2]._ma_trend)
		{
			return 1;
		}
		else if (g_bars._bars[3]._ma_trend > g_bars._bars[2]._ma_trend)
		{
			return -1;
		}
	}
	//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "] estimate_trend()=0  ");
	return 0;
}

bool signal2::long_condition()
{
	//
	// 计算当前k线的ha，每次tick都计算1次
	//
	g_bars.calc();

	if (g_bars._bars[0].is_ha_bear())
	{
		return false;
	}
	if (g_estimate_trend)
	{
		if (estimate_trend() < 0)
		{
			return false;
		}
	}

	//
	// 寻找趋势反转，确定颈线
	//
	double find = 0.0;
	_long_stoploss = g_bars._bars[0]._ha_low;
	_find_long_id = 0;
	for (int i = 1; i < g_bars._bars_size-2; ++i)
	{
		_long_stoploss = MathMin(_long_stoploss, g_bars._bars[i]._ha_low);
		if (g_bars._bars[i].is_ha_bear() 
			&& g_bars._bars[i+1].is_ha_bear()
			&& g_bars._bars[i]._ha_high < g_bars._bars[i+1]._ha_high
			)
		{
			_find_long_id = i;
			find = MathMax(g_bars._bars[i]._ha_high, g_bars._bars[i+1]._ha_high);
			find = MathMax(find, g_bars._bars[i]._ha_high + g_bars._bars[i]._atr * 0.3);
			_long_stoploss = MathMin(_long_stoploss, g_bars._bars[i+1]._ha_low);
			_long_stoploss = MathMin(_long_stoploss, g_bars._bars[i+2]._ha_low);
			break;
		}
	}

	if (find <= 0.0001)    // 并没有趋势反转
	{
		return false;
	}
	
	//
	// 过滤参数
	//
	if (g_signal_check_by_dragon)
	{
		if (_long_stoploss > g_bars._bars[_find_long_id]._ma_dragon_high)
		{
			return false;
		}
	}
	if (g_signal_check_by_trend)
	{
		if (_long_stoploss > g_bars._bars[_find_long_id]._ma_trend)
		{
			return false;
		}
	}
	if (g_signal_greater > 0.0001)
	{
		if (_long_stoploss < g_signal_greater) 
		{
			return false;
		}
	}
	if (g_signal_less > 0.0001)
	{
		if (_long_stoploss > g_signal_less) 
		{
			return false;
		}
	}
	
	//
	// 突破颈线，开仓
	//
	if (is_long_breakout(find, 0))
	{
		//if (is_long_breakout(find, 1) || is_long_breakout(find, 2) || is_long_breakout(find, 3))    // 确保是第1次突破
		//{
		//	return false;
		//}
		if (g_time_frame <= PERIOD_H1)
		{
			_long_stoploss = MathMin(_long_stoploss, Bid - g_bars._bars[1]._atr * _stoploss_atr_factor);    // 避免止损线太近，需要至少 1.5ATR
		}
		//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "][long_condition]find=", DoubleToString(find, g_digits), ";ha_close=", DoubleToString(g_bars._bars[0]._ha_close, g_digits), ";Ask=", DoubleToString(Ask, g_digits), ";_long_stoploss=", DoubleToString(_long_stoploss, g_digits));
		return true;
	}
	
	return false;
}

bool signal2::is_long_breakout(double find, int i)
{
	if (g_bars._bars[i].is_ha_bear())
	{
		return false;
	}
	if (g_bars._bars[i]._ha_low < find && g_bars._bars[i]._ha_high > find && Bid > find)
	{
		if (g_bars._bars[i]._ha_close > find    // 用 ha_close 来计算，尽量防止假突破
			|| Bid >= find + g_bars._bars[i+1]._atr * 0.3
			|| (g_bars._bars[i+1].is_ha_bull() && g_bars._bars[i+2].is_ha_bull() && g_bars._bars[i]._ha_high > g_bars._bars[i+1]._ha_high && g_bars._bars[i+1]._ha_high > g_bars._bars[i+2]._ha_high)
			|| (g_bars._bars[i+1].is_ha_bull() || g_bars._bars[i+2].is_ha_bull())
			)
		{
			return true;
		}
	}
	return false;
}

bool signal2::short_condition()
{
	g_bars.calc();
	
	if (g_bars._bars[0].is_ha_bull())
	{
		return false;
	}
	if (g_estimate_trend)
	{
		if (estimate_trend() > 0)
		{
			return false;
		}
	}
	
	double find = 0.0;
	_short_stoploss = g_bars._bars[0]._ha_high;
	_find_short_id = 0;
	for (int i = 1; i < g_bars._bars_size-2; ++i)
	{
		_short_stoploss = MathMax(_short_stoploss, g_bars._bars[i]._ha_high);
		if (g_bars._bars[i].is_ha_bull() 
			&& g_bars._bars[i+1].is_ha_bull()
			&& g_bars._bars[i]._ha_low > g_bars._bars[i+1]._ha_low
			)
		{
			_find_short_id = i;
			find = MathMin(g_bars._bars[i]._ha_low, g_bars._bars[i+1]._ha_low);
			find = MathMin(find, g_bars._bars[i]._ha_low - g_bars._bars[i]._atr * 0.3);
			_short_stoploss = MathMax(_short_stoploss, g_bars._bars[i+1]._ha_high);
			_short_stoploss = MathMax(_short_stoploss, g_bars._bars[i+2]._ha_high);
			break;
		}
	}

	if (find <= 0.0001)
	{
		return false;
	}
	
	if (g_signal_check_by_dragon)
	{
		if (_short_stoploss < g_bars._bars[_find_short_id]._ma_dragon_low)
		{
			return false;
		}
	}
	if (g_signal_check_by_trend)    
	{
		if (_short_stoploss < g_bars._bars[_find_short_id]._ma_trend)
		{
			return false;
		}
	}

	if (g_signal_greater > 0.0001)    
	{
		if (_short_stoploss < g_signal_greater) 
		{
			return false;
		}
	}
	if (g_signal_less > 0.0001)    
	{
		if (_short_stoploss > g_signal_less) 
		{
			return false;
		}
	}
	
	if (is_short_breakout(find, 0))
	{
		//if (is_short_breakout(find, 1) || is_short_breakout(find, 2) || is_short_breakout(find, 3))
		//{
		//	return false;
		//}
		if (g_time_frame <= PERIOD_H1)
		{
			_short_stoploss = MathMax(_short_stoploss, Bid + g_bars._bars[1]._atr * _stoploss_atr_factor);
		}
		//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "][short_condition]find=", DoubleToString(find, g_digits), ";ha_close=", DoubleToString(g_bars._bars[0]._ha_close, g_digits), ";Bid=", DoubleToString(Bid, g_digits), ";_short_stoploss=", DoubleToString(_short_stoploss, g_digits));
		return true;
	}
	return false;
}

bool signal2::is_short_breakout(double find, int i)
{
	if (g_bars._bars[i].is_ha_bull())
	{
		return false;
	}
	if (g_bars._bars[i]._ha_high > find && g_bars._bars[i]._ha_low < find && Bid < find)
	{
		if (g_bars._bars[i]._ha_close < find    // 用 ha_close 来计算，尽量防止假突破
			|| (Bid <= find - g_bars._bars[i+1]._atr * 0.3)
			|| (g_bars._bars[i+1].is_ha_bear() && g_bars._bars[i+2].is_ha_bear() && g_bars._bars[i]._ha_low < g_bars._bars[i+1]._ha_low && g_bars._bars[i+1]._ha_low < g_bars._bars[i+2]._ha_low)
			|| (g_bars._bars[i+1].is_ha_bear() || g_bars._bars[i+2].is_ha_bear())
			)
		{
			return true;
		}
	}
	return false;
}
