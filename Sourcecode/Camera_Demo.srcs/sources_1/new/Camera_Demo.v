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
    //ʱ���ź�
    wire clk_100MHz_system;
    wire clk_200MHz;
    
    //HDMI�ź�
    wire [23:0]rgb_data_src;
    wire rgb_hsync_src;
    wire rgb_vsync_src;
    wire rgb_vde_src;
    wire clk_pixel;
    wire clk_serial;
    
    //ϵͳʱ��
    clk_wiz_0 clk_10(.clk_out1(clk_100MHz_system),.clk_out2(clk_200MHz),.clk_in1(i_clk));
    
    parameter  NUM_ROW    = 1'd1          ;  //��ʶ���ͼ����������ɵ�
    parameter  NUM_COL    = 3'd3          ;  //��ʶ���ͼ����������ɵ�
    parameter  H_PIXEL    = 1280           ;  //ͼ���ˮƽ���أ��ɵ�,Ĭ��Ϊ480
    parameter  V_PIXEL    = 720           ;  //ͼ��Ĵ�ֱ���أ��ɵ���Ĭ��Ϊ272
    parameter  DEPBIT     = 4'd13         ;  //����λ��
    //LCD ID
    localparam  ID_4342 =   0;               //4����Ļ���ֱ��ʣ�480*272
    localparam  ID_7084 =   1;               //7����Ļ���ֱ��ʣ�800*480
    localparam  ID_7016 =   2;               //7����Ļ���ֱ��ʣ�1024*600
    localparam  ID_1018 =   5;               //10.1����Ļ���ֱ��ʣ�1280*800���Ѹ�Ϊ1280*720
    parameter   ID_LCD = ID_1018;            //���ڲ�ͬ��LCd��Ļ�޸ģ���ID_LCD��Ӧ��ֵ���ɣ�Ҳ���������������ã��˴���Ϊ1280*720
    wire clk_100m_lcd    ;  //100mhzʱ��
    wire clk_lcd         ;  //�ṩ��IIC����ʱ�Ӻ�lcd����ʱ��

    wire   [15:0]         ID_lcd          ;  //LCD��ID
    wire   [12:0]         cmos_h_pixel    ;  //CMOSˮƽ�������ظ���
    wire   [12:0]         cmos_v_pixel    ;  //CMOS��ֱ�������ظ���
    wire   [12:0]         total_v_pixel   ;  //��ֱ�����ش�С
    wire   [23:0]         sdram_max_addr  ;  //sdram��д������ַ
    wire                  clk_lcd_g       ;
    wire   [11:0]         digit           ;  //ʶ�𵽵�����
    wire   [15:0]         color_rgb       ;
    wire   [10:0]         xpos            ;  //���ص������
    wire   [10:0]         ypos            ;  //���ص�������
    wire                  hs_t            ;
    wire                  vs_t            ;
    wire                  de_t            ;
    //fifo
    wire                  rd_en           ;  //sdram_ctrlģ���ʹ��
    wire   [23:0]         rd_data         ;  //ԭΪsdram_ctrlģ������ݣ��ּ���֮ǰģ���ȡ��24λRGB888��ʽ��Ƶ�ź�

    wire                lcd_hs      ;  //LCD ��ͬ���ź�
    wire                lcd_vs      ;  //LCD ��ͬ���ź�
    wire                lcd_de      ;  //LCD ��������ʹ��
    wire       [23:0]   lcd_rgb     ;  //ԭ��ΪLCD RGB565��ɫ���ݣ����Ѹ�ΪRGB888
    wire                lcd_bl      ;  //LCD ��������źţ�û�ã�
    wire                lcd_rst     ;  //LCD ��λ�źţ�û�ã�
    wire                lcd_pclk    ; //LCD ����ʱ�ӣ���ȷ����û���ã�


    //����LCD����ģ��
    lcd u_lcd(
        .clk        (clk_100MHz_system),      //100mʱ��
        .rst_n      (i_rst),
        .lcd_hs     (hs_t ),      //��ͬ���������vip��ͼ����ģ�飩��
        .lcd_vs     (vs_t ),     //��ͬ���������vip��
        .lcd_de     (de_t ),      // ʹ�ܣ������vip��
        .lcd_rgb    (color_rgb),    //ԭ��Ϊ�����ͼ����ģ�����ʾģ���rgb565�źţ����Ѹ�Ϊ24λRGB888��ʽ      ***���������ӵ�HDMI��Ϊ�����Ƶ�źţ�
        .lcd_bl     (),         //LCD���� ��û�ã�
        .lcd_rst    (),         //LCD���� ��û�ã�
        .lcd_pclk   (lcd_pclk),         //LCD����ʱ�ӣ�û�ã� 
        .clk_lcd    (clk_lcd),        //lcd��ʱ��
        .pixel_data (rgb_data_src),       //ԭ��Ϊ����fifo����Ƶͼ�����ݣ�RGB565��ʽ�����Ѹ�Ϊ24λRGB888��   ***����������֮ǰ��ģ�鴫������Ƶ�źţ�
        .rd_en      (rd_en  ),       //ԭ��Ϊ�ش���fifo��ʹ�ܣ������lcdÿ������һ������Ϣ�ͻ���֮ǰ��ģ�����������ȡ��Ϣ      ***��δ���ӣ��ɸ�����Ҫ�����Ƿ����ӣ�  
        .ID_lcd     (ID_LCD),      //LCD�ͺ�   ***����������źŷֱ��ʣ��ɸı䣩  
        .pixel_xpos (xpos  ),      //x���꣨�����vip��
        .pixel_ypos (ypos  )           //y���꣨�����vip��
    );

    //ͼ����ģ��
    vip #(
        .NUM_ROW(NUM_ROW),            //ʶ�������֣�Ĭ��Ϊ1
        .NUM_COL(NUM_COL),           //ʶ�𼸸����֣�Ĭ��Ϊ3
        .H_PIXEL(H_PIXEL),           //��ʾ���߶�
        .V_PIXEL(V_PIXEL)            //��ʾ�����
    )u_vip(
        //module clock
        .clk              (clk_100MHz_system),  // ʱ���ź�
        .rst_n            (i_rst),  // ��λ�źţ�����Ч��
        //ͼ����ǰ�����ݽӿ�
        .pre_frame_vsync  (vs_t   ),       //��ͬ��������lcd��
        .pre_frame_hsync  (hs_t   ),        //��ͬ��������lcd��
        .pre_frame_de     (de_t   ),            //ʹ�ܣ�����lcd��
        .pre_rgb          (color_rgb),          //����rgb565�ź�
        .xpos             (xpos   ),            //x���꣨����lcd��
        .ypos             (ypos   ),             //y���꣨����lcd��
        //ͼ���������ݽӿ� 
        .post_frame_vsync (lcd_vs ),  //�����ͬ���ź�         ***����Ϊ����ź�һ���֣�δ���ӣ�
        .post_frame_hsync (lcd_hs ),  // �����ͬ���ź�           ***����Ϊ����ź�һ���֣�δ���ӣ�
        .post_frame_de    (lcd_de ),  // �����������ʹ��            ***��δ���ӣ�
        .post_rgb         (lcd_rgb),  // ���RGB565��ɫ����( ʶ������ı߿�,�Ѹ���Ϊ24λRGB888��        ***�������HDMI��Ϊʶ������ı߿�δ���ӣ�
        //user interface
        .digit            (digit  )   // ʶ�𵽵�����          ***�������ԭ�������������ܣ�Ҳ��������Խӵ�HDMI��δ���ӣ�
    );

    //HDMI����
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
    
    //ͼ��MIPI�ź�תRGB
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
    
    //����ͷIIC��SDA�ߵ���̬�ڵ�
    wire camera_iic_sda_i;
    wire camera_iic_sda_o;
    wire camera_iic_sda_t;
    
    //Tri-state gate
    IOBUF Camera_IIC_SDA_IOBUF
       (.I(camera_iic_sda_o),
        .IO(i_camera_iic_sda),
        .O(camera_iic_sda_i),
        .T(~camera_iic_sda_t));
    
    //����ͷIIC�����ź�
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
    
    //����ͷ����
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
    
    //����ͷIIC����
    Driver_IIC MIPI_Camera_IIC(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_sda(camera_iic_sda_i),
        .i_iic_write(iic_write),                //IICд�ź�,��������Ч
        .i_iic_read(iic_read),                  //IIC���ź�,��������Ч
        .i_iic_mode(iic_mode),                  //IICģʽ,1����˫��ַλ,0������ַλ,��λ��ַ��Ч
        .i_slave_addr(slave_addr),              //IIC�ӻ���ַ
        .i_reg_addr_h(reg_addr_h),              //�Ĵ�����ַ,��8λ
        .i_reg_addr_l(reg_addr_l),              //�Ĵ�����ַ,��8λ
        .i_data_w(data_w),                      //��Ҫ���������
        .o_data_r(data_r),                      //IIC����������
        .o_iic_busy(iic_busy),                  //IICæ�ź�,�ڹ���ʱæ,�͵�ƽæ
        .o_iic_scl(o_camera_iic_scl),           //IICʱ����
        .o_sda_dir(camera_iic_sda_t),           //IIC�����߷���,1�������
        .o_iic_sda(camera_iic_sda_o)            //IIC������
    );
    always @(posedge clk_100MHz_system)
    begin
      if(digit == 000100010001)
         led<=1;
    end
endmodule
