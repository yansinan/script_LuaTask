-- zip 解压缩
PROJECT = "ZIP"
VERSION = "2.0.0"

require "log"
require "sys"

-- require "unzip"

-- 需要 float 版本支持
zip = require "zzlib"

sys.taskInit(function ()
    sys.wait(8000)

    file = io.open("/lua/ascii.zip", "rb")
    output = zip.unzip(file:read("*a"), "a.txt")
    log.info("ascii", string.toHex(output or ""))

    file = io.open("/lua/bin.zip", "rb")
    output = zip.unzip(file:read("*a"), "a.txt")
    log.info("ascii", string.toHex(output or ""))

end)

--启动系统框架
sys.init(0, 0)
sys.run()
