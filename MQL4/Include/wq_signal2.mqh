#property strict
#include <wq_util.mqh>
#include <wq_ind.mqh>



// ===============================================================

class signal2
{
public:
	signal2(int magic, string symbol, int time_frame);
	~signal2();
	
	bool long_condition();
	bool short_condition();

private:
	void calc();

public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	indicator* _bars[20];
	int _bars_size;
	
	double _long_stoploss;
	double _short_stoploss;
	
	double _stoploss_atr_factor;
};

// ===============================================================

signal2::signal2(int magic, string symbol, int time_frame)
{
	_magic = magic;
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_size = 19;
	for (int i = 0; i < _bars_size; ++i)
	{
		_bars[i] = new indicator(_symbol, _time_frame);
	}
	
	_long_stoploss = 0.0;
	_short_stoploss = 0.0;
	
	_stoploss_atr_factor = 1.5;
}

signal2::~signal2()
{
	for (int i = 0; i < _bars_size; ++i)
	{
		delete _bars[i];
	}
}

void signal2::calc()
{
	if (g_is_new_bar)
	{
		for (int i = 0; i < _bars_size; ++i)
		{
			_bars[i].calc(i);
		}
	}
	else
	{
		//
		// 每个tick都计算
		//
		_bars[0].calc(0);
	}
}

bool signal2::long_condition()
{
	//
	// 计算当前k线的ha，每次tick都计算1次
	//
	calc();
	
	//
	// 当前的k线，正在跌，不能作多
	//
	if (_bars[0].is_ha_bear())    
	{
		return false;
	}
	
	//
	// 检查 ma，确定开仓方向
	//
	if (g_signal_check_by_ma)
	{
		if ((_bars[0]._ma_dragon_centre < _bars[0]._ma_trend)     // 死叉，不作多
			)
		{
			return false;
		}
	}
	
	//
	// 寻找趋势反转，确定颈线
	//
	double find = 0.0;
	_long_stoploss = _bars[0]._ha_low;
	int find_id = 0;
	for (int i = 1; i < _bars_size-2; ++i)
	{
		_long_stoploss = MathMin(_long_stoploss, _bars[i]._ha_low);
		if (_bars[i].is_ha_bear() 
			&& _bars[i+1].is_ha_bear()
			&& _bars[i]._ha_high < _bars[i+1]._ha_high
			)
		{
			find_id = i;
			if (g_time_frame <= PERIOD_H1)
			{
				find = MathMax(_bars[i]._ha_high, _bars[i+1]._ha_high);
				//find = MathMax(find, _bars[i+2]._ha_high);
				_long_stoploss = MathMin(_long_stoploss, _bars[i+1]._ha_low);
				_long_stoploss = MathMin(_long_stoploss, _bars[i+2]._ha_low);
			}
			else if (g_time_frame >= PERIOD_H4)
			{
				find = _bars[i]._ha_high;
			}
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
		if (_long_stoploss > _bars[find_id]._ma_dragon_high)
		{
			return false;
		}
	}
	
	if (g_signal_check_by_trend)
	{
		if (_long_stoploss > _bars[find_id]._ma_trend)
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
	if (_bars[0]._ha_low < find)
	{
		if (_bars[0]._ha_close >= find    // 用 ha_close 来计算，尽量防止假突破
			|| Bid >= find + _bars[1]._atr * 0.5
			)
		{
			if (g_time_frame <= PERIOD_H1)
			{
				_long_stoploss = MathMin(_long_stoploss, Bid - _bars[1]._atr * _stoploss_atr_factor);    // 避免止损线太近，需要至少 1.5ATR
			}
			
			Print("[INFO][", _symbol, "][", get_time_frame_str(_time_frame), "][long_condition]find=", DoubleToString(find, g_digits), ";ha_close=", DoubleToString(_bars[0]._ha_close, g_digits), ";Ask=", DoubleToString(Ask, g_digits), ";_long_stoploss=", DoubleToString(_long_stoploss, g_digits));
			
			return true;
		}
	}
	
	return false;
}

bool signal2::short_condition()
{
	calc();
	
	if (_bars[0].is_ha_bull())
	{
		return false;
	}
	
	if (g_signal_check_by_ma)
	{
		if ((_bars[0]._ma_dragon_centre > _bars[0]._ma_trend)
			)
		{
			return false;
		}
	}
	
	double find = 0.0;
	_short_stoploss = _bars[0]._ha_high;
	int find_id = 0;
	for (int i = 1; i < _bars_size-2; ++i)
	{
		_short_stoploss = MathMax(_short_stoploss, _bars[i]._ha_high);
		if (_bars[i].is_ha_bull() 
			&& _bars[i+1].is_ha_bull()
			&& _bars[i]._ha_low > _bars[i+1]._ha_low
			)
		{
			find_id = i;
			if (g_time_frame <= PERIOD_H1)
			{
				find = MathMin(_bars[i]._ha_low, _bars[i+1]._ha_low);
				//find = MathMin(find, _bars[i+2]._ha_low);
				_short_stoploss = MathMax(_short_stoploss, _bars[i+1]._ha_high);
				_short_stoploss = MathMax(_short_stoploss, _bars[i+2]._ha_high);
			}
			else if (g_time_frame >= PERIOD_H4)
			{
				find = _bars[i]._ha_low;
			}
			break;
		}
	}

	if (find <= 0.0001)
	{
		return false;
	}
	
	if (g_signal_check_by_dragon)
	{
		if (_short_stoploss < _bars[find_id]._ma_dragon_low)
		{
			return false;
		}
	}
	
	if (g_signal_check_by_trend)    
	{
		if (_short_stoploss < _bars[find_id]._ma_trend)
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
	
	if (_bars[0]._ha_high > find)
	{
		if (_bars[0]._ha_close < find
			|| Ask <= find - _bars[1]._atr * 0.5
			)
		{
			if (g_time_frame <= PERIOD_H1)
			{
				_short_stoploss = MathMax(_short_stoploss, Ask + _bars[1]._atr * _stoploss_atr_factor);
			}
			
			Print("[INFO][", _symbol, "][", get_time_frame_str(_time_frame), "][short_condition]find=", DoubleToString(find, g_digits), ";ha_close=", DoubleToString(_bars[0]._ha_close, g_digits), ";Bid=", DoubleToString(Bid, g_digits), ";_short_stoploss=", DoubleToString(_short_stoploss, g_digits));
			
			return true;
		}
	}
	
	return false;
}
