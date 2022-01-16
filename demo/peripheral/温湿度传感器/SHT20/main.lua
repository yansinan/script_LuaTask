--必须在这个位置定义PROJECT和VERSION变量
--PROJECT：ascii string类型，可以随便定义，只要不使用,就行
--VERSION：ascii string类型，如果使用Luat物联云平台固件升级的功能，必须按照"X.X.X"定义，X表示1位数字；否则可随便定义
PROJECT = "SHT20"
VERSION = "0.0.1"
-- 日志级别
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE
require "sys"
require "utils"
require "patch"
require "pins"

-- 控制台
require "console"
console.setup(2, 115200)

-- 系统工具
require "misc"
require "errDump"

-- 系統指示灯
require "SHT20"
-- 启动系统框架
sys.init(0, 0)
sys.run()
