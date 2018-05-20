#property strict

// ===============================================================

#include <wq_ind.mqh>

// ===============================================================

class bars
{
public:
	bars(string symbol, int time_frame);
	~bars();
	
	void tick_start();
	
	void calc();
	void calc_rsi_ac();
	
	int is_volatile_ok();
	int is_burst();
	int estimate_trend();
	
	bool is_breakout_long();	// buy
	bool is_breakout_short();	// sell
	
	bool is_ma_bottom();	// buy
	bool is_ma_top();	// sell
	
	bool is_bottom_reverse();	// buy
	bool is_top_reverse();	// sell
	
public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	indicator* _bars[360];
	int _bars_size;
	bool _is_bars_init;
	bool _is_tick_ok;
	
	double _atr_max;
	int _atr_max_period;
	datetime _atr_max_time;
	bool _atr_max_enable;
	
	int _donchian_trend;
	
	datetime _time_breakout_long;
	datetime _time_breakout_short;
	
	bool _rsi_ac_bull;
	bool _rsi_ac_bear;
	
	// buy
	double _bottom_reverse_threshold;
	double _bottom_low;
	indicator* _bottom_bar;
	
	// sell
	double _top_reverse_threshold;
	double _top_high;
	indicator* _top_bar;
	
};

// ===============================================================

bars::bars(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_size = 90;
	for (int i = 0; i < _bars_size; ++i)
	{
		_bars[i] = new indicator(_symbol, _time_frame);
	}
	_is_bars_init = false;
	_is_tick_ok = false;
	
	_atr_max = 0;
	_atr_max_period = 360;
	_atr_max_time = 0;
	_atr_max_enable = true;
	
	_donchian_trend = 0;
	
	_time_breakout_long = 0;
	_time_breakout_short = 0;
	
	_rsi_ac_bull = false;
	_rsi_ac_bear = false;
	
	_bottom_reverse_threshold = 0;
	_bottom_low = 0;
	_bottom_bar = new indicator(_symbol, _time_frame);
	
	_top_reverse_threshold = 0;
	_top_high = 0;
	_top_bar = new indicator(_symbol, _time_frame);
}

bars::~bars()
{
	delete _bottom_bar;
	delete _top_bar;
	for (int i = 0; i < _bars_size; ++i)
	{
		delete _bars[i];
		_bars[i] = NULL;
	}
}

void bars::tick_start()
{
	_is_tick_ok = false;
}

void bars::calc_rsi_ac()
{
	_bars[0]._rsi = iRSI(_symbol, _time_frame, g_rsi_period, PRICE_CLOSE, 0);
	_bars[0].calc_ac(0);
	if (!_rsi_ac_bull)
	{
		if (_bars[0]._rsi >= 70.0 && _bars[0]._ac_index  >= 1)
		{
			_rsi_ac_bull = true;
			_rsi_ac_bear = false;
		}
	}
	if (!_rsi_ac_bear)
	{
		if (_bars[0]._rsi <= 30 && _bars[0]._ac_index <= -1)
		{
			_rsi_ac_bear = true;
			_rsi_ac_bull = false;
		}
	}
/*
	if (_rsi_ac_bull)
	{
		if (_bars[0]._rsi >= 70.0 && _bars[0]._ac_index < 0)
		{
			_rsi_ac_bull = false;
		}
	}
	if (_rsi_ac_bear)
	{
		if (_bars[0]._rsi <= 30 && _bars[0]._ac_index > 0)
		{
			_rsi_ac_bear = false;
		}
	}
*/
}

void bars::calc()
{
	if (!_is_bars_init)
	{
		if (!_is_tick_ok)
		{
			for (int i = 0; i < _bars_size; ++i)
			{
				_bars[i].calc(i);
			}
			for (int i = _bars_size-6; i >= 0; --i)
			{
				if (_bars[i]._ha_close > _bars[i+3]._tutle_long_high)
				{
					_donchian_trend = 1;
				}
				else if (_bars[i]._ha_close < _bars[i+3]._tutle_long_low)
				{
					_donchian_trend = -1;
				}
				if (true)
				{
					if (_bars[i].is_ha_bear()
						&& _bars[i+1].is_ha_bear()
						&& _bars[i]._ha_high < _bars[i+1]._ha_high
						)
					{
						_bottom_reverse_threshold = _bars[i]._ha_high + _bars[i]._atr * 0.3;
						_bottom_low = Low[iLowest(_symbol, _time_frame, MODE_LOW, 5, i)];
						_bottom_bar.assign(_bars[i]);
					}
					else if (_bars[i].is_ha_bull() 
						&& _bars[i+1].is_ha_bull()
						&& _bars[i]._ha_low > _bars[i+1]._ha_low
						)
					{
						_top_reverse_threshold = _bars[i]._ha_low - _bars[i]._atr * 0.3;
						_top_high = High[iHighest(_symbol, _time_frame, MODE_HIGH, 5, i)];
						_top_bar.assign(_bars[i]);
					}
				}
			}
			if (_atr_max_enable)
			{
				_atr_max = _bars[1]._atr;
				for (int i = g_atr_period/2; i < _atr_max_period; NULL)
				{
					_atr_max = MathMax(_atr_max, iATR(_symbol, _time_frame, g_atr_period, i));
					i = i + g_atr_period/2;
				}
				_atr_max_time = iTime(_symbol, _time_frame, 0);
			}
			//calc_rsi_ac();
			
			
			
			
			_is_tick_ok = true;
		}
		_is_bars_init = true;
	}
	else
	{
		if (g_is_new_bar)
		{
			if (!_is_tick_ok)
			{
/*
				for (int i = _bars_size-1; i >= 1; --i)
				{
					_bars[i] = _bars[i-1];
				}
				_bars[0].calc(0);
*/
				for (int i = 0; i < _bars_size; ++i)
				{
					_bars[i].calc(i);
				}
				if (_bars[0]._ha_close > _bars[5]._tutle_long_high)
				{
					_donchian_trend = 1;
				}
				else if (_bars[0]._ha_close < _bars[5]._tutle_long_low)
				{
					_donchian_trend = -1;
				}
				if (_atr_max_enable)
				{
					if (iTime(_symbol, _time_frame, 0) > _atr_max_time + _time_frame * 60 * (_atr_max_period/5))
					{
					
						_atr_max = _bars[1]._atr;
						for (int i = g_atr_period/2; i < _atr_max_period; NULL)
						{
							_atr_max = MathMax(_atr_max, iATR(_symbol, _time_frame, g_atr_period, i));
							i = i + g_atr_period/2;
						}
						_atr_max_time = iTime(_symbol, _time_frame, 0);
					}
				}
				//calc_rsi_ac();
				if (true)
				{
					if (_bars[1].is_ha_bear()
						&& _bars[2].is_ha_bear()
						&& _bars[1]._ha_high < _bars[2]._ha_high
						)
					{
						_bottom_reverse_threshold = _bars[1]._ha_high + _bars[1]._atr * 0.3;
						_bottom_low = Low[iLowest(_symbol, _time_frame, MODE_LOW, 5, 0)];
						_bottom_bar.assign(_bars[1]);
					}
					else if (_bars[1].is_ha_bull() 
						&& _bars[2].is_ha_bull()
						&& _bars[1]._ha_low > _bars[2]._ha_low
						)
					{
						_top_reverse_threshold = _bars[1]._ha_low - _bars[1]._atr * 0.3;
						_top_high = High[iHighest(_symbol, _time_frame, MODE_HIGH, 5, 0)];
						_top_bar.assign(_bars[1]);
					}
				}
		


				_is_tick_ok = true;
			}
		}
		else
		{
			if (!_is_tick_ok)
			{
				_bars[0].calc(0);		// 每个tick都计算
				if (_bars[0]._ha_close > _bars[5]._tutle_long_high)
				{
					_donchian_trend = 1;
				}
				else if (_bars[0]._ha_close < _bars[5]._tutle_long_low)
				{
					_donchian_trend = -1;
				}
				//calc_rsi_ac();
				
				_is_tick_ok = true;
			}
		}
	}
}

/*******************************
2: 波动很大
1: 有波动
0: 没有波动
*******************************/
int bars::is_volatile_ok()
{
	if (_bars[0]._bolling_up - _bars[0]._bolling_low > _atr_max * 10
		|| _bars[0]._tutle_long_high - _bars[0]._tutle_long_low > _atr_max * 10
		)
	{
		return 2;
	}
	if ((_bars[0]._bolling_up - _bars[0]._bolling_low) > (_bars[25]._bolling_up - _bars[25]._bolling_low) * 2
		&& _bars[0]._bolling_up - _bars[0]._bolling_low > _bars[1]._atr * 4
		&& _bars[0]._bolling_up - _bars[0]._bolling_low > _atr_max * 2
		)
	{
		return 1;
	}
	if (_bars[0]._bolling_up - _bars[0]._bolling_low < _atr_max * 2.5)
	{
		return 0;
	}
/*
	if (MathAbs(_bars[0]._ma_dragon_centre - _bars[0]._ma_trend) < _bars[1]._atr	// 均线 粘合
		&& _bars[1]._atr < _atr_max * 0.3
		&& _bars[0]._bolling_up - _bars[0]._bolling_low < _atr_max * 2.5)
	{
		return 0;
	}
*/
	if ((_bars[0]._bolling_up - _bars[0]._bolling_low < _atr_max * 4)
		&& (_bars[0]._bolling_up - _bars[0]._bolling_low) < (_bars[25]._bolling_up - _bars[25]._bolling_low) * 0.5
		)
	{
		return 0;
	}
	if (_bars[0]._tutle_long_high - _bars[0]._tutle_long_low < _atr_max * 4
		&& _bars[0]._tutle_long_high < _bars[20]._tutle_long_high
		&& _bars[0]._tutle_long_low > _bars[20]._tutle_long_low
		)
	{
		return 0;
	}
	if (_bars[1]._atr < _atr_max * 0.2)
	{
		return 0;
	}
	for (int i = 0; i < 20; ++i)
	{
		if (_bars[i]._bolling_up - _bars[i]._bolling_low > _atr_max * 10
			|| _bars[i]._tutle_long_high - _bars[i]._tutle_long_low > _atr_max * 10
			)
		{
			return 2;
		}
		if ((_bars[i]._bolling_up - _bars[i]._bolling_low) > (_bars[i+25]._bolling_up - _bars[i+25]._bolling_low) * 5
			)
		{
			return 2;
		}
		if (_bars[i]._ha_high - _bars[i]._ha_low > _atr_max * 0.7)
		{
			//return 1;
		}
		if (_bars[i]._burst > 15)
		{
			//return 1;
		}
	}
	return 1;
}

int bars::is_burst()
{
	for (int i = 0; i < 10; ++i)
	{
		if (_bars[i]._burst >= 15)
		{
			if (_bars[i].is_ha_bull())
			{
				return 1;
			}
			else if (_bars[i].is_ha_bear())
			{
				return -1;
			}
		}
	}
	return 0;
}

bool bars::is_breakout_long()
{
	if (_bars[0].is_ha_bear())
	{
		return false;
	}
	if (_time_breakout_long > 0 && iTime(_symbol, _time_frame, 0) < _time_breakout_long + _time_frame * 60 * (5))
	{
		//return false;
	}
	if (_bars[0]._ha_close > _bars[5]._tutle_long_high
		//|| Bid > _bars[5]._tutle_long_high + _bars[1]._atr * 0.5
		)
	{
		_time_breakout_long = iTime(_symbol, _time_frame, 0);
		return true;
	}
/*
		if (_bars[0]._burst > 5 
			|| _bars[1]._burst > 5 
			|| _bars[2]._burst > 5
			|| (_bars[0]._ha_high - _bars[0]._ha_low) > _bars[1]._atr * 3
			|| (_bars[1]._ha_high - _bars[1]._ha_low) > _bars[1]._atr * 3
			|| (_bars[2]._ha_high - _bars[2]._ha_low) > _bars[1]._atr * 3
			)
		{
			_time_breakout_long = iTime(_symbol, _time_frame, 0);
			return true;
		}
		if ((_bars[0]._ha_close > _bars[1]._bolling_up 
				&& _bars[0]._ha_close > _bars[3]._tutle_long_high 
				&& (_bars[0]._ha_high - _bars[0]._ha_low) > _bars[1]._atr * 2 
				)
			|| (_bars[0]._ha_close > _bars[2]._bolling_up 
				&& _bars[1]._ha_close > _bars[2]._bolling_up 
				&& _bars[0]._ha_close > _bars[3]._tutle_long_high 
				&& _bars[1]._ha_close > _bars[3]._tutle_long_high 
				)
			)
		{
			_time_breakout_long = iTime(_symbol, _time_frame, 0);
			return true;
		}
*/
	return false;
}

bool bars::is_breakout_short()
{
	if (_bars[0].is_ha_bull())
	{
		return false;
	}
	if (_time_breakout_short > 0 && iTime(_symbol, _time_frame, 0) < _time_breakout_short + _time_frame * 60 * (5))
	{
		//return false;
	}
	if (_bars[0]._ha_close < _bars[5]._tutle_long_low
		//|| Bid < _bars[5]._tutle_long_low - _bars[1]._atr * 0.5
		)
	{
		_time_breakout_short = iTime(_symbol, _time_frame, 0);
		return true;
	}
/*
		if ((_bars[0]._ha_close < _bars[1]._bolling_low 
				&& _bars[0]._ha_close < _bars[3]._tutle_long_low
				&& (_bars[0]._ha_high - _bars[0]._ha_low) > _bars[1]._atr * 2
				)
			|| (_bars[0]._ha_close < _bars[2]._bolling_low 
				&& _bars[1]._ha_close < _bars[2]._bolling_low
				&& _bars[0]._ha_close < _bars[3]._tutle_long_low 
				&& _bars[1]._ha_close < _bars[3]._tutle_long_low 
				)
			)
*/
	return false;
}

bool bars::is_ma_bottom()
{
	if (_bars[0].is_ha_bear())
	{
		return false;
	}
	// down
	if ((_bars[5]._ma_dragon_centre > _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre > _bars[3]._ma_dragon_centre && _bars[3]._ma_dragon_centre > _bars[2]._ma_dragon_centre && _bars[2]._ma_dragon_centre > _bars[1]._ma_dragon_centre)
		|| (_bars[6]._ma_dragon_centre > _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre > _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre > _bars[3]._ma_dragon_centre && _bars[3]._ma_dragon_centre > _bars[2]._ma_dragon_centre)
		|| (_bars[7]._ma_dragon_centre > _bars[6]._ma_dragon_centre && _bars[6]._ma_dragon_centre > _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre > _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre > _bars[3]._ma_dragon_centre)
		|| (_bars[8]._ma_dragon_centre > _bars[7]._ma_dragon_centre && _bars[7]._ma_dragon_centre > _bars[6]._ma_dragon_centre && _bars[6]._ma_dragon_centre > _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre > _bars[4]._ma_dragon_centre)
		//|| (_bars[3]._ma_dragon_centre > _bars[2]._ma_dragon_centre && _bars[2]._ha_close < _bars[2]._ma_dragon_high)
		//|| (_bars[4]._ma_dragon_centre > _bars[3]._ma_dragon_centre && _bars[3]._ha_close < _bars[3]._ma_dragon_high && _bars[2]._ha_close < _bars[2]._ma_dragon_high)
		//|| (_bars[5]._ma_dragon_centre > _bars[4]._ma_dragon_centre && _bars[4]._ha_close < _bars[4]._ma_dragon_high && _bars[3]._ha_close < _bars[3]._ma_dragon_high && _bars[2]._ha_close < _bars[2]._ma_dragon_high)
		)
	{
		double ma_dragon_high = _bars[0]._ma_dragon_high;
		int i = 1;
		for (int i = 1; i < _bars_size-2; ++i)
		{
			if (_bars[i]._ma_dragon_high <= ma_dragon_high)
			{
				ma_dragon_high = _bars[i]._ma_dragon_high;
			}
			else
			{
				break;
			}
		}
		if (i >= _bars_size-2)
		{
			return false;
		}
		// up
		if (Bid > ma_dragon_high && _bars[0]._ha_low < ma_dragon_high)
		{
			//if (_bars[0]._burst > 1.5 || _bars[1]._burst > 1.5 || _bars[2]._burst > 1.5)
			{
				if ((_bars[0]._ha_close > _bars[1]._ma_dragon_high 
						&& _bars[1]._ha_high > _bars[2]._ma_dragon_high 
						)
					|| (_bars[0]._ha_close > _bars[1]._ma_dragon_high 
						&& ((_bars[0]._ha_high - _bars[0]._ha_low) > _bars[1]._atr * 2 || (_bars[1]._ha_high - _bars[1]._ha_low) > _bars[2]._atr * 2)
						)
					|| (_bars[0]._burst > 5 || _bars[1]._burst > 5 || _bars[2]._burst > 5)
					)
				{
					return true;
				}
			}
		}
	}
	return false;
}

bool bars::is_ma_top()
{
	if (_bars[0].is_ha_bull())
	{
		return false;
	}
	// up
	if ((_bars[5]._ma_dragon_centre < _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre < _bars[3]._ma_dragon_centre && _bars[3]._ma_dragon_centre < _bars[2]._ma_dragon_centre && _bars[2]._ma_dragon_centre < _bars[1]._ma_dragon_centre)
		|| (_bars[6]._ma_dragon_centre < _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre < _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre < _bars[3]._ma_dragon_centre && _bars[3]._ma_dragon_centre < _bars[2]._ma_dragon_centre)
		|| (_bars[7]._ma_dragon_centre < _bars[6]._ma_dragon_centre && _bars[6]._ma_dragon_centre < _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre < _bars[4]._ma_dragon_centre && _bars[4]._ma_dragon_centre < _bars[3]._ma_dragon_centre)
		|| (_bars[8]._ma_dragon_centre < _bars[7]._ma_dragon_centre && _bars[7]._ma_dragon_centre < _bars[6]._ma_dragon_centre && _bars[6]._ma_dragon_centre < _bars[5]._ma_dragon_centre && _bars[5]._ma_dragon_centre < _bars[4]._ma_dragon_centre)
		//|| (_bars[3]._ma_dragon_centre < _bars[2]._ma_dragon_centre && _bars[2]._ha_close > _bars[2]._ma_dragon_low)
		//|| (_bars[4]._ma_dragon_centre < _bars[3]._ma_dragon_centre && _bars[3]._ha_close > _bars[3]._ma_dragon_low && _bars[2]._ha_close > _bars[2]._ma_dragon_low)
		//|| (_bars[5]._ma_dragon_centre < _bars[4]._ma_dragon_centre && _bars[4]._ha_close > _bars[4]._ma_dragon_low && _bars[3]._ha_close > _bars[3]._ma_dragon_low && _bars[2]._ha_close > _bars[2]._ma_dragon_low)
		)
	{
		double ma_dragon_low = _bars[0]._ma_dragon_low;
		int i = 1;
		for (int i = 1; i < _bars_size-2; ++i)
		{
			if (_bars[i]._ma_dragon_low >= ma_dragon_low)
			{
				ma_dragon_low = _bars[i]._ma_dragon_low;
			}
			else
			{
				break;
			}
		}
		if (i >= _bars_size-2)
		{
			return false;
		}
		// down
		if (Bid < ma_dragon_low && _bars[0]._ha_high > ma_dragon_low)
		{
			//if (_bars[0]._burst > 1.5 || _bars[1]._burst > 1.5 || _bars[2]._burst > 1.5)
			{
				if ((_bars[0]._ha_close < _bars[1]._ma_dragon_low 
						&& _bars[1]._ha_low < _bars[2]._ma_dragon_low 
						)
					|| (_bars[0]._ha_close < _bars[1]._ma_dragon_low 
						&& ((_bars[0]._ha_high - _bars[0]._ha_low) > _bars[1]._atr * 2 || (_bars[1]._ha_high - _bars[1]._ha_low) > _bars[2]._atr * 2)
						)
					|| (_bars[0]._burst > 5 || _bars[1]._burst > 5 || _bars[2]._burst > 5)
					)
				{
					return true;
				}
			}
		}
	}
	return false;
}

bool bars::is_bottom_reverse()
{
	if (_bars[0].is_ha_bear())
	{
		return false;
	}
	if (_bottom_reverse_threshold <= 0.0001)
	{
		return false;
	}
	if (_bars[0]._ha_low < _bottom_reverse_threshold 
		&& Bid > _bottom_reverse_threshold
		)
	{
		if (_bars[0]._ha_close > _bottom_reverse_threshold
		//	|| (g_bars._bars[1].is_ha_bull() && g_bars._bars[2].is_ha_bull() && g_bars._bars[0]._ha_high > g_bars._bars[1]._ha_high && g_bars._bars[1]._ha_high > g_bars._bars[2]._ha_high)
		//	|| (g_bars._bars[1].is_ha_bull() && g_bars._bars[2].is_ha_bull())
			)
		{
			_bottom_low = MathMin(_bottom_low, Low[iLowest(_symbol, _time_frame, MODE_LOW, 5, 0)]);
			return true;
		}
	}
	return false;
}

bool bars::is_top_reverse()
{
	if (_bars[0].is_ha_bull())
	{
		return false;
	}
	if (_top_reverse_threshold <= 0.0001)
	{
		return false;
	}
	if (_bars[0]._ha_high > _top_reverse_threshold 
		&& Bid < _top_reverse_threshold
		)
	{
		if (_bars[0]._ha_close < _top_reverse_threshold 
		//	|| (g_bars._bars[1].is_ha_bear() && g_bars._bars[2].is_ha_bear() && g_bars._bars[0]._ha_low < g_bars._bars[1]._ha_low && g_bars._bars[1]._ha_low < g_bars._bars[2]._ha_low)
		//	|| (g_bars._bars[1].is_ha_bear() && g_bars._bars[2].is_ha_bear())
			)
		{
			_top_high = MathMax(_top_high, High[iHighest(_symbol, _time_frame, MODE_HIGH, 5, 0)]);
			return true;
		}
	}
	return false;
}

int bars::estimate_trend()
{
	if (_bars[1]._ma_dragon_centre > _bars[1]._ma_trend    // 均线多头
		&& _bars[2]._ma_dragon_centre < _bars[1]._ma_dragon_centre    // 快速均线 涨
		&& _bars[2]._ma_trend < _bars[1]._ma_trend    // 均线涨
		)
	{
		return 1;
	}
	else if (_bars[1]._ma_dragon_centre < _bars[1]._ma_trend    // 均线空头
		&& _bars[2]._ma_dragon_centre > _bars[1]._ma_dragon_centre    // 快速均线 跌
		&& _bars[2]._ma_trend > _bars[1]._ma_trend    // 均线跌
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend <= _bars[0]._ma_trend    // 慢速均线 涨
		&& _donchian_trend >= 1		// 向上 突破
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend >= _bars[0]._ma_trend    // 慢速均线 跌
		&& _donchian_trend <= -1		// 向下 突破
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend <= _bars[0]._ma_trend    // 慢速均线 涨
		&& _bars[1]._ma_dragon_centre > _bars[1]._ma_trend    // 均线多头
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend >= _bars[0]._ma_trend    // 慢速均线 跌
		&& _bars[1]._ma_dragon_centre < _bars[1]._ma_trend    // 均线空头
		)
	{
		return -1;
	}
	if (_bars[1]._ma_dragon_centre > _bars[1]._ma_trend    // 均线多头
		&& _donchian_trend >= 1		// 向上 突破
		)
	{
		return 1;
	}
	else if (_bars[1]._ma_dragon_centre < _bars[1]._ma_trend    // 均线空头
		&& _donchian_trend <= -1		// 向下 突破
		)
	{
		return -1;
	}
/*
	if (_bars[2]._ma_trend <= _bars[1]._ma_trend    // 均线涨
		&& _rsi_ac_bull
		)
	{
		return 1;
	}
	if (_bars[2]._ma_trend >= _bars[1]._ma_trend    // 均线跌
		&& _rsi_ac_bear
		)
	{
		return -1;
	}
	if (_bars[1]._ma_dragon_centre > _bars[1]._ma_trend    // 均线多头
		&& _rsi_ac_bull
		)
	{
		return 1;
	}
	else if (_bars[1]._ma_dragon_centre < _bars[1]._ma_trend    // 均线空头
		&& _rsi_ac_bear
		)
	{
		return -1;
	}
*/
/*
	if (MathAbs(_bars[0]._ma_dragon_centre - _bars[0]._ma_trend) < _bars[1]._atr	// 均线 粘合
		)
	{
		// 没有波动
		if (_bars[1]._atr < _atr_max * 0.5
			&& _bars[0]._bolling_up - _bars[0]._bolling_low < _atr_max * 2.5)
		{
			return 0;
		}
		if (_donchian_trend >= 1		// 向上 突破
			//&& _bars[2]._ma_dragon_centre < _bars[0]._ma_dragon_centre    // 快速均线 涨
			)
		{
			return 1;
		}
		else if (_donchian_trend <= -1		// 向下 突破
			//&& _bars[2]._ma_dragon_centre > _bars[0]._ma_dragon_centre    // 快速均线 跌
			)
		{
			return -1;
		}
	}
*/
	if (_bars[2]._ma_trend < _bars[1]._ma_trend)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[1]._ma_trend)
	{
		return -1;
	}
	if (_bars[2]._bolling_main < _bars[1]._bolling_main
		)
	{
		return 1;
	}
	else if (_bars[2]._bolling_main > _bars[1]._bolling_main
		)
	{
		return -1;
	}

	//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "] estimate_trend()=0  ");
	return 0;
}


/*
	if (g_rsi_ac_bull
		&& _bars[0]._ha_low > _bars[0]._ma_trend
		&& _bars[1]._ha_low > _bars[1]._ma_trend
		&& _bars[2]._ha_low > _bars[2]._ma_trend
		&& _bars[3]._ha_low > _bars[3]._ma_trend
		)
	{
		return 1;
	}
	if (g_rsi_ac_bear
		&& _bars[0]._ha_high < _bars[0]._ma_trend
		&& _bars[1]._ha_high < _bars[1]._ma_trend
		&& _bars[2]._ha_high < _bars[2]._ma_trend
		&& _bars[3]._ha_high < _bars[3]._ma_trend
		)
	{
		return -1;
	}
*/




/*

		|| (_bars[0]._ma_dragon_centre > _bars[0]._ma_trend && _bars[1]._ma_dragon_centre <= _bars[1]._ma_trend)
		|| (_bars[0]._ma_dragon_centre >= _bars[0]._ma_trend && _bars[1]._ma_dragon_centre < _bars[1]._ma_trend)
		)
*/

