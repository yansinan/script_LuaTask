module(..., package.seeall)
--[[
    U盘功能测试程序：
    注意:   1. U盘的盘符固定为：/usbmsc0
            2. 开机可以先mount，如果mount失败就使用格式化format，一般mount之后需要等待2秒左右再对文件进行操作
            3. 读写接口都是标准的
            4. lua写文件和PC端并不能同步显示，需要重新插拔一下USB
]]
require"audio"

function MscTask()
    sys.wait(5000)
    --挂载U盘,返回值0表示失败，1表示成功
    if io.mount(io.USBMSC) == 0 then
        io.format(io.USBMSC)
    end
    
    --第一个参数2表示U盘
    --第二个参数1表示返回的总空间单位为KB
    local MscTotalSize = rtos.get_fs_total_size(2)
    log.info("usb storage total size "..MscTotalSize.." B")
    
    --第一个参数2表示U盘
    --第二个参数1表示返回的总空间单位为KB
    local MscTotalSize = rtos.get_fs_free_size(2)
    log.info("usb storage free size "..MscTotalSize.." B")
    
    
    --遍历读取U盘根目录下的最多10个文件或者文件夹
    if io.opendir("/usbmsc0") then
        for i=1,10 do
            local fType,fName,fSize = io.readdir()
            if fType==32 then
                log.info("sd card file",fName,fSize)               
            elseif fType == nil then
                break
            end
        end        
        io.closedir("/usbmsc0")
    end
    
    --向U盘根目录下写入一个pwron.mp3
    io.writeFile("/usbmsc0/pwron.mp3",io.readFile("/lua/pwron.mp3"))
    --播放U盘根目录下的pwron.mp3
    audio.play(0,"FILE","/usbmsc0/pwron.mp3",audiocore.VOL7,function() sys.publish("AUDIO_PLAY_END") end)
    sys.waitUntil("AUDIO_PLAY_END")    
    
    --卸载U盘，返回值0表示失败，1表示成功
    --io.unmount(io.USBMSC)
end

sys.taskInit(MscTask)


