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

-- 发送数据
function send(...)
    -- sys.wait(10)
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

-- 读取数据
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

--处理接收到数据
function trans(dat)
    n = tonumber(dat:toHex(), 16)
    log.info("raw",dat:toHex())
    if not n then return end
    temp = n / 8
	if (temp >= 8192) then
        temp = temp - 8192
    end
	t = temp * 0.0625
	return t
end

function LM92()
    init(0x48)    
    send(0x01) 
    read(2)
    send(0x01, 0x10)  
    send(0x00) 
    read(2)
    sys.wait(300)
    while true do
        send(0)
        log.info("raw data", trans(read(2)))
        sys.wait(800)
    end
end

sys.taskInit(function()
	LM92()
end)

sys.init(0, 0)
sys.run()
