--- 模块功能：SHT20
-- @module SHT20
-- @author Fantasy

require"utils"
require"bit"

local i2cid = 2 --i2cid
local SHT20_ADDRESS = 0x40
---SHT20所用地址
local POLYNOMIAL = 0x131
CMD_READ_TEMPERATURE_hold = 0xE3
CMD_READ_HUMIDITY_hold    = 0xE5
CMD_READ_TEMPERATURE = 0xF3
CMD_READ_HUMIDITY    = 0xF5
CMD_READ_REGISTER    = 0xE7
CMD_WRITE_REGISTER   = 0xE6
CMD_RESET 			 = 0xFE

local function i2c_send(data)
    return i2c.send(i2cid, SHT20_ADDRESS, data)
end
local function i2c_recv(num)
    return i2c.recv(i2cid, SHT20_ADDRESS, num)
end

--器件初始化
local function SHT20_init()
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("SHT20","i2c.setup fail")
        return false
    end
    log.info("SHT20","i2c init_ok")
end

local function CheckCRC(buf)
    crc = 0
    for i=0,1 do
        crc = bit.bxor(crc,buf:byte(1))
        for j=0, 7 do
            if bit.band(crc,0x80) then
                crc = bit.bxor(bit.lshift(crc,1),POLYNOMIAL)
            else
                crc = bit.lshift(crc,1)
            end
        end
    end
    a,b = string.toHex(pack.pack('b',crc))
    return  a
end
--发送命令
local function SHT20_run_command(command,bytesToRead)
    retryCounter = 0
    if bytesToRead > 0 then
        i2c_send(command)
        while retryCounter < 10 do
            recv = i2c_recv(bytesToRead)
            if recv and #recv >= 3 then
                break
            end
            retryCounter = retryCounter + 1
            sys.wait(10)
        end
        a,b = string.toHex(pack.pack('b',recv:byte(3)))
        if CheckCRC(recv) ~= a then
            return false
        end
        return recv
    end
    return false
end
-- 将原始数据转换成温度
local function SHT20_to_temperature(buf)
    if buf == false then
        log.error("SHT20","CRC Error...\r\n")
        return false
    end
    return -46.85 + 175.72 * (bit.lshift(recv:byte(1),8) + buf:byte(2)) / 2^16
end
-- 将原始数据转换成湿度
local function SHT20_to_humidity(buf)
    if buf == false then
        log.error("SHT20","CRC Error...\r\n")
        return false
    end
    return -6 + 125.0 * (bit.lshift(recv:byte(1),8) + buf:byte(2)) / 2^16
end

local function SHT20_get_temperature()
    return SHT20_to_temperature(SHT20_run_command(CMD_READ_TEMPERATURE, 3))
end

local function SHT20_get_humidity()
    return SHT20_to_humidity(SHT20_run_command(CMD_READ_HUMIDITY, 3))
end
-- 测试代码
local function SHT20()
    sys.wait(1000)
    if SHT20_init() ~= false then
        sys.wait(500)
        while true do
            log.info("SHT20_get_temperature", SHT20_get_temperature(),"C")
            log.info("SHT20_get_humidity", SHT20_get_humidity(),"%")
            sys.wait(1000)
        end
    end
end
sys.taskInit(SHT20)
