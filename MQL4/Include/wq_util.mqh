#property strict


// ===========================================================================


extern const bool g_enable_long = true; 	// [下单方向] 做多
extern const bool g_enable_short = true; 	// [下单方向] 做空

extern const bool g_estimate_trend = true;	// [判断方向] 启用

extern int g_order_max = 1;	// [订单数量] 最大订单数量

extern const bool g_signal_check_by_dragon = false;	// [信号过滤] 价格回调短期均线
extern const bool g_signal_check_by_trend = false;    // [信号过滤] 价格回调长期均线
extern const double g_signal_greater = 0.0;    			// [信号过滤] 价格 > (__)
extern const double g_signal_less = 0.0;    				// [信号过滤] 价格 < (__)

extern const bool g_stop_enable = true;			// [止损] 启用
extern const bool g_stop_for_all_order = true;	// [止损] 所有订单

extern const bool g_stop_by_ha = false;		// [止损策略] 用HA反转
extern const bool g_stop_by_dragon = false;	// [止损策略] 用dragon
extern const bool g_stop_by_trend = false;	// [止损策略] 用trend
extern const bool g_stop_by_channel = true;	// [止损策略] 用Donchian

extern const bool g_break_even = true;				// [保本] (3 * ATR)
extern const bool g_break_even_clasp = false;	// [保本] HA 跟随

extern const bool g_lots_martin = true;	// [下注] 亏损加仓
extern double g_lots_min = 0.01;				// [下注] 最小注
extern double g_lots_max = 2.0;				// [下注] 最大注


const bool g_alert = true;		// [通知]alert


// ===========================================================================

bool g_ea_just_init = true;

bool g_is_new_bar = false;
datetime g_time_0 = 0;



string g_symbol = Symbol();
int g_time_frame = Period();


double g_tick_value = 0;
double g_stop_level = 0;
double g_spread = 0;
int g_digits = 0;
double g_point = 0;


double g_spread_limit = 0.0;    // 点差限制。在此点差内才能下单


int g_magic = 8317;


// ===========================================================================

const int time_frames[] = {PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
const int time_frames_sz = 6;

const string symbols[] = {"XAUUSD", "XAGUSD", 
	"#C-BRENT", "OIL", "#C-NATGAS", "UKOIL", "USOIL", 
	"#C-SOYBM", "#C-SOYB", "#C-SUGAR", "#C-COFFEE", "#C-COTTON", "#C-CORN", "#C-WHEAT", "#C-RICE", "#C-COPPER", 
	"USDCAD", "AUDUSD", "USDJPY", "NZDUSD", "GBPUSD", "EURUSD", "EURJPY", "GBPNZD", "EURGBP", "AUDCAD", "AUDNZD", 
	"USDIDX", "USDindex", 
	"USDCNH", "USDRUB", 
	"ETHUSD", "BTCUSD", "LTCUSD", "BTGUSD", "BCHUSD", "XRPUSD"
	};
const int symbol_sz = 37;

// ===========================================================================

const int g_ma_dragon_period = 34;
const int g_ma_trend_period = 89;
const int g_ma_mode = MODE_LWMA;  // MODE_EMA, MODE_LWMA

const int g_atr_period = 14;

const int g_tutle_long_period = 40;
const int g_tutle_medium_period = 20;
const int g_tutle_short_period = 10;

const int g_kdj_k_period = 9;
const int g_kdj_d_period = 3;
const int g_kdj_slow_period = 3;
const int g_kdj_level_high = 80;
const int g_kdj_level_low = 20;

const int g_rsi_period = 8;
bool g_rsi_ac_bull = false;
bool g_rsi_ac_bear = false;


// ===========================================================================

void init_g_para()
{
	g_symbol = Symbol();
	g_time_frame = Period();
	
	g_tick_value = MarketInfo(g_symbol, MODE_TICKVALUE);
	g_stop_level = MarketInfo(g_symbol, MODE_STOPLEVEL);
	g_spread = MarketInfo(g_symbol, MODE_SPREAD);
	g_digits = (int)MarketInfo(g_symbol, MODE_DIGITS);
	g_point = MarketInfo(g_symbol, MODE_POINT);
	
	g_magic = get_magic(g_symbol, g_time_frame);
	
	g_ea_just_init = true;
	
	g_is_new_bar = false;
	g_time_0 = 0;
	
	g_msg_time = 0;
	g_alert_time = 0;
	
	if (g_order_max > 50)
	{
		g_order_max = 50;
	}
	
	if ("UKOIL" == g_symbol || "USOIL" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 28.0 * 1.5;
	}
	else if ("XAUUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 30.0 * 1.5;
	}
	else if ("XAGUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 1);
		g_spread_limit = 20.0 * 1.5;
	}
	else if ("AUDUSD" == g_symbol || "EURUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 6.0 * 2;
	}
	else if ("USDJPY" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 7.0 * 2;
	}
	else if ("USDCHF" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 15.0 * 1.5;
	}
	else if ("NZDUSD" == g_symbol || "GBPUSD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 20.0 * 1.5;
	}
	else if ("USDCAD" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 25.0 * 1.5;
	}
	else if ("USDindex" == g_symbol)
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 50.0 * 1.5;
	}
	else if ("BTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.01);
		g_lots_max = 0.21;
		g_spread_limit = 6500.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else if ("ETHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_spread_limit = 600.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else if ("BCHUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.1);
		g_lots_max = 2.1;
		g_spread_limit = 1200.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else if ("LTCUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 0.5);
		g_lots_max = 10.5;
		g_spread_limit = 300.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else if ("XRPUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_spread_limit = 10.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else if ("BTGUSD" == g_symbol)
	{
		g_lots_min = MathMax(g_lots_min, 1);
		g_lots_max = 21;
		g_spread_limit = 200.0 * 1.5;
		//g_trailing_stop_by_ha = true;
		//g_trailing_stop_clasp = true;
	}
	else
	{
		g_lots_max = MathMin(g_lots_max, 2);
		g_spread_limit = 7.0 * 1.5;
	}
}

bool is_new_bar(int shift=0)
{
	g_is_new_bar = false;
	if (g_time_0 != iTime(g_symbol, g_time_frame, shift))
	{
		g_is_new_bar = true;
		g_time_0 = iTime(g_symbol, g_time_frame, shift);
	}
	return g_is_new_bar;
}

bool is_crypto_coin()
{
	if ("BTCUSD" == g_symbol 
		|| "ETHUSD" == g_symbol 
		|| "LTCUSD" == g_symbol 
		|| "BCHUSD" == g_symbol 
		|| "XRPUSD" == g_symbol 
		|| "BTGUSD" == g_symbol
		)
	{
		return true;
	}
	return false;
}

// ===========================================================================

int get_magic(string symbol, int tf)
{
	int s = 900;
	for (int j = 0; j < symbol_sz; ++j)
	{
		if (symbol == symbols[j])
		{
			s = 100 + j;
		}
	}
	g_magic = StrToInteger(StringConcatenate(g_magic * 1000, s, tf));
	return g_magic;
}

// ===========================================================================

void print_mt4_info()
{
	Print("IsTradeAllowed()=", IsTradeAllowed(), ",   ");
	Print("IsLibrariesAllowed()=", IsLibrariesAllowed(), ",   ");
	Print("IsDllsAllowed()=", IsDllsAllowed(), ",   ");
	
	Print("IsExpertEnabled()=", IsExpertEnabled(), ",   ");
	Print("IsTradeContextBusy()=", IsTradeContextBusy(), ",   ");
	Print("IsVisualMode()=", IsVisualMode(), ",   ");
	Print("IsOptimization()=", IsOptimization(), ",   ");
	Print("IsStopped()=", IsStopped(), ",   ");
	
	Print("IsDemo()=", IsDemo(), ",   ");
	Print("IsTesting()=", IsTesting(), ",   ");
}

void print_account_info()
{
	Print("AccountBalance()=", AccountBalance(), ",   账户余额");
	Print("AccountCredit()=", AccountCredit(), ",   账户信用额度");
	Print("AccountEquity()=", AccountEquity(), ",   账户净值");
	Print("AccountFreeMargin()=", AccountFreeMargin(), ",   账户可用保证金");
	Print("AccountFreeMarginMode()=", AccountFreeMarginMode(), ",   可用保证金计算方式");
	Print("AccountLeverage()=", AccountLeverage(), ",   账户杠杆比例");
	Print("AccountMargin()=", AccountMargin(), ",   账户已用保证金");
	Print("AccountProfit()=", AccountProfit(), ",   账户盈利金额");
	Print("AccountStopoutLevel()=", AccountStopoutLevel(), ",   账户的止损水平设置");
	Print("AccountStopoutMode()=", AccountStopoutMode(), ",   账户止损计算方式");
}

void print_market_info()
{
	Print("MODE_TIME=", MarketInfo(Symbol(), MODE_TIME), ",   服务器显示时间");
	Print("MODE_LOW=", MarketInfo(Symbol(), MODE_LOW ));
	Print("MODE_HIGH=", MarketInfo(Symbol(), MODE_HIGH));
	Print("MODE_BID=", MarketInfo(Symbol(), MODE_BID));
	Print("MODE_ASK=", MarketInfo(Symbol(), MODE_ASK));
	Print("MODE_POINT=", MarketInfo(Symbol(), MODE_POINT), ", 该货币最小变动单位点值");
	Print("MODE_DIGITS=", MarketInfo(Symbol(), MODE_DIGITS), ", 小数位数");
	Print("MODE_SPREAD=", MarketInfo(Symbol(), MODE_SPREAD), ", 点差");
	Print("MODE_STOPLEVEL=", MarketInfo(Symbol(), MODE_STOPLEVEL), ",  规定最小止赢止损线");
	Print("MODE_LOTSIZE=", MarketInfo(Symbol(), MODE_LOTSIZE), ",    一标准手所用资金,   标准手大小，黄金是100盎司，每次交易必须是100盎司的倍数 （ 黄金： 100 ） 。");
	Print("MODE_TICKVALUE=", MarketInfo(Symbol(), MODE_TICKVALUE), ",    一手每点该货币的价值,   跳动的基值，价格每次跳动的值都是它的倍数。如黄金，价格每次跳动都是0.05的倍数   黄金=0.05");      
	Print("MODE_TICKSIZE=", MarketInfo(Symbol(), MODE_TICKSIZE), ",    报价最小单位");
	Print("MODE_SWAPLONG=", MarketInfo(Symbol(), MODE_SWAPLONG), ",    多头掉期");
	Print("MODE_SWAPSHORT=", MarketInfo(Symbol(), MODE_SWAPSHORT), ",    空头掉期");
	Print("MODE_STARTING=", MarketInfo(Symbol(), MODE_STARTING),",     市场开始日期, 主要用于期货");
	Print("MODE_EXPIRATION=", MarketInfo(Symbol(), MODE_EXPIRATION),",    市场截止日期,主要用于期货");
	Print("MODE_TRADEALLOWED=", MarketInfo(Symbol(), MODE_TRADEALLOWED), ",    交易允许货币对数量");
	Print("MODE_MINLOT=", MarketInfo(Symbol(), MODE_MINLOT), ",       允许的最小手数");
	Print("MODE_LOTSTEP= ", MarketInfo(Symbol(), MODE_LOTSTEP), ",       改变标准手步幅");
	Print("MODE_MAXLOT= ", MarketInfo(Symbol(), MODE_MAXLOT), ",       允许的最大标准手数");
	Print("MODE_SWAPTYPE= ", MarketInfo(Symbol(), MODE_SWAPTYPE),",       掉期计算的方式    (0:点; 1 -基本货币对; 2: 兴趣; 3: 货币保证金)");
	Print("MODE_PROFITCALCMODE= ", MarketInfo(Symbol(), MODE_PROFITCALCMODE),"         赢利计算模式   (0: Forex(外汇); 1: CFD(黄金); 2: Futrues(期货)) ");
	Print("MODE_MARGINCALCMODE= ", MarketInfo(Symbol(), MODE_MARGINCALCMODE),"         保证金计算模式  (0: Forex(外汇); 1: CFD(黄金); 2: Futrues(期货); 3: CFD for indices(黄金指数))");
	Print("MODE_MARGININIT= ", MarketInfo(Symbol(), MODE_MARGININIT), "          一个标准手的初始保证金");  
	Print("MODE_MARGINMAINTENANCE= ", MarketInfo(Symbol(), MODE_MARGINMAINTENANCE), ",       一个标准手的开仓保证金");  
	Print("MODE_MARGINHEDGED= ", MarketInfo(Symbol(), MODE_MARGINHEDGED), ",       一个标准手的护盘保证金");  
	Print("MODE_MARGINREQUIRED= ", MarketInfo(Symbol(), MODE_MARGINREQUIRED), ",       一个标准手的自由保证金");  
	Print("MODE_FREEZELEVEL= ", MarketInfo(Symbol(), MODE_FREEZELEVEL), ",       冻结订单水平点");  
}

// ===========================================================================

string get_time_frame_str(int time_frame)
{
	if (time_frame == 0)
	{
		time_frame = Period();
	}
	switch (time_frame)
	{
	case PERIOD_M1: return "M1";break;
	case PERIOD_M5: return "M5";break;
	case PERIOD_M15: return "M15";break;
	case PERIOD_M30: return "M30";break;
	case PERIOD_H1: return "H1";break;
	case PERIOD_H4: return "H4";break;
	case PERIOD_D1: return "D1";break;
	}
	return "";
}

int get_tf_from_i(int tf_index)
{
	int r = PERIOD_M30;
	switch (tf_index)
	{
	case 0: r = PERIOD_M5;break;
	case 1: r = PERIOD_M15;break;
	case 2: r = PERIOD_M30;break;
	case 3: r = PERIOD_H1;break;
	case 4: r = PERIOD_H4;break;
	case 5: r = PERIOD_D1;break;
	};
	return r;
}

string get_order_str(int order_type)
{
	switch (order_type)
	{
	case OP_BUY: return "BUY";break;
	case OP_SELL: return "SELL";break;
	}
	return "";
}

// ===========================================================================

void print_screen(datetime x, double y, string s)
{
	if (IsTesting() || IsDemo() || IsStopped())
	{
		return;
	}
	if (StringLen(s) <= 0)
	{
		return;
	}
	static long screen_i = 0;
	string n = "wq_" + IntegerToString(x) + DoubleToStr(y) + IntegerToString(screen_i);
	++screen_i;
	ObjectDelete(n);
	ObjectCreate(n, OBJ_TEXT, 0, x, y);
	//ObjectSetText(n, s, 10, "Arial", DodgerBlue);
	ObjectSetText(n, s, 10, "Arial", Lime);
}

datetime g_msg_time = 0;
void send_msg(string msg)
{
	if (IsTesting() || IsDemo() || IsStopped())
	{
		return;
	}
	if (StringLen(msg) <= 0)
	{
		return;
	}
	const string s = "[" + Symbol() + "][" + get_time_frame_str(Period()) + "]" + msg;
	if (g_msg_time < iTime(Symbol(), Period(), 0))
	{
		g_msg_time = iTime(Symbol(), Period(), 0);
		bool r = SendNotification(s);
		if (!r)
		{
			Print("[ERROR] send_msg() last_err=", GetLastError(), "|msg=", s);
		}
	}
}

datetime g_alert_time = 0;
void alert(string msg)
{
	if (IsTesting() || IsDemo() || IsStopped())
	{
		return;
	}
	if (StringLen(msg) <= 0)
	{
		return;
	}
	const string s = "[" + Symbol() + "][" + get_time_frame_str(Period()) + "]" + msg;
	if (g_alert_time < iTime(Symbol(), Period(), 0))
	{
		g_alert_time = iTime(Symbol(), Period(), 0);
		if (g_alert)
		{
			Alert(s);
		}
	}
}

// ===========================================================================

