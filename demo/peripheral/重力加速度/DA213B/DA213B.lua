module(..., package.seeall)
require "utils"

local i2cId = 2

function ind(data)
    --print("shk.ind", data, cpu.INT_GPIO_POSEDGE)
    -- log.info("标志")
    if data == cpu.INT_GPIO_POSEDGE then
    --print("shk.ind DEV_SHK_IND")
        sys.publish("DEV_SHK_IND")
    end
end

pins.setup(pio.P0_10, ind) -- 高电平有效，来自机械振动传感器的中断


function init()
    local i2cSlaveAddr = 0x27
    -- 中断设置地址
    local INTset1addr = 0x16
    -- 活动持续时间地址
    local activeDURaddr = 0x27
    -- 有效中断阈值地址
    local activeTHSaddr = 0x28
    -- 中断映射地址
    local INTmapaddr = 0x19

    -- 配置地址
    local configaddr = 0x00
    -- 范围地址
    local rangeaddr = 0x0f
    -- 工作模式地址
    local modedddr = 0x11
    -- 频率地址
    local ODRaddr = 0x10
    -- 中断锁地址
    local INTlatchaddr = 0x21
    -- 工程模式地址
    local enginaddr = 0x7f

    local speed = i2c.setup(i2cId, 100000)
    if speed ~= 100000 then
        log.warn("通道开启失败")
        return
    end

    --log.info("数据类型", type(i2cSlaveAddr))
    --log.info("设置地址", i2cSlaveAddr)
    local _ = i2c.send(i2cId, i2cSlaveAddr, 0x01)
    --log.warn("发送地址", _)

    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)

    --log.warn("asldkfnalksdf", string.toHex(r))

    local _ = i2c.send(i2cId, i2cSlaveAddr, 0x09)
    --log.info("发送地址", _)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)
    --log.warn("asldkfnalksdf", string.toHex(r))

    local _ = i2c.send(i2cId, i2cSlaveAddr, {configaddr, 0x24})
    --log.info("设置配置传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {INTset1addr, 0x87})
    --log.info("设置中断字节传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {activeDURaddr, 0x00})
    --log.info("设置活动持续时间传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {activeTHSaddr, 0x05})
    --log.info("设置中断搁置传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {INTmapaddr, 0x04})
    --log.info("设置中断映射传输字节", _)

    local _ = i2c.send(i2cId, i2cSlaveAddr, {rangeaddr, 0x00})
    --log.info("设置范围传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {modedddr, 0x34})
    --log.info("设置工作模式传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {ODRaddr, 0x08})
    --log.info("设置频率传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {INTlatchaddr, 0x00})
    --log.info("设置中断锁传输字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {enginaddr, 0x83, enginaddr, 0x69, enginaddr, 0xBD})
    --log.info("设置工程模式传输字节", _)

    -- while true do
    local _ = i2c.send(i2cId, i2cSlaveAddr, 0x09)
    --log.info("发送地址", _)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)
    --log.warn("asldkfnalksdf", string.toHex(r))
    -- end

end

init()

