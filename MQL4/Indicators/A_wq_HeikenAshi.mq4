#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'224,001,006'
#property indicator_color2 C'031,192,071'
#property indicator_color3 C'224,001,006'
#property indicator_color4 C'031,192,071'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1


input color ExtColor1 = C'224,001,006';    // Shadow of bear candlestick
input color ExtColor2 = C'031,192,071';  // Shadow of bull candlestick
input color ExtColor3 = C'224,001,006';    // Bear candlestick body
input color ExtColor4 = C'031,192,071';  // Bull candlestick body


double ExtOpenBuffer[];
double ExtCloseBuffer[];

double ExtLowHighBuffer[];
double ExtHighLowBuffer[];


extern bool Indicator_On = true;
bool Deinitialized;
int Chart_Scale;
int Bar_Width;


void OnInit(void)
{
	Deinitialized = false; 
	
	Chart_Scale = ChartScaleGet();

	if(Chart_Scale == 0) {Bar_Width = 1;}
	else {if(Chart_Scale == 1) {Bar_Width = 2;}      
	else {if(Chart_Scale == 2) {Bar_Width = 2;}
	else {if(Chart_Scale == 3) {Bar_Width = 3;}
	else {if(Chart_Scale == 4) {Bar_Width = 6;}
	else {Bar_Width = 13;} }}}}

	IndicatorDigits(Digits);
	
	
	SetIndexStyle(0,DRAW_HISTOGRAM,0,Bar_Width,ExtColor3);
	SetIndexBuffer(0,ExtOpenBuffer);
	
	SetIndexStyle(1,DRAW_HISTOGRAM,0,Bar_Width,ExtColor4);
	SetIndexBuffer(1,ExtCloseBuffer);
	
	SetIndexStyle(2,DRAW_HISTOGRAM,0,1,ExtColor1);
	SetIndexBuffer(2,ExtLowHighBuffer);
	
	SetIndexStyle(3,DRAW_HISTOGRAM,0,1,ExtColor2);
	SetIndexBuffer(3,ExtHighLowBuffer);
	
	
	SetIndexDrawBegin(0,10);
	SetIndexDrawBegin(1,10);
	SetIndexDrawBegin(2,10);
	SetIndexDrawBegin(3,10);
	
	//ObjectsDeleteAll(0, OBJ_TEXT);
}

int deinit()
{
	return(0);
}

/*
当前柱的收盘价：haClose = (Open + High + Low + Close) / 4 
当前柱的开盘价：haOpen = (haOpen [before.]+ HaClose [before]) / 2 
当前柱的最高价：haHigh = Max (High, haOpen, haClose) 
当前柱的最低价：haLow = Min (Low, haOpen, haClose) 
*/
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
  
	if (!Indicator_On) 
	{
		if (!Deinitialized) {deinit(); Deinitialized = true;}
		return(0);
	}
  
   int    i,pos;
   double haOpen,haHigh,haLow,haClose;
   
   if(rates_total<=10)
      return(0);
      
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtLowHighBuffer,false);
   ArraySetAsSeries(ExtHighLowBuffer,false);
   ArraySetAsSeries(ExtOpenBuffer,false);
   ArraySetAsSeries(ExtCloseBuffer,false);
   ArraySetAsSeries(open,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(close,false);
   
//--- preliminary calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
     {
      //--- set first candle
      if(open[0]<close[0])
        {
         ExtLowHighBuffer[0]=low[0];
         ExtHighLowBuffer[0]=high[0];
        }
      else
        {
         ExtLowHighBuffer[0]=high[0];
         ExtHighLowBuffer[0]=low[0];
        }
      ExtOpenBuffer[0]=open[0];
      ExtCloseBuffer[0]=close[0];
      //---
      pos=1;
     }
	
	for(i=pos; i<rates_total; i++)
	{
		haOpen=(ExtOpenBuffer[i-1]+ExtCloseBuffer[i-1])/2;
		haClose=(open[i]+high[i]+low[i]+close[i])/4;
		haHigh=MathMax(high[i],MathMax(haOpen,haClose));
		haLow=MathMin(low[i],MathMin(haOpen,haClose));
		if(haOpen<haClose)
		{
			ExtLowHighBuffer[i]=haLow;
			ExtHighLowBuffer[i]=haHigh;
		}
		else
		{
			ExtLowHighBuffer[i]=haHigh;
			ExtHighLowBuffer[i]=haLow;
		}
		ExtOpenBuffer[i]=haOpen;
		ExtCloseBuffer[i]=haClose;
	}

	return(rates_total);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
	Chart_Scale = ChartScaleGet();
	OnInit();
}

int ChartScaleGet()
{
	long result = -1;
	ChartGetInteger(0,CHART_SCALE,0,result);
	return((int)result);
}









