
--- 模块功能：CCS811
--- Author JWL  



module(..., package.seeall)
require "pins"



local  CCS811_Add = 0x5A
local  STATUS_REG = 0x00
local  MEAS_MODE_REG = 0x01
local  ALG_RESULT_DATA = 0x02
local  ENV_DATA = 0x05
local  NTC_REG = 0x06
local  THRESHOLDS = 0x10
local  BASELINE = 0x11
local  HW_ID_REG = 0x20
local  ERROR_ID_REG = 0xE0
local  APP_START_REG = 0xF4
local  SW_RESET = 0xFF
local  CCS_811_ADDRESS = 0x5A
local  GPIO_WAKE = 0x5
local  DRIVE_MODE_IDLE = 0x0
local  DRIVE_MODE_1SEC = 0x10
local  DRIVE_MODE_10SEC = 0x20
local  DRIVE_MODE_60SEC = 0x30
local  INTERRUPT_DRIVEN = 0x8
local  THRESHOLDS_ENABLED = 0x4

local DEV_ID        =   CCS811_Add 		
local I2C_ID        =   0x02
local temp          =   0x5a

 
local wake_gpio =  pins.setup(pio.P0_13,1)

--注意 这两个函数只能在任务中调用
function ON_CS() 
    wake_gpio(0)
    sys.wait(20)
end

function OFF_CS() 
    wake_gpio(1)
    sys.wait(20)
end




local function I2C_Open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("模块功能：CCS811", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("模块功能：CCS811", "I2C.init is: succeed")
    end
    return i2c.SLOW
end


local function I2C_Write_Byte_CCS811(regAddress,content)
    i2c.send(I2C_ID, DEV_ID, {regAddress,content})
end

local function I2C_Read_Bytes_CCS811(regAddress,rdcnt)
    i2c.send(I2C_ID, DEV_ID, regAddress)
    return i2c.recv(I2C_ID, DEV_ID, rdcnt)
end

sys.taskInit(function()
    sys.wait(2000)
    I2C_Open(I2C_ID)
    sys.wait(500)

    local tinfo={}

    ON_CS()	
    table.insert(tinfo,I2C_Read_Bytes_CCS811(0x20,1)) 
    table.insert(tinfo,I2C_Read_Bytes_CCS811(0x23,2)) 
    table.insert(tinfo,I2C_Read_Bytes_CCS811(0x24,2)) 

    local sinfo= table.concat(tinfo) or ""
    if #sinfo ==0 then 
        log.info("[CCS811]","can not read ,please cheack hardware!" )
        return
    end  


    log.info("[CCS811]","sinfo=", sinfo:toHex() )




    local Status =  I2C_Read_Bytes_CCS811(0x00,1)
    if bit.band(Status:byte(1),0x10) >0 then 
        log.info("[CCS811]","&temp", nil )

        I2C_Write_Byte_CCS811(0xF4,nil)
    end



    I2C_Write_Byte_CCS811(0x01, 0x10)

    local MeasureMode =  I2C_Read_Bytes_CCS811(0x01,1)

    log.info("[CCS811]","Status, MeasureMode", string.format( "hex  Status=%02X, MeasureMode=%02X", Status:byte(1), MeasureMode:byte(1)))


    OFF_CS()

    log.info("[CCS811]","-----------------------------------------------------------------------")

    while true do

        ON_CS()	
        local Status = I2C_Read_Bytes_CCS811(0x00,1)
        local Error_ID = I2C_Read_Bytes_CCS811(0xE0,1)
        local BUF = I2C_Read_Bytes_CCS811(0x02,8)
        local tmpid= I2C_Read_Bytes_CCS811(0x20,1)
        OFF_CS()

        log.info("[CCS811]",  string.format( "hex  Status=%02X, Error_ID=%02X, tmpid=%02X", Status:byte(1), Error_ID:byte(1), tmpid:byte(1)))

        if BUF ~=nil then 
            log.info("[CCS811]","BUF:TOHEX",BUF:toHex())
            local eco2 = BUF:byte(1)
            eco2 = eco2 * 256 +  BUF:byte(2)

            local tvoc = BUF:byte(3)
            tvoc = tvoc * 256 +  BUF:byte(4)

            log.info("[CCS811]","eco2, tvoc", eco2, tvoc)
        end
        sys.wait(2000)
    end
end)