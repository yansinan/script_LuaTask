PROJECT = "sensor"
VERSION = "1.0.0"

require "log"
require "sys"
require "misc"

-- i2c ID
i2cid = 2

-- i2c 速率
 

 






local  Accuracy 			=		 	32768	 
local  ADS1115_ADDRESS_0	=		 	0x48            -- addr0:0x48 addr1:0x49 addr2:0x4A addr3:0x4B	 

local addr =  ADS1115_ADDRESS_0 
local speed = 100000


--************POINTER REGISTER*****************
local  ADS1115_Pointer_ConverReg	 =   	0x00	    --Convertion register
local  ADS1115_Pointer_ConfigReg	 =		0x01	    --Config register
local  ADS1115_Pointer_LoThreshReg	 =		0x02	    --Lo_thresh register
local  ADS1115_Pointer_HiThreshReg	 =		0x03	    --Hi_thresh register

--Bit[15]
--************CONFIG REGISTER*****************
local ADS1115_OS_OperationalStatus	 =	    0x0000		--No Effect
local ADS1115_OS_SingleConverStart	 =   	0x8000		--Begin a single conversion

--Bits[14:12]
local  ADS1115_MUX_Differ_01		 =		0x0000		--AINp=AIN0, AINn=AIN1(default)
local  ADS1115_MUX_Differ_03		 =		0x1000		--AINp=AIN0, AINn=AIN3
local  ADS1115_MUX_Differ_13		 =		0x2000		--AINp=AIN1, AINn=AIN3
local  ADS1115_MUX_Differ_23		 =		0x3000		--AINp=AIN2, AINn=AIN3
local  ADS1115_MUX_Channel_0		 =		0x4000		--AINp=AIN0, AINn=GND
local  ADS1115_MUX_Channel_1		 =		0x5000		--AINp=AIN1, AINn=GND
local  ADS1115_MUX_Channel_2		 =		0x6000		--AINp=AIN2, AINn=GND
local  ADS1115_MUX_Channel_3		 =		0x7000		--AINp=AIN3, AINn=GND
 
--Bits[11:9]
local  ADS1115_PGA_6144			     =		0x0000		--FS=6.144V
local  ADS1115_PGA_4096			     =		0x0200		--FS=4.096V
local  ADS1115_PGA_2048			     =		0x0400		--FS=2.048V(default)
local  ADS1115_PGA_1024		    	 =		0x0600		--FS=1.024V
local  ADS1115_PGA_0512			     =		0x0800		--FS=0.512V
local  ADS1115_PGA_0256			     =		0x0A00		--FS=0.256V
 

--Bit[8]
local  ADS1115_MODE_ContinuConver	 =		0x0000		--Continuous conversion mode
local  ADS1115_MODE_SingleConver	 =		0x0100		--Power-down single-shot mode(default)
 


--Bits[7:5]
local  ADS1115_DataRate_8			=	    0x0000		--Data Rate = 8
local  ADS1115_DataRate_16			=		0x0020		--Data Rate = 16
local  ADS1115_DataRate_32			=		0x0040		--Data Rate = 32
local  ADS1115_DataRate_64			=		0x0060		--Data Rate = 64
local  ADS1115_DataRate_128			=	    0x0080		--Data Rate = 128(default)
local  ADS1115_DataRate_250			=	    0x00A0		--Data Rate = 250
local  ADS1115_DataRate_475			=	    0x00C0		--Data Rate = 475
local  ADS1115_DataRate_860			=	    0x00E0		--Data Rate = 860
--Bit[4]
local  ADS1115_COMP_MODE_0			=		0x0000		--Traditional comparator with hysteresis
local  ADS1115_COMP_MODE_1			=		0x0010		--Window comparator
--Bit[3]
local  ADS1115_COMP_POL_0			=		0x0000		--Active low
local  ADS1115_COMP_POL_1			=		0x0008		--Active high
--Bit[2]
local  ADS1115_COMP_LAT_0			=		0x0000		--Non-latching comparator
local  ADS1115_COMP_LAT_1			=		0x0004		--Latching comparator
--Bits[1:0]
local  ADS1115_COMP_QUE_0			=		0x0000		--Assert after one conversion
local  ADS1115_COMP_QUE_1			=		0x0001		--Assert after two conversion
local  ADS1115_COMP_QUE_2			=		0x0002		--Assert after four conversion
local  ADS1115_COMP_QUE_3			=		0x0003		--Disable Comparator
 





local ADS1115_InitType={}

ADS1115_InitType["COMP_QUE"]= ADS1115_COMP_QUE_0



local function I2C_Write_Byte_ADS1115(regAddress,val)
    i2c.send(i2cid, addr, {regAddress,val})
end

local function I2C_Write_2Bytes_ADS1115(regAddress,val1,val2)
    i2c.send(i2cid, addr, {regAddress,val1,val2})
end

local function I2C_Read_Byte_ADS1115(regAddress)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, 1)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr:byte(1)
end
local function I2C_Read_Bytes_ADS1115(regAddress,cnt)
    i2c.send(i2cid, addr, regAddress)
    local rdstr = i2c.recv(i2cid, addr, cnt)
    log.info("rdstr:toHex()",rdstr:toHex())
    return rdstr
end








local function ADS1115_Config()
	local Config = ADS1115_InitType["OS"] + ADS1115_InitType["MUX"] + ADS1115_InitType["PGA"] + ADS1115_InitType["MODE"]  +ADS1115_InitType["DataRate"] + ADS1115_InitType["COMP_MODE"] + ADS1115_InitType["COMP_POL"] + ADS1115_InitType["COMP_LAT"] + ADS1115_InitType["COMP_QUE"]

    local val1 =bit.rshift(Config,8)
          val1 =bit.band(val1,0xFF)
    local val2 =bit.band(Config,0xFF)
    I2C_Write_2Bytes_ADS1115(ADS1115_Pointer_ConfigReg,val1,val2)
end



 
local function  ADS1115_UserConfig1()
    ADS1115_InitType["COMP_LAT"] = ADS1115_COMP_LAT_0
    ADS1115_InitType["COMP_MODE"] = ADS1115_COMP_MODE_0
    ADS1115_InitType["COMP_POL"] = ADS1115_COMP_POL_0
    ADS1115_InitType["DataRate"] = ADS1115_DataRate_475
    ADS1115_InitType["MODE"] = ADS1115_MODE_SingleConver
    ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_0
    ADS1115_InitType["OS"] = ADS1115_OS_SingleConverStart
    ADS1115_InitType["PGA"] = ADS1115_PGA_4096

    ADS1115_Config()
end

local function ADS1115_UserConfig2()
	ADS1115_InitType["COMP_LAT"] = ADS1115_COMP_LAT_0
	ADS1115_InitType["COMP_MODE"] = ADS1115_COMP_MODE_0
	ADS1115_InitType["COMP_POL"] = ADS1115_COMP_POL_0
	ADS1115_InitType["DataRate"] = ADS1115_DataRate_475
	ADS1115_InitType["MODE"] = ADS1115_MODE_ContinuConver
	ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_1
	ADS1115_InitType["OS"] = ADS1115_OS_OperationalStatus
	ADS1115_InitType["PGA"] = ADS1115_PGA_4096

    ADS1115_Config()
end
 



local function ADS1115_ReadRawData()
   local buff =  I2C_Read_Bytes_ADS1115(ADS1115_Pointer_ConverReg,2)
   return buff:byte(1) * 256  + buff:byte(2)
end


local function ADS1115_ScanChannel(channel)
    if channel ==0 then
        ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_0
    elseif channel==1 then 
        ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_1
    elseif channel==2 then 
        ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_2
    elseif channel==3 then 
        ADS1115_InitType["MUX"] = ADS1115_MUX_Channel_3
    end 
	ADS1115_Config()
end




local function ADS1115_RawDataToVoltage(rawData)
	local voltage=0
    log.info("rawData" ,rawData)
    if ADS1115_InitType.PGA == ADS1115_PGA_0256 then
        voltage = rawData * 0.0078125
    elseif  ADS1115_InitType.PGA == ADS1115_PGA_0512 then
        voltage = rawData * 0.015625
    elseif  ADS1115_InitType.PGA == ADS1115_PGA_1024 then
        voltage = rawData * 0.03125
    elseif  ADS1115_InitType.PGA == ADS1115_PGA_2048 then
        voltage = rawData * 0.0625
    elseif  ADS1115_InitType.PGA == ADS1115_PGA_4096 then
        voltage = rawData * 0.125
    elseif  ADS1115_InitType.PGA == ADS1115_PGA_6144 then
        voltage = rawData * 0.1875
    else
        voltage = 0
    end
	return voltage
end

local function ADS1115_GetVoltage()
    local rawData  = ADS1115_ReadRawData()
    return ADS1115_RawDataToVoltage(rawData);
end



-- 初始化
function init()
    if i2c.setup(i2cid, speed, addr) ~= speed then
        log.error("i2c", "setup fail", addr)
        return
    end

    log.info("dev i2c init_ok")
    return true
end


 

sys.taskInit(function()
    sys.wait(4000)

    if init() then 

        local x=1

        ADS1115_UserConfig2()

        while true do

            --测试VLCD 电压
            pmd.ldoset(x, pmd.LDO_VLCD)
            sys.wait(100)

            x= x+1
            if x>=15 then x=1 end

 
            local volt = ADS1115_GetVoltage()
 
            log.info("x,  volt=", x,  "," , volt)
            sys.wait(1000)
        end
    end
end)

sys.init(0, 0)
sys.run()
