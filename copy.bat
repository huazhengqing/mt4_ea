
cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal"
copy  "*.bat"    "D:\dev\mm\mt4_ea\"


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\24DDD2AF4B390B873FBAE45354FC1591\"
#xcopy ".\profiles\A_wq_bitcoin\*"    		"D:\dev\mm\mt4_ea\profiles\A_wq_bitcoin\"      /s /E /i /y
#xcopy ".\profiles\A_wq_usd\*"    			"D:\dev\mm\mt4_ea\profiles\A_wq_usd\"      /s /E /i /y
#xcopy ".\profiles\A_wq_commodity\*"    			"D:\dev\mm\mt4_ea\profiles\A_wq_commodity\"      /s /E /i /y

copy ".\templates\A_*"    					"D:\dev\mm\mt4_ea\templates\"
copy ".\MQL4\Experts\A_*.mq4"    			"D:\dev\mm\mt4_ea\MQL4\Experts\"
copy ".\MQL4\Include\wq_*"    				"D:\dev\mm\mt4_ea\MQL4\Include\"
copy ".\MQL4\Indicators\A_*.mq4"   			"D:\dev\mm\mt4_ea\MQL4\Indicators\"
copy ".\MQL4\Indicators\Sonic*.mq4"   		"D:\dev\mm\mt4_ea\MQL4\Indicators\"

xcopy "D:\dev\mm\mt4_ea\*"     "D:\百度云同步盘\stock\MQL4_MQL5\wangqing\mt4_ea\"  /s /E /i /y

cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\C142B020C05FAD9EEC4BE1375F709241\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y

cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\C348917D9E28C59E863914247686464D\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\50CA3DFB510CC5A8F28B48D1BF2A5702\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\50CA3DFB510CC5A8F28B48D1BF2A5702\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y



#pause




