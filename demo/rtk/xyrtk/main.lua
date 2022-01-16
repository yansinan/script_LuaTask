
PROJECT = "ADC"
VERSION = "2.0.0"

--加载日志功能模块，并且设置日志输出等级
--如果关闭调用log模块接口输出的日志，等级设置为log.LOG_SILENT即可
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"
require "gpsHxxt"


rtos.on(rtos.MSG_RTK_INFO, function(msg)
    log.info("rtk",msg.id,msg.status,msg.data)
end)


local function nmeaCb(nmeaItem)
	--log.info("nmeaCb",nmeaItem)
	rtk.write(nmeaItem)
end


local function test()
	sys.wait(5000)
	-- uart.setup(2,115200,8,uart.PAR_NONE,uart.STOP_1)
	gpsHxxt.setUart(2,115200,8,uart.PAR_NONE,uart.STOP_1)
	gpsHxxt.setNmeaMode(2,nmeaCb)
	gpsHxxt.open(gpsHxxt.DEFAULT,{tag="rtk"})

    local para =
    {
        appKey = "xyuwwhggzueyiqpgba12", 
        appSecret = "",
		solMode = rtk.SOLMODE_RTK,
		solSec = rtk.SEC_5S,
		reqSec = rtk.SEC_5S
    }
	rtk.open(para)
	--sys.wait(20000);
	--rtk.close()
	--para.reqSec=rtk.SEC_1S
	--rtk.open(para);
end

sys.taskInit(test)

--启动系统框架
sys.init(0, 0)
sys.run()
