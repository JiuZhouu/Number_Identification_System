`timescale 1ns / 1ps

module Camera_Demo(
    input i_clk,
    input i_rst,
    input i_clk_rx_data_n,
    input i_clk_rx_data_p,
    input [1:0]i_rx_data_n,
    input [1:0]i_rx_data_p,
    input i_data_n,
    input i_data_p,
    inout i_camera_iic_sda,
    output o_camera_iic_scl,
    output o_camera_gpio,
    output TMDS_Tx_Clk_N,
    output TMDS_Tx_Clk_P,
    output [2:0]TMDS_Tx_Data_N,
    output [2:0]TMDS_Tx_Data_P,
    output reg led
    );
    //时钟信号
    wire clk_100MHz_system;
    wire clk_200MHz;
    
    //HDMI信号
    wire [23:0]rgb_data_src;
    wire rgb_hsync_src;
    wire rgb_vsync_src;
    wire rgb_vde_src;
    wire clk_pixel;
    wire clk_serial;
    
    //系统时钟
    clk_wiz_0 clk_10(.clk_out1(clk_100MHz_system),.clk_out2(clk_200MHz),.clk_in1(i_clk));
    
    parameter  NUM_ROW    = 1'd1          ;  //需识别的图像的行数，可调
    parameter  NUM_COL    = 3'd3          ;  //需识别的图像的列数，可调
    parameter  H_PIXEL    = 1280           ;  //图像的水平像素，可调,默认为480
    parameter  V_PIXEL    = 720           ;  //图像的垂直像素，可调，默认为272
    parameter  DEPBIT     = 4'd13         ;  //数据位宽
    //LCD ID
    localparam  ID_4342 =   0;               //4寸屏幕，分辨率：480*272
    localparam  ID_7084 =   1;               //7寸屏幕，分辨率：800*480
    localparam  ID_7016 =   2;               //7寸屏幕，分辨率：1024*600
    localparam  ID_1018 =   5;               //10.1寸屏幕，分辨率：1280*800，已改为1280*720
    parameter   ID_LCD = ID_1018;            //对于不同的LCd屏幕修改，赋ID_LCD对应的值即可，也可以自行另外设置，此处设为1280*720
    wire clk_100m_lcd    ;  //100mhz时钟
    wire clk_lcd         ;  //提供给IIC驱动时钟和lcd驱动时钟

    wire   [15:0]         ID_lcd          ;  //LCD的ID
    wire   [12:0]         cmos_h_pixel    ;  //CMOS水平方向像素个数
    wire   [12:0]         cmos_v_pixel    ;  //CMOS垂直方向像素个数
    wire   [12:0]         total_v_pixel   ;  //垂直总像素大小
    wire   [23:0]         sdram_max_addr  ;  //sdram读写的最大地址
    wire                  clk_lcd_g       ;
    wire   [11:0]         digit           ;  //识别到的数字
    wire   [15:0]         color_rgb       ;
    wire   [10:0]         xpos            ;  //像素点横坐标
    wire   [10:0]         ypos            ;  //像素点纵坐标
    wire                  hs_t            ;
    wire                  vs_t            ;
    wire                  de_t            ;
    //fifo
    wire                  rd_en           ;  //sdram_ctrl模块读使能
    wire   [23:0]         rd_data         ;  //原为sdram_ctrl模块读数据，现即从之前模块获取的24位RGB888格式视频信号

    wire                lcd_hs      ;  //LCD 行同步信号
    wire                lcd_vs      ;  //LCD 场同步信号
    wire                lcd_de      ;  //LCD 数据输入使能
    wire       [23:0]   lcd_rgb     ;  //原本为LCD RGB565颜色数据，现已改为RGB888
    wire                lcd_bl      ;  //LCD 背光控制信号（没用）
    wire                lcd_rst     ;  //LCD 复位信号（没用）
    wire                lcd_pclk    ; //LCD 采样时钟（不确定有没有用）


    //例化LCD顶层模块
    lcd u_lcd(
        .clk        (clk_100MHz_system),      //100m时钟
        .rst_n      (i_rst),
        .lcd_hs     (hs_t ),      //场同步（输出至vip（图像处理模块））
        .lcd_vs     (vs_t ),     //行同步（输出至vip）
        .lcd_de     (de_t ),      // 使能（输出至vip）
        .lcd_rgb    (color_rgb),    //原本为输出到图像处理模块和显示模块的rgb565信号，现已改为24位RGB888格式      ***（这里连接到HDMI作为输出视频信号）
        .lcd_bl     (),         //LCD背光 （没用）
        .lcd_rst    (),         //LCD重置 （没用）
        .lcd_pclk   (lcd_pclk),         //LCD采样时钟（没用） 
        .clk_lcd    (clk_lcd),        //lcd内时钟
        .pixel_data (rgb_data_src),       //原本为来自fifo的视频图像数据，RGB565格式（现已改为24位RGB888）   ***（这里连接之前的模块传来的视频信号）
        .rd_en      (rd_en  ),       //原本为回传到fifo的使能，即完成lcd每处理完一部分信息就会向之前的模块请求继续读取信息      ***（未连接，可根据需要决定是否连接）  
        .ID_lcd     (ID_LCD),      //LCD型号   ***（决定输出信号分辨率，可改变）  
        .pixel_xpos (xpos  ),      //x坐标（输出至vip）
        .pixel_ypos (ypos  )           //y坐标（输出至vip）
    );

    //图像处理模块
    vip #(
        .NUM_ROW(NUM_ROW),            //识别几行数字，默认为1
        .NUM_COL(NUM_COL),           //识别几个数字，默认为3
        .H_PIXEL(H_PIXEL),           //显示屏高度
        .V_PIXEL(V_PIXEL)            //显示屏宽度
    )u_vip(
        //module clock
        .clk              (clk_100MHz_system),  // 时钟信号
        .rst_n            (i_rst),  // 复位信号（低有效）
        //图像处理前的数据接口
        .pre_frame_vsync  (vs_t   ),       //行同步（来自lcd）
        .pre_frame_hsync  (hs_t   ),        //场同步（来自lcd）
        .pre_frame_de     (de_t   ),            //使能（来自lcd）
        .pre_rgb          (color_rgb),          //输入rgb565信号
        .xpos             (xpos   ),            //x坐标（来自lcd）
        .ypos             (ypos   ),             //y坐标（来自lcd）
        //图像处理后的数据接口 
        .post_frame_vsync (lcd_vs ),  //输出场同步信号         ***（作为输出信号一部分，未连接）
        .post_frame_hsync (lcd_hs ),  // 输出行同步信号           ***（作为输出信号一部分，未连接）
        .post_frame_de    (lcd_de ),  // 输出数据输入使能            ***（未连接）
        .post_rgb         (lcd_rgb),  // 输出RGB565颜色数据( 识别区域的边框,已更改为24位RGB888）        ***（输出到HDMI作为识别区域的边框，未连接）
        //user interface
        .digit            (digit  )   // 识别到的数字          ***（输出，原本是输出到数码管，也许可以试试接到HDMI，未连接）
    );

    //HDMI驱动
    rgb2dvi_0 Mini_HDMI_Driver(
      .TMDS_Clk_p(TMDS_Tx_Clk_P),     // output wire TMDS_Clk_p
      .TMDS_Clk_n(TMDS_Tx_Clk_N),     // output wire TMDS_Clk_n
      .TMDS_Data_p(TMDS_Tx_Data_P),      // output wire [2 : 0] TMDS_Data_p
      .TMDS_Data_n(TMDS_Tx_Data_N),      // output wire [2 : 0] TMDS_Data_n
      .aRst_n(i_rst),                   // input wire aRst_n
      .vid_pData(lcd_rgb),         // input wire [23 : 0] vid_pData
      .vid_pVDE(rgb_vde_src),           // input wire vid_pVDE
      .vid_pHSync(rgb_hsync_src),       // input wire vid_pHSync
      .vid_pVSync(rgb_vsync_src),       // input wire vid_pVSync
      .PixelClk(clk_pixel)
    );
    
    //图像MIPI信号转RGB
    Driver_MIPI MIPI_Trans_Driver(
        .i_clk_200MHz(clk_200MHz),
        .i_clk_rx_data_n(i_clk_rx_data_n),
        .i_clk_rx_data_p(i_clk_rx_data_p),
        .i_rx_data_n(i_rx_data_n),
        .i_rx_data_p(i_rx_data_p),
        .i_data_n(i_data_n),
        .i_data_p(i_data_p),
        .o_camera_gpio(o_camera_gpio),
        .o_rgb_data(rgb_data_src),
        .o_rgb_hsync(rgb_hsync_src),
        .o_rgb_vsync(rgb_vsync_src),
        .o_rgb_vde(rgb_vde_src),
        .o_set_x(),
        .o_set_y(),
        .o_clk_pixel(clk_pixel)
    );
    
    //摄像头IIC的SDA线的三态节点
    wire camera_iic_sda_i;
    wire camera_iic_sda_o;
    wire camera_iic_sda_t;
    
    //Tri-state gate
    IOBUF Camera_IIC_SDA_IOBUF
       (.I(camera_iic_sda_o),
        .IO(i_camera_iic_sda),
        .O(camera_iic_sda_i),
        .T(~camera_iic_sda_t));
    
    //摄像头IIC驱动信号
    wire iic_busy;
    wire iic_mode;
    wire [7:0]slave_addr;
    wire [7:0]reg_addr_h;
    wire [7:0]reg_addr_l;
    wire [7:0]data_w;
    wire [7:0]data_r;
    wire iic_write;
    wire iic_read;
    wire ov5647_ack;
    
    //摄像头驱动
    OV5647_Init MIPI_Camera_Driver(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_busy(iic_busy),
        .o_iic_mode(iic_mode),          
        .o_slave_addr(slave_addr),    
        .o_reg_addr_h(reg_addr_h),   
        .o_reg_addr_l(reg_addr_l),   
        .o_data_w(data_w),      
        .o_iic_write(iic_write),
        .o_ack(ov5647_ack)                 
    );
    
    //摄像头IIC驱动
    Driver_IIC MIPI_Camera_IIC(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_sda(camera_iic_sda_i),
        .i_iic_write(iic_write),                //IIC写信号,上升沿有效
        .i_iic_read(iic_read),                  //IIC读信号,上升沿有效
        .i_iic_mode(iic_mode),                  //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
        .i_slave_addr(slave_addr),              //IIC从机地址
        .i_reg_addr_h(reg_addr_h),              //寄存器地址,高8位
        .i_reg_addr_l(reg_addr_l),              //寄存器地址,低8位
        .i_data_w(data_w),                      //需要传输的数据
        .o_data_r(data_r),                      //IIC读到的数据
        .o_iic_busy(iic_busy),                  //IIC忙信号,在工作时忙,低电平忙
        .o_iic_scl(o_camera_iic_scl),           //IIC时钟线
        .o_sda_dir(camera_iic_sda_t),           //IIC数据线方向,1代表输出
        .o_iic_sda(camera_iic_sda_o)            //IIC数据线
    );
    always @(posedge clk_100MHz_system)
    begin
      if(digit == 000100010001)
         led<=1;
    end
endmodule
