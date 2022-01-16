
module(...,package.seeall)

local i2cid,intregaddr = 0,0x57
local initstr,indcnt1,indcnt2 = "",0,0

local function clrint()
	print("shk.clrint 1")
	--if pincfg.GSENSOR() == 0 then
		print("shk.clrint 2")
		i2c.write(i2cid,0x1E,0x05)
		local rlt = i2c.read(i2cid,intregaddr,1)
		i2c.write(i2cid,0x1E,0x00)
		print("shk.clrint rlt",rlt,string.format("%02X",string.byte(rlt)))
	--end
end

local function init2()
	local cmd,i = {0x20,0x37,0x21,0x11,0x22,0x40,0x23,0xC8,0x25,0x02,0x30,0x7F,0x32,0x02}
	
	for i=1,#cmd,2 do
		i2c.write(i2cid,cmd[i],cmd[i+1])
		print("shk.init2",string.format("%02X",cmd[i]),string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))))
		initstr = initstr..","..(string.format("%02X",cmd[i]) or "nil")..":"..(string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))) or "nil")
	end
	clrint()
end

local function checkready()
	local s = i2c.read(i2cid,0x1D,1)
	print("shk.checkready",s,(s and s~="") and string.byte(s) or "nil")
	if s and s~="" then
		if bit.band(string.byte(s),0x80)==0 then
			init2()
			return
		end
	end
	sys.timerStart(checkready,1000)
end

local function init()
	local i2cslaveaddr = 0x18
	
	if i2c.setup(i2cid,i2c.SLOW,i2cslaveaddr) ~= i2c.SLOW then
		print("shk.init fail")
		initstr = "fail"
		return
	end
	i2c.write(i2cid,0x1E,0x05)
	local sl_val = i2c.read(i2cid,0x57,1)
	sl_val = bit.bor(string.byte(sl_val),0x40)
	i2c.write(i2cid,0x57,sl_val)
	init2()
	--sys.timerStart(checkready,1000)
end

local function init3()
	i2c.write(i2cid,0x1D,0x80)
	sys.timerStart(checkready,1000)
end

function checkabnormal()
	print(nil,"shk.checkabnormal")
	local val = i2c.read(i2cid,0x1B,1)
	if not val or val=="" or string.byte(val)~=0xDA then
		print(nil,"shk.checkabnormal 0x1B")
		--i2c.close(i2cid)
		init3()
		init()
		return
	end	
end

function getdebugstr()
	return initstr..";".."indcnt1:"..indcnt1..";".."indcnt2:"..indcnt2
end

function ind(data)
	print("shk.ind",data,cpu.INT_GPIO_NEGEDGE)
	if data ==  cpu.INT_GPIO_NEGEDGE then  --ÏÂ½µÑØÖÐ¶Ï
		clrint()
		print("shk.ind DEV_SHK_IND")
		sys.publish("DEV_SHK_IND")
	end
end

init()
sys.timerLoopStart(clrint,30000)
--sys.timerLoopStart(checkabnormal,300000)
