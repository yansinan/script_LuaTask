[toc]

# 1.目录文档介绍

- extra_file

  其它的一些扩展文件，里面有protoc模块的实现，只是里面一些部分还没有实现，待后面扩展实现。

- proto_exe

  protobuffer需要先创建一个模型结构，再编译成二进制pb文件，这个文件夹就是存储编译的exe文件和测试创建的模型文件。具体实现见下文。

- scripts

  测试demo的脚本文件和pb文件。

# 2.具体实现介绍

## 1. 创建模型结构

> 如proto_exe目录下，我们创建了`tracker.proto`proto3协议结构文件和`addressbook.proto`协议结构文件。结构的建议是需要遵循特定的语法的，详细的语法请参考：[Language Guide  | Protocol Buffers  | Google Developers](https://developers.google.cn/protocol-buffers/docs/proto?hl=zh-cn)
>
> ![image-20210825134943787](C:\Users\WJ\AppData\Roaming\Typora\typora-user-images\image-20210825134943787.png)

## 2.编译

> 模型创建好后，需要将模型编译成二进制数据。
>
> 我们在`proto_exe`目录下打开`cmd`控制台，如果我们要编译`tracker.proto`文件，在控制台输入`protoc-3.9.2-windows-x86_64.exe --descriptor_set_out=tracker.pb tracker.proto`，即可编译输出pb文件。



## 3.运行脚本

> 将scripts文件夹下面的文件和脚本下载到模块就可以成功编解码了。我们的库是移植`lua_protobuffer`的，具体可参考：
>
> [starwing/lua-protobuf: A Lua module to work with Google protobuf (github.com)](https://github.com/starwing/lua-protobuf)的实现。

