/*******************************************************************
https://www.mql5.com/zh/articles/2195
创建手动交易策略的模糊逻辑

(MathArctan(MathTan(((price1-price2)/(WindowPriceMax()- WindowPriceMin()))/((shift2-shift1)*1.000/WindowBarsPerChart())))*180/3.14;)

其实MA升幅快慢可以简单表达：
(MA(0)-MA(T))/Point/T,

T为图柱间隔，MA(0)为当前MA值，M(T)为当前倒退T个图柱的MA值。


*******************************************************************/
#property strict

// =======================================================

#include <wq_util.mqh>

// =======================================================

class indicator
{
public:
	indicator(string symbol, int time_frame);
	virtual ~indicator();
	virtual void reset();
	virtual void assign(const indicator& r);
	
public:
	void calc(int shift, indicator* pre);
	void calc_ha(int shift, indicator* pre);

	void calc_bolling(int shift);
	void calc_burst(int shift);
	void calc_choppy(int shift);
	int calc_adx(int shift);
	
	int calc_ac(int shift);
	
	void calc_z(int shift);
	int calc_rvi(int shift);
	
	bool is_ha_bull();
	bool is_ha_bear();
	
	double bolling_width();
	double channel_width();
	
public:
	string _symbol;
	int _time_frame;
	bool _filter_volatility;

	double _high;
	double _low;
	double _open;
	double _close;
	datetime _time;

	double _ha_open;
	double _ha_close;
	double _ha_high;
	double _ha_low;
	
	double _ma_dragon_high;
	double _ma_dragon_low;
	double _ma_dragon_centre;
	double _ma_trend;

	double _atr;
	
	double _channel_long_high;
	double _channel_long_low;
/*
	double _channel_medium_high;
	double _channel_medium_low;
	double _channel_short_high;
	double _channel_short_low;
*/
	double _rsi;
	int _ac_index;
	
	double _bolling_up;
	double _bolling_main;
	double _bolling_low;
	
	double _burst;    // 放量级别，几倍
	
	double _choppy_market_index;
	
   double _adx;
   double _adx_di_plus;
   double _adx_di_minus;

	double _kdj_main;
	double _kdj_signal;
/*
	double _z1;
	double _z2;
	double _z3;
	double _z4;
	double _z5;
	double _z6;
	double _z7;
	double _z8;
	double _z9;
*/
/*
	double _high_5;
	double _low_5;
	

	
	double _macd_main;
	double _macd_signal;
	
	int _cci_period;
	double _cci;
	
	int _rvi_period;
   double _rvi;
   double _rvi_sig;
   int _rvi_index;
   int _rvi_entry;  // [1=buy;-1=sell]
*/
};

// =======================================================

indicator::indicator(string symbol, int time_frame)
{
	_symbol = symbol;
	_time_frame = time_frame;
	_filter_volatility = false;
	reset();
}

indicator::~indicator()
{
}

void indicator::reset()
{
	_high = 0;
	_low = 0;
	_open = 0;
	_close = 0;
	_time = 0;

	_ha_open = 0;
	_ha_close = 0;
	_ha_high = 0;
	_ha_low = 0;
	
	_ma_dragon_high = 0;
	_ma_dragon_low = 0;
	_ma_dragon_centre = 0;
	_ma_trend = 0;
	
	_atr = 0;
	
	_channel_long_high = 0.0;
	_channel_long_low = 0.0;
/*
	_channel_medium_high = 0.0;
	_channel_medium_low = 0.0;
	_channel_short_high = 0.0;
	_channel_short_low = 0.0;
*/
	_rsi = 0;
	_ac_index = 0;
	
	_bolling_up = 0;
	_bolling_main = 0;
	_bolling_low = 0;
	
	_burst = 0;
	
	_choppy_market_index = 0;
	
	_adx = 0;
	_adx_di_plus = 0;
	_adx_di_minus = 0;
	
	_kdj_main = 0;
	_kdj_signal = 0;
/*
	_z1 = 0;
	_z2 = 0;
	_z3 = 0;
	_z4 = 0;
	_z5 = 0;
	_z6 = 0;
	_z7 = 0;
	_z8 = 0;
	_z9 = 0;
*/
/*
	_high_5 = 0.0;
	_low_5 = 0.0;
	
	
	
	_macd_main = 0;
	_macd_signal = 0;
	
	_cci = 0;
	
	
	_rvi = 0;
	_rvi_sig = 0;
	_rvi_index = 0;
	_rvi_entry = 0;
	
	_pinbar_entry = 0;
*/
}

void indicator::assign(const indicator& r)
{
	_symbol = r._symbol;
	_time_frame = r._time_frame;
	_filter_volatility = r._filter_volatility;

	_high = r._high;
	_low = r._low;
	_open = r._open;
	_close = r._close;
	_time = r._time;
	
	_ha_open = r._ha_open;
	_ha_close = r._ha_close;
	_ha_high = r._ha_high;
	_ha_low = r._ha_low;
	
	_ma_dragon_high = r._ma_dragon_high;
	_ma_dragon_low = r._ma_dragon_low;
	_ma_dragon_centre = r._ma_dragon_centre;
	_ma_trend = r._ma_trend;
	
	_atr = r._atr;
		
	_channel_long_high = r._channel_long_high;
	_channel_long_low = r._channel_long_low;
/*
	_channel_medium_high = r._channel_medium_high;
	_channel_medium_low = r._channel_medium_low;
	_channel_short_high = r._channel_short_high;
	_channel_short_low = r._channel_short_low;
*/
	_bolling_up = r._bolling_up;
	_bolling_main = r._bolling_main;
	_bolling_low = r._bolling_low;
	
	_burst = r._burst;
	
	_choppy_market_index = r._choppy_market_index;

	_adx = r._adx;
	_adx_di_plus = r._adx_di_plus;
	_adx_di_minus = r._adx_di_minus;
	
	_rsi = r._rsi;
	_ac_index = r._ac_index;
	
	_kdj_main = r._kdj_main;
	_kdj_signal = r._kdj_signal;
/*
	_z1 = r._z1;
	_z2 = r._z2;
	_z3 = r._z3;
	_z4 = r._z4;
	_z5 = r._z5;
	_z6 = r._z6;
	_z7 = r._z7;
	_z8 = r._z8;
	_z9 = r._z9;
*/
/*
	_high_5 = r._high_5;
	_low_5 = r._low_5;
	
	
	
	_macd_main = r._macd_main;
	_macd_signal = r._macd_signal;
	
	_cci = r._cci;
	_rvi = r._rvi;
	_rvi_sig = r._rvi_sig;
		
*/	
}

// =======================================================

/******************************************************************
当前柱的收盘价：haClose = (Open + High + Low + Close) / 4 
当前柱的开盘价：haOpen = (haOpen [before.]+ HaClose [before]) / 2 
当前柱的最高价：haHigh = Max (High, haOpen, haClose) 
当前柱的最低价：haLow = Min (Low, haOpen, haClose) 

	_ha_open = iCustom(_symbol, _time_frame, "A_wq_HeikenAshi", 0, shift);
******************************************************************/
void indicator::calc_ha(int shift, indicator* pre)
{
	_open = iOpen(_symbol, _time_frame, shift);
	_close = iClose(_symbol, _time_frame, shift);
	_high = iHigh(_symbol, _time_frame, shift);
	_low = iLow(_symbol, _time_frame, shift);

	if (NULL == pre)
	{
	   if (shift < 100)
	   {
		   _ha_open = iCustom(_symbol, _time_frame, "A_wq_HeikenAshi", 0, shift);
	   }
	   else
	   {
		   _ha_open = _open;
		}
	}
	else
	{
		_ha_open = (pre._ha_open + pre._ha_close) / 2;
	}
	_ha_close = (_open + _high + _low + _close) / 4;

	_ha_high = MathMax(MathMax(_high, _ha_open), _ha_close);
	_ha_low = MathMin(MathMin(_low, _ha_open), _ha_close);
}

void indicator::calc(int shift, indicator* pre)
{
	calc_ha(shift, pre);
	if (g_is_new_bar)
	{
		_time = iTime(_symbol, _time_frame, shift);
		_atr = iATR(_symbol, _time_frame, g_atr_period, shift);
	
		_ma_dragon_high = iMA(_symbol, _time_frame, g_ma_dragon_period, 0, g_ma_mode, PRICE_HIGH, shift);
		_ma_dragon_low  = iMA(_symbol, _time_frame, g_ma_dragon_period, 0, g_ma_mode, PRICE_LOW, shift);
		_ma_dragon_centre = iMA(_symbol, _time_frame, g_ma_dragon_period, 0, g_ma_mode, PRICE_TYPICAL, shift);
		_ma_trend = iMA(_symbol, _time_frame, g_ma_trend_period, 0, g_ma_mode, PRICE_TYPICAL, shift);
		
		_channel_long_high = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, g_channel_long_period, shift));
		_channel_long_low = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, g_channel_long_period, shift));
/*
		_channel_medium_high = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, g_channel_medium_period, shift)];
		_channel_medium_low = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, g_channel_medium_period, shift)];
		_channel_short_high = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, g_channel_short_period, shift)];
		_channel_short_low = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, g_channel_short_period, shift)];
*/
		calc_bolling(shift);
		
		_kdj_main = iStochastic(_symbol, _time_frame, g_kdj_k_period, g_kdj_d_period, g_kdj_slow_period, g_ma_mode, 0, MODE_MAIN, shift);
		_kdj_signal = iStochastic(_symbol, _time_frame, g_kdj_k_period, g_kdj_d_period, g_kdj_slow_period, g_ma_mode, 0, MODE_SIGNAL, shift);
		
/*	
		calc_z(shift);

		_high_5 = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, 5, shift)];
		_low_5 = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, 5, shift)];
		
		_macd_main = iMACD(_symbol, _time_frame, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, shift);
		_macd_signal = iMACD(_symbol, _time_frame, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, shift);
		
		_cci = iCCI(_symbol, _time_frame, _cci_period, PRICE_CLOSE, shift);
		
		calc_cmi(shift);
		calc_rvi(shift);
		calc_cci(shift);
*/
	}
	if (shift <= 0)
	{
		calc_burst(shift);
	}
	if (_filter_volatility)
	{
		calc_choppy(shift);
		calc_adx(shift);
	}
/*
	calc_pinbar(shift);
*/
}

/******************************************************************
	if (_burst >= 10 && _climax_bar != 0)
	{
		string s = "climax=" + DoubleToStr(_burst, 1);
		double y = 0;
		if (_climax_bar == 1)
			y = iLow(_symbol, _time_frame, shift) - _atr;
		else if (_climax_bar == -1)
			y = iHigh(_symbol, _time_frame, shift) + _atr;
	//	print_screen(s, iTime(_symbol, _time_frame, shift), y);
	}
******************************************************************/
void indicator::calc_burst(int shift)
{
	_burst = 0;
	double Range = iHigh(_symbol, _time_frame, shift) - iLow(_symbol, _time_frame, shift);
	double Value2 = iVolume(_symbol, _time_frame, shift) * Range;
	double HiValue2 = 0;
	double tempv2 = 0;
	double av = 0;
	for (int j = shift + 1; j <= shift + 10; j++) 
	{
		av = av + iVolume(_symbol, _time_frame, j);
	}
	av = av / 10;
	for (int n = shift + 1; n <= shift + 10; n++)
	{
		tempv2 = iVolume(_symbol, _time_frame, n) * (iHigh(_symbol, _time_frame, n) - iLow(_symbol, _time_frame, n));
		if (tempv2 >= HiValue2) 
		{
			HiValue2 = tempv2;
		}
	}
	if ((Value2 >= HiValue2) || (iVolume(_symbol, _time_frame, shift) >= av * 2))
	{
		if (av > 0 && HiValue2 > 0)
		{
			_burst = MathMax((double)(iVolume(_symbol, _time_frame, shift) / av), (double)(Value2 / HiValue2));
		}
	}
}

/******************************************************************
ChoppyMarketIndex = (Abs(Close-Close[29]) / (Highest(High,30)-Lowest(Low,30)) * 100)

分母是 最近30天最高价 – 最近30天的最低价。
分子则是 今天的收盘价-29天前的收盘价，然后再取绝对值。
ChoppyMarketIndex的数值也是会介于0-100之间，数值越大，代表市场趋势越明显。数值越小，则代表目前市场可能陷入摆荡状况。

_channel_long_period = ((_choppy_market_index) / 100) * 20;
******************************************************************/
void indicator::calc_choppy(int shift)
{
	double h = iHigh(_symbol, _time_frame, iHighest(_symbol, _time_frame, MODE_HIGH, g_channel_long_period, g_choppy_period + shift));
	double l = iLow(_symbol, _time_frame, iLowest(_symbol, _time_frame, MODE_LOW, g_channel_long_period, g_choppy_period + shift));
	_choppy_market_index = MathAbs(_close - iClose(_symbol, _time_frame, g_choppy_period - 1 + shift)) / (h - l) * 100;
}

/******************************************************************
Dynamic Break Out II Pseudocode
If BarNumber = 1 then lookBackDays = 20
Else do the following
Today's market volatility = StdDev(Close,30)
Yesterday's market volatility = StdDev(Close[1],30)
deltaVolatility = (today's volatility - yesterday's volatility)/today's volatility
lookBackDays = (1 + deltaVolatility) * lookBackDays
lookBackDays = MinList(lookBackDays,60)
lookBackDays = MaxList(lookBackDays,20)
******************************************************************/
void indicator::calc_bolling(int shift)
{


	_bolling_up = iBands(_symbol, _time_frame, g_bolling_period, g_bolling_deviation, g_bolling_bands_shift, PRICE_WEIGHTED, MODE_UPPER, shift);
	_bolling_main = iBands(_symbol, _time_frame, g_bolling_period, g_bolling_deviation, g_bolling_bands_shift, PRICE_WEIGHTED, MODE_MAIN, shift);
	_bolling_low = iBands(_symbol, _time_frame, g_bolling_period, g_bolling_deviation, g_bolling_bands_shift, PRICE_WEIGHTED, MODE_LOWER, shift);
}

/******************************************************************
https://www.mql5.com/zh/articles/1747
基于价格运动方向和速度的交易策略

AC指标，来衡量当前价格运动的速度和加速度

bull:
比较当前和前一个K线。如果当前K线超过了前一个，很可能价格要加速上涨。用1表示。
其次是比较相邻的3个柱形（从当前到第二个K线）。如果后面每一根K线都超过它前面的K线，我们可以认为价格在不断的加速上涨。用2表示。
类似的可以比较连续的4根K线，每一个前面的K线增幅都小于后来的K线。用3表示。
比较最近的连续5根K线，如果都是同一个方向。用4表示。

bear:
比较当前K线和前一跟K线。如果当前K线比前一个小，用-1代表。
比较3根K线，当前的都小于前一个。用 -2 表示。
比较4根K线。用 -3 代表。
比较5根K线。用 -4 代表。
******************************************************************/
int indicator::calc_ac(int shift)
{
	double ac[];
	ArrayResize(ac,6);
	for(int i=0; i < 6; i++)
	{
		ac[i]=iAC(_symbol, _time_frame, i + shift);
	}
	_ac_index = 0;
	// buy 
	if(ac[0] > ac[1] && ac[1] > ac[2] && ac[2] > ac[3] && ac[3] > ac[4] && ac[4] > ac[5])
		_ac_index = 5;
	else if(ac[0] > ac[1] && ac[1] > ac[2] && ac[2] > ac[3] && ac[3] > ac[4])
		_ac_index = 4;
	else if(ac[0] > ac[1] && ac[1] > ac[2] && ac[2] > ac[3])
		_ac_index = 3;
	else if(ac[0] > ac[1] && ac[1] > ac[2])
		_ac_index = 2;
	else if(ac[0] > ac[1])
		_ac_index = 1;
	// sell
	else if(ac[0] < ac[1] && ac[1] < ac[2] && ac[2] < ac[3] && ac[3] < ac[4] && ac[4] < ac[5])
		_ac_index = -5;
	else if(ac[0] < ac[1] && ac[1] < ac[2] && ac[2] < ac[3] && ac[3] < ac[4])
		_ac_index = -4;
	else if(ac[0] < ac[1] && ac[1] < ac[2] && ac[2] < ac[3])
		_ac_index = -3;
	else if(ac[0] < ac[1] && ac[1] < ac[2])
		_ac_index = -2;
	else if(ac[0] < ac[1])
		_ac_index = -1;
	return _ac_index;
}

/******************************************************************
ZigZag 指标获得前 N 个折点的函数

# 一般的MT4中 Custom Indicator 中都有 ZigZag 这个指标.
# 取到这三个之后再配合均线系统，可以进一步归纳主的顶点以便推断后面的调整.的起点.
double GetExtremumZZPrice(string sy="", int tf=0, int ne=0, int dp=12, int dv=5, int bs=3) {
  if (sy=="" || sy=="0") sy=Symbol();
  double zz;
  int    i, k=iBars(sy, tf), ke=0;
  for (i=0; i<k; i++) {
    zz=iCustom(sy, tf, "ZigZag", dp, dv, bs, 0, i);
    if (zz!=0) {
      ke++;
      if (ke>ne) return(zz);
    }
  }
  Print("GetExtremumZZPrice(): 曲折号",ne,"没有找到");
  return(0);
}
用法.
// zig zag 的三个参数
int    ExtDepth         = 12;
int    ExtDeviation     = 5;
int    ExtBackstep      = 3;
double room_0 = GetExtremumZZPrice(NULL, 0, 0, ExtDepth, ExtDeviation, ExtBackstep);  // 取当前的顶点.
double room_1 = GetExtremumZZPrice(NULL, 0, 1, ExtDepth, ExtDeviation, ExtBackstep); // 取前面的折点
double room_2 = GetExtremumZZPrice(NULL, 0, 2, ExtDepth, ExtDeviation, ExtBackstep); // 取前面的前面的折点.

******************************************************************/
/*
void indicator::calc_z(int shift)
{
	if (_z1 > 0 && _z2 > 0 && _z3 > 0 && _z4 > 0 && _z5 > 0 && _z6 > 0 && _z7 > 0 && _z8 > 0 && _z9 > 0)
	{
	//	return;
	}
	int c = 0;
	double t = 0;
	_z1 = 0;
	_z2 = 0;
	_z3 = 0;
	_z4 = 0;
	_z5 = 0;
	_z6 = 0;
	_z7 = 0;
	_z8 = 0;
	_z9 = 0;
	for (int i = 0; i < 600; ++i)
	{
		t = iCustom(_symbol, _time_frame, "A_wq_ZigZag", 0, shift + i);
		if (t > 0)
		{
			++c;
			switch (c)
			{
				case 1:
				{
					_z1 = t;
				}
				break;
				case 2:
				{
					_z2 = t;
				}
				break;
				case 3:
				{
					_z3 = t;
				}
				break;
				case 4:
				{
					_z4 = t;
				}
				break;
				case 5:
				{
					_z5 = t;
				}
				break;
				case 6:
				{
					_z6 = t;
				}
				break;
				case 7:
				{
					_z7 = t;
				}
				break;
				case 8:
				{
					_z8 = t;
				}
				break;
				case 9:
				{
					_z9 = t;
				}
				break;
			}
		}
		if (c >= 9)
		{
			break;
		}
	}
}
*/

/**********************************************
做多（买入信号）
绿色的ADX指标主线具有大于或对于30的值，而+DI值大于-DI。
AC的值在当前柱形上增长，并且比前两个柱形上逐渐增大的值都要大。视觉上，有三列绿色直方图，每列都比前一列短，并且所有这三个直方图都位于负值区域。
RVI信号（浅红色）线穿越主线（绿色），两者都在增长，但仍旧在零点以下。


做空（卖出信号）
绿色的ADX指标主线具有大于或对于30的值，而+DI的值小于-DI。
AC值在当前柱形上下跌，并且前两个柱形上AC值也持续下跌。视觉上，有三列红色直方图，每一列都比前一列低，三个的值都大于零。
RVI信号线（浅红色）穿越主线（绿色），都为下降趋势但都在正值区域。

**********************************************/
int indicator::calc_adx(int shift)
{
   _adx = iADX(_symbol, _time_frame, g_adx_period, PRICE_CLOSE, MODE_MAIN, shift);
   _adx_di_plus = iADX(_symbol, _time_frame, g_adx_period, PRICE_CLOSE, MODE_PLUSDI, shift);
   _adx_di_minus = iADX(_symbol, _time_frame, g_adx_period, PRICE_CLOSE, MODE_MINUSDI, shift);
	if (_adx > 30 && _adx_di_plus > _adx_di_minus)  // buy
	{
	}
	else if (_adx > 30 && _adx_di_plus < _adx_di_minus)  // sell
	{
	}
   return 0;
}
/*
int indicator::calc_rvi(int shift)
{
   _rvi = iRVI(_symbol, _time_frame, _rvi_period, MODE_MAIN, shift);
   _rvi_sig = iRVI(_symbol, _time_frame, _rvi_period, MODE_SIGNAL, shift);
   _rvi_index = 0;
   if (_rvi > 0.4)
   {
   	_rvi_index = 4;
   }
   else if (_rvi > 0.3)
   {
   	_rvi_index = 3;
   }
   else if (_rvi > 0.2)
   {
   	_rvi_index = 2;
   }
   else if (_rvi > 0.1)
   {
   	_rvi_index = 1;
   }
	else if(_rvi < -0.4)
   {
		_rvi_index = -4;
   }
	else if(_rvi < -0.3)
   {
		_rvi_index = -3;
   }
	else if(_rvi < -0.2)
   {
		_rvi_index = -2;
   }
	else if(_rvi < -0.1)
   {
		_rvi_index = -1;
   }
	_rvi_entry = 0;
	//if(_rvi > _rvi_sig && _rvi < -0.1)  // buy
	if(_rvi > _rvi_sig && _rvi_index != 0)  // buy
	{
		_rvi_entry = 1;
	}
	//else if(_rvi < _rvi_sig && _rvi > 0.1)  // sell
	else if(_rvi < _rvi_sig && _rvi_index != 0)  // sell
	{
		_rvi_entry = -1;
	}
   return 0;
}
*/
// =======================================================

bool indicator::is_ha_bull()
{
	return _ha_close > _ha_open + _atr * 0.2;
}

bool indicator::is_ha_bear()
{
	return _ha_close < _ha_open - _atr * 0.2;
}

double indicator::bolling_width()
{
	return _bolling_up - _bolling_low;
}

double indicator::channel_width()
{
	return _channel_long_high - _channel_long_low;
}

// =======================================================


