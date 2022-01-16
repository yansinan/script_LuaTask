
--- 模块功能：BMA250
--- Author JWL  参考C代码：https://github.com/ControlEverythingCommunity/BMA250



module(..., package.seeall)


local BMP_CHIPID       =    0x00
local BMP_VERSION      =    0x01
local BMP_ACC_X_LSB    =    0x02
local BMP_ACC_X_MSB    =    0x03
local BMP_ACC_Y_LSB    =    0x04
local BMP_ACC_Y_MSB    =    0x05
local BMP_ACC_Z_LSB    =    0x06
local BMP_ACC_Z_MSB    =    0x07

local BMP_GRANGE       =    0x0F	   -- g Range
local BMP_BWD          =    0x10	   -- Bandwidth
local BMP_PM           =    0x11	   -- Power modes
local BMP_SCR          =    0x13	   -- Special Control Register
local BMP_RESET        =    0x14	   -- Soft reset register writing 0xB6 causes reset
local BMP_ISR1         =    0x16	   -- Interrupt settings register 1
local BMP_ISR2         =    0x17	   -- Interrupt settings register 2
local BMP_IMR1         =    0x19	   -- Interrupt mapping register 1
local BMP_IMR2         =    0x1A	   -- Interrupt mapping register 2
local BMP_IMR3         =    0x1B	   -- Interrupt mapping register 3

local DEV_ID        =   0x18 		
local I2C_ID        =   0x02


local function I2C_Open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("BMA250", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("BMA250", "I2C.init is: succeed")
    end
    return i2c.SLOW
end


local function I2C_Write_Byte_BMA250(regAddress,content)
    i2c.send(I2C_ID, DEV_ID, {regAddress,content})
end

local function I2C_Read_Bytes_BMA250(regAddress,rdcnt)
    i2c.send(I2C_ID, DEV_ID, regAddress)
    return i2c.recv(I2C_ID, DEV_ID, rdcnt)
end
local function I2C_Read_Byte_BMA250(regAddress)
    i2c.send(I2C_ID, DEV_ID, regAddress)
    return i2c.recv(I2C_ID, DEV_ID, 1):byte(1)
end



sys.taskInit(function()
    sys.wait(2000)
    I2C_Open(I2C_ID)
    sys.wait(500)

    while true do

        I2C_Write_Byte_BMA250(BMP_GRANGE,0X03)
        sys.wait(100)
        I2C_Write_Byte_BMA250(BMP_BWD,0X08)
        sys.wait(100)

        local data = I2C_Read_Bytes_BMA250(BMP_ACC_X_LSB,6)


        if data~=nil and #data==6 then
            _, x, y, z = pack.unpack(data, "<HHH")
            log.info("x, y, z", x, y, z)
        else
            log.info("BMA250","error read!!")
        end
    end
end)