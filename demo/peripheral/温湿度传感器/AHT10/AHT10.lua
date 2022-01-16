--- 模块功能：AHT10功能测试.
-- @module i2c
-- @author openLuat
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.8.10
local function i2c_open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("I2C.init is: ", "fail")
    end
end

function readAHT10()
    local id = 2
    i2c_open(id)
    --数值查询，发送指令0xAC, 0x22, 0x00,通过iic发送完毕之后，AHT10返回的数值是6个字节的数组
    i2c.send(id, 0x38, {0xAC, 0x22, 0x00})
    --等待75毫秒以上
    --rtos.sleep(80)
    --1[状态位],2[湿度第一段],3[湿度第二段],4前四位[湿度第三段],4后四位[温度第一段],5[温度第二段],6[温度第三段]
    local data = i2c.recv(id, 0x38, 6)
    log.info("i2cdata", #data, data:toHex())
    i2c.close(id)
    if #data == 6 then
        local _, _, data2, data3, data4, data5, data6 = pack.unpack(data, "b6")
        local hum = bit.bor(bit.bor(bit.lshift(data2, 12), bit.lshift(data3, 4)), bit.rshift(data4, 4))/ 1048576 * 10000
        log.info("hum", hum/100 )
        local tmp = bit.bor(bit.bor(bit.lshift(bit.band(data4, 0x0f), 16), bit.lshift(data5, 8)), data6) / 1048576 * 20000 - 5000
        log.info("tmp", tmp/100)
        --前面将数据放大了100倍，方便没有float的固件保留精度，在使用float固件时直接缩小100倍还原
        --return tmp, hum
        return tmp/100, hum/100
    else
        return 0, 0
    end
end

sys.timerLoopStart(readAHT10,2000)