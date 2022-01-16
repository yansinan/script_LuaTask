--- 模块功能：I2C BMP180功能测试.
-- @author denghai
-- @module i2c.BMP180
-- @license MIT
-- @copyright openLuat
-- @release 2021.09.22

module(...,package.seeall)
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
    log.info("read", val:toHex())
    if val and #val > 0 then return val end
    return "\x00"
end

-- 读取short 值 
function short(addr, n)
    send(addr)
    if n then
        f, val = pack.unpack(read(2), ">H")
    else
        f, val = pack.unpack(read(2), ">h")
    end
    
    log.info("val", f, val)
    return f and val or 0
end

sys.taskInit(function()
    sys.wait(8000)
    init(0x77)
    send(0xD0)
    local id = read(1)
    if "U"~=id then 
        print("error id",id)
        sys.restart("error i2c id!")
        return
    end
    -- 复位
    send(0xE0,0xB6)

    AC1 = short(0xAA)
    AC2 = short(0xAC)
    AC3 = short(0xAE)
    AC4 = short(0xB0,true)
    AC5 = short(0xB2,true)
    AC6 = short(0xB4,true)
    B1  = short(0xB6)
    B2  = short(0xB8)
    MB  = short(0xBA)
    MC  = short(0xBC)
    MD  = short(0xBE)

    while true do
        sys.wait(2000)
        -- 温度 ℃
        send(0xF4,0x2E)
        sys.wait(1000)
        log.info("温度raw", short(0xF6))
        UT = short(0xF6)
        -- 气压 Pa
        send(0xF4,0x34) 
        sys.wait(1000)
        send(0xF6)
        _, UP = pack.unpack(read(2), "<H")
        log.info("气压raw", UP)
        BMP_UncompemstatedToTrue(UT,UP)
    end

end)

--//用获取的参数对温度和大气压进行修正，并计算海拔
function BMP_UncompemstatedToTrue(UT,UP)
    local p = 0
    local X1 = (UT - AC6) * AC5/32768
    -- log.info("X1 ",X1,"UT ",UT,"AC6 ",AC6)
    -- local X2 = bit.lshift(MC,11) / (X1 + MD)
    local X2 = MC*2048 / (X1 + MD)
    -- log.info("X2",MC,"MC",X2,"MD",MD)
    local B5 = X1 + X2
    -- log.info("B5",B5)
    -- local Temp  = bit.rshift((B5 + 8) ,4)
    local Temp  = (B5 + 8)/16
    log.info("温度修正",Temp)
    local B6 = B5 - 4000
    -- log.info("B6",B6)
    X1 = (B2 *((B6 * B6)/4096))/2048
    -- X1 = bit.rshift(B2 * bit.rshift(B6 * B6,12) ,11)
    -- log.info("X1",X1,"B2",B2,"B6",B6)
    X2 = (AC2 * B6)/2048
    -- X2 = bit.rshift(AC2 * B6,11)
    -- log.info("X2",X2,"AC2",AC2)
    local X3 = X1 + X2
    -- log.info("X3",X3)
    local B3 = ((AC1 * 4 + X3) + 2) /4
    -- log.info("B3",B3,"AC1",AC1)
    X1 = (AC3 * B6)/8192
    -- X1 = bit.rshift(AC3 * B6 ,13)
    -- log.info("X1",X1,"AC3",AC3)
    X2 = (B1 *((B6*B6)/4096)) /65536
    -- X2 = bit.rshift((B1 *bit.rshift(B6*B6 ,12)) ,16)
    -- log.info("X2",X2,"B1",B1)
    -- X3 = bit.rshift(X1 + X2 + 2, 2)
    X3 = (X1 + X2 + 2)/4
    -- log.info("X3",X3)
    local B4 = (AC4 * (X3 + 32768))/32768
    -- local B4 = bit.rshift(AC4 * (X3 + 32768) ,15)
    -- log.info("B4",B4,"AC4",AC4)
    local B7 = (UP - B3) * 50000
    -- log.info("B7",B7,"UP",UP)
    if(B7 < 0x80000000) then
        p = (B7 * 2) / B4
    else
        p = (B7 / B4) * 2
    end
    -- log.info("p",p)
    X1 = (p/256) * (p/256)
    -- X1 = bit.rshift(p ,8) * bit.rshift(p,8)
    -- log.info("X1",X1)
    X1 = (X1 * 3038)/65536
    -- X1 = bit.rshift(X1 * 3038,16)
    -- log.info("X1",X1)
    X2 = (-7357 * p)/65536
    -- X2 = bit.rshift(-7357 * p, 16)
    -- log.info("X2",X2)
    p = p + (X1 + X2 + 3791)/16
    -- p = p + bit.rshift(X1 + X2 + 3791,4)
    log.info("气压修正", p)
    local altitude = 44330 * (1-math.pow(((p) / 101325.0),(1.0/5.255)))
    log.info("海拔", altitude)
end 
