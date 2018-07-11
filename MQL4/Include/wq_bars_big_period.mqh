#property strict
#include <wq_ind.mqh>

class bars_big_period
{
public:
	bars_big_period(string symbol, int time_frame);
	~bars_big_period();

	void calc();
	
	int check_trend_for_trend();
	bool check_trend_for_martin(int OP_Type);
	
	bool check_sideway();

public:
	string _symbol;
	int _time_frame;
	
	indicator* _bars_0;
	indicator* _bars_1;
	indicator* _bars_2;
	indicator* _bars_15;
	indicator* _bars_30;
	
	int _breakout_trend;
};

bars_big_period* g_bars_big = NULL;

// ===============================================================

bars_big_period::bars_big_period(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	
	_bars_0 = new indicator(_symbol, _time_frame);
	_bars_1 = new indicator(_symbol, _time_frame);
	_bars_2 = new indicator(_symbol, _time_frame);
	_bars_15 = new indicator(_symbol, _time_frame);
	_bars_30 = new indicator(_symbol, _time_frame);
	
	_breakout_trend = 0;
}

bars_big_period::~bars_big_period()
{
	delete _bars_0;
	delete _bars_1;
	delete _bars_2;
	delete _bars_15;
	delete _bars_30;
}

// ===============================================================

void bars_big_period::calc()
{
	_bars_0.calc(0, NULL);
	if (g_is_new_bar)
	{
		_bars_1.calc(1, NULL);
		_bars_2.calc(2, NULL);
		_bars_15.calc(15, NULL);
		_bars_30.calc(30, NULL);
	}
	if (_bars_0._ha_high > _bars_1._channel_long_high)
	{
		_breakout_trend = 1;
	}
	else if (_bars_0._ha_low < _bars_1._channel_long_low)
	{
		_breakout_trend = -1;
	}
}

// ===============================================================

int bars_big_period::check_trend_for_trend()
{
   if (_bars_1._bolling_up > _bars_0._bolling_up && _bars_1._bolling_low < _bars_0._bolling_low
      && _bars_0._ha_high < _bars_0._bolling_up && _bars_0._ha_low > _bars_0._bolling_low
      && (MathAbs(_bars_0._ma_dragon_centre - _bars_0._ma_trend) < (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low)
         || MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.2
         )
      )
   {
	   return 0;
   }
   if ((_bars_0._ha_close > _bars_0._ma_dragon_centre || Bid > _bars_0._ma_dragon_centre)
      && (_bars_0._ma_dragon_centre > _bars_1._ma_dragon_centre /*|| _bars_0._ma_dragon_centre > _bars_0._ma_trend */)
      )
   {
      if (_bars_1._ha_close > _bars_1._ha_open) // bar1 bull
      {
         if (_bars_0._ha_close > _bars_0._ha_open) // bar0 bull
         {
		      return 1;
		   }
		   else if (_bars_0._ha_close > _bars_1._ha_low)
         {
		      return 1;
		   }
      }
	   else if (_bars_1._ha_close < _bars_1._ha_open) // bar1 bear
	   {
	      if (_bars_0._ha_close > _bars_1._ha_high) // bar0 bull
	      {
		      return 1;
	      }
	      if (_bars_0._ha_high > _bars_1._ha_high && _bars_0._ha_close > _bars_0._ha_open) // bar0 bull
	      {
		      return 1;
	      }
	      if (Bid > _bars_1._ha_high) // bar0 bull
	      {
		      return 1;
	      }
	   }
	}
   else if (_bars_0._ha_close < _bars_0._ma_dragon_centre
      && (_bars_0._ma_dragon_centre < _bars_1._ma_dragon_centre /*|| _bars_0._ma_dragon_centre < _bars_0._ma_trend*/)
      )
   {
      if (_bars_1._ha_close < _bars_1._ha_open) // bar1 
      {
         if (_bars_0._ha_close < _bars_0._ha_open) // bar0 
         {
		      return -1;
		   }
		   else if (_bars_0._ha_close < _bars_1._ha_high)
         {
		      return -1;
		   }
      }
	   else if (_bars_1._ha_close > _bars_1._ha_open)
	   {
	      if (_bars_0._ha_close < _bars_1._ha_low)
	      {
		      return -1;
	      }
	      if (_bars_0._ha_low < _bars_1._ha_low && _bars_0._ha_close < _bars_0._ha_open) // bar0 
	      {
		      return -1;
	      }
	      if (Bid < _bars_1._ha_low) // bar0 
	      {
		      return -1;
	      }
	   }
	}
	return 0;
}

bool bars_big_period::check_trend_for_martin(int OP_Type)
{
   if (OP_Type == OP_BUY)
   {
      if (check_sideway())
      {
         double ma_0 = iMA(_symbol, PERIOD_D1, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 0);
         double ma_1 = iMA(_symbol, PERIOD_D1, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 1);
         if (ma_1 > ma_0)
         {
            return false;
         }
      }
      if ((_bars_0._ha_close > _bars_0._ma_dragon_high)
         && (_bars_1._ma_dragon_centre < _bars_0._ma_dragon_centre)
         )
      {
         if (_bars_0._ha_close > _bars_0._ha_open) // bar0 bull
         {
		      return true;
		   }
         if (_bars_1._ha_close > _bars_1._ha_open) // bar1 bull
         {
            if (_bars_0._ha_close > _bars_1._ha_low)
            {
   		      return true;
   		   }
         }
   	   else if (_bars_1._ha_close < _bars_1._ha_open) // bar1 bear
   	   {
   	      if (_bars_0._ha_close > _bars_1._ha_high) // bar0 bull
   	      {
   		      return true;
   	      }
   	   }
   	}
	}
   if (OP_Type == OP_SELL)
   {
      if (check_sideway())
      {
         double ma_0 = iMA(_symbol, PERIOD_D1, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 0);
         double ma_1 = iMA(_symbol, PERIOD_D1, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, 1);
         if (ma_1 < ma_0)
         {
            return false;
         }
      }
      if ((_bars_0._ha_close < _bars_0._ma_dragon_low)
         && (_bars_1._ma_dragon_centre > _bars_0._ma_dragon_centre)
         )
      {
         if (_bars_0._ha_close < _bars_0._ha_open) // bar0 
         {
		      return true;
		   }
         if (_bars_1._ha_close < _bars_1._ha_open) // bar1 
         {
   		   if (_bars_0._ha_close < _bars_1._ha_high)
            {
   		      return true;
   		   }
         }
   	   else if (_bars_1._ha_close > _bars_1._ha_open)
   	   {
   	      if (_bars_0._ha_close < _bars_1._ha_low)
   	      {
   		      return true;
   	      }
   	   }
      }
	}
	return false;
}

bool bars_big_period::check_sideway()
{
   if (MathAbs(_bars_0._ma_dragon_centre - _bars_0._ma_trend) < (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low)
      && MathAbs(_bars_15._ma_dragon_centre - _bars_15._ma_trend) < (_bars_15._ma_dragon_high - _bars_15._ma_dragon_low)
      && MathAbs(_bars_0._ma_dragon_centre - _bars_15._ma_dragon_centre) < (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 0.3
      //&& MathAbs(_bars_0._ma_dragon_centre - _bars_30._ma_dragon_centre) < (_bars_0._ma_dragon_high - _bars_0._ma_dragon_low) * 1
      )
   {
	   return true;
   }
	return false;
}




