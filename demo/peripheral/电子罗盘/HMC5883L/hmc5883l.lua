--- 模块功能：ADC功能测试.
-- ADC测量精度(12bit)
-- 每隔1s读取一次ADC值
-- @author openLuat
-- @module adc.testAdc
-- @license MIT
-- @copyright openLuat
-- @release 2018.12.19

module(...,package.seeall)

PROJECT = "hmc5883l_demo"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
local i2cid = 2

-- i2c 速率
 
--打开vlcd电压域
pmd.ldoset(15,pmd.LDO_VLCD)-- GPIO 0、1、2、3、4


local addr = 0x1e        --addr

local speed = 100000      --iic速率


local Config_a     = 0x00    --配置寄存器a:设置的数据输出速率和测量配置  0 11 100 00  0X70
local Config_b     = 0x01    --配置寄存器b：设置装置的增益              001 00000    0Xe0
local mode         = 0x02    --模式寄存器: 默认单一测量模式01，连续00           000000 00    0X00/0x01
local Msb_x        = 0x03    --x 高位数据输出
local Lsb_x        = 0x04    --x 低位数据输出
local Msb_y        = 0x07    --x 高位数据输出
local Lsb_y        = 0x08    --x 低位数据输出
local Msb_z        = 0x05    --x 高位数据输出
local Lsb_z        = 0x06    --x 低位数据输出
local status       = 0x09    --  状态寄存器    0x00
local recogn_a     = 0x0a    --  识别寄存器a   0x48
local recogn_b     = 0x0b    --  识别寄存器b   0x34
local recogn_c     = 0x0c    --  识别寄存器c   0x33



--写数据
local function I2C_Write_Byte(regAddress,val,val2)
    i2c.send(i2cid, addr, {regAddress,val,val2})
    
end

--读取单个字节
local function I2C_Read_Byte(regAddress)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, 1)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr:byte(1)--变成10进制数据
end

--读取多个字节
local function I2C_Read_Bytes(regAddress,cnt)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, cnt)
    --log.info("rdstr:toHex()-------",rdstr:toHex())
    return rdstr
end


-- 初始化
function init()
    if  i2c.setup(i2cid, speed, addr) ~= speed  then
        log.error("i2c", "setup fail", addr)
        i2c.close(i2cid)
        return
    end

    log.info("dev i2c init_ok")
    return true
end

function hmc5883l_int()

    I2C_Write_Byte(Config_a,0x70)  --写配置a寄存器数据
    I2C_Write_Byte(Config_b,0x20)  --写配置b寄存器数据  增益660
    I2C_Write_Byte(mode,0x00)      --写模式寄存器数据
end

function hmc5883l_read()

    local hx=I2C_Read_Byte(Msb_x)
    local lx=I2C_Read_Byte(Lsb_x)
    local x_data=hx*256+lx

    local hy=I2C_Read_Byte(Msb_y)
    local ly=I2C_Read_Byte(Lsb_y)
    local y_data=hy*256+ly

    local hz=I2C_Read_Byte(Msb_z)
    local lz=I2C_Read_Byte(Lsb_z)
    local z_data=hz*256+lz

    if(x_data>32768)  then
        x_data= -(0xFFFF - x_data + 1)   
    end

    if(y_data>32768)  then
        y_data = -(0xFFFF - y_data + 1)
    end 

    if(z_data>32768)  then
        z_data = -(0xFFFF - z_data+ 1)
    end



    local Angle= math.atan2(y_data,x_data)*(180/3.14159265)+180;--单位：角度 (0~360)
    Angle= Angle 




    log.info("x,y,z-----------", x_data,y_data,z_data )

    log.info("Angle",string.format("%.1f", Angle))

    return x_data,y_data,z_data
end



sys.taskInit(function()
    sys.wait(3000)
    
    while true do
        sys.wait(2000)
        if init() then 

            --初始化hmc588配置
            hmc5883l_int()

            --读取x,y,z数值
            hmc5883l_read()
            
            i2c.close(i2cid)
        end
    end
end)


