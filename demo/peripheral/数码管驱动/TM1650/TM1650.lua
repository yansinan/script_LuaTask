module(..., package.seeall)
require "utils"
require "i2c"
require "log"
require "misc"
require "pack"


--注意：此处的i2cslaveaddr是7bit地址
--如果i2c外设手册中给的是8bit地址，需要把8bit地址右移1位，赋值给i2cslaveaddr变量
--如果i2c外设手册中给的是7bit地址，直接把7bit地址赋值给i2cslaveaddr变量即可
--发起一次读写操作时，启动信号后的第一个字节是命令字节
--命令字节的bit0表示读写位，0表示写，1表示读
--命令字节的bit7-bit1,7个bit表示外设地址
--i2c底层驱动在读操作时，用 (i2cslaveaddr << 1) | 0x01 生成命令字节
--i2c底层驱动在写操作时，用 (addr[1] << 1) | 0x00 生成命令字节




local  off   =0x00--关闭显示
local  on    =0x01--打开显示
local  seven =0x08--
local  eight =0x00


local i2cid = 2
local addr = {0x34, 0x35, 0x36, 0x37}--分别用于第一、第二、第三、第四个数 + 亮度设置，地址需右移一位
-- local addr2 = {0x68, 0x6A, 0x6C, 0x6E, 0x48}--分别用于第一、第二、第三、第四个数 + 亮度设置
--7段数码屏
local NUM_7 = {0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f,0x77,0x7c,0x39,0x5e,0x79,0x71,0x00}--数码管显示8段0~f对应的值
--8段数码屏
local NUM_8 = {0xBF, 0x86, 0xDB, 0xCF, 0xE6, 0xED, 0xFD, 0x87, 0xFF, 0xEF,0xf7,0xfc,0xb9,0xde,0xf9,0xf1,0x00}--数码管显示8段0~f对应的值




local function i2c_open()
    if i2c.setup(i2cid, i2c.SLOW) ~= i2c.SLOW then
        log.error("TM1650", "I2C.init is: fail")
        i2c.close(i2cid)
        return
    else
        log.error("TM1650", "I2C.init is: succeed")
    end
    return i2c.SLOW
end


---------------------------------------------数码管显示--------------------------------------

 



----------------------------------key demo test-----------------------------------------------------
local key = {
                {11,12,13,14},
                {21,22,23,24},
                {31,32,33,34},
                {41,42,43,44},
                {51,52,53,54},
                {61,62,63,64},
                {71,72,73,74}

            }


local value = {

                {0x44,0x45,0x46,0x47},
                {0x4C,0x4D,0x4E,0x4F},
                {0x54,0x55,0x56,0x57},
                {0x5C,0x5D,0x5E,0x5F},
                {0x64,0x65,0x66,0x67},
                {0x6C,0x6D,0x6E,0x6F},
                {0x74,0x75,0x76,0x77},
                
            }

local i2cid=2
--local revData,key_name
function TM1650_Gate_KEY()
	
    i2c.send(i2cid, 0x24,0x01)--开显示
    local revData = i2c.recv(i2cid,0x24,1)--读按键数据
 
    --转成number
    local _,keyname=pack.unpack(revData, 'b1')
    if keyname  ~= nil then
      -- log.info("********************",keyname,type(keyname))
      -- log.info("keypad test********************")
        for i=1,7 do
            for j=1,4 do
              
                 if  (keyname == value[i][j]) then
                    
                   local keyname = key[i][j]
                    log.info("key_value--------------", keyname)
                    return keyname
                
                end

            end
        end
            
    end
  
end

sys.taskInit(function()
    
    
    local slot,dspcnt=0,0
    sys.wait(3000)

    i2c_open()

    while true do

        sys.wait(100)
        slot = slot+1

        if slot %10 ==0 then
            dspcnt = dspcnt +1

            for k=1,#addr do
                i2c.send(i2cid, 0x24,0x01)
                i2c.send(i2cid, addr[k], 0x00)
            end

            for i=1,#addr do 
                i2c.send(i2cid, 0x24,0x01)
                i2c.send(i2cid, addr[i],NUM_8[dspcnt%17 +1])

            end
        end
 

        --按键读取测试
       TM1650_Gate_KEY()

     end

end)

-- --数码显示
-- sys.timerLoopStart(TM1650_Write, 2000)


