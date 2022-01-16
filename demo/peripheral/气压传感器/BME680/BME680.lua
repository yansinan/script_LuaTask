--- 模块功能：BME680功能测试.
-- @author openLuat
-- @module i2c.testI2c
-- @license MIT
-- @copyright openLuat
-- @release 2021.09.19

module(...,package.seeall)

require"utils"
require "powerKey"

local i2cid = 2
local i2cslaveaddr = 0x76
local cmd,i ={0x1D,0x1f,0x20,0x21,0x22,0x23,0x24,0xEA,0xE9,0x8B,0x8A,0x8C,0x2A,0x2B,0xD0,0x74,0x70,0x71,0x72,0xEE,0xED,0xEB,0xEC,0x02,0x00}
local pressure_data={0x1F,0x20,0x21,0x8F,0x8E,0x91,0x90,0x92,0x95,0x94,0x97,0x96,0x99,0x98,0x9D,0x9C,0x9F,0x9E,0xA0}
local temprature_data={0x22,0x23,0x24,0xEA,0XE9,0X8B,0x8A,0x8C}
local humidity_data={0x25,0x26,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8}
local gas_data={0x2A,0x2B,0x04,0xED,0xEC,0xEB,0xEE,0x02,0x00}
local chip_id={0xD0}
local ctrl_meas=0xB6           --初始化配置值 寄存器地址0x74 
local setup_ctrl_meas          --初始化配置函数
local i2copen_flag=false       --i2c打开标志
temperature=nil              --温度值
pressure=nil                 --压力值
humidity=nil                 --湿度值
local gasResistence            --大气质量电阻值
local iaq                      --空气质量水平
local CompensateTemperature    --计算实际温度数据
local CompensatePressure       --计算实际压力
local CompensateHumidity       --计算实际湿度数据

--setup ctrl meas 
--return i2c open flag
setup_ctrl_meas=function()
  sys.taskInit(function()
    if i2c.setup(i2cid,100000) ~= 100000 then
      print("BME680 init fail")
      i2copen_flag=false
      return i2copen_flag
  end
    i2c.send(i2cid,i2cslaveaddr, {0xB6,0xE0})              --执行复位
    sys.wait(1000)
    i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
    i2c.send(i2cid,i2cslaveaddr, {0x72,0x05})
    i2c.send(i2cid,i2cslaveaddr, {0x75,0x1C})
    i2c.send(i2cid,i2cslaveaddr, {0x70,0x08})
    i2c.send(i2cid,i2cslaveaddr, {0x71,0x19})
    i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
    sys.wait(20)
end)
i2copen_flag=true
return i2copen_flag
end

local function readdata(table)
  if not i2copen_flag then
    if i2c.setup(i2cid,100000) ~= 100000 then
        print("init fail")
        return
    end
  else  
    for i=1,#table,1 do
      --向从设备i2cslaveaddr发送寄存器地址cmd[i]
      i2c.send(i2cid,i2cslaveaddr,table[i])
      
      print("testI2c.init",string.format("%02X",table[i]),string.toHex(i2c.recv(i2cid,i2cslaveaddr,1)))
      
    end
  end
end

local function longCb()
  --   sys.taskInit(function()
  --     if not i2copen_flag then
  --       if i2c.setup(i2cid,100000) ~= 100000 then
  --           print("init fail")
  --           return
  --         end
  --     else log.debug("BME680","i2c is open") end
  --     while true do
  --       i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
  --       sys.wait(10)
  --   log.debug("压力","======================================================================")
  --   readdata(pressure_data)
  --   log.debug("温度","======================================================================")
  --   readdata(temprature_data)
  --   log.debug("湿度","======================================================================")
  --   readdata(humidity_data)
  --   log.debug("空气质量","======================================================================")
  --   readdata(gas_data)
  --   log.debug("芯片ID","======================================================================")
  --   readdata(chip_id)
  --   sys.wait(5000)
  -- end
  --   --i2c.close(i2cid)
  --   end)
 CompensateTemperature()
 CompensateHumidity()
 CompensatePressure()
end

local function shortCb()
      setup_ctrl_meas()
end

powerKey.setup(3000, longCb, shortCb)

--计算实际温度数据
--reurn 实际温度
CompensateTemperature=function ()
  sys.taskInit(function()
    if not i2copen_flag then
      if i2c.setup(i2cid,100000) ~= 100000 then
          print("init fail")
          return
      end
    else  
      i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
      sys.wait(10)
      i2c.send(i2cid,i2cslaveaddr,0xE9)
      local dig_t1=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_t1=tonumber(string.sub(dig_t1,3,4)..string.sub(dig_t1,1,2),16)
      
      i2c.send(i2cid,i2cslaveaddr,0x8A)
      local dig_t2=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_t2=tonumber(string.sub(dig_t2,3,4)..string.sub(dig_t2,1,2),16)
      
      i2c.send(i2cid,i2cslaveaddr,0x8C)
      local dig_t3=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_t3=tonumber(dig_t3,16)
      
      i2c.send(i2cid,i2cslaveaddr,0x22)
      local adcCode=string.toHex(i2c.recv(i2cid,i2cslaveaddr,3))
      adcCode=tonumber(string.sub(adcCode,1,5),16)
      local var2,var1
      var1 = (adcCode) / 16384.0 - dig_t1 / 1024.0
      var1 = var1 * dig_t2
      var2 = ((adcCode) / 131072.0 - dig_t1 / 8192.0)
      var2 = (var2 * var2) * dig_t3
      
      temperature = (var1 + var2) / 5120.0
    end
 log.info("BME680 ",(string.format("实际温度%.2f℃\n",temperature)))
 
 end)
 return
end
--计算实际湿度数据
CompensateHumidity=function ()
  sys.taskInit(function()
    if not i2copen_flag then
      if i2c.setup(i2cid,100000) ~= 100000 then
          print("init fail")
          return
      end
    else  
      i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
      sys.wait(10)
      i2c.send(i2cid,i2cslaveaddr,0xE2)
      local dig_h1=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_h1=tonumber(string.sub(dig_h1,3,4)..string.sub(dig_h1,1,1),16)
      i2c.send(i2cid,i2cslaveaddr,0xE1)
      local dig_h2=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_h2=tonumber(string.sub(dig_h2,1,3),16)
      i2c.send(i2cid,i2cslaveaddr,0xE4)
      local dig_h3=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_h3=tonumber(dig_h3,16)
      i2c.send(i2cid,i2cslaveaddr,0xE5)
      local dig_h4=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_h4=tonumber(dig_h4,16)
      i2c.send(i2cid,i2cslaveaddr,0xE6)
      local dig_h5=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_h5=tonumber(dig_h5,16)
      i2c.send(i2cid,i2cslaveaddr,0xE7)
      local dig_h6=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_h6=tonumber(dig_h6,16)
      i2c.send(i2cid,i2cslaveaddr,0xE8)
      local dig_h7=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_h7=tonumber(dig_h7,16)
      i2c.send(i2cid,i2cslaveaddr,0x25)
      local adcCode=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      adcCode=tonumber(adcCode,16)
      --log.debug("测试","dig_h1",dig_h1,"dig_h2",dig_h2,"dig_h3",dig_h3,"dig_h4",dig_h4,"dig_h5",dig_h5,"dig_h6",dig_h6,"dig_h7",dig_h7,"\n","adcCode",adcCode)
      local var1,var2,var3,var4,temp
      
      --log.debug("测试",temperature)
      if temperature and adcCode and dig_h1 then
        temp=temperature
        var1=(adcCode)-((dig_h1*16)+((dig_h3/2)*temp))
        var2=var1*(((dig_h2/262144)*(1 + ((dig_h4/16384)*temp)+((dig_h5/1048576)*temp*temp))))
        var3 =dig_h6 / 16384
        var4 =dig_h7 / 2097152
        humidity = var2 + ((var3 + (var4 * temp)) * var2 * var2)
        log.info("BME680 ",(string.format("实际湿度%.2f℃",humidity)).."%")
      else
        log.warn("BME680","需先测量当前环境温度进行校准","temperature",temperature,"adcCode",adcCode,"dig_h1",dig_h1)
      end
      
    end
  end)
  return
end
--计算实际压力数据
CompensatePressure=function ()
  sys.taskInit(function()
    if not i2copen_flag then
      if i2c.setup(i2cid,100000) ~= 100000 then
          print("init fail")
          return
      end
    else  
      i2c.send(i2cid,i2cslaveaddr, {0x74, ctrl_meas})
      sys.wait(10)
      i2c.send(i2cid,i2cslaveaddr,0x8E)
      local dig_p1=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p1=tonumber(string.sub(dig_p1,3,4)..string.sub(dig_p1,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0x90)
      local dig_p2=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p2=tonumber(string.sub(dig_p2,3,4)..string.sub(dig_p2,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0x92)
      local dig_p3=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_p3=tonumber(dig_p3,16)
      i2c.send(i2cid,i2cslaveaddr,0x94)
      local dig_p4=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p4=tonumber(string.sub(dig_p4,3,4)..string.sub(dig_p4,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0x96)
      local dig_p5=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p5=tonumber(string.sub(dig_p5,3,4)..string.sub(dig_p5,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0x99)
      local dig_p6=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_p6=tonumber(dig_p6,16)
      i2c.send(i2cid,i2cslaveaddr,0x98)
      local dig_p7=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_p7=tonumber(dig_p7,16)
      i2c.send(i2cid,i2cslaveaddr,0x9C)
      local dig_p8=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p8=tonumber(string.sub(dig_p8,3,4)..string.sub(dig_p8,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0x9E)
      local dig_p9=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
      dig_p9=tonumber(string.sub(dig_p9,3,4)..string.sub(dig_p9,1,2),16)
      i2c.send(i2cid,i2cslaveaddr,0xA0)
      local dig_p10=string.toHex(i2c.recv(i2cid,i2cslaveaddr,1))
      dig_p10=tonumber(dig_p10,16)
      i2c.send(i2cid,i2cslaveaddr,0x1F)
      local adcCode=string.toHex(i2c.recv(i2cid,i2cslaveaddr,3))
      adcCode=tonumber(string.sub(adcCode,1,5),16)
      --log.debug("测试","dig_p1",dig_p1.."\n","dig_p2",dig_p2.."\n","dig_p3",dig_p3.."\n","dig_p4",dig_p4.."\n","dig_p5",dig_p5.."\n","dig_p6",dig_p6.."\n","dig_p7",dig_p7.."\n","dig_p8",dig_p8.."\n","dig_p9",dig_p9.."\n","dig_p10",dig_p10.."\n","adcCode",adcCode.."\n")
      if temperature and adcCode and dig_p1 then
        local pressure_min = 30000.0
        local pressure_max = 110000.0
        local var1,var2,var3,t_fine
        t_fine=temperature*5120
        var1 = (t_fine / 2.0) - 64000.0
        var2 = var1 * var1 * (dig_p6) / 131072.0
        var2 = var2 + var1 * (dig_p5) * 2.0
        var2 = (var2 / 4.0) + ((dig_p4) * 65536.0)
        var1 = (dig_p3) * var1 * var1 / 16384.0
        var1 = (var1 + (dig_p2) * var1) / 524288.0
        var1 = (1.0 + var1 / 32768.0) * (dig_p1)

        pressure = 1048576.0 - adcCode
        pressure = ((pressure - (var2 / 4096.0)) * 6250.0 )/ var1
        var1 = (dig_p9 * pressure * pressure )/ 2147483648.0
        var2 = pressure * (dig_p8) / 32768.0
        var3 = ((pressure  / 256) * (pressure  / 256) * (pressure  / 256)* (dig_p10 / 131072))
        pressure = pressure + (var1 + var2 +var3+ (dig_p7*128.0)) / 16.0

        log.info("BME280 ",(string.format("实际压力%.2f Pa",pressure)))
      else
        log.warn("BME680","需先测量当前环境温度进行校准")
      end
    end
  end)
end