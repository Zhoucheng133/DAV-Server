# DAV Server

## 简介

<img src="assets/icon.png" width="100px">

![License](https://img.shields.io/badge/License-MIT-dark_green)

这是一个用于搭建WebDAV服务的软件，可以快速地创建一个WebDAV服务器，支持用户身份验证

核心组件的仓库[在这里](https://github.com/Zhoucheng133/DAV-Core)

> [!NOTE]
> 在Windows下核心组件（二进制的exe文件）可能会被Windows Defender或者其他安全软件误判为病毒，为确保程序正确运行，请保留二进制文件在你的设备上。这个二进制文件你可以自行打包生成。

## 截图

<img src="demo/demo.png" width="400px">

## 使用

### 服务器端（分享文件的设备）

支持Windows和macOS系统，Linux系统理论也支持  
你只需要打开本软件-选择路径和端口号（默认8080）并且启动即可

### 客户端（访问文件的设备）

你可以使用任何支持访问WebDAV的文件管理软件来访问

## 在你的设备上配置DAV Server
1. 你可以自行打包核心组件，核心组件的仓库[在这里](https://github.com/Zhoucheng133/DAV-Core)
2. 打包的可执行的二进制文件复制到`assets`文件夹（如果你没有自行打包核心组件，在assets文件夹中也有我打包好的）
3. 使用Flutter打包/调试本项目

## 更新日志

### 1.0.0 (2025/2/17)
- 第一个版本