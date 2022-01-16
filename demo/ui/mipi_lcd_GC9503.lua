--- 模块功能：ILI9806E驱动芯片LCD命令配置
-- @author openLuat
-- @module ui.mipi_lcd_GC9503V
-- @license MIT
-- @copyright openLuat
-- @release 2021.09.01

--[[
注意：MIPI接口

module(...,package.seeall)
]]
--[[
函数名：init
功能  ：初始化LCD参数
参数  ：无
返回值：无
]]
local function init()
    local para =
    {
		width = 480, --分辨率宽度，
		height = 854, --分辨率高度
		bpp = 16, --MIPI LCD直接写16，暂不支持其他配置
		bus = disp.BUS_MIPI, --LCD专用SPI引脚接口，不可修改
		xoffset = 0, --X轴偏移
		yoffset = 0, --Y轴偏移
		freq = 200000000, --mipi时钟最高为500000000 最低为125000000
		pinrst = pio.P0_20, --reset，复位引脚,MIPI屏幕必须填写
		pinrs = 0xffff, --mipi不需要rs脚，直接写0xffff

		---- porch_vs porch_vbp porch_vfp porch_hs porch_hbp porch_hfp 这6个参数可以不配置
		---- 软件有默认的配置。一般mipi屏会兼容多套参数。也可以根据厂商提供的参数进行修改
		---- （480+30+30+10）*（854+15+8+2）* 16
		porch_vs = 2,
		porch_vbp = 15, 
		porch_vfp = 8,
		porch_hs = 10,
		porch_hbp = 30,
		porch_hfp = 30,

		-- continue_mode 可以不配置底层默认为0. 配置后一直处于高速continue 模式
		continue_mode = 1,

		--初始化命令
		--前两个字节表示类型：0001表示延时，0000或者0002表示命令，0003表示数据
		--延时类型：后两个字节表示延时时间（单位毫秒）
		--命令类型：后两个字节命令的值
		--数据类型：后两个字节数据的值
		--现在MIPI LCD 只支持,lane 2线,RGB565格式
       
		initcmd =
        {

			0x000200F0, 0x00030055, 0x000300AA, 0x00030052, 0x00030008, 0x00030000,

			0x000200F6, 0x0003005A, 0x00030087,

			0x000200C1, 0x0003003F,

			0x000200C2, 0x0003000E,

			0x000200C6, 0x000300F8,

			0x000200C9, 0x00030010,

			0x000200CD, 0x00030025,

			0x00020087, 0x00030004, 0x00030003, 0x00030066,

			0x00020086, 0x00030099, 0x000300a3, 0x000300a3, 0x00030051,

			0x000200F8, 0x0003008A,

			0x000200AC, 0x00030065,

			0x000200A7, 0x00030047,

			0x000200A0, 0x000300DD,
			0x000200FA, 0x00030008, 0x00030008, 0x00030000, 0x00030004,

			0x000200A3, 0x0003002E,

			0x000200FD, 0x00030028, 0x0003003c, 0x00030000,
			0x00020071, 0x00030048,

			0x00020072, 0x00030048,

			0x00020073, 0x00030000, 0x00030044,

			0x00020097, 0x000300EE,

			0x00020083, 0x00030093,

			0x0002009A, 0x00030084,

			0x0002009B, 0x00030054,

			0x00020082, 0x0003005d, 0x0003005d,

			0x000200B1, 0x00030010,

			0x0002007A, 0x00030013, 0x0003001A,

			0x0002007B, 0x00030013, 0x0003001A,

			0x00020064, 0x00030018, 0x00030009, 0x00030003, 0x00030059, 0x00030003, 0x00030003, 0x00030018, 0x00030008, 0x00030003, 0x0003005A, 0x00030003, 0x00030003, 0x0003007A, 0x0003007A, 0x0003007A, 0x0003007A,

			0x00020067, 0x00030018, 0x00030007, 0x00030003, 0x0003005B, 0x00030003, 0x00030003, 0x00030018, 0x00030006, 0x00030003, 0x0003005C, 0x00030003, 0x00030003, 0x0003007A, 0x0003007A, 0x0003007A, 0x0003007A,

			0x00020068, 0x00030000, 0x00030008, 0x0003000A, 0x00030008, 0x00030009, 0x00030000, 0x00030000, 0x00030008, 0x0003000A, 0x00030008, 0x00030009, 0x00030000, 0x00030000,

			0x00020060, 0x00030018, 0x00030008, 0x0003007A, 0x0003007A, 0x00030018, 0x00030002, 0x0003007A, 0x0003007A,

			0x00020063, 0x00030018, 0x00030002, 0x0003006D, 0x0003006D, 0x00030018, 0x00030007, 0x0003007A, 0x0003007A,

			0x00020069, 0x00030014, 0x00030022, 0x00030014, 0x00030022, 0x00030044, 0x00030022, 0x00030008,

			0x000200D1, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x000200D2, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x000200D3, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x000200D4, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x000200D5, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x000200D6, 0x00030000, 0x00030000, 0x00030000, 0x00030008, 0x00030000, 0x0003001D, 0x00030000, 0x0003005F, 0x00030000, 0x00030091, 0x00030000, 0x000300CE, 0x00030000, 0x000300F5, 0x00030001, 0x0003002B, 0x00030001, 0x0003007f, 0x00030001, 0x000300ed, 0x00030002, 0x00030023, 0x00030002, 0x00030078, 0x00030002, 0x000300b2, 0x00030002, 0x000300b4, 0x00030002, 0x000300f1, 0x00030003, 0x00030029, 0x00030003, 0x00030049, 0x00030003, 0x0003006d, 0x00030003, 0x00030082, 0x00030003, 0x0003009b, 0x00030003, 0x000300A5, 0x00030003, 0x000300B0, 0x00030003, 0x000300B5, 0x00030003, 0x000300BF, 0x00030003, 0x000300DE, 0x00030003, 0x000300FF,

			0x00020011, 0x00030000,

			0x00020029, 0x00030000,


			
        },
        --休眠命令
        sleepcmd = {
	    	0x00020028,
            0x00020010,
        },
        --唤醒命令
        wakecmd = {
        	0x00020011,
	    	0x00020029,
        }
    }
    disp.init(para)
    disp.clear()
    disp.update()
end

-- VLCD电压域配置
pmd.ldoset(15,pmd.LDO_VIBR)

-- 背光配置
function backlightopen(on)
	if on then
		pins.setup(pio.P0_8,1)
		log.info("mipi_lcd_GC9503V 你打开了背光")
	else
		pins.setup(pio.P0_8,0)
		log.info("mipi_lcd_GC9503V 你关闭了背光")
	end
end
backlightopen(true)
-- 初始化
init()
