PROJECT = "sensor"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
i2cid = 2

-- i2c 速率
 
--#define DEFAULT_CONFIG_800    1100 1100 0001 0000 // 800ms

local DEFAULT_CONFIG_800 =0xCC10

local  RESULT_REG = 0x00
local  CONFIG_REG = 0x01
local  LOWLIMIT_REG = 0x02
local  HIGHLIMIT_REG = 0x03
local  MANUFACTUREID_REG = 0x7E
local  DEVICEID_REG = 0x7F



local addr = 0x44
local speed = 100000





local function I2C_Write_Byte_CJMCU3001(regAddress,p1,p2)
 
    i2c.send(i2cid, addr, {regAddress,p1,p2})
end

local function I2C_Read_Byte_CJMCU3001(regAddress)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, 1)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr:byte(1)
end
local function I2C_Read_Bytes_CJMCU3001(regAddress,cnt)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, cnt)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr
end




-- 初始化
function init()
    if i2c.setup(i2cid, speed, addr) ~= speed then
        log.error("i2c", "setup fail", addr)
        return
    end

    local whoid = I2C_Read_Bytes_CJMCU3001(DEVICEID_REG,2)
    if whoid:byte(1) ==0x30 and whoid:byte(2) ==0x01  then 
        log.info("===================dev is ok========================")
    else
        log.info("i2c dev id is wrong!")
        return false
    end

    local manufid = I2C_Read_Bytes_CJMCU3001(MANUFACTUREID_REG,2)
    log.info("dev manufid",string.format("0x%02X%02X",manufid:byte(1),manufid:byte(2)))



	local devcfg = I2C_Read_Bytes_CJMCU3001(CONFIG_REG,2)
    log.info("dev config",string.format("0x%02X%02X",devcfg:byte(1),devcfg:byte(2)))



	local lowlimit = I2C_Read_Bytes_CJMCU3001(LOWLIMIT_REG,2)
    log.info("dev  lowlimit",string.format("0x%02X%02X",lowlimit:byte(1),lowlimit:byte(2)))

    local higlimit = I2C_Read_Bytes_CJMCU3001(HIGHLIMIT_REG,2)
    log.info("dev  higlimit",string.format("0x%02X%02X",higlimit:byte(1),higlimit:byte(2)))


 

    I2C_Write_Byte_CJMCU3001(CONFIG_REG,0xCC,0X10)


    log.info("dev i2c init_ok")
    return true
end



--获取加速度计的原始数据
local function TEST_CJMCU3001()
    local val = I2C_Read_Bytes_CJMCU3001(RESULT_REG,2)
    local raw = (val:byte(1)) *256  + (val:byte(2))

    local result = bit.band(raw, 0x0FFF)
    local expont = bit.band(raw, 0xF000)
    expont = bit.rshift(expont,12)
    return result * 0.01  * math.pow(2, expont)
end




sys.taskInit(function()
    sys.wait(4000)

    if init() then 
        while true do
            local val = TEST_CJMCU3001()
            log.info("lux=", val)
            sys.wait(1000)
        end
    end
end)

sys.init(0, 0)
sys.run()
