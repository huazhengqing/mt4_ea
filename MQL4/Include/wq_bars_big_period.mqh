#property strict

// ===============================================================

#include <wq_ind.mqh>

// ===============================================================

class bars_big_period
{
public:
	bars_big_period(string symbol, int time_frame);
	~bars_big_period();

	void calc();
	
	int check_trend();
	bool is_sideways();

public:
	string _symbol;
	int _time_frame;
	
	indicator* _bars_0;
	indicator* _bars_1;
	indicator* _bars_15;
	
	
	int _breakout_trend;
};

// ===============================================================

bars_big_period::bars_big_period(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_0 = new indicator(_symbol, _time_frame);
	_bars_1 = new indicator(_symbol, _time_frame);
	_bars_15 = new indicator(_symbol, _time_frame);
	
	_breakout_trend = 0;
}

bars_big_period::~bars_big_period()
{
	delete _bars_0;
	delete _bars_1;
	delete _bars_15;
}

// ===============================================================

void bars_big_period::calc()
{
	_bars_0.calc(0, NULL);
	if (g_is_new_bar)
	{
		_bars_1.calc(1, NULL);
		_bars_15.calc(15, NULL);
	}
	if (_bars_0._ha_high > _bars_1._channel_long_high)
	{
		_breakout_trend = 1;
	}
	if (_bars_0._ha_low < _bars_1._channel_long_low)
	{
		_breakout_trend = -1;
	}
}

// ===============================================================

int bars_big_period::check_trend()
{
	if (MathAbs(_bars_0._ma_dragon_centre - _bars_0._ma_trend) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low) * 0.5
		&& MathAbs(_bars_15._ma_dragon_centre - _bars_15._ma_trend) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low) * 0.5
		&& MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low) * 0.5
		)
	{
		return 0;
	}
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_15._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre > _bars_0._ma_trend
		&& _bars_15._ma_dragon_centre > _bars_15._ma_trend
		&& _bars_0._close > _bars_0._ma_dragon_low
		)
	{
		return 1;
	}
	else if (_bars_1._ma_trend > _bars_0._ma_trend
		&& _bars_15._ma_trend > _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre < _bars_0._ma_trend
		&& _bars_15._ma_dragon_centre < _bars_15._ma_trend
		&& _bars_0._close < _bars_0._ma_dragon_high
		)
	{
		return -1;
	}
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_low > _bars_0._ma_trend + (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.3
		&& _bars_0._close > _bars_0._ma_dragon_low
		)
	{
		return 1;
	}
	else if (_bars_1._ma_trend > _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_high < _bars_0._ma_trend - (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.3
		&& _bars_0._close < _bars_0._ma_dragon_high
		)
	{
		return -1;
	}
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre - (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_low > _bars_0._ma_trend
		&& _bars_0._close > _bars_0._ma_dragon_low
		)
	{
		return 1;
	}
	else if (_bars_1._ma_trend > _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre + (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_high < _bars_0._ma_trend
		&& _bars_0._close < _bars_0._ma_dragon_high
		)
	{
		return -1;
	}
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_15._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre - (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_low > _bars_0._ma_trend + (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._close > _bars_0._ma_trend
		)
	{
		return 1;
	}
	else if (_bars_1._ma_trend > _bars_0._ma_trend
		&& _bars_15._ma_trend > _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre + (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_high < _bars_0._ma_trend - (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._close < _bars_0._ma_trend
		)
	{
		return -1;
	}
/*
	if (_bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre > (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_centre > _bars_0._ma_trend
		)
	{
		return 1;
	}
	else if (_bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre - _bars_0._ma_dragon_centre > (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.5
		&& _bars_0._ma_dragon_centre < _bars_0._ma_trend
		)
	{
		return -1;
	}
	if (_bars_15._ma_trend < _bars_0._ma_trend
		&& _bars_0._ma_trend - _bars_15._ma_trend > (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.3
		&& _bars_0._ma_dragon_centre > _bars_0._ma_trend
		)
	{
		return 1;
	}
	else if (_bars_15._ma_trend > _bars_0._ma_trend
		&& _bars_15._ma_trend - _bars_0._ma_trend > (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.3
		&& _bars_0._ma_dragon_centre < _bars_0._ma_trend
		)
	{
		return -1;
	}
*/
	return 0;
}

bool bars_big_period::is_sideways()
{
	if (MathAbs(_bars_0._ma_dragon_centre - _bars_0._ma_trend) < _bars_1._atr * 0.5	// 均线 粘合
		&& MathAbs(_bars_15._ma_dragon_centre - _bars_15._ma_trend) < _bars_15._atr * 0.5	// 均线 粘合
		&& MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low)	// 均线 横盘
		)
	{
		return true;
	}
	if (MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low) * 0.3	// 均线 横盘
		&& MathAbs(_bars_0._ma_dragon_centre - _bars_0._ma_trend) < (_bars_1._ma_dragon_high - _bars_1._ma_dragon_low) * 1
		)
	{
		return true;
	}
	if (MathAbs(_bars_0._ma_trend - _bars_15._ma_trend) < _bars_1._atr * 0.1	// 均线 横盘
		&& MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < _bars_1._atr * 0.5	// 均线 横盘
		)
	{
		return true;
	}
/*
	if (MathAbs(_bars_0._ma_trend - _bars_15._ma_trend) < _bars_1._atr * 0.1	// 均线 横盘
		&& _bars_0.bolling_width() < _atr_max * 3
		&& iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 10, 0)) < _bars_0._bolling_up
		&& iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 10, 0)) > _bars_0._bolling_low
		)
	{
		return true;
	}
*/
	return false;
}

// ===============================================================



// ===============================================================



















