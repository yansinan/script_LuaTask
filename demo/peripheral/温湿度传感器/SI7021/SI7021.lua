module(..., package.seeall)
--- 模块功能：SI7021温湿度传感器
-- @author openLuat
-- @module SI7021
-- @license MIT
-- @copyright openLuat
-- @release 2021.6.2
sys.taskInit(
    function()
        sys.wait(6000)
        log.info("test start")
        i2c.setup(2, 100000, 0x40)
        while true do
            local temp, humi
            i2c.send(2, 0x40, 0xF3)
            sys.wait(200)

            local rawTemp = i2c.recv(2, 0x40, 3)
            local temp_h, temp_l = string.byte(rawTemp ,1), string.byte(rawTemp ,2)
            if temp_h and temp_l then
                temp = temp_h * 256 + temp_l
                temp = ((175.72 * temp) / 65536) - 46.85
            else
                log.info("没温度")
            end
           
            sys.wait(200)

            i2c.send(2, 0x40, 0xF5)
            sys.wait(200)
            local rawHumi = i2c.recv(2, 0x40, 3)
            local humi_h, humi_l = rawHumi:byte(1), rawHumi:byte(2)
            if humi_h and humi_l then
                humi = humi_h * 256 + humi_l
                humi = ((125 * humi) / 65536) - 6
            else
                log.info("没湿度")
            end

            if temp and humi then
                log.info("测量数据","温度:", temp - temp % 0.01 .. "°C", "湿度:", humi - humi % 0.01 .. "%RH")
            else
                log.info("没测量数据")
            end
            sys.wait(200)
            --i2c.close(2)
        end
    end
)