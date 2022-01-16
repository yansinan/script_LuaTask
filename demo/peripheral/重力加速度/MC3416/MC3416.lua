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

function init() -- 3416

    local i2cSlaveAddr = 0x4c
    -- 配置模式地址
    local modeAddr = 0x07

    -- 插入中断控制地址
    local intrCtrlAddr = 0x06
    -- 运动控制地址
    local motionCtrlAddr = 0x09
    -- 输出速率配置地址
    local sampleAAddr = 0x08
    -- 运动阈值设置地址
    -- LSB
    local threshLSBAddr = 0x43
    -- MSB
    local thershMSBAddr = 0x44
    -- 取消反跳地址
    local debounceAddr = 0x45
    -- 读设备电路状态地址
    local devicestatusAddr = 0x05
    -- 读运动状态地址
    local devicemotionAddr = 0x13

    local speed = i2c.setup(i2cId, 100000, i2cSlaveAddr)
    if speed ~= 100000 then
        log.warn("通道开启失败")
        return
    end


    local _ = i2c.send(i2cId, i2cSlaveAddr, 0x05)
    --log.warn("发送地址", _)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)

    --log.warn("asldkfnalksdf", string.toHex(r))

    -- enter standy mode, cann't write register in wakeup mode
    local _ = i2c.send(i2cId, i2cSlaveAddr, {modeAddr, 0xC3})
    --log.warn("配置待机模式传输成功字节", _)

    local _ = i2c.send(i2cId, i2cSlaveAddr, 0x05)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)
    --log.warn("asldkfnalksdf", string.toHex(r))

    local _ = i2c.send(i2cId, i2cSlaveAddr, {intrCtrlAddr, 0x44})
    --log.warn("配置插入传输成功字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {motionCtrlAddr, 0x04})
    --log.warn("配置运动传输成功字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {sampleAAddr, 0x02})
    --log.warn("配置速率传输成功字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {threshLSBAddr, 0x50})
    --log.warn("配置运动阈值高传输成功字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {thershMSBAddr, 0x00})
    --log.warn("配置运动阈值低传输成功字节", _)
    local _ = i2c.send(i2cId, i2cSlaveAddr, {debounceAddr, 0x00})
    --log.warn("配置取消反跳传输成功字节", _)

    local _ = i2c.send(i2cId, i2cSlaveAddr, {modeAddr, 0xC1})
    --log.warn("配置唤醒模式传输成功字节", _)

    local _ = i2c.send(i2cId, i2cSlaveAddr, devicestatusAddr)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)
    --log.warn("asldkfnalksdf", string.toHex(r))

    -- while true do

    local _ = i2c.send(i2cId, i2cSlaveAddr, devicestatusAddr)
    --log.warn("发送地址", _)
    local r = i2c.recv(i2cId, i2cSlaveAddr, 1)
    --log.warn("asldkfnalksdf", string.toHex(r))

    -- end
end

init()
