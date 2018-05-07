
cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal"
copy  "*.bat"    "D:\dev\mm\mt4_ea\"


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\39369E9A010897DDC6DFB2F026E04236\"
#xcopy ".\profiles\A_wq_bitcoin\*"    		"D:\dev\mm\mt4_ea\profiles\A_wq_bitcoin\"      /s /E /i /y
#xcopy ".\profiles\A_wq_usd\*"    			"D:\dev\mm\mt4_ea\profiles\A_wq_usd\"      /s /E /i /y
#xcopy ".\profiles\A_wq_commodity\*"    			"D:\dev\mm\mt4_ea\profiles\A_wq_commodity\"      /s /E /i /y



copy ".\templates\A_*"    					"D:\dev\mm\mt4_ea\templates\"
copy ".\MQL4\Experts\A_*.mq4"    			"D:\dev\mm\mt4_ea\MQL4\Experts\"
copy ".\MQL4\Include\wq_*"    				"D:\dev\mm\mt4_ea\MQL4\Include\"
copy ".\MQL4\Indicators\A_*.mq4"   			"D:\dev\mm\mt4_ea\MQL4\Indicators\"
copy ".\MQL4\Indicators\Sonic*.mq4"   		"D:\dev\mm\mt4_ea\MQL4\Indicators\"



xcopy "D:\dev\mm\mt4_ea\*"     "D:\百度云同步盘\stock\MQL4_MQL5\wangqing\mt4_ea\"  /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\68F860AB0483135E3D2C8B03DCB3B032\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\C348917D9E28C59E863914247686464D\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\CC6AAA3367A6592D7E05F97A0A1C9C96\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y


cd "%UserProfile%\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\"
xcopy "D:\dev\mm\mt4_ea\*"     "."   /s /E /i /y




#pause




