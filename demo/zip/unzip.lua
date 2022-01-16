module(..., package.seeall)

-- 挂载sd卡，sd卡里放一个zip文件，压缩方式需要是deflate（7zip中zip格式默认使用deflate），
io.mount(io.SDCARD)

local zfile, err = zip.open("/sdcard0/test.zip")

-- 列出压缩包中的所有文件
for file in zfile:files() do
    print(file.filename)
end

-- 解压文件到sd卡中
for file in zfile:files() do
    local wf = io.open("/sdcard0/"..file.filename, "w")
    rf, err = zfile:open(file.filename)
    local s = rf:read("*a")
    wf:write(s)
    wf:close()
    rf:close()
end

zfile:close()

io.unmount(io.SDCARD)

print("unzip end")