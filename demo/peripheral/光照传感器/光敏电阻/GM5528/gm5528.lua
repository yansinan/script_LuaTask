
-- @author openLuat
-- @module alarm.testAlarm
-- @license MIT
-- @copyright openLuat  
-- @release 2021.11.18

require "log"
require "sys"
require "misc"
module(...,package.seeall)

-- 本程序支持 5528 和 5516， 其他55XX 可以对照调整。
-- 应用范围：
--     照相机自动测光          
--     室内光线控制
--     工业控制                   
--     光控灯
--     光电控制
--     报警器
--     光控开关                   
--     电子玩具

MAX_VOLT = 1810   --用GLOBAL1V8做上拉电压

local LUX1_RES,LUX_Y,MAX_RESVAL
local COMPONET_TYPE="5528" -- ohter is 5516


if COMPONET_TYPE  == "5528" then
    ----------5528 10 lux (5000,10000)
    LUX1_RES=141000    --不同型号，此值不同
    LUX_Y=0.6
    MAX_RESVAL= 100000
else
---------5516 -10 lux (8000~20000)
   LUX1_RES=62000      --不同型号，此值不同
   LUX_Y=0.6
   MAX_RESVAL=  500000
end

local ADC_ID=3 -------ADC3
--                     |
--                     |
-- 1.8V -------10K-----|----GM55XX--------GND


local function get_resinfo()

    local _,volt = adc.read(ADC_ID)
    log.info("testAdc3.volt",volt)

--    res * 1800 / (res+10000) = volt
--    1800*res = volt *res + 10000 *volt
      local res = MAX_RESVAL

      if volt < MAX_VOLT then
          res =   10000*volt / (1810-volt)
          if res > MAX_RESVAL then
             res = MAX_RESVAL
          end
      end

      local lux = math.pow(LUX1_RES/res, 1/LUX_Y )
      return volt,math.floor(res),math.floor( lux )
end



sys.taskInit(function()
    sys.wait(4000)
    adc.open(ADC_ID)
    while true do
        local v,r,lux= get_resinfo()
        log.info("volt, res ,lux=",v,r,lux )
        sys.wait(1000)
    end
end)

sys.init(0, 0)
sys.run()
