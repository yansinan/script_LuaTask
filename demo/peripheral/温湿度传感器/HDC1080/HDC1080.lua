--- 模块功能：HDC1080温湿度传感器
-- @author FeoniL
-- @module HDC1080
-- @license MIT
-- @copyright openLuat
-- @release 2021.8.4
module(..., package.seeall)
require "utils"
require "pm"
require "powerKey"
pm.wake("WORK") -- 模块保持唤醒
local rbuf=""
local i2cid = 2 -- core 0025版本之前，0、1、2都表示i2c 2
local i2cslaveaddr=0x40
local cmd,i = {0x00,0x01,0x02,0xFB,0xFC,0xfd,0xfe,0xff}
local Serialid,i={0xFB,0xFC,0xFD}
local Configuration=0x10

--读取温度
local function readTemperature()
    sys.taskInit(function ()
            if i2c.setup(i2cid,100000) ~= 100000 then
                print("init fail")
                return
            end
            i2c.send(i2cid,i2cslaveaddr,0x02)
            i2c.send(i2cid,i2cslaveaddr,Configuration)
            i2c.send(i2cid,i2cslaveaddr,0x00)
            sys.wait(50)
            local tm=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
            if tm=="" then print("i2c recv error")  i2c.close(i2cid) return 0 end
            log.info("i2c.recv",tm)
            tm=tonumber(tm, 16)
            local over_tm=tm/65535*165-40
            log.info("HDC1080",(string.format("实际温度%.2f℃\n",over_tm)))
            i2c.close(i2cid)
        end)
end
--读取湿度
local function readHumidity()
    sys.taskInit(function ()
        if i2c.setup(i2cid,100000) ~= 100000 then
            print("init fail")
            return
        end
        i2c.send(i2cid,i2cslaveaddr,0x02)
        i2c.send(i2cid,i2cslaveaddr,Configuration)
        i2c.send(i2cid,i2cslaveaddr,0x01)
        sys.wait(50)
        local wd=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
        if wd=="" then print("i2c recv error")  i2c.close(i2cid) return 0 end
        log.info("i2c.recv",wd)
        wd=tonumber(wd, 16)
        local over_wd=wd/65535*100
        log.info("HDC1080",(string.format("实际湿度%.2f\n",over_wd)))
        i2c.close(i2cid)
    end)
end
--读取制造商ID Manufacturer
local function Manufacturer()
    if i2c.setup(i2cid,100000) ~= 100000 then
        print("init fail")
        return
    end
    i2c.send(i2cid,i2cslaveaddr,0xfe)
    print("制造商ID：",string.toHex(i2c.recv(i2cid,i2cslaveaddr,2)))
    i2c.close(i2cid)
end
--复位
local function RESET()
    if i2c.setup(i2cid,100000) ~= 100000 then
        print("init fail")
        return
    end
    i2c.send(i2cid,i2cslaveaddr,0x02)
    i2c.send(i2cid,i2cslaveaddr,0x80)
    i2c.close(i2cid)
end
--读取序列号
local function Serial_ID()
    if i2c.setup(i2cid,100000) ~= 100000 then
        print("init fail")
        return
    end
        for i=1,#Serialid,1 do
            i2c.send(i2cid,i2cslaveaddr,Serialid[i])
            local wl=string.toHex(i2c.recv(i2cid,i2cslaveaddr,2))
            rbuf=rbuf..wl
            print(type(rbuf),rbuf)
        end
       print("序列号",rbuf,tonumber(rbuf,16))
    i2c.close(i2cid)
end
local function longCb()
    readTemperature()
end
local function shortCb()
    readHumidity()
end
sys.taskInit(function ()
    sys.wait(7000)
    while true do
        readHumidity()
        sys.wait(1000)
        readTemperature()
    sys.wait(5000)
    end
end)
powerKey.setup(1000, longCb, shortCb)
