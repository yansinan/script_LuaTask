--- 模块功能：MCP23008
--- Author JWL  参考STM32  https://blog.csdn.net/lnniyunlong99/article/details/107728094

module(..., package.seeall)

require "utils"
require "sys"
require "pins"



local MCP23008_IODIR 	    =	0x00                      
local MCP23008_IPOL 	    =	0x01                      
local MCP23008_GPINTEN 	    =	0x02                      
local MCP23008_DEFVAL 	    =	0x03                      
local MCP23008_INTCON 	    =	0x04                     
local MCP23008_IOCON 	    =	0x05                     
local MCP23008_GPPU 	    =	0x06                    
local MCP23008_INTF 	    =	0x07                     
local MCP23008_INTCAP 	    =	0x08                      
local MCP23008_GPIO 	    =	0x09                     
local MCP23008_OLAT 	    =	0x0A                     
                 
               
local INPUT				    =	0x01                            
local OUTPUT			    =	0x00                          
local ENABLE			    =   0x01                          
local DISABLE		        =   0x00                          
local SET				    =   0x01                            
local RESET				    =   0x00                            
local POLARITY_REVERSE	    =	0x01                      
local POLARITY_NON_REVERSE  =	0x00                    
local PIN0				    =   0x01                            
local PIN1				    =	0x02                            
local PIN2				    =	0x04                            
local PIN3				    =	0x08                            
local PIN4				    =	0x10                            
local PIN5				    =	0x20                            
local PIN6				    =	0x40                            
local PIN7				    =	0x80                            
local ALLPIN			    =	0xFF                          
local DIS_INTERRUPT			=   0x00	                      
local HIGHLEVEL_INTERRUPT	=	0x01	                  
local LOWLEVEL_INTERRUPT	=	0x02	                  
local CHANGE_INTERRUPT		=   0x03	                    
local INT_CONJUNCTION	    =   0x00	                  
local INT_INDEPENDENT	    =   0x01	                  
local HWA_EN				=	0x00	                        
local HWA_DIS				=	0x01	                        
local INT_OD				=	0x00	                        
local INT_PUSHPULL_HIGH	    =	0x01	                    
local INT_PUSHPULL_LOW	    =	0x02	                    
local I2C_READ              =   0x01   
local I2C_WRITE             =   0x00   
local DEV_ID                =   0x20				
local I2C_ID                =   0x02


local function I2C_Open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("MCP23008", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("MCP23008", "I2C.init is: succeed")
    end
    return i2c.SLOW
end

local function I2C_Write_Byte_MCP23008(deviceAddr, regAddress,content)
    local i2cslaveaddr = bit.bor(DEV_ID,  deviceAddr)
    i2c.send(I2C_ID, i2cslaveaddr, {regAddress,content})
end

local function I2C_Read_Byte_MCP23008(deviceAddr,  regAddress)
    local i2cslaveaddr =bit.bor(DEV_ID,  deviceAddr)
    i2c.send(I2C_ID, i2cslaveaddr, regAddress)
    return i2c.recv(I2C_ID, i2cslaveaddr, 1):byte(1)
end


local function MCP23008_INIT(deviceAddr,intp,hwa, o)
	local state,res;

	--首先设置其他位的默认状态
	state = 0X22;		--001011 10,BANK = 0,默认不关联AB（bit = 0）,禁用顺序操作,使能变化率控制、使能硬件地址,开漏输出

	if intp==INT_CONJUNCTION then
        state = bit.bor(state,0x40)  --	state |= 0x40;
    end
	if hwa==HWA_DIS then
        state = bit.band( state, bit.bnot(0x08))  -- state &= (~0x08);
    end
	if o==INT_PUSHPULL_HIGH then
        state = bit.band(state, bit.bnot(0x04))   -- state &= (~0x04);
		state = bit.bor(state,0x02)               -- state |= 0x02;
    end
	if o==INT_PUSHPULL_LOW then
        state = bit.band(state, bit.bnot(0x04))   -- state &= (~0x04);
        state = bit.band(state, bit.bnot(0x02))   -- state &= (~0x02);
    end
	--写回方向寄存器
	res = I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_IOCON,state)

    log.info("MCP23008_INIT,ret",string.format("%02X",state, res))
	return res;
end

local function MCP23008_IO_DIR(deviceAddr,pin,dir)

	local portState = 0x00
	--首先读取当前端口方向的配置状态
	--因为B端口的地址比A端口的寄存器的地址都是大1，所以采用+的技巧切换寄存器
	--portState =I2C_Read_Byte_MCP23008(deviceAddr,MCP23008_IODIR);

	if dir==INPUT then
		portState = bit.bor(portState, pin)             --portState |= pin;
    else
        portState = bit.band(portState, bit.bnot(pin))	--portState &= (~pin);
	end

	--写回方向寄存器
	I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_IODIR,portState)
	
end

local function MCP23008_IO_PU(deviceAddr,pin,pu)
	local portState = 0x00
	if pu==ENABLE then
        portState = bit.bor(portState,pin)  --	portState |= pin;
    else
        portState = bit.band(portState, bit.bnot(pin))  	--portState &= (~pin);
	end
	I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_GPPU,portState)
end






local function MCP23008_IO_INT(deviceAddr, pin, intKind)
    local portState_GPINTEN = 0 -- 中断使能寄存器
	local portState_DEFVAL  = 0 -- 中断默认值寄存器
	local portState_INTCON  = 0 -- 中断控制寄存器
	
	--首先读取当前配置状态
	--因为B端口的地址比A端口的寄存器的地址都是大1，所以采用+的技巧切换寄存器
	portState_GPINTEN = I2C_Read_Byte_MCP23008(deviceAddr,MCP23008_GPINTEN)		
	portState_DEFVAL  = I2C_Read_Byte_MCP23008(deviceAddr,MCP23008_DEFVAL )
	portState_INTCON  = I2C_Read_Byte_MCP23008(deviceAddr,MCP23008_INTCON )

    log.info("portState_GPINTEN,portState_DEFVAL,portState_INTCON", portState_GPINTEN,portState_DEFVAL,portState_INTCON)
 
	--判断中断的类型
	--如果是关闭中断
	if intKind==DIS_INTERRUPT then
        portState_GPINTEN = bit.band(portState_GPINTEN,bit.bnot(pin))  -- portState_GPINTEN &= (~pin);	
    end
	--如果是变化中断
	if intKind==CHANGE_INTERRUPT then
		portState_GPINTEN = bit.bor(portState_GPINTEN, pin)             -- portState_GPINTEN |= pin;
        portState_INTCON  = bit.band(portState_INTCON, bit.bnot(pin))   -- portState_INTCON  &= (~pin);		
    end
	--如果是高电平中断
	if intKind==HIGHLEVEL_INTERRUPT then
		portState_GPINTEN = bit.bor(portState_GPINTEN, pin)             -- portState_GPINTEN |= pin;
		portState_INTCON  = bit.bor(portState_INTCON,  pin)              -- portState_INTCON  |= pin;
		portState_DEFVAL  = bit.band(portState_DEFVAL, bit.bnot(pin))   -- portState_DEFVAL  &= (~pin);		
    end
	--如果是低电平中断
	if intKind==LOWLEVEL_INTERRUPT then
		portState_GPINTEN = bit.bor(portState_GPINTEN, pin)             -- portState_GPINTEN |= pin;
		portState_INTCON  = bit.bor(portState_INTCON,  pin)              -- portState_INTCON  |= pin;
		portState_DEFVAL  = bit.bor(portState_DEFVAL,  pin)              -- portState_DEFVAL  |= pin;		
    end
	--写回寄存器
    I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_GPINTEN,portState_GPINTEN)
    I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_INTCON,portState_INTCON)
    I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_DEFVAL,portState_DEFVAL)

end




local function MCP23008_WRITE_GPIO(deviceAddr,val)	
	I2C_Write_Byte_MCP23008(deviceAddr,MCP23008_GPIO,val)
end


local function MCP23008_READ_GPIO(deviceAddr)
	return I2C_Read_Byte_MCP23008(deviceAddr,MCP23008_GPIO)
end


local flag_interrupt=0

pins.setup(
   pio.P0_13,
   function(msg)
        flag_interrupt = 1

        log.info("flag_interrupt, msg", flag_interrupt, msg )
   end,
   pio.PULLUP
)



sys.taskInit(function()

    sys.wait(4000)
    I2C_Open(I2C_ID)
    sys.wait(500)


    
    --8路输出初始化

  
    
    MCP23008_INIT(0x00,INT_INDEPENDENT,HWA_EN,INT_OD)
   
    sys.wait(50)

    MCP23008_IO_DIR(0x00,ALLPIN,INPUT)
    sys.wait(50)
    
    local val = MCP23008_READ_GPIO(0x00)
    log.info("gpio=",string.format("%02X",val))


    -- MCP23008_IO_PU(0x00,ALLPIN,ENABLE)
    -- sys.wait(50)
    -- MCP23008_IO_INT(0x00,ALLPIN,CHANGE_INTERRUPT)
    -- sys.wait(2500)

    MCP23008_IO_DIR(0x00,ALLPIN,OUTPUT)


    while true do

        --对PORT 写入高低电平
        MCP23008_WRITE_GPIO(0x00,0x01)
        log.info("set high")
        sys.wait(1000)
        log.info("set low")
        MCP23008_WRITE_GPIO(0x00,0x00)
        sys.wait(1000)

        -- --读取端口的值日
        -- local val = MCP23008_READ_GPIO(0x00)
        -- log.info("port A=",string.format("%02X",val))

        sys.wait(2000)
     

    end
end)






