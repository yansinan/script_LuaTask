
module(..., package.seeall)

require "pins"

pmd.ldoset(15, pmd.LDO_VMMC)

local STB = pins.setup(pio.P0_24, 1, pio.PULLUP) -- TF_cmd
local CLK = pins.setup(pio.P0_25, 1, pio.PULLUP) -- TF_D0
local DIO = pins.setup(pio.P0_26, 1, pio.PULLUP) -- TF_D1

typeTable = {
    0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c,
    0x39, 0x5e, 0x79, 0x71
};

function SEND(data)
    for i = 0, 7, 1 do
        local mbit = bit.isset(data, i) and 1 or 0
        CLK(0)
        DIO(mbit)
        CLK(1)
    end
end

function Command(data)
    STB(0)
    SEND(data)
    STB(1)
end

function init()
    Command(0x8f)
    Command(0x40)
    STB(0)
    SEND(0xc0) ----清0
    for j = 1, 16, 1 do SEND(0x00) end
    STB(1)
end
function READKEY()
    local temp = {}
    STB(0)
    SEND(0x42)
    for i = 1, 4, 1 do
        Byte = ""
        for j = 1, 8, 1 do
            CLK(0)
            t = DIO()
            Byte = Byte .. t
            CLK(1)
        end
        temp[i] = tonumber(Byte, 2)
    end
    STB(1)
    return temp
end
---------------------------------------------------测试DEMO--------------------------------------
function NumLight(addr, tab)
    STB(0)
    SEND(addr)
    SEND(tab)
    STB(1)
end

function TM1638Disp()
    init()
    Command(0x44)
    for i = 0, 7, 1 do
        NumLight(0xc0 + (i * 2), typeTable[i + 2])
        sys.wait(200)
    end

    for i = 1, #typeTable, 1 do
        for j = 0, 7, 1 do NumLight(0xc0 + (j * 2), typeTable[i]) end
        sys.wait(200)
    end

end

function keyDemo()
    while true do
        for index, value in ipairs(READKEY()) do
            if bit.isset(value, 7) then
                NumLight(0xc0 + ((index - 1) * 2), typeTable[index + 1])
                NumLight(0xc0 + ((index - 1) * 2) + 1, 0xff)
            else
                NumLight(0xc0 + ((index - 1) * 2), 0x00)
                NumLight(0xc0 + ((index - 1) * 2) + 1, 0x00)
            end
            if bit.isset(value, 3) then
                NumLight(0xc8 + ((index - 1) * 2), typeTable[index + 1 + 4])
                NumLight(0xc8 + ((index - 1) * 2) + 1, 0xff)
            else
                NumLight(0xc8 + ((index - 1) * 2), 0x00)
                NumLight(0xc8 + ((index - 1) * 2) + 1, 0x00)
            end
        end
        sys.wait(50)
    end
end

sys.taskInit(function()
    TM1638Disp()
    keyDemo()
end)
