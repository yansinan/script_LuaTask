PROJECT = "sensor"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
i2cid = 2

-- i2c 速率
speed = 100000

-- 初始化
function init(address)
    if i2c.setup(i2cid, speed, -1, 1) ~= speed then
        log.error("i2c", "setup fail", addr)
        return
    end
    addr = address
end

-- 读取数据
function send(...)
    sys.wait(10)
    if not addr then 
        log.info("i2c", "addr err")
        return 
    end
    local t = {...}
    if i2c.send(i2cid, addr, t) ~= #t then
        log.error("i2c", "send fail", #t)
        return
    end
    return true
end

-- 发送数据
function read(n)
    sys.wait(10)
    if not addr then 
        log.info("i2c", "addr err")
        return "\x00" 
    end
    val = i2c.recv(i2cid, addr, n)
    if val and #val>0 then
        return val
    end
    return "\x00"
end

-- 颜色识别传感器
function TCS34725()
    init(0x29) 
    send(0x83, 0xff)
    send(0x81, 0x00)
    send(0x8f, 0x00)
    send(0x80, 0x03)
    sys.wait(800)
    while true do
        sys.wait(1000)
        send(0x94)
        _, c, red, green, blue = pack.unpack(read(8), "<HHHH")
        if red and green and blue then
            lux = (-0.32466 * red) + (1.57837 * green) + (-0.73191 * blue)
            log.info("red", red)
            log.info("green", green)
            log.info("blue", blue)
            log.info("c, lux", c, lux)
        else
            log.info("TCS34725", "err")
        end
    end
end

sys.taskInit(function()
	sys.wait(3000)
	TCS34725()
end)

sys.init(0, 0)
sys.run()
