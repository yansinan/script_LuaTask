--- 模块功能：I2C功能测试.
-- @author openLuat
-- @module i2c.testI2c
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)

require"utils"
require "powerKey"
--pmd.ldoset(5,pmd.LDO_VMMC)
--i2c.set_id_dup(0)
local i2cid = 2
local i2cslaveaddr = 0x40
local cmd,i ={0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0xC,0x0D,0x0E,0X0F,0xFC,0xFD,0xFE,0xFF}
-- sys.taskInit(function()
    
--     if i2c.setup(i2cid,100000) ~= 100000 then
--         print("init fail")
--         return
--       end
-- for i=1,#cmd,1 do
--   --向从设备i2cslaveaddr发送寄存器地址cmd[i]
--   i2c.send(i2cid,i2cslaveaddr,cmd[i])
--   --向从设备i2cslaveaddr发送要写入从设备寄存器内的数据cmd[i+1]
--   print("testI2c.init",string.format("%02X",cmd[i]),string.toHex(i2c.recv(i2cid,i2cslaveaddr,2)))
--   i2c.close(i2cid)
-- end
-- end)
local function longCb()
    sys.taskInit(function()
    
        if i2c.setup(i2cid,100000) ~= 100000 then
            print("init fail")
            return
          end
    for i=1,#cmd,1 do
      --向从设备i2cslaveaddr发送寄存器地址cmd[i]
      i2c.send(i2cid,i2cslaveaddr,cmd[i])
      --向从设备i2cslaveaddr发送要写入从设备寄存器内的数据cmd[i+1]
      print("testI2c.init",string.format("%02X",cmd[i]),string.toHex(i2c.recv(i2cid,i2cslaveaddr,6)))
    end
    i2c.close(i2cid)
    end)
end
local function shortCb()
      i2c.close(i2cid)
end

sys.taskInit(function()
  if i2c.setup(i2cid,100000) ~= 100000 then
      print("HDC2080 init fail")
      return
  end
  while true do
    sys.wait(3000)
    i2c.send(2, 0x40, {0x0F, 0xF9})
    sys.wait(10)
    i2c.send(i2cid,i2cslaveaddr,0x00)
   local zwdata=i2c.recv(i2cid,i2cslaveaddr,4) --读取温湿度数据
   local data=string.toHex(zwdata)
   --温度数据
   TEMP_LOW=string.sub(data,1,2)
   TEMP_HIGH=string.sub(data,3,4)
   --湿度数据
   HUMID_LOW=string.sub(data,5,6)
   HUMID_HIGH=string.sub(data,7,8)
   --log.debug("i2c",data,TEMP_LOW,TEMP_HIGH,HUMID_LOW,HUMID_HIGH)
  local tm=tonumber(TEMP_HIGH..TEMP_LOW,16)
  local over_tm=tm/65535*165-40
  log.info("HDC2080",(string.format("实际温度%.2f℃\n",over_tm)))
  local wd=tonumber(HUMID_HIGH..HUMID_LOW, 16)
  local over_wd=wd/65535*100
    log.info("HDC1080",string.format("实际湿度%.2f",over_wd).."%")
  end
end)
powerKey.setup(3000, longCb, shortCb)