 

sys.taskInit(
    -- can定时清中断.





    function()
        sys.waitUntil("SPI_INIT_OK")
        while true do
            -- testSpiFlash.sampleCan()
          --  testSpiFlash.interrupFlagClear()
            sys.wait(1000)
        end
    end
)

sys.taskInit(
    -- can定时清中断.
    function()

        sys.wait(5000)

        testSpiFlash.init_my()



        sys.waitUntil("SPI_INIT_OK")
        while true do
            -- testSpiFlash.sampleCan()
            local canbuf = {0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x07}

            --18 FF 26 32
            testSpiFlash.Period_CAN_Send(0x18FF2631, canbuf) --0xF001
            sys.wait(1000)
        end
    end
)

sys.taskInit(
    function()
        local uploadTimePeriod = 5000
        local timerCount = 0
        local extdCanEnbale = true
        sys.waitUntil("SPI_INIT_OK")
        --while true do
            --local uptable = {}
           -- local table = _G.canTable
            --if next(table) ~= nil and next(table) ~= "" then
                --for k, v in pairs(table) do
                   -- log.info("table data list is", k:toHex(), v:toHex())
                    --local nextpos, canid, candata
                    --canid, candata = k, v
                    --nextpos, canid = pack.unpack(canid, ">I")
                    --canid = testSpiFlash.reg2canid(canid, extdCanEnbale)
                    --log.info("receive can id is", string.format("%08X", canid))
                    --local canidStr = string.format("%08X", canid)
                    --uptable[canidStr] = v:toHex() --放入到上报table中

                    --table[k] = nil --清空当前键值.
                --end
            --end
            -- log.info("can frame is receied", result, list)
           -- if next(uptable) ~= nil then
               --local str = json.encode(uptable)
               -- str = create.LuaReomve(str, "\\")
               -- log.info("upload json data is", str)
                --sys.publish("NET_SENT_RDY_" .. "1", str)
            --end

            --[[ local table
            for k, v in pairs(uploadJson) do
                -- log.info("data is", k, v)
                if next(v) ~= nil then
                    table = v
                    local str = json.encode(table)
                    str = create.LuaReomve(str, "\\")
                    log.info("upload json data is", str)
                    sys.publish("NET_SENT_RDY_" .. "1", str)
                    -- 上传监控服务器时间间隔
                    if timerCount == 0 then
                        sys.publish("NET_SENT_RDY_" .. "3", str)
                    end
                    -- json格式拆包发送时间间隔.
                    sys.wait(1000)
                    log.info("not nil value", k, v)
                end
            end ]]
            log.info("upload task is running")
            sys.wait(uploadTimePeriod)
            timerCount = timerCount + 1
            timerCount = math.fmod(timerCount, 5)
        --end
    end
)
