
PROJECT = "DS18B20"
VERSION = "2.0.0"

--加载日志功能模块，并且设置日志输出等级
--如果关闭调用log模块接口输出的日志，等级设置为log.LOG_SILENT即可
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"
 
local function testds18b20()
	sys.wait(5000)
	-- 个别gpio需要打开电压域才可以正常使用
	pmd.ldoset(15,pmd.LDO_VLCD)
	
	while true do
		local status,temperature = onewire.read_ds18b20(pio.P0_19)
		if status == onewire.OK then
			log.info("18b20","temperature:",temperature/10000)
		elseif status == onewire.NOT_SENSOR then
			log.info("18b20","未检测到传感器,请检查硬件连接")
		elseif status == onewire.READ_ERROR then
			log.info("18b20","读取数据过程错误")
		elseif status == onewire.CHECK_ERROR then
			log.info("18b20","数据校验错误")
		end
		sys.wait(1000)
		
	end
end
sys.taskInit(testds18b20)
 




--启动系统框架
sys.init(0, 0)
sys.run()
