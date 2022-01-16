PROJECT = "sensor"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
i2cid = 2

-- i2c 速率
 





local  LIS2DH12_POWER_DOWN        = 0
local  LIS2DH12_ODR_1Hz           = 1
local  LIS2DH12_ODR_10Hz          = 2
local  LIS2DH12_ODR_25Hz          = 3
local  LIS2DH12_ODR_50Hz          = 4
local  LIS2DH12_ODR_100Hz         = 5
local  LIS2DH12_ODR_200Hz         = 6
local  LIS2DH12_ODR_400Hz         = 7
local  LIS2DH12_ODR_1kHz620_LP    = 8
local  LIS2DH12_ODR_5kHz376_LP    = 9
local  LIS2DH12_ODR_1kHz344_NM_HP = 9

local  LIS2DH12_2g   = 0
local  LIS2DH12_4g   = 1
local  LIS2DH12_8g   = 2
local  LIS2DH12_16g  = 3

local LIS2DH12_HR_12bit   = 0
local LIS2DH12_NM_10bit   = 1
local LIS2DH12_LP_8bit    = 2

local PROPERTY_DISABLE  = 0
local PROPERTY_ENABLE   = 1

local LIS2DH12_TEMP_DISABLE  = 0
local LIS2DH12_TEMP_ENABLE   = 3



local OUT_X_L     =   0x28
local OUT_X_H     =   0x29
local OUT_Y_L     =   0x2A
local OUT_Y_H     =   0x2B
local OUT_Z_L     =   0x2C
local OUT_Z_H     =   0x2D

local addr = 0x19

local speed = 100000




local  WHO_AM_I         =        0x0F
local  CTRL_REG1        =        0x20
local  CTRL_REG4        =        0x23
local  TEMP_CFG_REG     =        0x1F
local  STATUS_REG       =        0x27
local  STATUS_REG_AUX   =        0x07
local  OUT_TEMP_L       =        0x0C
local  OUT_TEMP_H       =        0x0D

local function LIS2DH12_FROM_FS_2g_HR_TO_mg(lsb)   return (bit.rshift(lsb,4)) * 1.0  end
local function LIS2DH12_FROM_FS_4g_HR_TO_mg(lsb)   return (bit.rshift(lsb,4)) * 2.0  end
local function LIS2DH12_FROM_FS_8g_HR_TO_mg(lsb)   return (bit.rshift(lsb,4)) * 4.0  end
local function LIS2DH12_FROM_FS_16g_HR_TO_mg(lsb)  return (bit.rshift(lsb,4)) * 12.0 end
local function LIS2DH12_FROM_LSB_TO_degC_HR(lsb)   return (bit.rshift(lsb,6)) / 4.0  +25.0  end

local function LIS2DH12_FROM_FS_2g_NM_TO_mg(lsb)   return (bit.rshift(lsb,6)) * 4.0  end
local function LIS2DH12_FROM_FS_4g_NM_TO_mg(lsb)   return (bit.rshift(lsb,6)) * 8.0  end
local function LIS2DH12_FROM_FS_8g_NM_TO_mg(lsb)   return (bit.rshift(lsb,6)) * 16.0  end
local function LIS2DH12_FROM_FS_16g_NM_TO_mg(lsb)  return (bit.rshift(lsb,6)) * 48.0  end
local function LIS2DH12_FROM_LSB_TO_degC_NM(lsb)   return (bit.rshift(lsb,6)) / 4.0  +25.0  end

local function LIS2DH12_FROM_FS_2g_LP_TO_mg(lsb)   return (bit.rshift(lsb,8)) * 16.0  end
local function LIS2DH12_FROM_FS_4g_LP_TO_mg(lsb)   return (bit.rshift(lsb,8)) * 32.0  end
local function LIS2DH12_FROM_FS_8g_LP_TO_mg(lsb)   return (bit.rshift(lsb,8)) * 64.0  end
local function LIS2DH12_FROM_FS_16g_LP_TO_mg(lsb)  return (bit.rshift(lsb,8)) * 192.0  end
local function LIS2DH12_FROM_LSB_TO_degC_LP(lsb)   return (bit.rshift(lsb,8)) * 1.0  +25.0  end




--------------------------------




local function I2C_Write_Byte_LIS2DH12TR(regAddress,content)
    i2c.send(i2cid, addr, {regAddress,content})
end

local function I2C_Read_Byte_LIS2DH12TR(regAddress)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, 1)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr:byte(1)
end


-------------------------------------------------------------

local function lis2dh12_block_data_update_set(val)
    local rdval = I2C_Read_Byte_LIS2DH12TR(CTRL_REG4)
    val   = (val==1) and 0x80 or 0x00
    rdval = bit.band(rdval,0x7F)
    rdval = bit.bor(rdval, val)
    I2C_Write_Byte_LIS2DH12TR(CTRL_REG4,rdval)
end

local function lis2dh12_data_rate_set(val)

   val = bit.band(val,0x0F)
   val = bit.lshift(val,4)
   local rdval =I2C_Read_Byte_LIS2DH12TR(CTRL_REG1)
   rdval = bit.band(rdval,0x0F)
   rdval = bit.bor(rdval, val)
   I2C_Write_Byte_LIS2DH12TR(CTRL_REG1, rdval)
end

--
local function lis2dh12_full_scale_set(val)

   val = bit.band(val,0x03)
   val = bit.lshift(val,4)
   local rdval = I2C_Read_Byte_LIS2DH12TR(CTRL_REG4)

   rdval = bit.band(rdval,0xCF)
   rdval = bit.bor(rdval, val)
   I2C_Write_Byte_LIS2DH12TR(CTRL_REG4,rdval)
end


local function lis2dh12_temperature_meas_set( val)

    val = bit.band(val,0x03)
    val = bit.lshift(val,6)
    local rdval =  I2C_Read_Byte_LIS2DH12TR( TEMP_CFG_REG)
    rdval = bit.band(rdval,0x3F)
    rdval = bit.bor(rdval, val)
    I2C_Write_Byte_LIS2DH12TR(TEMP_CFG_REG, rdval)
end

local function lis2dh12_operating_mode_set(val)
    local rdval, lpen, hr
    if  val == LIS2DH12_HR_12bit then
        lpen = 0x00
        hr   = 0x08
    elseif val == LIS2DH12_NM_10bit then
        lpen = 0x00
        hr   = 0x00
    elseif val == LIS2DH12_LP_8bit then 
        lpen = 0x80
        hr   = 0x00
    end

    rdval =  I2C_Read_Byte_LIS2DH12TR( CTRL_REG1);
    rdval = bit.band(rdval,0xF7)
    rdval = bit.bor(rdval, lpen)
    I2C_Write_Byte_LIS2DH12TR( CTRL_REG1, rdval);

    rdval =I2C_Read_Byte_LIS2DH12TR( CTRL_REG4);
    rdval = bit.band(rdval,0xF7)
    rdval = bit.bor(rdval, hr)
    I2C_Write_Byte_LIS2DH12TR( CTRL_REG4, rdval);
end


local function lis2dh12_status_get()
   return I2C_Read_Byte_LIS2DH12TR( STATUS_REG)
end

local function lis2dh12_temp_data_ready_get()
    local rdval = I2C_Read_Byte_LIS2DH12TR(STATUS_REG_AUX)
    return bit.band(rdval,0x20)
end

local function lis2dh12_acceleration_raw_get()
    local xl,xh,yl,yh,zl,zh
 
    xl = I2C_Read_Byte_LIS2DH12TR(OUT_X_L)
    xh = I2C_Read_Byte_LIS2DH12TR(OUT_X_H)

    yl = I2C_Read_Byte_LIS2DH12TR(OUT_Y_L)
    yh = I2C_Read_Byte_LIS2DH12TR(OUT_Y_H)

    zl = I2C_Read_Byte_LIS2DH12TR(OUT_Z_L)
    zh = I2C_Read_Byte_LIS2DH12TR(OUT_Z_H)

    local x,y,z

    x = xh * 256 + xl
    y = yh * 256 + yl
    z = zh * 256 + zl

    log.info(string.format(" xl,xh,yl,yh,zl,zh =0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X ",xl,xh,yl,yh,zl,zh))

    return x,y,z
end

local function  lis2dh12_temperature_raw_get()
      local tl,th
      tl = I2C_Read_Byte_LIS2DH12TR(OUT_TEMP_L)
      th = I2C_Read_Byte_LIS2DH12TR(OUT_TEMP_H)
 
      log.info(string.format("tl,th =%02X %02X ",tl,th))
      return  th * 256 + tl
end


-- 初始化
function init()
    if i2c.setup(i2cid, speed, addr) ~= speed then
        log.error("i2c", "setup fail", addr)
        return
    end

    local whoid = I2C_Read_Byte_LIS2DH12TR(WHO_AM_I)


    if whoid ==0x33 then 
        log.info("===================dev is ok========================")
    else
        log.info("i2c dev id is wrong!")
        return false
    end


    lis2dh12_block_data_update_set(PROPERTY_ENABLE)
    lis2dh12_data_rate_set(LIS2DH12_ODR_10Hz)
    lis2dh12_full_scale_set(LIS2DH12_2g)

    lis2dh12_temperature_meas_set(LIS2DH12_TEMP_ENABLE)
    lis2dh12_operating_mode_set(LIS2DH12_HR_12bit)

     log.info("dev i2c init_ok")
     return true
end



--获取加速度计的原始数据
local function TEST_LIS2DH12TR()
    local accel={x=nil,y=nil,z=nil}
    local xl,xh,yl,yh,zl,zh


    local  stat = lis2dh12_status_get() or 0

    if bit.band(stat,0x10) >0 then
          local acceleration_mg ={0,0,0}
          local x,y,z = lis2dh12_acceleration_raw_get()

          acceleration_mg[1] = LIS2DH12_FROM_FS_2g_HR_TO_mg( x )
          acceleration_mg[2] = LIS2DH12_FROM_FS_2g_HR_TO_mg( y )
          acceleration_mg[3] = LIS2DH12_FROM_FS_2g_HR_TO_mg( z )

          log.info("Acceleration [mg]",acceleration_mg[1], acceleration_mg[2], acceleration_mg[3] , "--------------",x,y,z)


          if lis2dh12_temp_data_ready_get() >0 then
 
            local tempv = lis2dh12_temperature_raw_get()
            temperature_degC = LIS2DH12_FROM_LSB_TO_degC_HR( tempv)
            log.info("Temperature [degC]", temperature_degC,tempv)

          end
    else
        log.info("dev read loop!!!!!!!!!!!!!!!!")

    end
 
end




sys.taskInit(function()
    sys.wait(4000)

    if init() then 
        while true do
            TEST_LIS2DH12TR()
            sys.wait(1000)
        end
    end
end)

sys.init(0, 0)
sys.run()
