--- 模块功能：呼吸灯
-- @author openLuat
-- @module breathingLight
-- @license MIT
-- @copyright openLuat
-- @release 2021.6.2
module(...,package.seeall)
require "misc"

--模块温度返回回调函数
--@temp温度，srting类型，如果要对该值进行运算，可以使用带float的固件将该值转为number
local function getTemperatureCb(temp)
    log.info("Temperature",temp)
end

--2秒循环查询模块温度
sys.timerLoopStart(misc.getTemperature,2000,getTemperatureCb)

