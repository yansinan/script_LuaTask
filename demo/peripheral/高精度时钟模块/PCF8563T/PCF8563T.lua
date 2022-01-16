--- 模块功能：PCF8563T
-- @module PCF8563T
-- @author JWL
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.10.16

module(...,package.seeall)
require"utils"
require"bit"

pm.wake("PCF8563T")

local i2cid = 2 --i2cid
local i2cslaveaddr              =   0X51 --slave address

local REG_SEC = 0X02



local function i2c_send(data)
    i2c.send(i2cid, i2cslaveaddr, data)
end
local function i2c_recv(data,num)
    i2c.send(i2cid, i2cslaveaddr, data)
    local revData = i2c.recv(i2cid, i2cslaveaddr, num)
    return revData
end
 
 

local function bcd_to_hex(data)
    local hex = bit.rshift(data,4)*10+bit.band(data,0x0f)
    return hex;
 
end

local function hex_to_bcd(data)
      local hex = bit.lshift(data/10,4)+data%10
      return hex;
 
end

local function PCF8563T_read_time()
    -- read time
    local time_data = {}
    local data = i2c_recv(REG_SEC,7)
    time_data.tm_year  = bcd_to_hex(data:byte(7)) + 2000
    time_data.tm_mon   = bcd_to_hex(bit.band(data:byte(6),0x7f))
    time_data.tm_wday  = bcd_to_hex(data:byte(5))
    time_data.tm_mday  = bcd_to_hex(data:byte(4))
    time_data.tm_hour  = bcd_to_hex(data:byte(3))
    time_data.tm_min   = bcd_to_hex(data:byte(2))
    time_data.tm_sec   = bcd_to_hex(data:byte(1))

    log.info("data:toHex()", data:toHex())
	return time_data
end

local function PCF8563T_set_time(time)
    -- set time
    local data7 = hex_to_bcd(time.tm_year - 2000)
    local data6 = hex_to_bcd(time.tm_mon)
    local data5 = hex_to_bcd(time.tm_wday)
    local data4 = hex_to_bcd(time.tm_mday)
    local data3 = hex_to_bcd(time.tm_hour)
    local data2 = hex_to_bcd(time.tm_min)
    local data1 = hex_to_bcd(time.tm_sec)

    log.info("set time:",data7,data6,data5,data4,data3,data2,data1)


    i2c_send({REG_SEC, data1,data2,data3,data4,data5,data6,data7})

 
end

local function PCF8563T()
    sys.wait(4000)
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("I2c.init","fail")
        return
    end

    local set_time = {tm_year=2021,tm_mon=10,tm_mday=16,tm_wday=6,tm_hour=11,tm_min=19,tm_sec=9}
    PCF8563T_set_time(set_time)
 
    while true do
 
        local time = PCF8563T_read_time()
        log.info("PCF8563T_read_time",time.tm_year,time.tm_mon,time.tm_mday, time.tm_hour,time.tm_min,time.tm_sec, "week=".. time.tm_wday)

       -- log.info("PCF8563T_read_time",time.tm_year,time.tm_mon,time.tm_mday,time.tm_hour,time.tm_min,time.tm_sec)
        sys.wait(1000)
    end
end
sys.taskInit(PCF8563T)




