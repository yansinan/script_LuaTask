--- 模块功能：I2C功能测试.
-- @author JWL
-- @module i2c.BMP280
-- @license MIT
-- @copyright openLuat
-- @release 2021.11.12

module(...,package.seeall)
-- 调试BMP280芯片会出现数据不变化的情况，要关电5分钟后再使用。

require"utils"


local dev={}

local I2C_ID        =   0x02
local DEV_ID        =   0x76 		


local BMP280_REGISTER_DIG_T1              = 0x88
local BMP280_REGISTER_DIG_T2              = 0x8A
local BMP280_REGISTER_DIG_T3              = 0x8C

local BMP280_REGISTER_DIG_P1              = 0x8E
local BMP280_REGISTER_DIG_P2              = 0x90
local BMP280_REGISTER_DIG_P3              = 0x92
local BMP280_REGISTER_DIG_P4              = 0x94
local BMP280_REGISTER_DIG_P5              = 0x96
local BMP280_REGISTER_DIG_P6              = 0x98
local BMP280_REGISTER_DIG_P7              = 0x9A
local BMP280_REGISTER_DIG_P8              = 0x9C
local BMP280_REGISTER_DIG_P9              = 0x9E

local BMP280_REGISTER_CHIPID             = 0xD0
local BMP280_REGISTER_VERSION            = 0xD1
local BMP280_REGISTER_SOFTRESET          = 0xE0

--R calibration stored in 0xE1-0xF0
local BMP280_REGISTER_CAL26              = 0xE1  

local BMP280_REGISTER_CONTROL            = 0xF4
local BMP280_REGISTER_CONFIG             = 0xF5
local BMP280_REGISTER_PRESSUREDATA       = 0xF7
local BMP280_REGISTER_TEMPDATA           = 0xFA



local function I2C_Open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("BMP280", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("BMP280", "I2C.init is: succeed")
    end
    return i2c.SLOW
  end
  
  local function I2C_Write_Byte_BMP280(regAddress,content)
    i2c.send(I2C_ID, DEV_ID, {regAddress,content})
  end
  
  local function I2C_Read_Bytes_BMP280(regAddress,rdcnt)
    i2c.send(I2C_ID, DEV_ID, regAddress)
    return i2c.recv(I2C_ID, DEV_ID, rdcnt)
  end


  local function read8(regaddr)
    local buff = I2C_Read_Bytes_BMP280(regaddr,1)
    return  buff:byte(1)
  end
  

  local function read16(regaddr)
    local buff = I2C_Read_Bytes_BMP280(regaddr,2)
    return (buff:byte(1)) *256 + buff:byte(2)
  end
  local function readS16(regaddr)
    local val = read16(regaddr)
    if val < 0x8000 then return val end
    return val -0x10000
  end

  local function read16_LE(regaddr)
     local buff = I2C_Read_Bytes_BMP280(regaddr,2)
     return (buff:byte(2)) *256 + buff:byte(1)
  end

  local function readS16_LE(regaddr)
     local val = read16_LE(regaddr)
     if val < 0x8000 then return val end
     return val -0x10000
  end


  local function readCoefficients(void)
      dev["calib"]["dig_T1"] = read16_LE(BMP280_REGISTER_DIG_T1);
      dev["calib"]["dig_T2"] = readS16_LE(BMP280_REGISTER_DIG_T2);
      dev["calib"]["dig_T3"] = readS16_LE(BMP280_REGISTER_DIG_T3);
      dev["calib"]["dig_P1"] = read16_LE(BMP280_REGISTER_DIG_P1);
      dev["calib"]["dig_P2"] = readS16_LE(BMP280_REGISTER_DIG_P2);
      dev["calib"]["dig_P3"] = readS16_LE(BMP280_REGISTER_DIG_P3);
      dev["calib"]["dig_P4"] = readS16_LE(BMP280_REGISTER_DIG_P4);
      dev["calib"]["dig_P5"] = readS16_LE(BMP280_REGISTER_DIG_P5);
      dev["calib"]["dig_P6"] = readS16_LE(BMP280_REGISTER_DIG_P6);
      dev["calib"]["dig_P7"] = readS16_LE(BMP280_REGISTER_DIG_P7);
      dev["calib"]["dig_P8"] = readS16_LE(BMP280_REGISTER_DIG_P8);
      dev["calib"]["dig_P9"] = readS16_LE(BMP280_REGISTER_DIG_P9);
  end
 

  local function lshift(x,y)
     return x * math.pow(2,y)
  end
  local function rshift(x,y)
    return  x / math.pow(2,y)
  end
 



 local function readTemperature()
    local var1, var2;
    local adc_T = read16(BMP280_REGISTER_TEMPDATA)
    adc_T = lshift(adc_T,8)
    adc_T = adc_T+ read8(BMP280_REGISTER_TEMPDATA+2)
    adc_T = rshift(adc_T,4)
    var1  = (((( rshift(adc_T,3)) - (lshift(  dev["calib"]["dig_T1"],1)))) * (dev["calib"]["dig_T2"])) 

    var1 = rshift(var1,11)
    var2  = ((  rshift((((rshift(adc_T,4)) - (dev["calib"]["dig_T1"])) *  ((rshift(adc_T,4)) - (dev["calib"]["dig_T1"]))) , 12)) *   (dev["calib"]["dig_T3"]))
    var2 = rshift(var2,14)

    dev["calib"]["t_fine"] = var1 + var2
    local T  =  rshift((dev["calib"]["t_fine"]  * 5 + 128), 8 ) 
    return  math.floor(T)/100;
 end


local function readPressure() 
    local var1, var2, p
    
    local adc_P = read16(BMP280_REGISTER_PRESSUREDATA)
    adc_P = lshift(adc_P,8)
    adc_P = adc_P+ read8(BMP280_REGISTER_PRESSUREDATA+2)
    adc_P = rshift(adc_P,4)
    log.info("adc_P", adc_P)

    var1 =dev["calib"]["t_fine"]  - 128000;
    var2 = var1 * var1 *  dev["calib"]["dig_P6"]
    var2 = var2 + ( lshift( (var1*dev["calib"]["dig_P5"]),17) )
    var2 = var2 + (lshift((dev["calib"]["dig_P4"]),35))
    var1 = (  rshift((var1 * var1 * dev["calib"]["dig_P3"]),8)) + ( lshift((var1 * dev["calib"]["dig_P2"]),12) )
    var1 = ((( lshift(1,47)  )+var1)) * rshift((dev["calib"]["dig_P1"]),33)
    log.info("[calib] ", json.encode(dev["calib"]))
    if var1 == 0 then 
      return 0 -- avoid exception caused by division by zero
    end
    p = 1048576 - adc_P
    p = (( (  lshift(p, 31)) - var2)*3125) / var1
    var1 = ((dev["calib"]["dig_P9"]) * ( rshift( p,13)  ) * ( rshift(p,13)  )) 
    var1 = rshift(var1,25)
    var2 = ((dev["calib"]["dig_P8"]) * p)
    var2 = rshift(var2,19)
  
    p = (rshift((p + var1 + var2) , 8)) + ( lshift((dev["calib"]["dig_P7"]),4)  )
    return math.floor(p/256);
end
  
  
sys.taskInit(function()
    sys.wait(4000)
    I2C_Open(I2C_ID)
    sys.wait(200)
    dev["calib"]   = {}   
    dev["calib"]["t_fine"]  = 0
    dev["chip_id"] = I2C_Read_Bytes_BMP280(BMP280_REGISTER_CHIPID,1)
    log.info("BMP280 chipid=",  string.format("%02X", dev["chip_id"]:byte(1) ) )
    readCoefficients()
    I2C_Write_Byte_BMP280(BMP280_REGISTER_CONTROL, 0x3F);
 
    while true do
        sys.wait(100)

        local temp = readTemperature()
         local pres = readPressure()
        log.info("temp, pres", temp .."℃",  pres)


        sys.wait(2000)
    end
  end)
  
  