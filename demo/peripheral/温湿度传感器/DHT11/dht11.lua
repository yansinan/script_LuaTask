
PROJECT = "DHT11"
VERSION = "2.0.0"

--加载日志功能模块，并且设置日志输出等级
--如果关闭调用log模块接口输出的日志，等级设置为log.LOG_SILENT即可
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"

local function testdht11()
	sys.wait(5000)
	-- 个别gpio需要打开电压域才可以正常使用
	pmd.ldoset(15,pmd.LDO_VLCD)
	while true do
		local status,humidity,temperature = onewire.read_dht11(pio.P0_7)
		if status == onewire.OK then
			log.info("dht11","temperature:",temperature)
            log.info("dht11","humidity:",humidity)
		elseif status == onewire.NOT_SENSOR then
			log.info("dht11","未检测到传感器,请检查硬件连接")
		elseif status == onewire.READ_ERROR then
			log.info("dht11","读取数据过程错误")
		elseif status == onewire.CHECK_ERROR then
			log.info("dht11","数据校验错误")
		end
		sys.wait(1000)
	end
end
sys.taskInit(testdht11)


--启动系统框架
sys.init(0, 0)
sys.run()
