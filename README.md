# Number_Identification_System
## 2020 Xilinx Summer School 数字识别项目
## 项目概要 
   1.本设计的目的是在FPGA上实现数字识别，即通过外接摄像头采集纯底色数字字符的视频图像数据，输入到FPGA中进行图像处理，并识别出视频图像中的数字字符，同时，将图像传输到HDMI显示屏上进行显示。由于本设计的综合性、系统性较强，故应用到的知识点也较多，包含组合逻辑、时钟分频、IP核调用等基本知识点，以及MIPI摄像头视频输入、视频图像处理、HDMI视频显示输出、机器视觉等进阶知识点。数字字符识别系统的总体设计流程主要包含四大部分：图像采集模块、图像存储模块、图像处理模块、显示模块。图像处理模块只要采用特征识别的算法匹配进行数字识别。
   2.本设计属于FPGA图像处理的范畴，FPGA以其出色的实时流水线运算能力而能够被应用于很多对实时性有着很高要求的领域，视频图像处理正是其中之一。利用FPGA实现的数字识别技术，能够有效地应用在一些需要实时、快速地获取数字信息的场合，例如可用于在道路监控系统中抓拍违章车辆，并从其车牌上识别出车牌号；在手机银行APP中可以直接由银行卡的照片中获取银行卡号，进而避免了手动输入可能出现的错误；以及在票务系统中可以用于快速识别纸质票上的序号等等。
## 完成情况
   完成情况：能够实现ov5647摄像头驱动，正常传输视频信号；学习FPGA应用：基于SEA开发板进行图像处理；学习视频传输原理，对视频信号进行处理（灰度化、二值化）；设计存储模块，对FPGA发挥有限资源这个知识点有了更深的理解；实现数字识别（用红线框出数字范围）；学习HDMI显示原理、时序，用HDMI线连接显示屏输出。
   性能参数：灰度化图像正常输出；二值化图像正常输出；识别微软雅黑字体的数字，红线框出待识别数字范围；
## 实践中遇到的问题及解决方案

## 软件平台及板卡型号
   vivado 2018.3
   Spartan7系列的xc7s15ftgb196-1 
## 外设列表：
   1. ov5647摄像头（树莓派摄像头C款）
   2. mini-HDMI连接线
   3. 可兼容720P的显示屏（本实验中为海信电视） 
## 仓库目录介绍： 
   1.README.md 简介 
   2.images 图片 
   3.sourcecode 源码 
   4.ExecutableFiles bit文件 
## 作品照片(附在Images文件夹里面）
