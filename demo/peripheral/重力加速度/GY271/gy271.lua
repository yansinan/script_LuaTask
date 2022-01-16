module(..., package.seeall)

id = 2
addr = 0x1E
sys.taskInit(function()
    sys.wait(3000)
    local abc = i2c.setup(id, 100000, addr)
    log.info("i2c通道开启返回值", abc)
    i2c.send(id, addr, {0x02, 0x00})
    sys.wait(70)
    i2c.send(id, addr, {0x01, 0x20})
    sys.wait(70)
    while true do
        i2c.send(id, addr, {0x02, 0x01})
        i2c.send(id, addr, {0x03})
        sys.wait(70)
        local abc = i2c.recv(2, addr, 6)
        _, x, z, y = pack.unpack(abc, ">hhh")
        log.info("x", x)
        log.info("y", y)
        log.info("z", z)
        sys.wait(500)
    end
end)
