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

-- 光照传感器
function TSL2561()
    init(0x39)       -- 初始化
    send(0x80, 0x03) -- 启动
    send(0x81, 0x02) -- 积分时间
    sys.wait(300)
    while true do
        local s = ""
        for i=0, 3 do
            send(140+i)
            s = s..read(1)
            sys.wait(200)
        end
        _, ch0, ch1 = pack.unpack(s, "<HH")
        log.info("Full Spectrum(IR + Visible)", ch0)
        log.info("Infrared Value", ch1)
        log.info("Visible Value", ch0-ch1)
    end
end

sys.taskInit(function()
	sys.wait(3000)
	TSL2561()
end)

sys.init(0, 0)
sys.run()
