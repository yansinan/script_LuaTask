
PROJECT = "GPIO_SINGLE"
VERSION = "2.0.0"

require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"
require "pins"
 
 
require"pm"
require"ril"

 

require"lcd_HER88128_663"
 


--启动系统框架
sys.init(0, 0)
sys.run()
