#property strict
#include <wq_ind.mqh>
#include <wq_bars_big_period.mqh>

class bars
{
public:
	bars(string symbol, int time_frame);
	~bars();
	
	void tick_start();
	
	void calc(int shift);
	void calc_atr_max();
	void calc_rsi_ac();
	
	int check_volatility();
	int check_burst();
	int check_trend();
	bool is_sideways();
	
	bool is_ma_cross_bull(int i);
	bool is_ma_cross_bear(int i);
	
	int is_breakout_long(int i);	// buy
	int is_breakout_short(int i);	// sell
	
	void check_wave_long(int i);
	void check_wave_short(int i);
	bool is_wave_breakout_long(int i);	// buy
	bool is_wave_breakout_short(int i);	// sell
	
	void check_ha_bottom(int i);
	void check_ha_top(int i);
	bool is_ha_bottom_reverse();	// buy
	bool is_ha_top_reverse();	// sell
	
	void check_ma_bottom(int i);
	void check_ma_top(int i);
	bool is_ma_bottom_reverse();	// buy
	bool is_ma_top_reverse();	// sell
	
   bool is_kdj_cross_bull();
   bool is_kdj_cross_bear();

   bool is_bar_bull();
   bool is_bar_bear();
   
public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	bool _filter_volatility;
	
	indicator* _bars[360];
	int _bars_size;
	bool _is_bars_init;
	bool _is_tick_ok;
	
	double _atr_max;
	int _atr_max_period;
	datetime _atr_max_time;
	bool _atr_max_enable;
	
	int _breakout_trend;
	
	bool _rsi_ac_bull;
	bool _rsi_ac_bear;
	
	// wave
	double _wave_f_atr;
	
	// buy
	indicator* _wave_long_z3;
	indicator* _wave_long_z2;
	indicator* _wave_long_z1;
	double _wave_long_threshold;
	double _wave_long_low;
	
	// sell
	indicator* _wave_short_z3;
	indicator* _wave_short_z2;
	indicator* _wave_short_z1;
	double _wave_short_threshold;
	double _wave_short_high;
	
	// buy
	double _ha_bottom_reverse_threshold;
	double _ha_bottom_low;
	indicator* _ha_bottom_bar;
	
	// sell
	double _ha_top_reverse_threshold;
	double _ha_top_high;
	indicator* _ha_top_bar;
	
	// buy
	double _ma_bottom_reverse_threshold;
	double _ma_bottom_low;
	indicator* _ma_bottom_bar;
	
	// sell
	double _ma_top_reverse_threshold;
	double _ma_top_high;
	indicator* _ma_top_bar;
};

bars* g_bars = NULL;

// ===============================================================

bars::bars(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	_filter_volatility = false;
	
	_bars_size = 90;
	for (int i = 0; i < _bars_size; ++i)
	{
		_bars[i] = new indicator(_symbol, _time_frame);
		_bars[i]._filter_volatility = _filter_volatility;
	}
	_is_bars_init = false;
	_is_tick_ok = false;
	
	_atr_max = 0;
	_atr_max_period = 360;
	_atr_max_time = 0;
	_atr_max_enable = true;
	
	_breakout_trend = 0;
	
	_rsi_ac_bull = false;
	_rsi_ac_bear = false;

	// wave
	_wave_f_atr = 2.5;	// 2
	
	_wave_long_z3 = new indicator(_symbol, _time_frame);
	_wave_long_z2 = new indicator(_symbol, _time_frame);
	_wave_long_z1 = new indicator(_symbol, _time_frame);
	_wave_long_threshold = 0;
	_wave_long_low = 0;
	
	_wave_short_z3 = new indicator(_symbol, _time_frame);
	_wave_short_z2 = new indicator(_symbol, _time_frame);
	_wave_short_z1 = new indicator(_symbol, _time_frame);
	_wave_short_threshold = 0;
	_wave_short_high = 0;
	
	_ha_bottom_reverse_threshold = 0;
	_ha_bottom_low = 0;
	_ha_bottom_bar = new indicator(_symbol, _time_frame);
	
	_ha_top_reverse_threshold = 0;
	_ha_top_high = 0;
	_ha_top_bar = new indicator(_symbol, _time_frame);
	
	_ma_bottom_reverse_threshold = 0;
	_ma_bottom_low = 0;
	_ma_bottom_bar = new indicator(_symbol, _time_frame);
	
	_ma_top_reverse_threshold = 0;
	_ma_top_high = 0;
	_ma_top_bar = new indicator(_symbol, _time_frame);
}

bars::~bars()
{
	delete _wave_long_z3;
	delete _wave_long_z2;
	delete _wave_long_z1;
	
	delete _wave_short_z3;
	delete _wave_short_z2;
	delete _wave_short_z1;
	
	delete _ma_bottom_bar;
	delete _ma_top_bar;
	delete _ha_bottom_bar;
	delete _ha_top_bar;
	for (int i = 0; i < _bars_size; ++i)
	{
		delete _bars[i];
		_bars[i] = NULL;
	}
}

// ===============================================================

void bars::tick_start()
{
	_is_tick_ok = false;
}

void bars::calc_atr_max()
{
	if (!_atr_max_enable)
	{
		return;
	}
	if (_atr_max_time > 0 && iTime(_symbol, _time_frame, 0) < _atr_max_time + _time_frame * 60 * (_atr_max_period/5))
	{
		return;
	}
	_atr_max = _bars[1]._atr;
	int step = int(g_atr_period / 2.0);
	for (int i = step; i < _atr_max_period; )
	{
		_atr_max = MathMax(_atr_max, iATR(_symbol, _time_frame, g_atr_period, i));
		i = i + step;
	}
	_atr_max_time = iTime(_symbol, _time_frame, 0);
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

void bars::calc(int shift)
{
	if (!_is_bars_init)
	{
		_is_bars_init = true;
		if (!_is_tick_ok)
		{
			_is_tick_ok = true;
			for (int i = 0; i < _bars_size; ++i)
			{
				_bars[i]._filter_volatility = _filter_volatility;
			}
			_bars[_bars_size - 1].calc(_bars_size - 1 + shift, NULL);
			for (int i = _bars_size - 2; i >= 0; --i)
			{
				_bars[i].calc(i + shift, _bars[i+1]);
			}
			calc_atr_max();
			//calc_rsi_ac();
			for (int i = _bars_size-30; i >= 0; --i)
			{
				if (is_breakout_long(i) >= 1)
				{
					_breakout_trend = 1;
				}
				else if (is_breakout_short(i) >= 1)
				{
					_breakout_trend = -1;
				}
				if (true)
				{
					check_wave_long(i);
					check_wave_short(i);
				}
				if (true)
				{
					check_ha_bottom(i);
					check_ha_top(i);
				}
				if (true)
				{
					check_ma_bottom(i);
					check_ma_top(i);
				}
			}
		}
	}
	else
	{
		if (g_is_new_bar)
		{
			if (!_is_tick_ok)
			{
				_is_tick_ok = true;
				for (int i = _bars_size-1; i >= 1; --i)
				{
					_bars[i].assign(_bars[i-1]);
				}
				_bars[0].calc(0 + shift, _bars[1]);
/*
				for (int i = 0; i < _bars_size; ++i)
				{
					_bars[i].calc(i + shift);
				}
*/
				calc_atr_max();
				//calc_rsi_ac();
				if (is_breakout_long(0) >= 1)
				{
					_breakout_trend = 1;
				}
				else if (is_breakout_short(0) >= 1)
				{
					_breakout_trend = -1;
				}
				if (true)
				{
					check_wave_long(1);
					check_wave_short(1);
				}
				if (true)
				{
					check_ha_bottom(1);
					check_ha_top(1);
				}
				if (true)
				{
					check_ma_bottom(1);
					check_ma_top(1);
				}
			}
		}
		else
		{
			if (!_is_tick_ok)
			{
				_is_tick_ok = true;
				_bars[0].calc(0 + shift, _bars[1]);		// 每个tick都计算
				//calc_rsi_ac();
				if (is_breakout_long(0) >= 1)
				{
					_breakout_trend = 1;
				}
				else if (is_breakout_short(0) >= 1)
				{
					_breakout_trend = -1;
				}
			}
		}
	}
}

// ===============================================================

int bars::check_burst()
{
	if (_bars[0].is_ha_bull())
	{
		if (_bars[0]._burst >= 5)
		{
			return 1;
		}
		for (int i = 1; i < 5; ++i)
		{
			if (_bars[i]._burst >= 6)
			{
				return 1;
			}
		}
	}
	else if (_bars[0].is_ha_bear())
	{
		if (_bars[0]._burst >= 5)
		{
			return -1;
		}
		for (int i = 1; i < 5; ++i)
		{
			if (_bars[i]._burst >= 6)
			{
				return -1;
			}
		}
	}
	return 0;
}

/*******************************
0: 没有波动
1: 有波动
2: 波动很大
*******************************/
int bars::check_volatility()
{
	if (_bars[0]._choppy_market_index < 20)
	{
		//Print("[DEBUG] _choppy_market_index  ", _bars[0]._choppy_market_index);
		return 0;
	}
	if (_bars[0]._adx < 20)
	{
		//Print("[DEBUG] _adx  ", _bars[0]._adx);
		return 0;
	}
	double limit = MathMin(_bars[1]._atr * 4.0, _atr_max * 2.1);
	if (_bars[0].bolling_width() < limit
		&& iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 10, 0)) < _bars[0]._bolling_up
		&& iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 10, 0)) > _bars[0]._bolling_low
		)
	{
		return 0;
	}
/*
	if (_bars[1]._atr < _atr_max * 0.1)
	{
		return 0;
	}
	if (iATR(_symbol, _time_frame, 5, 0) < iATR(_symbol, _time_frame, 16, 0) * 0.7) 
	{
		return 0;
	}
*/
	return 1;
}

bool bars::is_sideways()
{
	if (MathAbs(_bars[0]._ma_dragon_centre - _bars[0]._ma_trend) < _bars[1]._atr * 0.5	// 均线 粘合
		&& MathAbs(_bars[15]._ma_dragon_centre - _bars[15]._ma_trend) < _bars[15]._atr * 0.5	// 均线 粘合
		//&& MathAbs(_bars[30]._ma_dragon_centre - _bars[30]._ma_trend) < _bars[30]._atr * 0.5	// 均线 粘合
		)
	{
		return true;
	}
	if (MathAbs(_bars[0]._ma_dragon_centre - _bars[0]._ma_trend) < _bars[1]._atr * 0.5	// 均线 粘合
		&& MathAbs(_bars[15]._ma_dragon_centre - _bars[15]._ma_trend) < _bars[15]._atr * 0.5	// 均线 粘合
		&& MathAbs(_bars[0]._ma_dragon_centre - _bars[15]._ma_dragon_centre) < (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low)	// 均线 横盘
		)
	{
		return true;
	}
	if (MathAbs(_bars[0]._ma_dragon_centre - _bars[15]._ma_dragon_centre) < (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.3	// 均线 横盘
		&& MathAbs(_bars[0]._ma_dragon_centre - _bars[0]._ma_trend) < (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 1
		)
	{
		return true;
	}
	if (MathAbs(_bars[0]._ma_trend - _bars[15]._ma_trend) < _bars[1]._atr * 0.1	// 均线 横盘
		&& MathAbs(_bars[0]._ma_dragon_centre - _bars[15]._ma_dragon_centre) < _bars[1]._atr * 0.5	// 均线 横盘
		)
	{
		return true;
	}
	if (MathAbs(_bars[0]._ma_trend - _bars[15]._ma_trend) < _bars[1]._atr * 0.1	// 均线 横盘
		&& _bars[0].bolling_width() < _atr_max * 3
		&& iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 10, 0)) < _bars[0]._bolling_up
		&& iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 10, 0)) > _bars[0]._bolling_low
		)
	{
		return true;
	}
	return false;
}

/*******************************
0: 没方向
1: 向上
-1: 向下
*******************************/
int bars::check_trend()
{
	if (_bars[2]._ma_trend < _bars[0]._ma_trend
		&& (_bars[15]._ma_trend < _bars[0]._ma_trend) 
		&& _breakout_trend >= 1
		&& _bars[1]._ma_dragon_high > _bars[1]._ma_trend
		&& (_bars[0]._ma_trend - _bars[15]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.3
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[0]._ma_trend
		&& (_bars[15]._ma_trend > _bars[0]._ma_trend) 
		&& _breakout_trend <= -1
		&& _bars[1]._ma_dragon_low < _bars[1]._ma_trend
		&& (_bars[15]._ma_trend - _bars[0]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.3
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend < _bars[1]._ma_trend		// 均线涨
		&& (_bars[0]._ma_trend - _bars[15]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.5		// 均线涨 强势
		&& _bars[1]._ma_dragon_high > _bars[1]._ma_trend		// 均线不能差太多
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[1]._ma_trend		// 均线跌
		&& (_bars[15]._ma_trend - _bars[0]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.5		// 均线 强势
		&& _bars[1]._ma_dragon_low < _bars[1]._ma_trend		// 均线不能差太多
		)
	{
		return -1;
	}
	if (is_ma_cross_bull(1)
		&& (_bars[15]._ma_trend < _bars[0]._ma_trend) 
		&& _breakout_trend >= 1
		)
	{
		return 1;
	}
	else if (is_ma_cross_bear(1)
		&& (_bars[15]._ma_trend > _bars[0]._ma_trend) 
		&& _breakout_trend <= -1
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend < _bars[0]._ma_trend    // 慢速均线 涨
		&& _bars[2]._ma_dragon_centre < _bars[0]._ma_dragon_centre
		&& _bars[1]._ma_dragon_high > _bars[1]._ma_trend
		&& _breakout_trend >= 1
		&& _bars[0]._ha_close > _bars[1]._ma_dragon_high + _bars[1]._atr * 1
		&& _bars[0]._ha_close > _bars[1]._ma_trend + _bars[1]._atr * 2
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[0]._ma_trend    // 慢速均线 跌
		&& _bars[2]._ma_dragon_centre > _bars[0]._ma_dragon_centre
		&& _bars[1]._ma_dragon_low < _bars[1]._ma_trend
		&& _breakout_trend <= -1
		&& _bars[0]._ha_close < _bars[1]._ma_dragon_low - _bars[1]._atr * 1
		&& _bars[0]._ha_close < _bars[1]._ma_trend - _bars[1]._atr * 2
		)
	{
		return -1;
	}
	if (_bars[1]._ma_dragon_low > _bars[1]._ma_trend    // 均线多头
		&& _breakout_trend >= 1
		&& MathAbs(_bars[0]._ma_trend - _bars[15]._ma_trend) < _bars[1]._atr * 0.1	// 均线 横盘
		)
	{
		return 1;
	}
	else if (_bars[1]._ma_dragon_high < _bars[1]._ma_trend    // 均线空头
		&& _breakout_trend <= -1
		&& MathAbs(_bars[0]._ma_trend - _bars[15]._ma_trend) < _bars[1]._atr * 0.1	// 均线 横盘
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend < _bars[0]._ma_trend    // 慢速均线 涨
		&& (_bars[0]._ma_trend - _bars[15]._ma_trend) > _bars[1]._atr * 0.1
		&& _bars[1]._ma_dragon_low > _bars[1]._ma_trend    // 均线多头
		&& _breakout_trend >= 1
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[0]._ma_trend    // 慢速均线 跌
		&& (_bars[15]._ma_trend - _bars[0]._ma_trend) > _bars[1]._atr * 0.1
		&& _bars[1]._ma_dragon_high < _bars[1]._ma_trend    // 均线空头
		&& _breakout_trend <= -1
		)
	{
		return -1;
	}
	// 没有突破
	if (_bars[2]._ma_trend < _bars[0]._ma_trend
		&& (_bars[15]._ma_trend < _bars[0]._ma_trend) 
		&& _bars[1]._ma_dragon_centre > _bars[1]._ma_trend
		&& (_bars[0]._ma_trend - _bars[15]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.2
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[0]._ma_trend
		&& (_bars[15]._ma_trend > _bars[0]._ma_trend) 
		&& _bars[1]._ma_dragon_centre < _bars[1]._ma_trend
		&& (_bars[15]._ma_trend - _bars[0]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.2
		)
	{
		return -1;
	}
	if (_bars[2]._ma_trend < _bars[0]._ma_trend
		&& (_bars[15]._ma_trend < _bars[0]._ma_trend) 
		&& (_bars[0]._ma_trend - _bars[15]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.2
		)
	{
		return 1;
	}
	else if (_bars[2]._ma_trend > _bars[0]._ma_trend
		&& (_bars[15]._ma_trend > _bars[0]._ma_trend) 
		&& (_bars[15]._ma_trend - _bars[0]._ma_trend) > (_bars[1]._ma_dragon_high - _bars[1]._ma_dragon_low) * 0.2
		)
	{
		return -1;
	}
	//Print("[DEBUG][", _symbol, "][", get_time_frame_str(_time_frame), "] check_trend()=0  ");
	return 0;
}

// ===============================================================

bool bars::is_ma_cross_bull(int i)
{
	if (_bars[i]._ma_dragon_centre > _bars[i]._ma_trend    // 均线多头
		&& _bars[i+1]._ma_dragon_centre < _bars[i]._ma_dragon_centre    // 快速均线 涨
		&& _bars[i+1]._ma_trend < _bars[i]._ma_trend    // 均线涨
		)
	{
		return true;
	}
	return false;
}

bool bars::is_ma_cross_bear(int i)
{
	if (_bars[i]._ma_dragon_centre < _bars[i]._ma_trend    // 均线空头
		&& _bars[i+1]._ma_dragon_centre > _bars[i]._ma_dragon_centre    // 快速均线 跌
		&& _bars[i+1]._ma_trend > _bars[i]._ma_trend    // 均线跌
		)
	{
		return true;
	}
	return false;
}

// ===============================================================

int bars::is_breakout_long(int i)
{
	if (_bars[i]._ha_close > _bars[i+3]._channel_long_high)
	{
		return 1;
/*
		if (_bars[i]._ha_high > _bars[i+1]._bolling_up)
		{
			return 1;
		}
		if (i <= 0)
		{
			int tf = get_large_time_frame(_time_frame);
			while (tf <= PERIOD_H4)
			{
				double bolling_up = iBands(_symbol, tf, g_bolling_period, g_bolling_deviation, g_bolling_bands_shift, PRICE_WEIGHTED, MODE_UPPER, 1);
				if (_bars[i]._ha_high > bolling_up)
				{
					return 1;
				}
				tf = get_large_time_frame(tf);
			}
		}
*/
	}
	return 0;
}

int bars::is_breakout_short(int i)
{
	if (_bars[i]._ha_close < _bars[i+3]._channel_long_low)
	{
		return 1;
/*
		if (_bars[i]._ha_low < _bars[i+1]._bolling_low)
		{
			return 1;
		}
		if (i <= 0)
		{
			int tf = get_large_time_frame(_time_frame);
			while (tf <= PERIOD_H4)
			{
				double bolling_low = iBands(_symbol, tf, g_bolling_period, g_bolling_deviation, g_bolling_bands_shift, PRICE_WEIGHTED, MODE_LOWER, 1);
				if (_bars[i]._ha_low < bolling_low)
				{
					return 1;
				}
				tf = get_large_time_frame(tf);
			}
		}
*/
	}
	return 0;
}

// ===============================================================

void bars::check_wave_long(int i)
{
	if (!g_is_new_bar)
	{
		return;
	}
	if (_bars[i]._ha_close < _bars[i]._ha_open)		// bear, bottom, 3, 1
	{
		// wave_long
		if (_wave_long_z3._ha_low <= 0)
		{
			_wave_long_z3.assign(_bars[i]);
		}
		else if (_wave_long_z2._ha_high > 0)
		{
			if (_wave_long_z2._ha_high - _bars[i]._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				if (_wave_long_z1._ha_low <= 0)
				{
					_wave_long_z1.assign(_bars[i]);
				}
				else if (_bars[i]._ha_low < _wave_long_z1._ha_low)
				{
					_wave_long_z1.assign(_bars[i]);
				}
			}
		}
	}
	else if (_bars[i]._ha_close > _bars[i]._ha_open)	// bull, top, 2
	{
		// wave_long
		if (_wave_long_z2._ha_high <= 0)
		{
			if (_wave_short_z3._ha_low > 0 && _bars[i]._ha_high - _wave_short_z3._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				_wave_long_z2.assign(_bars[i]);
			}
		}
		else 
		{
			if (_wave_long_z1._ha_low <= 0)
			{
				if (_bars[i]._ha_high > _wave_long_z2._ha_high)
				{
					_wave_long_z2.assign(_bars[i]);
				}
			}
			else if (_bars[i]._ha_high - _wave_long_z1._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				_wave_long_z3.assign(_wave_long_z1);
				_wave_long_z2.assign(_bars[i]);
				_wave_long_z1.reset();
			}
		}
	}
	if (_wave_long_z3._ha_low <= 0
		|| _wave_long_z2._ha_high <= 0
		|| _wave_long_z1._ha_low <= 0
		)
	{
		return;
	}
	_wave_long_threshold = 0;
	_wave_long_low = 0;
	if (_wave_long_z3._ha_low < _wave_long_z2._ha_high - _bars[i]._atr * 2
		&& _wave_long_z2._ha_high > _wave_long_z1._ha_low + _bars[i]._atr * _wave_f_atr
		&& _wave_long_z3._ha_low < _wave_long_z1._ha_low - _bars[i]._atr * 0.5
		&& _wave_long_z3._ha_close < _wave_long_z3._ma_trend 
		&& _wave_long_z3._ha_close < _wave_long_z3._ma_dragon_low 
		&& _wave_long_z3._ma_dragon_low < _wave_long_z3._ma_trend 
		&& _wave_long_z2._ha_high > _wave_long_z2._ma_trend
		&& _wave_long_z2._ha_high > _wave_long_z2._ma_dragon_high
		&& _wave_long_z1._ha_low < _wave_long_z1._ma_dragon_high
		//&& _wave_long_z1._ha_low > _wave_long_z1._ma_dragon_low - _wave_long_z1._atr
		)
	{
		_wave_long_threshold = _wave_long_z2._ha_high;
		_wave_long_low = _wave_long_z1._ha_low;
	}
}

void bars::check_wave_short(int i)
{
	if (!g_is_new_bar)
	{
		return;
	}
	if (_bars[i]._ha_close < _bars[i]._ha_open)
	{
		// wave_short
		if (_wave_short_z2._ha_low <= 0)
		{
			if (_wave_short_z3._ha_high > 0 && _wave_short_z3._ha_high - _bars[i]._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				_wave_short_z2.assign(_bars[i]);
			}
		}
		else
		{
			if (_wave_short_z1._ha_high <= 0)
			{
				if (_bars[i]._ha_low < _wave_short_z2._ha_low)
				{
					_wave_short_z2.assign(_bars[i]);
				}
			}
			else if (_wave_short_z1._ha_high - _bars[i]._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				_wave_short_z3.assign(_wave_short_z1);
				_wave_short_z2.assign(_bars[i]);
				_wave_short_z1.reset();
			}
		}
	}
	else if (_bars[i]._ha_close > _bars[i]._ha_open)
	{
		// wave_short
		if (_wave_short_z3._ha_high <= 0)
		{
			_wave_short_z3.assign(_bars[i]);
		}
		else if (_wave_short_z2._ha_low > 0)
		{
			if (_bars[i]._ha_high - _wave_short_z2._ha_low > _bars[i]._atr * _wave_f_atr)
			{
				if (_wave_short_z1._ha_high <= 0)
				{
					_wave_short_z1.assign(_bars[i]);
				}
				else if (_bars[i]._ha_high > _wave_short_z1._ha_high)
				{
					_wave_short_z1.assign(_bars[i]);
				}
			}
		}
	}
	if (_wave_short_z3._ha_high <= 0
		|| _wave_short_z2._ha_low <= 0
		|| _wave_short_z1._ha_high <= 0
		)
	{
		return;
	}
	_wave_short_threshold = 0;
	_wave_short_high = 0;
	if (_wave_short_z3._ha_high > _wave_short_z2._ha_low + _bars[i]._atr * 2
		&& _wave_short_z2._ha_low < _wave_short_z1._ha_high - _bars[i]._atr * _wave_f_atr
		&& _wave_short_z3._ha_high > _wave_short_z1._ha_high + _bars[i]._atr * 0.5
		&& _wave_short_z3._ha_close > _wave_short_z3._ma_trend 
		&& _wave_short_z3._ha_close > _wave_short_z3._ma_dragon_high
		&& _wave_long_z3._ma_dragon_high > _wave_long_z3._ma_trend 
		&& _wave_short_z2._ha_low < _wave_short_z2._ma_trend
		&& _wave_short_z2._ha_low < _wave_short_z2._ma_dragon_low
		&& _wave_short_z1._ha_high > _wave_short_z1._ma_dragon_low
		//&& _wave_short_z1._ha_high < _wave_short_z1._ma_dragon_high + _wave_short_z1._atr
		)
	{
		_wave_short_threshold = _wave_short_z2._ha_low;
		_wave_short_high = _wave_short_z1._ha_high;
	}
}

bool bars::is_wave_breakout_long(int i)
{
	if (_wave_long_threshold <= 0.00001)
	{
		return false;
	}
	if (Bid > _wave_long_threshold
		&& _bars[i]._ha_close > _wave_long_threshold
		&& _bars[i]._ha_low < _wave_long_threshold
		&& Bid > _bars[i]._ma_trend 
		&& Bid > _bars[i]._ma_dragon_high 
		)
	{
		return true;
	}
	return false;
}

bool bars::is_wave_breakout_short(int i)
{
	if (_wave_short_threshold <= 0.00001)
	{
		return false;
	}
	if (Bid < _wave_short_threshold
		&& _bars[i]._ha_close < _wave_short_threshold
		&& _bars[i]._ha_high > _wave_short_threshold
		&& Bid < _bars[i]._ma_trend 
		&& Bid < _bars[i]._ma_dragon_low
		)
	{
		return true;
	}
	return false;
}

// ===============================================================

void bars::check_ha_bottom(int i)
{
	if (_bars[i]._ha_close < _bars[i]._ha_open
		&& _bars[i+1]._ha_close < _bars[i+1]._ha_open
		&& _bars[i]._ha_high < _bars[i+1]._ha_high
		)
	{
		_ha_bottom_reverse_threshold = MathMax(_bars[i+1]._ha_high, _bars[i]._ha_high + _bars[i]._atr * 0.3);
		_ha_bottom_reverse_threshold = MathMin(_ha_bottom_reverse_threshold, iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 6, i)) + _bars[i]._atr * 0.3);
		_ha_bottom_low = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 5, i));
		_ha_bottom_bar.assign(_bars[i]);
	}
}

void bars::check_ha_top(int i)
{
	if (_bars[i]._ha_close > _bars[i]._ha_open
		&& _bars[i+1]._ha_close > _bars[i+1]._ha_open
		&& _bars[i]._ha_low > _bars[i+1]._ha_low
		)
	{
		_ha_top_reverse_threshold = MathMin(_bars[i+1]._ha_low, _bars[i]._ha_low - _bars[i]._atr * 0.3);
		_ha_top_reverse_threshold = MathMax(_ha_top_reverse_threshold, iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 6, i)) - _bars[i]._atr * 0.3);
		_ha_top_high = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 5, i));
		_ha_top_bar.assign(_bars[i]);
	}
}

bool bars::is_ha_bottom_reverse()
{
	if (!_bars[0].is_ha_bull())
	{
		return false;
	}
	if (_ha_bottom_reverse_threshold <= 0.00001)
	{
		return false;
	}
	if (_bars[0]._ha_low < _ha_bottom_reverse_threshold 
		&& Bid > _ha_bottom_reverse_threshold
		&& _bars[0]._ha_close > _ha_bottom_reverse_threshold
		)
	{
		_ha_bottom_low = MathMin(_ha_bottom_low, iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 5, 0)));
		return true;
	}
	return false;
}

bool bars::is_ha_top_reverse()
{
	if (!_bars[0].is_ha_bear())
	{
		return false;
	}
	if (_ha_top_reverse_threshold <= 0.00001)
	{
		return false;
	}
	if (_bars[0]._ha_high > _ha_top_reverse_threshold 
		&& Bid < _ha_top_reverse_threshold
		&& _bars[0]._ha_close < _ha_top_reverse_threshold 
		)
	{
		_ha_top_high = MathMax(_ha_top_high, iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 5, 0)));
		return true;
	}
	return false;
}

// ===============================================================

void bars::check_ma_bottom(int i)
{
	if (_bars[i+1]._ma_dragon_centre > _bars[i]._ma_dragon_centre
		)
	{
		_ma_bottom_reverse_threshold = _bars[i]._ma_dragon_high;
		_ma_bottom_low = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 5, i));
		_ma_bottom_bar.assign(_bars[i]);
	}
}

void bars::check_ma_top(int i)
{
	if (_bars[i+1]._ma_dragon_centre < _bars[i]._ma_dragon_centre
		)
	{
		_ma_top_reverse_threshold = _bars[i]._ma_dragon_low;
		_ma_top_high = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 5, i));
		_ma_top_bar.assign(_bars[i]);
	}
}

bool bars::is_ma_bottom_reverse()
{
	if (!_bars[0].is_ha_bull())
	{
		return false;
	}
	if (_ma_bottom_reverse_threshold <= 0.00001)
	{
		return false;
	}
	if (Bid > _ma_bottom_reverse_threshold 
		&& _bars[0]._ha_close > _ma_bottom_reverse_threshold
		&& _bars[0]._ha_low < _ma_bottom_reverse_threshold
		)
	{
		return true;
	}
	return false;
}

bool bars::is_ma_top_reverse()
{
	if (!_bars[0].is_ha_bear())
	{
		return false;
	}
	if (_ma_top_reverse_threshold <= 0.00001)
	{
		return false;
	}
	if (Bid < _ma_top_reverse_threshold
		&& _bars[0]._ha_close < _ma_top_reverse_threshold
		&& _bars[0]._ha_high > _ma_top_reverse_threshold
		)
	{
		return true;
	}
	return false;
}

bool bars::is_kdj_cross_bull()
{
	if (_bars[0]._kdj_signal < 30 && _bars[0]._kdj_main < 30)
	{
	   if ((_bars[1]._kdj_main <= _bars[1]._kdj_signal && _bars[0]._kdj_main > _bars[0]._kdj_signal) 
	   //   || (_bars[1]._kdj_main < _bars[1]._kdj_signal && _bars[0]._kdj_main >= _bars[0]._kdj_signal)
	      )
	   {
	      return true;
	   }
	}
	return false;
}

bool bars::is_kdj_cross_bear()
{
	if (_bars[0]._kdj_signal > 75 && _bars[0]._kdj_main > 75 
	   && _bars[1]._kdj_signal >= _bars[1]._kdj_main && _bars[0]._kdj_signal < _bars[0]._kdj_main)
	{
	   return true;
	}
	return false;
}


bool bars::is_bar_bull()
{
	if (_bars[1]._ha_open < _bars[1]._ha_close) // bull
	{
	   if (_bars[0]._ha_open < _bars[0]._ha_close) // bull
	   {
		   return true;
		}
	}
   else if (_bars[1]._ha_open > _bars[1]._ha_close) // bear
   {
	   if (_bars[0]._ha_open < _bars[0]._ha_close && _bars[0]._ha_close > _bars[1]._ha_open) // bull
	   {
		   return true;
		}
   }
	return false;
}

bool bars::is_bar_bear()
{
	if (_bars[1]._ha_open > _bars[1]._ha_close) 
	{
	   if (_bars[0]._ha_open > _bars[0]._ha_close) 
	   {
		   return true;
		}
	}
   else if (_bars[1]._ha_open < _bars[1]._ha_close) 
   {
	   if (_bars[0]._ha_open > _bars[0]._ha_close && _bars[0]._ha_close < _bars[1]._ha_open) 
	   {
		   return true;
		}
   }
	return false;
}

// ===============================================================

// ===============================================================




