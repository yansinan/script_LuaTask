--- 模块功能：SPI接口的CAN控制器
--- 默认启用SPI1,pin8,10,11,12,17,18
-- @author openLuat
-- @module spi.testSpiFlash
-- @license
-- @copyright
-- @release 2019.02.27

module(..., package.seeall)

require "utils"
require "pins"
-- listbase = require "ring"
-- local rf = require "receive"
-- rf.list = "test"
-- list = listbase:new()
--[[
注意：此demo测试过程中，硬件上使用的是标准的SPI_1引脚
硬件连线图如下：
Air模块--CAN模块
GND--GND
SPI_CS--CS
SPI_CLK--CLK
SPI_DO--DI
SPI_DI--DO
VDDIO--VCC
]]
local SPIRESET = 0xC0
local SPIREAD = 0x03
local SPIREADRX = 0x90
local SPIWRITE = 0x02
local SPIWRITETX = 0x40
local SPIRTS = 0x80
local SPIREADSTATUS = 0xA0
local SPIRXSTATUS = 0xB0
local SPIBITMODIFY = 0x05
--[[
 * @brief	Adressen der Register des MCP2515
 *
 * Die Redundanten Adressen von z.B. dem Register CANSTAT ( 0x0E, 0x1E, 0x2E, ... ) wurden
 * dabei nicht mit aufgelistet.
 ]]
local RXF0SIDH = 0x00

local RXF1SIDH = 0x04

local RXF2SIDH = 0x08

local BFPCTRL = 0x0C
local TXRTSCTRL = 0x0D
local CANSTAT = 0x0E
local CANCTRL = 0x0F

local RXF3SIDH = 0x10
local RXF4SIDH = 0x14
local RXF5SIDH = 0x18

local TEC = 0x1C
local REC = 0x1D

local RXM0SIDH = 0x20
local RXM1SIDH = 0x24

local CNF3 = 0x28
local CNF2 = 0x29
local CNF1 = 0x2A
local CANINTE = 0x2B
local CANINTF = 0x2C
local EFLG = 0x2D

local TXB0CTRL = 0x30
local TXB1CTRL = 0x40
local TXB2CTRL = 0x50
local RXB0CTRL = 0x60
local RXB1CTRL = 0x70

--[[
 * @brief	Bitdefinition von CNF2
 ]]
local BTLMODE = 7
local SAM = 6
local PHSEG12 = 5
local PHSEG11 = 4
local PHSEG10 = 3
local PHSEG2 = 2
local PHSEG1 = 1
local PHSEG0 = 0
--[[
 * @brief	Bitdefinition von CNF1
 ]]
local SJW1 = 7
local SJW0 = 6
local BRP5 = 5
local BRP4 = 4
local BRP3 = 3
local BRP2 = 2
local BRP1 = 1
local BRP0 = 0
--[[
 * @brief	Bitdefinition von CANINTE
 ]]
local MERRE = 7
local WAKIE = 6
local ERRIE = 5
local TX2IE = 4
local TX1IE = 3
local TX0IE = 2
local RX1IE = 1
local RX0IE = 0
--[[
 * @brief	Bitdefinition von CANINTF
 ]]
local MERRF = 7
local WAKIF = 6
local ERRIF = 5
local TX2IF = 4
local TX1IF = 3
local TX0IF = 2
local RX1IF = 1
local RX0IF = 0
--[[
 * @brief	Bitdefinition von EFLG
 ]]
local RX1OVR = 7
local RX0OVR = 6
local TXB0 = 5
local TXEP = 4
local RXEP = 3
local TXWAR = 2
local RXWAR = 1
local EWARN = 0
--[[
 * @brief	Bitdefinition von TXBnCTRL ( n = 0, 1, 2 )
 ]]
local ABTF = 6
local MLOA = 5
local TXERR = 4
local TXREQ = 3
local TXP1 = 1
local TXP0 = 0
--[[
 * @brief	Bitdefinition von RXB0CTRL
 ]]
local RXM1 = 6
local RXM0 = 5
local RXRTR = 3
local BUKT = 2
local BUKT1 = 1
local FILHIT0 = 0
--[[
 * @brief	Bitdefinition von TXBnSIDL ( n = 0, 1 )
 ]]
local EXIDE = 3
--[[
 * @brief	Bitdefinition von RXB1CTRL
 *
 * @see		RXM1, RXM0, RXRTR und FILHIT0 sind schon für RXB0CTRL definiert
 ]]
local FILHIT2 = 2
local FILHIT1 = 1
--[[
 * @brief	Bitdefinition von RXBnSIDL ( n = 0, 1 )
 ]]
local SRR = 4
local IDE = 3
--[[
 * @brief	Bitdefinition von RXBnDLC ( n = 0, 1 )
 *
 * @see		TXBnDLC   ( gleiche Bits )
 ]]
local RTR = 6
local DLC3 = 3
local DLC2 = 2
local DLC1 = 1
local DLC0 = 0

local CANRTR = 0x80
local CANEID = 0x40

local READ_LENGTH = 14

--- Begin mt
local MCPSIDH = 0
local MCPSIDL = 1
local MCPEID8 = 2
local MCPEID0 = 3

local PRSEG1TQ = 0
local PHSEG13TQ = 16
local PHSEG23TQ = 2


local setGpio10Fnc = pins.setup(pio.P0_10,0)
local function csLow()
  --拉低CS开始传输数据
  -- pio.pin.setval(0, 10)
  setGpio10Fnc(0)
end

local function csHigh()
  --传输结束拉高CS
  -- pio.pin.setval(1, 10)
  setGpio10Fnc(1)
end

local function rxTxLedInit()
  -- -- 接受指示灯
  -- -- pio.pin.close(19)
  -- -- pio.pin.setdir(pio.OUTPUT, 19)
  -- -- pio.pin.setval(0, 19) --初始状态灯灭
  -- -- -- 发送指示灯
  -- pio.pin.close(18)
  -- pio.pin.setdir(pio.OUTPUT, 18)
  -- pio.pin.setval(0, 18) --初始状态灯灭
end
-- 接受灯闪烁
function rxLedFlash()
  -- pio.pin.setval(1, 19)
  -- sys.wait(100) --不能用在定时器函数中.
  -- pio.pin.setval(0, 19)
end
-- 发送灯闪烁
function txLedFlash()
--   pio.pin.setval(1, 18)
--   sys.wait(100) --不能用在定时器函数中.
--   pio.pin.setval(0, 18)
 end
-- 接受灯闪烁二次
function rxLedFlash2Times()
  -- pio.pin.setval(1, 19)
  -- sys.wait(100) --不能用在定时器函数中.
  -- pio.pin.setval(0, 19)
  -- sys.wait(100)
  -- pio.pin.setval(1, 19)
  -- sys.wait(100) --不能用在定时器函数中.
  -- pio.pin.setval(0, 19)
end
-- 发送灯闪烁二次
function txLedFlash2Times()
  -- pio.pin.setval(1, 18)
  -- sys.wait(100) --不能用在定时器函数中.
  -- pio.pin.setval(0, 18)
  -- sys.wait(100)
  -- pio.pin.setval(1, 18)
  -- sys.wait(100) --不能用在定时器函数中.
  -- pio.pin.setval(0, 18)
end
--[[
 *	Bit Timings
 *	
   *	Fosc	   = 8MHz		   8M
 *	BRP 	   = 3					( teilen durch 8 )
 *	TQ = 2 * (BRP + 1) / Fosc		( => 1 µS )
 *	
 *	Sync Seg   = 1TQ
 *	Prop Seg   = ( PRSEG + 1 ) * TQ  = 1 TQ
 *	Phase Seg1 = ( PHSEG1 + 1 ) * TQ = 3 TQ
 *	Phase Seg2 = ( PHSEG2 + 1 ) * TQ = 3 TQ
 *	
 *	Bus speed  = 1 / (Total # of TQ) * TQ
 *			   = 1 / 8 * TQ = 125 kHz
 ]]
--位运算tmd麻烦
function canid2reg(canid, extdEanble)
  --  local canid = "1C1F1714"
  -- local data2, data3
  -- local nextpos, data = pack.unpack(canid:fromHex(), ">I")
  if extdEanble then
    local dataHigh11bit = bit.band(canid, 0x1ffc0000)
    dataHigh11bit = bit.lshift(dataHigh11bit, 3)

    local dataLow18bit = bit.band(canid, 0x3ffff)
    dataLow18bit = bit.set(dataLow18bit, 19) --使能扩展位.

    -- log.info("bit.rshift(dataHigh18bit, 11)", dataLow18bit, dataHigh11bit)
    local reg = dataHigh11bit + dataLow18bit
    local b1, b2, b3, b4
    b1 = bit.band(reg, 0xff)
    b2 = bit.band(bit.rshift(reg, 8), 0xff)
    b3 = bit.band(bit.rshift(reg, 16), 0xff)
    b4 = bit.band(bit.rshift(reg, 24), 0xff)
    -- log.info("can filter reg is", reg, b4, b3, b2, b1)
    return b1, b2, b3, b4
  else
    local reg = bit.lshift(canid, 5)
    local b1, b2
    b1 = bit.band(reg, 0xff)
    b2 = bit.band(bit.rshift(reg, 8), 0xff)
    -- log.info("can filter reg is", reg, b2, b1)
    return b1, b2
  end
end

function reg2canid(reg, extdEanble)
  if extdEanble then
    local dataHigh11bit = bit.band(reg, 0xffe00000)
    dataHigh11bit = bit.rshift(dataHigh11bit, 3)
    local dataLow18bit = bit.band(reg, 0x0003ffff)
    local canid = dataLow18bit + dataHigh11bit
    return canid
  else
    local dataHigh11bit = bit.band(reg, 0xffe00000)
    canid = bit.band(bit.rshift(dataHigh11bit, 21), 0x7ff)
    return canid
  end
end

function canidMask2reg(canidMask, extdEanble)
  --  local canid = "1C1F1714"
  -- local data2, data3
  -- local nextpos, data = pack.unpack(canid:fromHex(), ">I")
  if extdEanble then
    local dataLow11bit = bit.band(canidMask, 0x1ffc0000)
    dataLow11bit = bit.lshift(dataLow11bit, 3)

    local dataHigh18bit = bit.band(canidMask, 0x3ffff)
    dataHigh18bit = bit.set(dataHigh18bit, 19) --使能扩展位.

    -- log.info("bit.rshift(dataHigh18bit, 11)", dataHigh18bit, dataLow11bit)
    local reg = dataLow11bit + dataHigh18bit
    local b1, b2, b3, b4
    b1 = bit.band(reg, 0xff)
    b2 = bit.band(bit.rshift(reg, 8), 0xff)
    b3 = bit.band(bit.rshift(reg, 16), 0xff)
    b4 = bit.band(bit.rshift(reg, 24), 0xff)
    -- log.info("can filter reg is", reg, b4, b3, b2, b1)
    return b1, b2, b3, b4
  else
    local reg = bit.lshift(canidMask, 5)
    local b1, b2
    b1 = bit.band(reg, 0xff)
    b2 = bit.band(bit.rshift(reg, 8), 0xff)
    -- log.info("can filter reg is", reg, b2, b1)
    return b1, b2
  end
end

local function spiInit()
  --打开SPI引脚的供电
  --pmd.ldoset(6,pmd.LDO_VMMC) --3.0v
  -- pmd.ldoset(6, pmd.LDO_VMMC) --3.0v
  -- pmd.ldoset(6, pmd.LDO_VLCD) --3.0v
  --SPI 初始化
  -- local result = spi.setup(spi.SPI_1,0,0,8,812500,1,1)
  local result = spi.setup(spi.SPI_1,0,0,8,1625000,1,1)
  -- local result = spi.setup(spi.SPI_1, 0, 0, 8, 13000000, 1)
  --local result = spi.setup(spi.SPI_1,1,1,8,110000,1)
  log.info("testSpiMCP2515.init", result)
  if result == 1 then
    sys.publish("SPI_INIT_OK")
  end

  --重新配置GPIO10 (CS脚) 配为输出,默认高电平
  pio.pin.close(10)
  pio.pin.setdir(pio.OUTPUT, 10)
  pio.pin.setval(1, 10)

  --pio.pin.close(pio.P0_17)
  --pio.pin.setdir(pio.INPUT,pio.P0_17)

  --pins.setup(pio.P0_17,nil,pio.PULLUP)
  -- 芯片重启
  -- pio.pin.close(26) --724版本无此引脚
  -- pio.pin.setdir(pio.OUTPUT, 26)
  -- pio.pin.setval(0, 26) --反向输出,0--高电平
  -- 芯片重启
  -- pio.pin.close(25)
  -- pio.pin.setdir(pio.INPUT, 25)
  -- pio.pin.setval(0, 26) --反向输出,0--高电平
end

local function refreshTable(frame)
  local candata, canid
  local B0, B1, B2, B3, B4, B5, B6, B7
  local B0B1, B2B3, B4B5, B6B7

  canid = frame:sub(1, 4)
  candata = frame:sub(-8)
  -- local nextpos, canid = pack.unpack(canid, ">I") --转化为寄存器数字，还不是canid
  -- local table = _G.canTable
  -- table[canid] = candata

  --[[   for k, v in pairs(table) do
    log.info("table data list is", k, v)
  end ]]
  -- canid = testSpiFlash.reg2canid(canid, extdCanEnbale)

  print(candata:toHex())
end

function mcp2515_readXXStatus_helper(cmd)
  local status = nil
  csLow()
  spi.send_recv(spi.SPI_1, string.char(cmd))
  local status = spi.recv(spi.SPI_1, 1)
  --status = spi.send_recv(spi.SPI_1,string.char(cmd))
  csHigh()
  -- return string.byte(status)
  return status
end

local function mcp2515_write_register(adress, data)
  csLow()
  spi.send_recv(spi.SPI_1, string.char(SPIWRITE, adress, data))
  --spi.send(spi.SPI_1,string.char(SPIWRITE))
  --spi.send(spi.SPI_1,string.char(adress))
  --spi.send(spi.SPI_1,string.char(data))
  log.info("write reg addr and data", adress, data)
  csHigh()
end

-- E0 EB 17 14    08 00 00 00 00 00 00 00 12  0E
-- E0 EB 17 14    08 00 00 00 00 00 00 00 12  0C
-- 1110 0000 1110 1011 0001 0111 0001 0100
local dataIsReceived = false
local function gpio17IntFnc(msg)
  --[[   local dataNMadress = 0x06 --从0x66开始读取can数据
  local dataNMadress2 = 0x00 ]]
  local dataNMadress = 0x04 --从0x71地址开始读取can数据
  local dataNMadress2 = 0x00
  local canData, canID, canFrame
  -- log.info("---------------------------testGpioSingle.gpio4IntFnc------------------------------", msg, getGpio17Fnc())
  --上升沿中断
  -- log.info("testGpioSingle.gpio4IntFnc", msg, getGpio17Fnc())
 
  if msg == cpu.INT_GPIO_POSEDGE then
    --[[     data = mcp2515_read_rx_buffer(dataNMadress2)
    mcp2515_bit_modify(CANINTF, 0x01, 0x00)
    mcp2515_bit_modify(CANINTF, 0x02, 0x00)
    log.info("上升沿", data:toHex(),data:len()) ]]
  elseif msg == cpu.INT_GPIO_NEGEDGE then
    --根据滤波器匹配去判断，更快
    --[[     canID = mcp2515_readXXStatus_helper(SPIRXSTATUS)
    log.info("下降沿 滤波器选中", canID)

    -- data = mcp2515_read_register(dataNMadress)
    -- 自动清零的读数据
    canData = mcp2515_read_rx_buffer(dataNMadress, 8)
    canFrame = canID .. canData ]]
    -- canFrame = mcp2515_read_rx_buffer(dataNMadress, 8 + 5) --读取地址标识和数据.0x71~0x7d
    -- log.info("fall edge", canFrame:toHex())
    dataIsReceived = true
    -- log.info("list is:", type(list),list.first)
    -- list:pushlast(canFrame)
    -- sys.publish("ListReadPeriodIsReady", list)
    -- mcp2515_bit_modify(CANINTF, 0x01, 0x00)
    -- mcp2515_bit_modify(CANINTF, 0x02, 0x00)
    -- log.info("下降沿 读取数据", canFrame:toHex())



    csLow()
    spi.send(spi.SPI_1, string.char(0x03,0x61))
            data = spi.recv(spi.SPI_1, 4)
    print("yyyy:"..data:toHex())
    csHigh()
    


     csLow()
      spi.send(spi.SPI_1, string.char(0x03,0x65))
              data = spi.recv(spi.SPI_1, 1)
      print("lenth:"..data:toHex())
      csHigh()


      csLow()
        spi.send(spi.SPI_1, string.char(0x03,0x66))
        data = spi.recv(spi.SPI_1, data:toHex())
        print("ttt:"..data:toHex())
    -- log.info("队列长度", list:length())
    -- refreshTable(canFrame)
    csHigh()




  end
  mcp2515_bit_modify(CANINTF, 0x01, 0x00)
  mcp2515_bit_modify(CANINTF, 0x02, 0x00) --for cs pin if float, so this i necessary

  mcp2515_write_register(CANINTE, 0)
  mcp2515_write_register(CANINTE, 3)

 
end

--GPIO4配置为中断，可通过getGpio4Fnc()获取输入电平，产生中断时，自动执行gpio4IntFnc函数
pio.pin.setdebounce(5)



-- getGpio17Fnc = pins.setup(24, gpio17IntFnc)
getGpio17Fnc = pins.setup(18, gpio17IntFnc, pio.PULLUP)  --tannew 1 -- zhu19  -tanori 26
-- getGpio17Fnc = pins.setup(pio.P0_24,gpio17IntFnc)  

-- pio.pin.setdebounce(0)  --关闭延时消抖功能
--GPIO4配置为输入模式，可通过getGpio4Fnc()获取输入电平，执行gpio4IntFnc函数获取当前电平
-- getGpio17Fnc = pins.setup(24)

--[[ local function csLow()
  --拉低CS开始传输数据
  pio.pin.setval(0, pio.P0_10)
end

local function csHigh()
  --传输结束拉高CS
  pio.pin.setval(1, pio.P0_10)
end ]]


-- 从指定地址起始的寄存器读取数据。
local function mcp2515_read_register(adress)
  local data = nil
  csLow()
  spi.send_recv(spi.SPI_1, string.char(SPIREAD, adress))
  --spi.send(spi.SPI_1,string.char(adress))
  data = spi.send_recv(spi.SPI_1, string.char(0x00))
  -- data = spi.recv(spi.SPI_1, 1)
  --data = spi.send_recv(spi.SPI_1,string.char(SPIREAD,adress))
  csHigh()
  return string.byte(data)
end

-- 读RX 缓冲
-- 读取接收缓冲器时，在“n,m”所指示的四个地址中的一个放置地
-- 址指针可以减轻一般读命令的开销。注：在拉升CS 引脚为高电平
-- 后，相关的RX 标志位（CANINTF.RXnIF）将被清零。
function mcp2515_read_rx_buffer(adress, length)
  -- local dummyData = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}
  local data
  local tmpadr
  csLow()
  tmpadr = (SPIREADRX + adress)
  --data = spi.send_recv(spi.SPI_1,string.char(tmpadr))
  spi.send_recv(spi.SPI_1, string.char(tmpadr))
  -- data = spi.send_recv(spi.SPI_1, string.char(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
  data = spi.recv(spi.SPI_1, length)
  csHigh()
  -- return string.byte(data)
  return data
end

function mcp2515_bit_modify(adress, mask, data)
  csLow()
  -- spi.send(spi.SPI_1, string.char(SPIBITMODIFY, adress, mask, data))
  spi.send_recv(spi.SPI_1, string.char(SPIBITMODIFY, adress, mask, data))
  --spi.send(spi.SPI_1,string.char(SPIBITMODIFY))
  --spi.send(spi.SPI_1,string.char(adress))
  --spi.send(spi.SPI_1,string.char(mask))
  --spi.send(spi.SPI_1,string.char(data))
  csHigh()
end

-- RX 状态指令
-- 2 1 0 滤波器匹配
-- 0 0 0 RXF0
-- 0 0 1 RXF1
-- 0 1 0 RXF2
-- 0 1 1 RXF3
-- 1 0 0 RXF4
-- 1 0 1 RXF5
-- 1 1 0 RXF0 （滚存到RXB1）
-- 1 1 1 RXF1 （滚存到RXB1）

function mcp2515_init(canid1, canid2, canid3, canid4, canidMask, extdEanble)
  -- function mcp2515_init()
  local tempcnf1
  local tempcnf2
  local tempcnf3

  spiInit()
  rxTxLedInit() --初始化接受发送led指示灯.
  csLow()
  local ret = spi.send_recv(spi.SPI_1, string.char(SPIRESET))
  log.info("<-- Mcp2515 is rt: ", ret,ret:toHex() )
  csHigh()

  mcp2515_bit_modify(CANCTRL, 0xE0, 128)
  --ret = mcp2515_read_register(CANCTRL)
  --log.info("<-- CANCTRL is : ",ret)

  --mcp2515_write_register(CNF1,0x09)     --// 50k  BRP=09,
  --mcp2515_write_register(CNF1,0x03)  --125k
  mcp2515_write_register(CNF1, 0x01) --250k

  mcp2515_write_register(CNF2, (0x80 + PHSEG13TQ + PRSEG1TQ))
  mcp2515_write_register(CNF3, PHSEG23TQ)

  mcp2515_bit_modify(TXB0CTRL, 0x0B, 0x03)
  mcp2515_bit_modify(TXB1CTRL, 0x0B, 0x02)
  mcp2515_bit_modify(TXB2CTRL, 0x0B, 0x01)
  if extdEanble then
    mcp2515_bit_modify(RXB0CTRL, 0x60, 0x60) --只接收符合滤波器条件的带有标准标识符的有效报文，用以关闭该通道
    mcp2515_bit_modify(RXB1CTRL, 0x60, 0x60) --只接收符合滤波器条件的带有扩展标识符的有效报文
  else
    mcp2515_bit_modify(RXB0CTRL, 0x60, 0x40) --只接收符合滤波器条件的带有扩展标识符的有效报文，用以关闭该通道
    mcp2515_bit_modify(RXB1CTRL, 0x60, 0x20) --只接收符合滤波器条件的带有标准标识符的有效报文
  end

  --mcp2515_Filter_ID(const unsigned char addr, unsigned char ext, unsigned int can_id)
  --	/* Filter Buffer 0 */
  csLow()

  local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF0SIDH, 0xff, 0xff))
  --关闭该缓存
  csHigh()

  csLow()
  local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF1SIDH, 0xff, 0xff))
  csHigh()

  --	/* Filter Buffer 1 */

  if extdEanble then --扩展帧.
    csLow()
    log.info("received canid data is", canid1, canid2, canid3, canid4, canidMask, extdEanble)
    local b1, b2, b3, b4 = canid2reg(canid1, extdEanble)
    -- local b1, b2, b3, b4 = canid2reg(canid1, true)
    log.info("extend canid is", b4, b3, b2, b1)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF2SIDH, b4, b3, b2, b1))
    csHigh()

    csLow()
    local b1, b2, b3, b4 = canid2reg(canid2, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF3SIDH, b4, b3, b2, b1))
    csHigh()

    csLow()
    local b1, b2, b3, b4 = canid2reg(canid3, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF4SIDH, b4, b3, b2, b1))
    csHigh()

    csLow()
    local b1, b2, b3, b4 = canid2reg(canid4, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF5SIDH, b4, b3, b2, b1))
    csHigh()
    --	/* Maske  Buffer 0 */
    csLow()
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXM0SIDH, 0xff, 0xff, 0xff, 0xff)) --不屏蔽.
    csHigh()

    --	/* Maske Buffer 1 */
    csLow()
    local b1, b2, b3, b4 = canidMask2reg(canidMask, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXM1SIDH, b4, b3, b2, b1))
    csHigh()
  else --标准帧.
    csLow()
    log.info("received canid data is", canid1, canid2, canid3, canid4, canidMask, extdEanble)
    local b1, b2 = canid2reg(canid1, extdEanble)
    log.info("extend canid is", b2, b1)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF2SIDH, b2, b1))

    csHigh()

    csLow()
    local b1, b2 = canid2reg(canid2, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF3SIDH, b2, b1))
    csHigh()

    csLow()
    local b1, b2 = canid2reg(canid3, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF4SIDH, b2, b1))
    csHigh()

    csLow()
    local b1, b2 = canid2reg(canid4, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXF5SIDH, b2, b1))
    csHigh()
    --	/* Maske  Buffer 0 */
    csLow()
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXM0SIDH, 0xff, 0xff)) --不屏蔽.
    csHigh()

    --	/* Maske Buffer 1 */
    csLow()
    local b1, b2 = canidMask2reg(canidMask, extdEanble)
    local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, RXM1SIDH, b2, b1))
    csHigh()
  end

  --	/* Pins RXnBF Pins ( High Impedance State ) */
  mcp2515_write_register(BFPCTRL, 0)
  --	/* TXnRTS Bits als Inputs */
  mcp2515_write_register(TXRTSCTRL, 0)

  tempcnf1 = mcp2515_read_register(CNF1)
  tempcnf2 = mcp2515_read_register(CNF2)
  tempcnf3 = mcp2515_read_register(CNF3)
  log.info("<-- CNF -->\r\n", tempcnf1, tempcnf2, tempcnf3)

  mcp2515_bit_modify(CANCTRL, 0xE0, 0)

  mcp2515_write_register(CANINTE, 0)
  mcp2515_write_register(CANINTE, 3)
end

-- canid = 0x012
-- canbuf = {}
-- canbuf[1] = 1
-- canbuf[2] = 2
-- canbuf[3] = 3
-- canbuf[4] = 4
-- canbuf[5] = 5
-- canbuf[6] = 6
-- canbuf[7] = 7
-- canbuf[8] = 8
local flagsRTR = 0
local TxBnum = 3
local ctrlval = 0
local temp0 = 0
local temp1 = 0
local temp2 = 0
local temp3 = 0
local length = 8
local rttmpval = 0
function Period_CAN_Send(canid, canbuf)
  TxBnum = 3
  for i = 1, 3 do
    ctrlval = mcp2515_read_register(TXB0CTRL + 0x10 * (i - 1))
    -- log.info("<-- ctrlval val. -->\r\n", ctrlval)
    --if((ctrlval&0x08) == 0) then
    if (((ctrlval % 16) / 8) == 0) then
      TxBnum = (i - 1)
      -- log.info("<-- CANTX NUM. -->\r\n", TxBnum)
      break
    end
  end

  if (TxBnum < 3) then
    ctrlval = TXB0CTRL + 0x10 * TxBnum + 1
  else
    ctrlval = TXB0CTRL + 1
  end

  if (canid > 0x7ff) then --扩展帧.
    temp3, temp2, temp1, temp0 = canid2reg(canid, true)
  else
    --temp[0] = (unsigned char) (id>>3)
    --temp[1] = (unsigned char) (id<<5)
    temp0 = (canid / 8) % 256
    temp1 = (canid * 32) % 256
    temp2 = 0
    temp3 = 0
  end
  --mcp2515_write_register_p(ctrlval, temp, 4)
  csLow()
  local retnum = spi.send_recv(spi.SPI_1, string.char(SPIWRITE, ctrlval, temp0, temp1, temp2, temp3))
  csHigh()

  if (flagsRTR > 0) then
    mcp2515_write_register((ctrlval + 4), (length + 64))
  else
    mcp2515_write_register((ctrlval + 4), length)
  end

  --mcp2515_write_register_p(ctrlval+5, data, length)
  csLow()
  local retnum =
    spi.send_recv(
    spi.SPI_1,
    string.char(
      SPIWRITE,
      (ctrlval + 5),
      canbuf[1],
      canbuf[2],
      canbuf[3],
      canbuf[4],
      canbuf[5],
      canbuf[6],
      canbuf[7],
      canbuf[8]
    )
  )
  csHigh()
  txLedFlash()
  mcp2515_bit_modify(ctrlval - 1, 0x08, 0x08)

  --[[
  rttmpval = mcp2515_read_register(ctrlval-1)
  while(((rttmpval%16)/8) == 1) do
    rttmpval = mcp2515_read_register(ctrlval-1)
    log.info("<-- WAIT TX COMPLETE. -->", rttmpval)
    local txstatus = mcp2515_read_register(ctrlval-1)
    log.info("<-- TXBCTRL STATUS. -->", txstatus) 
  end
--]]
end

local function loop()
  --mcp2515_init()
  Period_CAN_Send()

  --spi.close(spi.SPI_1)
end

--[[ sys.taskInit(function()                
        mcp2515_init()
        while true do
          Period_CAN_Send()
          log.info("enter the can code")
          sys.wait(1000)
        end

    end
) ]]
-- mcp2515_init()
-- mcp2515_init(0x18f101d0,0x18f101d0,0x18f101d0,0x18f101d0,true)
-- sys.timerLoopStart(loop, 10000)

--[[ function transList()
  sys.publish("ListReadPeriodIsReady", list)
end ]]

function sampleCan()
  local dataNMadress = 0x04 --从0x71地址开始读取can数据
  local dataNMadress2 = 0x00
  local canData, canID, canFrame
  local level = getGpio17Fnc()
  if (level == 0) then --int 引脚是电平
    --根据滤波器匹配去判断，更快
    --[[     canID = mcp2515_readXXStatus_helper(SPIRXSTATUS)
    log.info("read can ID is", canID:toHex()) ]]
    -- data = mcp2515_read_register(dataNMadress)
    -- 自动清零的读数据
    --[[     canData = mcp2515_read_rx_buffer(dataNMadress, 8+5) --读取地址标识和数据.0x71~0x7d
    log.info("read can data is", canData:toHex())
    canFrame = canID .. canData ]]
    canFrame = mcp2515_read_rx_buffer(dataNMadress, 8 + 5) --读取地址标识和数据.0x71~0x7d
    refreshTable(canFrame)
    -- log.info("read can frame is", canFrame:toHex())
    -- log.info("list is:", type(list),list.first)
    -- 放入接受数据缓冲区.
    -- list:pushlast(canFrame)
    -- sys.publish("ListReadPeriodIsReady", list)  --发布消息
    -- mcp2515_bit_modify(CANINTF, 0x01, 0x00)
    -- mcp2515_bit_modify(CANINTF, 0x02, 0x00)
    -- log.info("下降沿 读取数据", canFrame:toHex())
    -- log.info("队列长度", list:length())
    -- 接受指示灯闪烁
    rxLedFlash() --不能用在定时器函数中，里面包含延时函数
    mcp2515_bit_modify(CANINTF, 0x02, 0x00) --for cs pin if float, so this i necessary
    log.info("enter the can sample")
  end
  --定时清理，不管是否有中断发生，防止进不了中断.
  -- mcp2515_bit_modify(CANINTF, 0x01, 0x00)
  -- mcp2515_bit_modify(CANINTF, 0x02, 0x00) --for cs pin if float, so this i necessary
  -- log.info("entre the can timer")
  -- Period_CAN_Send()
end

function interrupFlagClear()
  mcp2515_bit_modify(CANINTF, 0x02, 0x00) --for cs pin if float, so this i necessary
end
-- sys.timerLoopStart(transList, 10000)
-- sys.timerLoopStart(sampleCan, 30000)


sys.taskInit(
  function()
    while true do
        -- csLow()

        -- spi.send(spi.SPI_1, string.char(0x03,0x66))
        -- data = spi.recv(spi.SPI_1, 8)
        -- print("ttt:"..data:toHex())
        -- csHigh()
      -- if dataIsReceived == true then
      --   rxLedFlash()
      --   dataIsReceived = false
      -- end
      sys.wait(1000)
    end
  end
)

function init_my()

  local canid1 = 0x10101
  local canid2 = 0x30605
  local canid3 = 0x31405
  local canid4 = 0x31201
  local canidMask = 0xfffce0f0
  local extdCanEnbale = true
  testSpiFlash.mcp2515_init(canid1, canid2, canid3, canid4, canidMask, extdCanEnbale)

  log.info("jwl","init all mcp .....")
end





-- 串口ID,串口读缓冲区
local UART1_ID,UART2_ID,UART3_ID, recvQueue = 1,2,3, {}
-- 串口超时，串口准备好后发布的消息
local uartimeout, recvReady,RECV_MAXCNT = 100, "UART_RECV_ID",1024

local flag_enatc="1"

local function usb_write(data)
  uart.write(uart.USB, data) 
end


uart.setup(uart.USB, 0, 0, uart.PAR_NONE, uart.STOP_1)
uart.on(uart.USB, "receive", function()
  table.insert(recvQueue, uart.read(uart.USB, RECV_MAXCNT))
  sys.timerStart(sys.publish, uartimeout, recvReady,usb_write)
end)


sys.subscribe(recvReady, function(sndcb)
  local str_recv = table.concat(recvQueue)
  recvQueue = {}

  app_procmd(str_recv,sndcb)
end)




function app_procmd(str_recv, fncallbk)
  log.info("str_recv------------",str_recv,str_recv:toHex())
  local str_rsp =""
  local flag_handled=true
  local prefix = string.match(str_recv, "[aA][tT](%+%u+)")
  if prefix ~=nil then
      

      if prefix == "+RIL?" then
          str_rsp = "+RIL:"..flag_enatc

      elseif prefix == "+RIL" then
          local temp_enatc = string.match( str_recv, "+RIL=(%d+)")
          if temp_enatc ~= nil then
              flag_enatc = temp_enatc
          end
          if flag_enatc == "0" then  ril.setrilcb(nil) end
          str_rsp = "+RIL:"..flag_enatc

      elseif prefix == "+CGMR" or prefix == "+PRO"  then
          str_rsp = string.format("+RPO:%s %s\r\n", _G.PROJECT,_G.VERSION)
      elseif prefix == "+MEM" then    
          str_rsp = "+DISK: "..rtos.get_fs_free_size().." Bytes +RAM: ".._G.collectgarbage("count").." Bytes"
          log.info("cur_tick:",mutils.getsystick())

      elseif prefix == "+TIME" then    
          local c = misc.getClock()
          str_rsp = string.format('+TIME: %04d-%02d-%02d %02d:%02d:%02d timestamp:%d', c.year, c.month, c.day, c.hour, c.min, c.sec, os.time())
      elseif prefix == "+INIT" then    
 
     --   init_my()

     
  -- mcp2515_bit_modify(CANCTRL, 0xE0, 128)
  -- --ret = mcp2515_read_register(CANCTRL)
  -- --log.info("<-- CANCTRL is : ",ret)

  -- --mcp2515_write_register(CNF1,0x09)     --// 50k  BRP=09,
  -- --mcp2515_write_register(CNF1,0x03)  --125k
  -- mcp2515_write_register(CNF1, 0x01) --250k

  -- mcp2515_write_register(CNF2, (0x80 + PHSEG13TQ + PRSEG1TQ))
  -- mcp2515_write_register(CNF3, PHSEG23TQ)

  -- mcp2515_bit_modify(TXB0CTRL, 0x0B, 0x03)
  -- mcp2515_bit_modify(TXB1CTRL, 0x0B, 0x02)
  -- mcp2515_bit_modify(TXB2CTRL, 0x0B, 0x01)
 
  --   mcp2515_bit_modify(RXB0CTRL, 0x60, 0x60) --只接收符合滤波器条件的带有标准标识符的有效报文，用以关闭该通道
  --   mcp2515_bit_modify(RXB1CTRL, 0x60, 0x60) --只接收符合滤波器条件的带有扩展标识符的有效报文



    -- mcp2515_write_register(BFPCTRL, 0)
    -- --	/* TXnRTS Bits als Inputs */
    -- mcp2515_write_register(TXRTSCTRL, 0)
  
    -- tempcnf1 = mcp2515_read_register(CNF1)
    -- tempcnf2 = mcp2515_read_register(CNF2)
    -- tempcnf3 = mcp2515_read_register(CNF3)
    -- log.info("<-- CNF -->\r\n", tempcnf1, tempcnf2, tempcnf3)
  
    -- mcp2515_bit_modify(CANCTRL, 0xE0, 0)
  
    mcp2515_write_register(CANINTE, 0)
    mcp2515_write_register(CANINTE, 3)
 

     
      else
          flag_handled=false
      end


  else
      if  string.upper(str_recv) =="AT\r\n" then
          str_rsp ="OK\r\n"
      else
          flag_handled=false
      end
  end


  if str_rsp ~="" then
      fncallbk(str_rsp)
  end

  if (not flag_handled) and (flag_enatc == "1") then
      log.info("send at cmd ==>" ,str_recv)
       ril.setrilcb(fncallbk)
       ril.request(str_recv)
  end
end
