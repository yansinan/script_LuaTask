--- 模块功能：I2C MCP4725功能测试.
-- @author denghai
-- @module i2c.MCP4725
-- @license MIT
-- @copyright openLuat
-- @release 2021.09.16

module(...,package.seeall)
require "bit"
require"utils"
local i2cid = 2
--定义器件在IIC总线中的从地址   
--//This is the I2C Address of the MCP4725, by default (A0 pulled to GND).
local MCP4725_ADDR = 0x60   

--mcp4725 mode
local MCP4725_MODE_DAC    = 0x00                        --/**< DAC mode */
local MCP4725_MODE_EEPROM = 0x03                        --/**< EEPROM mode */
--mcp4725 power down enumeration
local MCP4725_POWER_DOWN_MODE_NORMAL   = 0x00           --/**< power down normal mode */
local MCP4725_POWER_DOWN_MODE_1K_GND   = 0x01           --/**< power down 1K GND */
local MCP4725_POWER_DOWN_MODE_100K_GND = 0x02           --/**< power down 100K GND */
local MCP4725_POWER_DOWN_MODE_500K_GND = 0x03           --/**< power down 500K GND */

--/Sinewave Tables were generated using this calculator:
--//http://www.daycounter.com/Calculators/Sine-Generator-Calculator.phtml
local sintab2 = 
{
  2048, 2073, 2098, 2123, 2148, 2174, 2199, 2224,
  2249, 2274, 2299, 2324, 2349, 2373, 2398, 2423,
  2448, 2472, 2497, 2521, 2546, 2570, 2594, 2618,
  2643, 2667, 2690, 2714, 2738, 2762, 2785, 2808,
  2832, 2855, 2878, 2901, 2924, 2946, 2969, 2991,
  3013, 3036, 3057, 3079, 3101, 3122, 3144, 3165,
  3186, 3207, 3227, 3248, 3268, 3288, 3308, 3328,
  3347, 3367, 3386, 3405, 3423, 3442, 3460, 3478,
  3496, 3514, 3531, 3548, 3565, 3582, 3599, 3615,
  3631, 3647, 3663, 3678, 3693, 3708, 3722, 3737,
  3751, 3765, 3778, 3792, 3805, 3817, 3830, 3842,
  3854, 3866, 3877, 3888, 3899, 3910, 3920, 3930,
  3940, 3950, 3959, 3968, 3976, 3985, 3993, 4000,
  4008, 4015, 4022, 4028, 4035, 4041, 4046, 4052,
  4057, 4061, 4066, 4070, 4074, 4077, 4081, 4084,
  4086, 4088, 4090, 4092, 4094, 4095, 4095, 4095,
  4095, 4095, 4095, 4095, 4094, 4092, 4090, 4088,
  4086, 4084, 4081, 4077, 4074, 4070, 4066, 4061,
  4057, 4052, 4046, 4041, 4035, 4028, 4022, 4015,
  4008, 4000, 3993, 3985, 3976, 3968, 3959, 3950,
  3940, 3930, 3920, 3910, 3899, 3888, 3877, 3866,
  3854, 3842, 3830, 3817, 3805, 3792, 3778, 3765,
  3751, 3737, 3722, 3708, 3693, 3678, 3663, 3647,
  3631, 3615, 3599, 3582, 3565, 3548, 3531, 3514,
  3496, 3478, 3460, 3442, 3423, 3405, 3386, 3367,
  3347, 3328, 3308, 3288, 3268, 3248, 3227, 3207,
  3186, 3165, 3144, 3122, 3101, 3079, 3057, 3036,
  3013, 2991, 2969, 2946, 2924, 2901, 2878, 2855,
  2832, 2808, 2785, 2762, 2738, 2714, 2690, 2667,
  2643, 2618, 2594, 2570, 2546, 2521, 2497, 2472,
  2448, 2423, 2398, 2373, 2349, 2324, 2299, 2274,
  2249, 2224, 2199, 2174, 2148, 2123, 2098, 2073,
  2048, 2023, 1998, 1973, 1948, 1922, 1897, 1872,
  1847, 1822, 1797, 1772, 1747, 1723, 1698, 1673,
  1648, 1624, 1599, 1575, 1550, 1526, 1502, 1478,
  1453, 1429, 1406, 1382, 1358, 1334, 1311, 1288,
  1264, 1241, 1218, 1195, 1172, 1150, 1127, 1105,
  1083, 1060, 1039, 1017,  995,  974,  952,  931,
   910,  889,  869,  848,  828,  808,  788,  768,
   749,  729,  710,  691,  673,  654,  636,  618,
   600,  582,  565,  548,  531,  514,  497,  481,
   465,  449,  433,  418,  403,  388,  374,  359,
   345,  331,  318,  304,  291,  279,  266,  254,
   242,  230,  219,  208,  197,  186,  176,  166,
   156,  146,  137,  128,  120,  111,  103,   96,
    88,   81,   74,   68,   61,   55,   50,   44,
    39,   35,   30,   26,   22,   19,   15,   12,
    10,    8,    6,    4,    2,    1,    1,    0,
     0,    0,    1,    1,    2,    4,    6,    8,
    10,   12,   15,   19,   22,   26,   30,   35,
    39,   44,   50,   55,   61,   68,   74,   81,
    88,   96,  103,  111,  120,  128,  137,  146,
   156,  166,  176,  186,  197,  208,  219,  230,
   242,  254,  266,  279,  291,  304,  318,  331,
   345,  359,  374,  388,  403,  418,  433,  449,
   465,  481,  497,  514,  531,  548,  565,  582,
   600,  618,  636,  654,  673,  691,  710,  729,
   749,  768,  788,  808,  828,  848,  869,  889,
   910,  931,  952,  974,  995, 1017, 1039, 1060,
  1083, 1105, 1127, 1150, 1172, 1195, 1218, 1241,
  1264, 1288, 1311, 1334, 1358, 1382, 1406, 1429,
  1453, 1478, 1502, 1526, 1550, 1575, 1599, 1624,
  1648, 1673, 1698, 1723, 1747, 1772, 1797, 1822,
  1847, 1872, 1897, 1922, 1948, 1973, 1998, 2023
}

local gs_handle={inited=0,mode=0,power_mode=0,ref_voltage=0}
function mcp4725_init(handle)
    if (nil==handle)then                                                 --      /* check handle */
        return 2                                                         --      /* return error */
    end
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("MCP4725","i2c.setup fail")
        i2c.close(i2cid)
        return 1
    end
    handle.inited = 1                                                    --      /* flag finish initialization */
    
    return 0                                                             --     /* success return 0 */
end
function mcp4725_deinit(handle)
    if (nil==handle) then                                               --       /* check handle */
        return 2                                                        --      /* return error */
    end
    if (1~=handle.inited)then                                           --/* check handle initialization */
        return 3                                                        --        /* return error */
    end    
    i2c.close(i2cid)
    handle.inited = 0                                                    --          /* flag close */
    
    return 0                                                            --           /* success return 0 */
end
function mcp4725_set_mode(handle, mode)
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end
    handle.mode = mode

    return 0                                                    --/* success return 0 */
end
function mcp4725_get_mode()
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end    
    return handle.mode
end
function mcp4725_set_power_mode(handle, mode)
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end
    
    handle.power_mode = mode

    return 0                                                        -- /* success return 0 */
end
function mcp4725_get_power_mode()
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end
    
    return handle.power_mode
end
function mcp4725_set_reference_voltage(handle, ref_voltage)
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end
    
    handle.ref_voltage = ref_voltage

    return 0
end
function mcp4725_get_reference_voltage()
    if (nil==handle)then
        return 2
    end
    if (1~=handle.inited)then
        return 3
    end
    
    return handle.ref_voltage
end
function mcp4725_convert_to_register(handle, s)
    local reg = 0
    if (nil==handle)  then                                      --                     /* check handle */
        return false
    end
    if (1~=handle.inited) then
        return false
    end
    if (0==handle.ref_voltage)then
        log.info("mcp4725: reference voltage can't be zero.\n")
        return 1                                                                --   /* return error */
    end
    reg = (s * 4096.0000000 / handle.ref_voltage)
    
    return reg
end
function mcp4725_read(handle) 
    buf={0,0,0,0,0}
    temp = "0"
    value = 0
    if ("nil"==type(handle)) then 
        return false
    end
    if (1~=handle.inited )then
        return false
    end  
    temp = i2c.recv(i2cid,MCP4725_ADDR,5)  
    if(nil == temp) or (5 ~= #temp) then                 --        /* read data */
        log.info("mcp4725: read failed.\n")              --     /* read data failed */
        
        return false                                     --       /* return error */
    end
    _,buf[1],buf[2],buf[3],buf[4],buf[5] =pack.unpack(temp,"bbbbb")
    if (MCP4725_MODE_DAC==handle.mode) then                 --          /* if use dac mode */
        value = bit.bor(bit.lshift(buf[2],8),buf[3])            --       /* get value */
        value = bit.rshift(value,4)                             --        /* right shift 4 */
        return value
    else if (MCP4725_MODE_EEPROM==handle.mode) then             --      /* if use eeprom mode */
            value = bit.bor(bit.lshift(bit.band(buf[4],0x0F),8) ,buf[5])
            return value
        else
                log.info("mcp4725: mode is invalid.\n")         --  /* mode is invalid */
                return false
        end
    end
end
function mcp4725_write(handle, value)
    local buf={0,0,0,0,0,0}
    if ("nil"==type(handle))  then                                                        -- /* check handle */
        return 2                                                             --    /* return error */
    end
    if 1~=handle.inited then                                                      --/* check handle initialization */
        return 3                                                             --    /* return error */
    end
    
    value = bit.band(value,0xFFF)                                   --               /* get valid part */
    if (MCP4725_MODE_DAC==handle.mode )  then                       --                /* dac mode */
        buf[1] = bit.band(bit.rshift(value,8) ,0xFF)                              --               /* set msb */
        buf[1] = bit.bor(buf[1] ,bit.lshift(handle.power_mode ,4))   --             /* set power mode */
        buf[2] = bit.band(value,0xFF)                                 --          /* set lsb */
        buf[3] = bit.band(bit.rshift(value ,8) ,0xFF)                    --        /* set msb */
        buf[3] = bit.bor(buf[1],bit.lshift(handle.power_mode,4))       --                       /* set power mode */
        buf[4] = bit.band(value,0xFF)                                    --            /* set lsb */
        log.info("mcp4725_write", buf[1],buf[2],buf[3],buf[4])
        i2c.send(i2cid,MCP4725_ADDR, {buf[1],buf[2],buf[3],buf[4]})     --        /* write command */
        return 0
    else if (MCP4725_MODE_EEPROM==handle.mode)    then                   --          /* eeprom mode */
        buf[1] = bit.lshift(0x03,5)                                         --           /* set mode */
        buf[1] = bit.bor(buf[1] ,bit.lshift(handle.power_mode,1))           --           /* set power mode */
        value = bit.lshift(value, 4)                                        --            /* right shift 4 */
        buf[2] = bit.band(bit.rshift(value ,8),0xFF)                        --             /* set msb */
        buf[3] = bit.band(value,0xFF)                                        --        /* set lsb */
        buf[4] = bit.lshift(0x03 ,5)                                         --         /* set mode */
        buf[4] = bit.bor(buf[1] ,bit.lshift(handle.power_mode ,1))           --      /* set power mode */
        value = bit.lshift(value,4)                                         --     /* right shift 4 */
        buf[5] = bit.band(bit.rshift(value,8),0xFF)                          --  /* set msb */
        buf[6] = bit.band(value,0xFF)                                           -- /* set lsb */
        
        i2c.send(i2cid,MCP4725_ADDR, {buf[1],buf[2],buf[3],buf[4],buf[5],buf[6]})   --/* write command */
        return 0
        else
             log.info("mcp4725: mode is invalid.\n")                     -- /* mode is invalid */
             return 1
        end
    end
end 
function mcp4725_register_test()
    res = mcp4725_init(gs_handle)
    if (0~=res) then
        log.info("mcp4725: init failed.\n")
        return 1
    end
    res = mcp4725_set_reference_voltage(gs_handle, 3.3)
    if (0~=res) then
        log.info("mcp4725: set reference voltage failed.\n")
        mcp4725_deinit(gs_handle)        
        return 1 
    end
end    
function mcp4725_write_test()
    local times = 512
    res = mcp4725_init(gs_handle) 
    if (0~=res) then
        log.info("mcp4725: init failed.\n")        
        return 1 
    end
    --/* set power down normal mode */
    res = mcp4725_set_power_mode(gs_handle, MCP4725_POWER_DOWN_MODE_NORMAL) 
    if (0~=res) then
        log.info("mcp4725: set power mode failed.\n") 
        mcp4725_deinit(gs_handle)         
        return 1 
    end
    --/* set reference voltage 3.3V */
    res = mcp4725_set_reference_voltage(gs_handle, 3.3) 
    if (0~=res) then
        log.info("mcp4725: set reference voltage failed.\n") 
        mcp4725_deinit(gs_handle)         
        return 1 
    end
    --/* set dac mode */
    res = mcp4725_set_mode(gs_handle, MCP4725_MODE_DAC) 
    if (0~=res) then
        log.info("mcp4725: set mode failed.\n") 
        mcp4725_deinit(gs_handle)         
        return 1 
    end
    log.info("mcp4725: set dac mode.\n")  
    for i=1, times, 1 do
        local input = (math.random(1,100)%65536)/65536.0*3.3  
        --/* convert to register */
        res = mcp4725_convert_to_register(gs_handle, input)
        if (not(res)) then
            log.info("mcp4725: convert to register failed.\n") 
            mcp4725_deinit(gs_handle) 
            
            return 1 
        end
        local reg = sintab2[i]
        -- local reg = res                      用这个没有波形，直接输入数组值就有波形
        --/* write dac */
        log.info("mcp4725: write data sintab2[i]",i ,"=",sintab2[i])
        res = mcp4725_write(gs_handle, reg) 
        if (0~=res) then 
            log.info("mcp4725: write data failed.\n") 
            mcp4725_deinit(gs_handle)             
            return 1 
        end
        -- 如下是读值测试
        -- sys.wait(1000) 
        -- res = mcp4725_read(gs_handle) 
        -- if not(res) then
        --     log.info("mcp4725: read data failed.\n") 
        --     mcp4725_deinit(gs_handle) 
            
        --     return 1 
        -- end
        -- log.info("mcp4725: dac read check write", input,reg,res) 
        -- sys.wait(1000) 
    end
end

sys.taskInit(function()
    sys.wait(5000)
    local lookup = 1
    log.info("MCP4725")
    while true do
        mcp4725_write_test()
        sys.wait(5)
    end
end)

