--- 模块功能：BME280功能测试.
-- @author openLuat
-- @module BME280
-- @license MIT
-- @copyright openLuat
-- @release 2021.09.13

module(...,package.seeall)

require"utils"

local i2cid = 2
local i2cslaveaddr = 0x76
local cmd,i ={0xD0,0xE0,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,0XFB,0xFc,who="read all"}
local pressure_data={0xF7,0xF8,0xF9,who="pressure"}
local temprature_data={0xFA,0xFB,0xFC,who="temprature"}
local chip_id={0xD0,who="chip_ID"}
local dig_T={0x88,0x89,0x8A,0x8B,0x8C,0x8D,who="dig_T"}
local dig_P={0x8E,0x8F,0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9E,0x9F,who="dig_P"}                   
local i2copen_flag=false              --i2c开启标志位
local setup                           --初始化函数
local read_T                          --读取温度函数
local read_P                          --读取压力函数
local ctrl_meas=0x3F                  --默认配置，根据需要自行修改
local temprature                      --校准计算后的温度数据
local pressure                        --校准计算后的压力数据
local temperature__correction         --采集实际环境中的温度作为后续计算气压值的校准数据

--读取数据
local function readdata(table)
  if type(table)=="table" then
    log.debug("who",dig_T.who)
    sys.taskInit(function()
      if i2c.setup(i2cid,100000) ~= 100000 then
          print("init fail")
          return
        end
      for i=1,#table,1 do
        --向从设备i2cslaveaddr发送寄存器地址cmd[i]
        i2c.send(i2cid,i2cslaveaddr,table[i])
        --向从设备i2cslaveaddr发送要写入从设备寄存器内的数据cmd[i+1]
        print("testI2c.init",string.format("%02X",table[i]),string.toHex(i2c.recv(i2cid,i2cslaveaddr,1)))
      end
      i2c.close(i2cid)
  end)
  else log.warn("BME280 readdata ","input data type not table")
  end
end

--初始化函数
setup=function()
  sys.taskInit(function()
    if i2c.setup(i2cid,100000) ~= 100000 then
      print("HDC2080 init fail")
      i2copen_flag=false
      return i2copen_flag
  end
    i2c.send(i2cid,i2cslaveaddr, {0xE0, 0xB6})              --执行复位
    sys.wait(1000)
    i2c.send(i2cid,i2cslaveaddr, {0xF4, ctrl_meas})
    sys.wait(10)
end)
i2copen_flag=true
return i2copen_flag
end

--[[ 此部分注释放开即可使用724-A13等开发板按键触发检测
    require "powerKey"
local function longCb()
  sys.taskInit(read_P)
end
local function shortCb()
 sys.taskInit(read_T)
end

powerKey.setup(3000, longCb, shortCb)
]]


read_T= function ()
  temprature=nil
  if i2copen_flag then                                   --判断当前i2c是否打开
    log.info("BME280","i2c opening")
  else
    if i2c.setup(i2cid,100000) ~= 100000 then            
      print("BME280 init fail")
      i2copen_flag=false
      return false
    else 
      i2copen_flag=true
    end
  end
  i2c.send(i2cid,i2cslaveaddr, {0xF4, ctrl_meas})       --写入默认配置，如需修改请参考手册中0xF4
  sys.wait(1000)
  i2c.send(i2cid,i2cslaveaddr,0xF7)                     --读取adc采集温度数据
   local zwdata=i2c.recv(i2cid,i2cslaveaddr,6)
   local data=string.sub(string.toHex(zwdata),7,11)
  i2c.send(i2cid,i2cslaveaddr,0x88)                     --读取温度校准数据
    local dig_T_data=string.toHex(i2c.recv(i2cid,i2cslaveaddr,6))
    local dig_T1=string.sub(dig_T_data,3,4)..string.sub(dig_T_data,1,2)
    local dig_T2=string.sub(dig_T_data,7,8)..string.sub(dig_T_data,5,6)
    local dig_T3=string.sub(dig_T_data,11,12)..string.sub(dig_T_data,9,10)
  i2c.close(i2cid)
  i2copen_flag=false
  --结束数据获取开始运算实际温度数据
  if data=="80000" then log.debug("BME280 err:","initial data")
  else
    data=tonumber(data,16)
    dig_T1=tonumber(dig_T1,16)
    dig_T2=tonumber(dig_T2,16)
    dig_T3=tonumber(dig_T3,16)
    if dig_T1 and dig_T2 and dig_T3 then
    local var1 = ((data) / 16384.0 - (dig_T1) / 1024.0) * (dig_T2)
    local var2 = (((data) / 131072.0 - (dig_T1) / 8192.0) * ((data) / 131072.0 - (dig_T1) / 8192.0)) * (dig_T3)
    local temprature=(var1+var2)/5120
    temperature__correction=var1+var2
    log.info("BME280 ",(string.format("实际温度%.2f℃\n",temprature)))
    else
      log.debug("BME280 err ",":recv data nil ")
    end
    return temprature
  end
end


read_P=function ()
  pressure=nil
  if i2copen_flag then                                   --判断当前i2c是否打开
    log.info("BME280","i2c opening")
  else
    if i2c.setup(i2cid,100000) ~= 100000 then            
      print("BME280 init fail")
      i2copen_flag=false
      return false
    else i2copen_flag=true
    end
  end
  i2c.send(i2cid,i2cslaveaddr, {0xF4, ctrl_meas})       --写入默认配置，如需修改请参考手册中0xF4
  sys.wait(1000)
  i2c.send(i2cid,i2cslaveaddr,0xF7)                     --读取adc采集压力数据
   local zwdata=i2c.recv(i2cid,i2cslaveaddr,6)
   local data=string.sub(string.toHex(zwdata),1,5)
  i2c.send(i2cid,i2cslaveaddr,0x8E)                     --读取压力校准数据
    local dig_P_data=string.toHex(i2c.recv(i2cid,i2cslaveaddr,18))
    local dig_P1=string.sub(dig_P_data,3,4)..string.sub(dig_P_data,1,2)
    local dig_P2=string.sub(dig_P_data,7,8)..string.sub(dig_P_data,5,6)
    local dig_P3=string.sub(dig_P_data,11,12)..string.sub(dig_P_data,9,10)
    local dig_P4=string.sub(dig_P_data,15,16)..string.sub(dig_P_data,13,14)
    local dig_P5=string.sub(dig_P_data,19,20)..string.sub(dig_P_data,17,18)
    local dig_P6=string.sub(dig_P_data,23,24)..string.sub(dig_P_data,21,22)
    local dig_P7=string.sub(dig_P_data,27,28)..string.sub(dig_P_data,25,26)
    local dig_P8=string.sub(dig_P_data,31,32)..string.sub(dig_P_data,29,30)
    local dig_P9=string.sub(dig_P_data,35,36)..string.sub(dig_P_data,33,34)
  i2c.close(i2cid)
  if data=="80000" then log.debug("BME280 err:","initial data")
    else
  data=tonumber(data,16)
  dig_P1=tonumber(dig_P1,16)
  dig_P2=tonumber(dig_P2,16)
  dig_P3=tonumber(dig_P3,16)
  dig_P4=tonumber(dig_P4,16)
  dig_P5=tonumber(dig_P5,16)
  dig_P6=tonumber(dig_P6,16)
  dig_P7=tonumber(dig_P7,16)
  dig_P8=tonumber(dig_P8,16)
  dig_P9=tonumber(dig_P9,16)
  i2copen_flag=false
  --结束数据获取开始运算实际压力数据

  local  var1, var2, p
  var1 = (temperature__correction/ 2.0) - 64000.0
  var2 = var1 * var1 * (dig_P6) / 32768.0
  var2 = var2 + var1 * (dig_P5) * 2.0
  var2 = (var2 / 4.0) + ((dig_P4) * 65536.0)
  var1 = ((dig_P3) * var1 * var1 / 524288.0 + (dig_P2) * var1) / 524288.0
  var1 = (1.0 + var1 / 32768.0) * (dig_P1)
  if(0.0 == var1) then
    return 0                                                  -- avoid exception caused by division by zero
  end
  p = 1048576.0 -data
  p = (p - (var2 / 4096.0)) * 6250.0 / var1
  var1 = (dig_P9) * p * p / 2147483648.0
  var2 = p * (dig_P8) / 32768.0
  p = p + (var1 + var2 + (dig_P7)) / 16.0
  pressure =p
  log.info("BME280 ",(string.format("实际压力%.2f Pa\n",pressure)))
  return pressure 
  end
end

sys.taskInit(function()
  sys.wait(5000)
  setup()
  read_T()
  read_P()
end)
