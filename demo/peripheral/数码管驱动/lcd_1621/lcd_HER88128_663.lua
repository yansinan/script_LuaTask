
require"pins"




local	HT1621_CMD_ID	=0x80		--前3位 100有效
local	HT1621_DATA_ID	=0xA0		--前3位 101有效

local BIAS=0x29	--0x50-- 1/3 bias   4 com
local SYSEN=0x01	--0X02--Turn on system oscillator振荡
local LCDON=0x03	--0x06--Turn on LCD bias generator偏压发生器
local LCDOFF=0x02	--0x04--Turn off LCD bias generator
local RC256=0X18

 


local LCD_CS = pins.setup(pio.P0_3,0)
local LCD_WR = pins.setup(pio.P0_1,0)
local LCD_DAT = pins.setup(pio.P0_0,0)
local LCD_VCC = pins.setup(pio.P0_18,0)

local DIGITS={["1"] =0XA0,["2"] = 0X6D,["3"] = 0XE9, ["4"] = 0XE2, ["5"] = 0XCB , ["6"] = 0XCF, ["7"] = 0XA1, ["8"] =0XEF, ["9"] =0xEB, ["0"] =0XAF }


local DISPMEM={0X00,0X00,0X00,0X00,0X00,0X00,0X00}

local function __NOP()

end

function sendbit_high(data,cnt)--传地址，高六位
	local i
	for i=1, cnt do
		if bit.band(data,0x80)==0 then
            LCD_DAT(0)
		else
            LCD_DAT(1)
        end
		LCD_WR(0)

		LCD_WR(1)
		data = bit.lshift(data,1)
    end
end

function sendbit_low(data, cnt)--传送数据，低四位
	local i
	for i=1,cnt do
		if bit.band(data,0x01)==0 then
            LCD_DAT(0)
		else
            LCD_DAT(1)
        end
		LCD_WR(0)

		LCD_WR(1)
		data=bit.rshift(data,1)
    end
end

function sendcmd( command)--写命令
	LCD_CS(0)
	sendbit_high(0x80,3)
	sendbit_high(command,8)
	sendbit_high(0x0,1)
	LCD_CS(1)
end

function write_1621( addr, data)--写地址和数据
	LCD_CS(0)
	sendbit_high(0xa0,3)
	sendbit_high(bit.lshift(addr, 2),6)
	sendbit_low(data,4)
	LCD_CS(1)
end

local coLcdTask = sys.taskInit(function()
    local i=0
    _pac=0x00
    
    LCD_VCC(1)--打开电源
    pmd.ldoset(15,pmd.LDO_VLCD)
	pmd.ldoset(15,pmd.LDO_VBACKLIGHT_R)

    sendcmd(RC256)
    sendcmd(BIAS)
    sendcmd(SYSEN)
    sendcmd(LCDON)

	local digno=0
    while true do

		--test code by JWL
        local tmpd=0
		DISPMEM[1] = DIGITS[ tostring(digno)]
		DISPMEM[2] = DIGITS[ tostring(digno)]
		DISPMEM[3] = DIGITS[ tostring(digno)]
		DISPMEM[4] = DIGITS[ tostring(digno)]
		DISPMEM[5] = DIGITS[ tostring(digno)]
		DISPMEM[6] = DIGITS[ tostring(digno)]
		DISPMEM[7] = 0x08 --只显示“元”

		log.info("tostring(digno)", tostring(digno),  string.format("%X" ,DISPMEM[1]))

		digno = digno +1
		if digno>=10 then  digno =0 end

        for i=1,#DISPMEM do  
			tmpd =  bit.band( DISPMEM[i],0x0F)
			write_1621( (i-1) *2 +0,tmpd)

			tmpd =  bit.band( DISPMEM[i],0xF0)
			tmpd =  bit.rshift(tmpd,4)

			if digno %2 ==0 and  i~=7  then 
				tmpd = bit.bor(tmpd,0x01)
			end

			write_1621( (i-1) *2 +1,tmpd)
		end

		sys.wait(800)
    end
end)