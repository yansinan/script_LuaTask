module(..., package.seeall)

require "pins"

pmd.ldoset(15, pmd.LDO_VMMC)

local CLK = pins.setup(pio.P0_25, 1, pio.PULLUP) -- TF_D0
local DIO = pins.setup(pio.P0_26, 1, pio.PULLUP) -- TF_D1

typeTable = {
    0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c,
    0x39, 0x5e, 0x79, 0x71
};

function SEND(data)
    for i = 0, 7, 1 do
        CLK(0)

        local mbit = bit.isset(data, i) and 1 or 0
        DIO(mbit)

        CLK(1)
    end

    CLK(0)
    DIO(1)

    CLK(1)
    mack = DIO()
    if mack == 0 then DIO(0) end
    CLK(0)
end

function start()
    DIO(0)
    sys.wait(5)
end

function stop()
    DIO(0)
    CLK(1)
    DIO(1)
end

---------------------------------------------------测试DEMO--------------------------------------
sys.taskInit(function()
    start()
    SEND(0x8f)
    stop()

    start()
    SEND(0x40) -- 地址模式
    stop()

    start()
    SEND(0xc0)
    for i = 1, 4 do SEND(0x00) end
    stop()

    while true do
        for i = 1, #typeTable do
            start()
            SEND(0xc0)
            for j = 1, 4 do SEND(typeTable[i]) end
            stop()
            sys.wait(1000)
        end
    end

end)

