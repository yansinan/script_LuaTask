--- 模块功能：HDC1000功能测试.
-- @module i2c
-- @author openLuat
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.9.9

require "sys"

-- 打开 I2C 地址为7位地址 0x40
local function OPEN(id)
    if i2c.setup(id, i2c.SLOW, 0x40) ~= i2c.SLOW then
        log.error("i2c.init is: ", "fail")
    end
end

-- 发送指令
function SEND(id, addr, data)
    i2c.send(id, addr, data)
    sys.wait(80)
end

sys.taskInit(function ()
    sys.wait(5000)
    -- I2C 通道为 2
    local id = 2
    OPEN(id)
    SEND(id, 0x40, {0x02, 0x1000})
    while true do
        -- 读取温度
        SEND(2, 0x40, 0x01)
        SEND(2, 0x40, 0x00)
        local temp = tonumber(i2c.recv(id, 0x40, 2):toHex(), 16)
        log.info("温度", temp / 65536 * 165 - 40)
        -- 读取湿度
        SEND(2, 0x40, 0x00)
        SEND(2, 0x40, 0x00)
        local humi = tonumber(i2c.recv(id, 0x40, 2):toHex(), 16)
        log.info("湿度", humi / 65536 * 100)
        sys.wait(1000)
    end
end)
