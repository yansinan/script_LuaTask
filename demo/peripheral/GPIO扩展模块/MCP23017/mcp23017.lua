--- 模块功能：MCP23017
--- Author JWL  参考STM32  https://blog.csdn.net/lnniyunlong99/article/details/107728094

module(..., package.seeall)

require "utils"
require "sys"
require "pins"



local MCP23017_IODIR 	    =	0x00                      
local MCP23017_IPOL 	    =	0x02                      
local MCP23017_GPINTEN 	    =	0x04                      
local MCP23017_DEFVAL 	    =	0x06                      
local MCP23017_INTCON 	    =	0x08                      
local MCP23017_IOCON 	    =	0x0A                      
local MCP23017_GPPU 	    =	0x0C                      
local MCP23017_INTF 	    =	0x0E                      
local MCP23017_INTCAP 	    =	0x10                      
local MCP23017_GPIO 	    =	0x12                      
local MCP23017_OLAT 	    =	0x14                      
local MCP23017_PORTA	    =	0x00                      
local MCP23017_PORTB	    =	0x01                      
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
local INTA_INTB_CONJUNCTION	=   0x00	                  
local INTA_INTB_INDEPENDENT	=   0x01	                  
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
        log.error("MCP23017", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("MCP23017", "I2C.init is: succeed")
    end
    return i2c.SLOW
end

local function I2C_Write_Byte_MCP23017(deviceAddr, regAddress,content)
    local i2cslaveaddr = bit.bor(DEV_ID,  deviceAddr)
    i2c.send(I2C_ID, i2cslaveaddr, {regAddress,content})
end

local function I2C_Read_Byte_MCP23017(deviceAddr,  regAddress)
    local i2cslaveaddr =bit.bor(DEV_ID,  deviceAddr)
    i2c.send(I2C_ID, i2cslaveaddr, regAddress)
    return i2c.recv(I2C_ID, i2cslaveaddr, 1):byte(1)
end


local function MCP23017_INIT(deviceAddr,intab,hwa,port, o)
	local state,res;

	--首先设置其他位的默认状态
	state = 0X22;		--001011 10,BANK = 0,默认不关联AB（bit = 0）,禁用顺序操作,使能变化率控制、使能硬件地址,开漏输出

	if intab==INTA_INTB_CONJUNCTION then
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
	res = I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_IOCON +port,state)
	return res;
end

local function MCP23017_IO_DIR(deviceAddr,port,pin,dir)

	local portState = 0x00
	--首先读取当前端口方向的配置状态
	--因为B端口的地址比A端口的寄存器的地址都是大1，所以采用+的技巧切换寄存器
	--portState =I2C_Read_Byte_MCP23017(deviceAddr,MCP23017_IODIR+port);

	if dir==INPUT then
		portState = bit.bor(portState, pin)             --portState |= pin;
    else
        portState = bit.band(portState, bit.bnot(pin))	--portState &= (~pin);
	end

	--写回方向寄存器
	I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_IODIR+port,portState)
	
end

local function MCP23017_IO_PU(deviceAddr,port,pin,pu)
	local portState = 0x00
	if pu==ENABLE then
        portState = bit.bor(portState,pin)  --	portState |= pin;
    else
        portState = bit.band(portState, bit.bnot(pin))  	--portState &= (~pin);
	end
	I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_GPPU+port,portState)
end






local function MCP23017_IO_INT(deviceAddr, port, pin, intKind)
    local portState_GPINTEN = 0 -- 中断使能寄存器
	local portState_DEFVAL  = 0 -- 中断默认值寄存器
	local portState_INTCON  = 0 -- 中断控制寄存器
	
	--首先读取当前配置状态
	--因为B端口的地址比A端口的寄存器的地址都是大1，所以采用+的技巧切换寄存器
	portState_GPINTEN = I2C_Read_Byte_MCP23017(deviceAddr,MCP23017_GPINTEN +port)		
	portState_DEFVAL  = I2C_Read_Byte_MCP23017(deviceAddr,MCP23017_DEFVAL  +port)
	portState_INTCON  = I2C_Read_Byte_MCP23017(deviceAddr,MCP23017_INTCON  +port)

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
    I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_GPINTEN+port,portState_GPINTEN)
    I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_INTCON+port,portState_INTCON)
    I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_DEFVAL+port,portState_DEFVAL)

end




local function MCP23017_WRITE_GPIO(deviceAddr,port,val)	
	I2C_Write_Byte_MCP23017(deviceAddr,MCP23017_GPIO+port,val)
end


local function MCP23017_READ_GPIO(deviceAddr,port)
	return I2C_Read_Byte_MCP23017(deviceAddr,MCP23017_GPIO+port)
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

    sys.wait(2000)
    I2C_Open(I2C_ID)
    sys.wait(500)


    
    --16路输出初始化
    MCP23017_INIT(0x00,INTA_INTB_INDEPENDENT,HWA_EN, MCP23017_PORTB,INT_OD)
    sys.wait(100)


    MCP23017_IO_DIR(0x00,MCP23017_PORTB,ALLPIN,INPUT)
    sys.wait(50)

    MCP23017_IO_PU(0x00,MCP23017_PORTB,ALLPIN,ENABLE)
    sys.wait(50)
    MCP23017_IO_INT(0x00,MCP23017_PORTB,ALLPIN,CHANGE_INTERRUPT)
    sys.wait(2500)


    local val = MCP23017_READ_GPIO(0x00,MCP23017_PORTB)
    log.info("port B=",string.format("%02X",val))



    while true do

        --对PORT A 写入高低电平
        MCP23017_WRITE_GPIO(0x00,MCP23017_PORTA,0x01)
        log.info("set high")
        sys.wait(1000)
        log.info("set low")
        MCP23017_WRITE_GPIO(0x00,MCP23017_PORTA,0x00)
        sys.wait(1000)

        --读取端口的值日
        local val = MCP23017_READ_GPIO(0x00,MCP23017_PORTB)
        log.info("port B=",string.format("%02X",val))

 
        -- if flag_interrupt ==1 then
        --     flag_interrupt = 0
        --     local val = MCP23017_READ_GPIO(0x00,MCP23017_PORTB)
        --     log.info("port B=",string.format("%02X",val))
        -- else
        --     sys.wait(2000)
        -- end

        sys.wait(2000)
     

    end
end)






