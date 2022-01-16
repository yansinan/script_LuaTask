module(..., package.seeall)
----GT911

require "misc"
require "utils"
require "pins"

local GT911addr = 0x14
local i2cid = 2

local rst = pins.setup(23, 1)
local int = pins.setup(19)

local function init()
    if i2c.setup(i2cid, i2c.SLOW) ~= i2c.SLOW then
        print("i2c.init fail")
        return
    end
    -------------------------初始化-------------------------
    rst(0)
    int(1)
    sys.wait(10)
    rst(1)
    sys.wait(10)
    int(0)
    sys.wait(55)
    sys.wait(50)
end
sys.taskInit(init)

local ispress = false
local last_x, last_y
x = 0
y = 0



function get()
    
        i2c.send(i2cid, GT911addr, string.char(0x81, 0x4e))
        pressed = i2c.recv(i2cid, GT911addr, 1)
        if pressed:byte()==nil then
            return false, false, -1, -1    
        end
        pressed = bit.band(pressed:byte(), 0x0f)
        i2c.send(i2cid, GT911addr, string.char(0x81, 0x4e, 0x00, 0x00))
        if pressed == 0 then
            if ispress == false then
                -- _G.iCool_standByTimeoutSleepScreen()
                return false, false, -1, -1
            end

            ispress = false
            -- log.info("ispress x,y ", ispress, x, y)
            return true, ispress, x, y
        end
            i2c.send(i2cid, GT911addr, string.char(0x81, 0x51))
            xh = i2c.recv(i2cid, GT911addr, 1):byte()
            i2c.send(i2cid, GT911addr, string.char(0x81, 0x50))
            xl = i2c.recv(i2cid, GT911addr, 1):byte()

            i2c.send(i2cid, GT911addr, string.char(0x81, 0x53))
            yh = i2c.recv(i2cid, GT911addr, 1):byte()
            i2c.send(i2cid, GT911addr, string.char(0x81, 0x52))
            yl = i2c.recv(i2cid, GT911addr, 1):byte()
            x = xl + (xh * 256)
            y = yl + (yh * 256)
        if ispress == true and last_x == x and last_y == y then
                return false, false, -1, -1
            end
            ispress = true
            last_x = x
            last_y = y
            -- log.info("ispress x,y ", ispress, x, y)
            return true, ispress, x, y
    end
