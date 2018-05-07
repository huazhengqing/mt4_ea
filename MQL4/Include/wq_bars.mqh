#property strict
#include <wq_util.mqh>
#include <wq_ind.mqh>


// ===============================================================

class bars
{
public:
	bars(string symbol, int time_frame);
	~bars();
	
	void tick_start();
	void calc();
	
public:
	int _magic;
	string _symbol;
	int _time_frame;
	
	indicator* _bars[50];
	int _bars_size;
	bool _is_bars_init;
	bool _is_tick_ok;
	
};

// ===============================================================

bars::bars(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_size = 20;
	for (int i = 0; i < _bars_size; ++i)
	{
		_bars[i] = new indicator(_symbol, _time_frame);
	}
	_is_bars_init = false;
	_is_tick_ok = false;
}

bars::~bars()
{
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

				for (int i = 0; i < _bars_size; ++i)
				{
					_bars[i].calc(i);
				}

/*
				for (int i = _bars_size-1; i >= 1; --i)
				{
					_bars[i] = _bars[i-1];
				}
				_bars[0].calc(0);
*/
				_is_tick_ok = true;
			}
		}
		else
		{
			if (!_is_tick_ok)
			{
				_bars[0].calc(0);		// 每个tick都计算
				_is_tick_ok = true;
			}
		}
	}
}

