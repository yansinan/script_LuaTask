--- 模块功能：protobuffer测试
-- @author openLuat
-- @module lbsLoc.testLbsLoc
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.23

--以下为简单的测试，移植的是lua_protobuffer库，详细的接口可以参考：https://github.com/starwing/lua-protobuf

local pb = require "lua_protobuf"
local conv = require "pb.conv"

require"utils"

sys.taskInit(function ()
    sys.wait(2000)
    print('lua_protobuffer test start .............')

    --proto2测试
    --[[
    pb.loadfile("/lua/addressbook.pb")

    local addressBook =
    {
        name = "Alice",
        id = 12345,
        phone =
        {
            {number = "1301234567"},
            {number = "87654321", type = "WORK"},
            {number = "13912345678", type = "MOBILE"},
        },
        email = "username@domain.com"
    }

    -- 序列化成二进制数据
    local data = pb.encode("tutorial.Person", addressBook)
    log.info("protobuf.encode",data:toHex())
    -- 从二进制数据解析出实际消息
    local msg = pb.decode("tutorial.Person", data)
    -- 这里调用了serpent库，用于序列化打印table数据，实际生产可不包含
    print(require "serpent".block(msg))
    ]]

    --proto3 test
    local tracker = {
        query = "www",
        page_number = 8,
        result_per_page = 100,
    }

    pb.loadfile("/lua/tracker.pb")

    --[[pb Module test]]--
    --设置启用hook函数选项
    print(pb.option("enable_hooks"))
    pb.hook("tracker.SearchRequest", function()
        print("decode sucess")
    end)

    -- 序列化成二进制数据
    local data = pb.encode("tracker.SearchRequest", tracker)
    log.info("protobuf.encode",data:toHex())
    -- 从二进制数据解析出实际消息

    local msg = pb.decode("tracker.SearchRequest", data)
    -- 这里调用了serpent库，用于序列化打印table数据，实际生产可不包含
    print(require "serpent".block(msg))

    --pb.(type|field)[s]()获取指定类型||字段的信息
    print(pb.type("tracker.SearchRequest"))
    -- list all types that loaded into pb
    for name, basename, type in pb.types() do
        print(name, basename, type)
    end

    print(pb.field("tracker.SearchRequest", "query"))
    -- notice that you needn't receive all return values from iterator
    for name, number, type in pb.fields "tracker.SearchRequest" do
        print(name, number, type)
    end

    --将字段的类型名转换为打包/解包格式化程序
    print(pb.typefmt("tracker.SearchRequest"))

    --获取类型的默认表
    print(pb.defaults("tracker.SearchRequest"))

    --获取当前pb状态值
    local statu = pb.state()
    print(statu)

    --[[pb.conv Module test]]--
    print('pb.conv Module test start .............')
    print(conv.encode_int32(32))

    print(conv.encode_uint32(64))

    local s32 = conv.encode_sint32(-100)
    print(conv.decode_sint32(s32))

    local s64 = conv.encode_sint64(-1000000000000)
    print(conv.decode_sint64(s64))

    local flo = conv.encode_float(10.55)
    print(conv.decode_float(flo))

    local doubl = conv.encode_double(10.55)
    print(conv.decode_double(doubl))

end
)
