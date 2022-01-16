module(..., package.seeall)
--- 模块功能：ws2801-LED驱动控制
-- @author openLuat
-- @module SI7021
-- @license MIT
-- @copyright openLuat
-- @release 2021.8.31


--注！！！
--ws2801驱动电平为3.3V
--724开发板引出的spi电平为1.8V,需要转到3.3V才可以正常使用；
--820开发板引出的spi经过板上电平转换到3.3v，将VLCD电压域打开到15用于电平转换；
pmd.ldoset(15, pmd.LDO_VMMC)
pmd.ldoset(15, pmd.LDO_VLCD)
require "pm"
pm.wake("WS2801")
local i, j, k = 1, 1, 1
local ledNmb = 31           --灯的个数
function setColor(r, g, b) return string.char(r, g, b) end
local red = setColor(255, 0, 0)
local green = setColor(0, 255, 0)
local blue = setColor(0, 0, 255)
local white = setColor(255, 255, 255)
local orange = setColor(253, 128, 60)
local pink = setColor(255, 87, 215)
local lightBlue = setColor(0, 255, 255)
local purple = setColor(128, 0, 255)
local tmp = {red, green, blue, white, orange, pink, lightBlue, purple}
local black = setColor(0, 0, 0)

-- 每次打开下面其中一种分支进行测试！！！

-- 单个灯随机，全部一起亮
sys.taskInit(function()
    sys.wait(5000)
    log.info("test start")
    local result = spi.setup(spi.SPI_1, 0, 0, 8, 20000, 1)
    log.info("spi开启结果", result)
    while true do
        local data = ""
        for i = 1, ledNmb do
            local temp = setColor(math.random(0, 255), math.random(0, 255),
                                  math.random(0, 255))
            data = data .. temp
        end
        spi.send(spi.SPI_1, data)
        sys.wait(200)
    end
end)

-- 从头到尾，从尾到头
--[[ sys.taskInit(function()
    sys.wait(5000)
    log.info("test start")
    local result = spi.setup(spi.SPI_1, 0, 0, 8, 20000, 1)
    log.info("spi开启结果", result)
    while true do
        local temp = i % 2
        if temp == 1 then
            for i = 1, ledNmb do
                spi.send(spi.SPI_1 , string.rep(tmp[k], i))
                sys.wait(10)
            end
        elseif temp == 0 then
            if k - 1 == 0 then
                for j = 1, ledNmb do
                    spi.send(spi.SPI_1, string.rep((tmp[#tmp]), ledNmb - j) .. string.rep(tmp[k], j))
                    sys.wait(10)
                end
            else
                for j = 1, ledNmb do
                    spi.send(spi.SPI_1, string.rep((tmp[k - 1]), ledNmb - j) .. string.rep(tmp[k], j))
                    sys.wait(10)
                end
            end
        end
        i = i + 1
        k = k + 1
        if k > #tmp then
            k = 1
        end
    end
end) ]]

-- 全部随机颜色
--[[ sys.taskInit(function()
    sys.wait(5000)
    log.info("test start")
    local result = spi.setup(spi.SPI_1, 0, 0, 8, 20000, 1)
    log.info("spi开启结果", result)
    while true do
        local data = setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
        spi.send(spi.SPI_1, string.rep(data, ledNmb))
        sys.wait(200)
    end
end) ]]

-- 从中间到两边，从两边到中间
--[[ sys.taskInit(function()
    sys.wait(5000)
    log.info("test start")
    local result = spi.setup(spi.SPI_1, 0, 0, 8, 20000, 1)
    log.info("spi开启结果", result)
    while true do
        local data = ""
        if k > #tmp then k = 1 end
        -- data = string.rep(black, 15) .. white .. string.rep(black, 15)
        for i = 0, ledNmb / 2 do
            if k - 1 == 0 then
                data = string.rep(tmp[#tmp], i) ..
                           string.rep(tmp[1], ledNmb - 2 * i) ..
                           string.rep(tmp[#tmp], i)
                -- elseif k - #tmp == 0 then
                --    data = string.rep(tmp[1], i) .. string.rep(tmp[k], ledNmb - 2 * i) .. string.rep(tmp[1], i)
            else
                data = string.rep(tmp[k - 1], i) ..
                           string.rep(tmp[k], ledNmb - 2 * i) ..
                           string.rep(tmp[k - 1], i)
            end
            spi.send(spi.SPI_1, data)
            sys.wait(50)
        end

        for i = 0, ledNmb / 2 do
            if k - #tmp == 0 then
                data = string.rep(tmp[k - 1], ledNmb / 2 - i) ..
                           string.rep(tmp[1], 1 + 2 * i) ..
                           string.rep(k - 1, ledNmb / 2 - i)
            elseif k - 1 == 0 then
                data = string.rep(tmp[#tmp], ledNmb / 2 - i) ..
                           string.rep(tmp[k + 1], 1 + 2 * i) ..
                           string.rep(tmp[#tmp], ledNmb / 2 - i)
            else
                data = string.rep(tmp[k - 1], ledNmb / 2 - i) ..
                           string.rep(tmp[k + 1], 1 + 2 * i) ..
                           string.rep(tmp[k - 1], ledNmb / 2 - i)
            end
            spi.send(spi.SPI_1, data)
            sys.wait(50)
        end

        k = k + 1
    end
end) ]]

-- 声控灯
--[[ require "record"
local result = spi.setup(spi.SPI_1, 0, 0, 8, 20000, 1)
local nm
local function lightUp(num)
    if not num then
        return
    end
    local tmp = {}
    for i =1, ledNmb do
        if i <= num then 
            table.insert(tmp, i, string.char(255,0,0))
        else
            table.insert(tmp, i, string.char(0, 0, 0))
        end
    end
    --log.info("这里是测试", table.concat(tmp):toHex())
    return table.concat(tmp)
end
record.start(0x7FFFFFFF,function (result,size,tag)
    if result and tag=="STREAM" then
        local s = audiocore.streamrecordread(size)
        --print("s的长度", #s)
        if #s < 100 then return end
        temp = {}
        for i=1,50 do
            local d = s:byte(i*2)--低八位数据用不上。。
            if d > 127 then d = - d + 256 end
            d = d * ledNmb / 127
            nm = d
        end
    end
end,"STREAM",0,audiocore.PCM,200)

sys.timerLoopStart(function() spi.send(spi.SPI_1, lightUp(nm)) end, 10) ]]



-- 炫彩声控灯
--[[ spi.setup(spi.SPI_1,0,0,8,20000,1,0)

local function onLight(lights,r,g,b)
    local temp = {}
    for i=1,#lights do
        table.insert(temp,lights[i] and string.char(r,g,b) or string.char(0x00,0x00,0x00))
    end
    return table.concat(temp)
end

--前n个灯，点亮
local function makeOn(n)
    local temp = {}
    for i=1,ledNmb do
        temp[i] = i<=n
    end
    return temp
end

--local max = 0
local now = 0

require"record"
record.start(0x7FFFFFFF,function (result,size,tag)
    if result and tag=="STREAM" then
        local s = audiocore.streamrecordread(size)
        if #s < 100 then return end
        local tm = 0
        for i=1,50 do
            local d = s:byte(i*2)--低八位数据用不上。。
            if d > 127 then d = - d + 256 end
            d = d * ledNmb / 127
            if d > tm then tm = d end
        end
        now = tm
    end
end,"STREAM",0,audiocore.PCM,100)

sys.timerLoopStart(function()
    local nl = makeOn(now)
    -- if max > now then
    --     max = max - 1
    -- end
    -- if max < now then
    --     max = now
    -- end
    -- nl[max] = true
    --log.info("now,max",now,max)
    local r,g,b = 0,0,0
    if now <= 10 then
        r = 0xff - now * 0xff / 10
        b = now * 0xff / 10
    elseif now <= 20 then
        b = 0xff - (now - 10) * 0xff / 10
        g = (now - 10) * 0xff / 10
    else
        r = (now - 20) * 0xff / 10
        if r > 0xff then r = 0xff end
        g = 0xff - (now - 20) * 0xff / 10
        if g < 0 then g = 0 end
    end
    spi.send(spi.SPI_1,onLight(nl,r,g,b))
end,20) ]]
