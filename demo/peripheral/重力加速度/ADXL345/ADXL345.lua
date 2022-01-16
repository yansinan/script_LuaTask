PROJECT = "sensor"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
i2cid = 2

-- i2c 速率
speed = 100000


---ADXL345所用寄存器地址

local ADXL345_DATA_FORMAT         =   0x31 --测量范围,正负16g，13位模式
local ADXL345_BW_RATE             =   0x2C --速率设定为12.5
local ADXL345_POWER_CTL           =   0x2D --选择电源模式
local ADXL345_INT_ENABLE          =   0x2E --使能 DATA_READY 中断
local ADXL345_OFSX                =   0x1E --X 偏移量
local ADXL345_OFSY                =   0x1F --Y 偏移量
local ADXL345_OFSZ                =   0x20 --Z 偏移量

local ADXL345_RA_ACCEL_XOUT_H     =   0x32
local ADXL345_RA_ACCEL_XOUT_L     =   0x33
local ADXL345_RA_ACCEL_YOUT_H     =   0x34
local ADXL345_RA_ACCEL_YOUT_L     =   0x35
local ADXL345_RA_ACCEL_ZOUT_H     =   0x36
local ADXL345_RA_ACCEL_ZOUT_L     =   0x37

-- 初始化
function init(address)
if i2c.setup(i2cid, speed, address) ~= speed then
        log.error("i2c", "setup fail", addr)
return
end
    addr = address


    i2c.send(i2cid, addr, {ADXL345_DATA_FORMAT, 0x0B})
    i2c.send(i2cid, addr, {ADXL345_BW_RATE, 0x08})
    i2c.send(i2cid, addr, {ADXL345_POWER_CTL, 0x08})
    i2c.send(i2cid, addr, {ADXL345_INT_ENABLE, 0x80})
    i2c.send(i2cid, addr, {ADXL345_OFSX, 0x00})
    i2c.send(i2cid, addr, {ADXL345_OFSY, 0x00})
    i2c.send(i2cid, addr, {ADXL345_OFSZ, 0x05})

    log.info("i2c init_ok")
end



--获取加速度计的原始数据
local function ADXL345_get_accel_raw()
local accel={x=nil,y=nil,z=nil}
    i2c.send(i2cid, addr,ADXL345_RA_ACCEL_XOUT_H)--获取的地址
local x = i2c.recv(i2cid, addr, 2)--获取2字节
    _,accel.x = pack.unpack(x,">h")
    i2c.send(i2cid, addr,ADXL345_RA_ACCEL_YOUT_H)--获取的地址
local y = i2c.recv(i2cid, addr, 2)--获取2字节
    _,accel.y = pack.unpack(y,">h")
    i2c.send(i2cid, addr,ADXL345_RA_ACCEL_ZOUT_H)--获取的地址
local z = i2c.recv(i2cid, addr, 2)--获取2字节
    _,accel.z = pack.unpack(z,">h")
return accel or 0
end



-- adxl345
sys.taskInit(function()
    sys.wait(8000)
init(0x53)

while true do

local test1 = ADXL345_get_accel_raw()
        log.info("ADXL345acceltest", "accel.x",test1.x,"accel.y",test1.y,"accel.z",test1.z)

        sys.wait(1000)
end
end)

sys.init(0, 0)
sys.run()
