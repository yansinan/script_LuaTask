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
    log.info("返回字节数",i2c.send(i2cid, addr, t))
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

-- 陀螺仪
function L3G4200D()
    init(0x69)
    send(0x20, 0x0f)
    while true do
        sys.wait(1000)
        send(0xA8)
        _, x, y, z = pack.unpack(read(6), "<HHH")
        log.info("x, y, z", x, y, z)
    end
end

sys.taskInit(function()
	sys.wait(3000)
    pm.sleep("WAKE")
    log.info("休眠状态",pm.isSleep("WAKE"))
	L3G4200D()
end)

sys.init(0, 0)
sys.run()
