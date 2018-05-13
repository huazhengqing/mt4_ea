/*
http://www.forex-tsd.com/
*/
//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 4
//#property indicator_color1 Red
//#property indicator_color2 Lime
//#property indicator_color3 Red
//#property indicator_color4 Lime


extern int g_ma_period = 6;
extern int g_ma_period2 = 2;
const int g_ma_mode = MODE_LWMA;  // MODE_EMA, MODE_LWMA

color ExtColor1 = C'224,001,006';	// Shadow of bear candlestick
color ExtColor2 = C'031,192,071';	// Shadow of bull candlestick
color ExtColor3 = C'224,001,006';	// Bear candlestick body
color ExtColor4 = C'031,192,071';	// Bull candlestick body

double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];
double ExtMapBuffer7[];
double ExtMapBuffer8[];


int ExtCountedBars=0;


int init()
{
	IndicatorBuffers(8);
	
	SetIndexStyle(0,DRAW_HISTOGRAM,0,0,ExtColor3);
	SetIndexBuffer(0,ExtMapBuffer1);
	SetIndexDrawBegin(0,5);
	
	SetIndexStyle(1,DRAW_HISTOGRAM,0,0,ExtColor4);
	SetIndexBuffer(1,ExtMapBuffer2);
	
	SetIndexStyle(2,DRAW_HISTOGRAM,0,2,ExtColor1);
	SetIndexBuffer(2,ExtMapBuffer3);
	
	SetIndexStyle(3,DRAW_HISTOGRAM,0,2,ExtColor2);
	SetIndexBuffer(3,ExtMapBuffer4);
	
	SetIndexBuffer(4,ExtMapBuffer5);
	SetIndexBuffer(5,ExtMapBuffer6);
	SetIndexBuffer(6,ExtMapBuffer7);
	SetIndexBuffer(7,ExtMapBuffer8);
	
	return(0);
}

int deinit()
{
	return(0);
}

int start()
{
   double maOpen,maClose,maLow,maHigh;
   double haOpen,haHigh,haLow,haClose;
   if(Bars<=10) return(0);

   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   int limit=Bars-counted_bars;
   if(counted_bars==0) limit-=1+MathMax(1,MathMax(g_ma_period,g_ma_period2));
	
	int pos=limit;
	while(pos>=0)
	{
		maOpen=iMA(NULL,0,g_ma_period,0,g_ma_mode,MODE_OPEN,pos);
		maClose=iMA(NULL,0,g_ma_period,0,g_ma_mode,MODE_CLOSE,pos);
		maLow=iMA(NULL,0,g_ma_period,0,g_ma_mode,MODE_LOW,pos);
		maHigh=iMA(NULL,0,g_ma_period,0,g_ma_mode,MODE_HIGH,pos);

		haOpen=(ExtMapBuffer5[pos+1]+ExtMapBuffer6[pos+1])/2;
		haClose=(maOpen+maHigh+maLow+maClose)/4;
		haHigh=MathMax(maHigh,MathMax(haOpen,haClose));
		haLow=MathMin(maLow,MathMin(haOpen,haClose));
		if(haOpen<haClose)
		{
			ExtMapBuffer7[pos]=haLow;
			ExtMapBuffer8[pos]=haHigh;
		}
		else
		{
			ExtMapBuffer7[pos]=haHigh;
			ExtMapBuffer8[pos]=haLow;
		}
		ExtMapBuffer5[pos]=haOpen;
		ExtMapBuffer6[pos]=haClose;
		pos--;
	}

	int i;
	for(i=0; i<limit; i++) ExtMapBuffer1[i]=iMAOnArray(ExtMapBuffer7,0,g_ma_period2,0,g_ma_mode,i);
	for(i=0; i<limit; i++) ExtMapBuffer2[i]=iMAOnArray(ExtMapBuffer8,0,g_ma_period2,0,g_ma_mode,i);
	for(i=0; i<limit; i++) ExtMapBuffer3[i]=iMAOnArray(ExtMapBuffer5,0,g_ma_period2,0,g_ma_mode,i);
	for(i=0; i<limit; i++) ExtMapBuffer4[i]=iMAOnArray(ExtMapBuffer6,0,g_ma_period2,0,g_ma_mode,i);
	
	return(0);
}
