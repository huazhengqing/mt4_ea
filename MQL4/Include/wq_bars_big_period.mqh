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

public:
	string _symbol;
	int _time_frame;
	
	indicator* _bars_0;
	indicator* _bars_1;
	indicator* _bars_15;
};

// ===============================================================

bars_big_period::bars_big_period(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_0 = new indicator(_symbol, _time_frame);
	_bars_1 = new indicator(_symbol, _time_frame);
	_bars_15 = new indicator(_symbol, _time_frame);
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
	if (g_is_new_bar)
	{
		_bars_0.calc(0, NULL);
		_bars_1.calc(1, NULL);
		_bars_15.calc(15, NULL);
	}
}

int bars_big_period::check_trend()
{
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_15._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre > _bars_0._ma_trend
		&& _bars_15._ma_dragon_centre > _bars_15._ma_trend
		&& _bars_0._close > _bars_0._ma_trend
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
		&& _bars_0._close < _bars_0._ma_trend
		)
	{
		return -1;
	}
	if (_bars_1._ma_trend < _bars_0._ma_trend
		&& _bars_15._ma_trend < _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre < _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre > _bars_0._ma_trend
		&& _bars_0._close > _bars_0._ma_trend
		)
	{
		return 1;
	}
	else if (_bars_1._ma_trend > _bars_0._ma_trend
		&& _bars_15._ma_trend > _bars_0._ma_trend
		&& _bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_15._ma_dragon_centre > _bars_0._ma_dragon_centre
		&& _bars_0._ma_dragon_centre < _bars_0._ma_trend
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

// ===============================================================

