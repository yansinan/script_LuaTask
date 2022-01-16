--[[
Author: 稀饭放姜
Date: 2020-12-18 15:50:05
LastEditors: 稀饭放姜
LastEditTime: 2020-12-25 12:24:25
FilePath: \HeFeiYunShi-Air724\user\sensor.lua
--]]
require "utils"
module(..., package.seeall)

-- id = 2
-- 初始化并打开I2C操作
-- @param I2C 内部ID
-- @return number ,I2C的速率
local function i2c_open(id, speed)
    if i2c.setup(id, speed or i2c.SLOW) ~= i2c.SLOW then
        i2c.close(id)
        return i2c.setup(id, speed or i2c.SLOW)
    end
    return i2c.SLOW
end

--- 读取寄存器值
-- @number id： I2C端口号
-- @number addr:从机地址
-- @number reg: 寄存器地址
-- @return number: 寄存器当前值
function readRegister(id, addr, reg)
    log.info("-------->I2C OPEN Result:", i2c_open(id))
    i2c.send(id, addr, reg)
    local _, val = pack.unpack(i2c.recv(id, addr, 1), 'b')
    i2c.close(id)
    log.info("读取", string.format("寄存器:0x%02x 当前值:0x%02x", reg, val or 0))
    return val;
end

--- 写寄存器方法
-- @number  id: I2C端口号
-- @number addr:从机地址
-- @number reg: 寄存器地址
-- @number ...: 要写入寄存器其他值
-- @return number:  寄存当前值
function writeRegister(id, addr, reg, ...)
    log.info("-------->I2C OPEN Result:", i2c_open(id))
    i2c.send(id, addr, {reg, ...})
    local _, val = pack.unpack(i2c.recv(id, addr, 1), 'b')
    log.info("重读", string.format("寄存器:0x%02x 当前值:0x%02x", reg, val or 0))
    i2c.close(id)
    return val
end

-------------------------------------- KXTJ3-1057 驱动代码开始 --------------------------------------
local KXTJ3_ADDR = 0x0E --KXTJ3 的地址
local KXTJ3_DCST_RESP = 0x0C -- KXTJ3 的数字通自检寄存器
local KXTJ3_SELF_TEST = 0x3A -- KXTJ3 的功自检寄存器
-- 加速度输出寄存器
local KXTJ3_XOUT_L = 0x06
local KXTJ3_XOUT_H = 0x07
local KXTJ3_YOUT_L = 0x08
local KXTJ3_YOUT_H = 0x09
local KXTJ3_ZOUT_L = 0x0A
local KXTJ3_ZOUT_H = 0x0B
-- 中断寄存器
local KXTJ3_INT_SOURCE1 = 0x16
local KXTJ3_INT_SOURCE2 = 0x17
local KXTJ3_STATUS_REG = 0x18
local KXTJ3_INT_REL = 0x1A
-- 控制寄存器
local KXTJ3_CTRL_REG1 = 0x1B -- KXTJ3的CTRL_REG1地址
local KXTJ3_CTRL_REG2 = 0x1D
local KXTJ3_INT_CTRL_REG1 = 0x1E
local KXTJ3_INT_CTRL_REG2 = 0x1F
local KXTJ3_DATA_CTRL_REG = 0x21
local KXTJ3_WAKEUP_COUNTER = 0x29
local KXTJ3_WAKEUP_THRESHOLD_H = 0x6A
local KXTJ3_WAKEUP_THRESHOLD_L = 0x6B

--- 数字通信自检验证
-- number id: I2C端口号
-- return number 正常返回0x55,其他值为异常
function dcst(id)
    local val = readRegister(id, KXTJ3_ADDR, KXTJ3_DCST_RESP)
    log.info("KXTJ3C DCST Result:", string.format("0x%02x", val or 0))
    return val;
end

--- 读中断状态
-- number id: I2C端口号
-- return number 返回状态寄存器当前值
function readStatus(id)
    local val = readRegister(id, KXTJ3_ADDR, KXTJ3_STATUS_REG)
    log.info("KXTJ3C read interrupt status:", string.format("0x%02x", val or 0))
    return val;
end

--- 清中断状态
-- number id: I2C端口号
-- return nil
function clearStatus(id)
    readRegister(id, KXTJ3_ADDR, KXTJ3_INT_REL)
    log.info("Clear Interrupt status register：", "OK")
end

--- 读取中断源寄存器
-- number id: I2C端口号
-- @number src: 1 读中断源1寄存器, 2读中断源2寄存器
-- @return number: 返中断源寄存器的值
function readInterrupt(id, src)
    local val = 0
    if src == 2 then
        val = readRegister(id, KXTJ3_ADDR, KXTJ3_INT_SOURCE2)
    else
        val = readRegister(id, KXTJ3_ADDR, KXTJ3_INT_SOURCE1)
    end
    log.info("readInterrupt register：", string.format("%02x", val or 0))
    return val
end

--- 配置 KXTJ3工作模式
-- number id: I2C端口号
-- @number mode: 0 准备模式, 1工作模式
-- @return number: 返中断源寄存器的值
function setMode(id, mode)
    log.info("-------->I2C OPEN Result:", i2c_open(id))
    i2c.send(id, KXTJ3_ADDR, KXTJ3_CTRL_REG1)
    local _, val = pack.unpack(i2c.recv(id, KXTJ3_ADDR, 1), 'b')
    i2c.send(id, KXTJ3_ADDR, {KXTJ3_CTRL_REG1, mode == 0 and bit.clear(val, 7) or bit.set(val, 7)})
    val = readRegister(id, KXTJ3_ADDR, KXTJ3_CTRL_REG1)
    i2c.close(id)
    log.info("读取CTRL_REG1寄存器:", string.format("当前值:0x%02x", val or 0))
end

--- 读取三轴输出值,注意结果是 Tri-axis 数字量
-- @param  axis: 'x','y','z' 分别表示x,y,z轴
-- @number n: 分辨率,可选值8,12,14(CTRL_REG1配置)
-- @return number: Tri-axis Digital
function readAxis(id, axis, n)
    local val, recv, reg = 0, {}, {}
    if axis == 'x' then
        reg[1] = KXTJ3_XOUT_L
        reg[2] = KXTJ3_XOUT_H
    elseif axis == 'y' then
        reg[1] = KXTJ3_YOUT_L
        reg[2] = KXTJ3_YOUT_H
    elseif axis == 'z' then
        reg[1] = KXTJ3_ZOUT_L
        reg[2] = KXTJ3_ZOUT_H
    else
        return 0
    end
    recv[1] = readRegister(id, KXTJ3_ADDR, reg[1])
    recv[2] = readRegister(id, KXTJ3_ADDR, reg[2])
    val = recv[2] * 256 + recv[1]
    if n == 8 then
        return recv[2]
    elseif n == 12 then
        return (recv[2] > 0x7F) and bit.bor(bit.rshift(val, 4), 0xF000) or bit.band(bit.rshift(val, 4), 0x0FFF)
    elseif n == 14 then
        return (recv[2] > 0x7F) and bit.bor(bit.rshift(val, 4), 0xC000) or bit.band(bit.rshift(val, 4), 0x3FFF)
    end
    return 0;
end

-- KXTJ3-1057 功自检
-- number id: I2C端口号
-- @return nil
function selfTest(id)
    setMode(id, 0)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_SELF_TEST, 0xCA)
    setMode(id, 1)
    log.info("on self test axis-x: ", readAxis(id, 'x', 8))
    log.info("on self test axis-y: ", readAxis(id, 'y', 8))
    log.info("on self test axis-z: ", readAxis(id, 'z', 8))
    setMode(id, 0)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_SELF_TEST, 0x00)
    setMode(id, 1)
    log.info("out self test axis-x: ", readAxis(id, 'x', 8))
    log.info("out self test axis-y: ", readAxis(id, 'y', 8))
    log.info("out self test axis-z: ", readAxis(id, 'z', 8))
end
-------------------------------------- KXTJ3-1057 驱动代码结束 --------------------------------------
--- 初始化配置
-- number id: I2C端口号
-- @return nil
function init(id)
    -- 进入配置模式
    setMode(id, 0)
    -- 复位控制寄存器2
    writeRegister(id, KXTJ3_ADDR, KXTJ3_CTRL_REG2, 0x86)
    -- 配置控制寄存器2 为50HZ
    writeRegister(id, KXTJ3_ADDR, KXTJ3_CTRL_REG2, 0x06)
    -- 配置唤醒延时和唤阈值
    writeRegister(id, KXTJ3_ADDR, KXTJ3_WAKEUP_COUNTER, 50)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_WAKEUP_THRESHOLD_H, (1500 - (1500 % 256)) / 256)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_WAKEUP_THRESHOLD_L, 1500 % 256)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_DATA_CTRL_REG, 0x02)
    -- 配置控制寄存器1 配置唤中断,(B0010 0010)
    writeRegister(id, KXTJ3_ADDR, KXTJ3_CTRL_REG1, 0x82)
    -- 清中断
    clearStatus(id)
    log.info("KXTJ3C init done: ", "ok!")
end

init(2)
