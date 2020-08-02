
module vip(
    //module clock
    input           clk            ,  
    input           rst_n          ,  

    //����Ϊ����LCDģ���ͬ���źš���Ƶͼ���źţ�24λ������������
    input           pre_frame_vsync,
    input           pre_frame_hsync,
    input           pre_frame_de   ,
    input    [23:0] pre_rgb        ,
    input    [10:0] xpos           ,
    input    [10:0] ypos           ,

    //����ź�
    output          post_frame_vsync,  // ���ͬ��
    output          post_frame_hsync,  // ���ͬ��
    output          post_frame_de   ,  // ���ʹ��
    output   [23:0] post_rgb        ,  // ���24λRGB

    //user interface
    output  [3:0]  digit              // ���ʶ����
);

//parameter define
parameter NUM_ROW = 1  ;               // ʶ��ͼ������
parameter NUM_COL = 3  ;               // ʶ��ͼ�������������ָ�����
parameter H_PIXEL = 1280;               // ͼ����
parameter V_PIXEL = 720;               // ͼ��߶�
parameter DEPBIT  = 13 ;               

//wire define
wire   [ 7:0]         img_y;
wire                  monoc;
wire                  monoc_fall;
wire   [DEPBIT-1:0]   row_border_addr;
wire   [DEPBIT-1:0]   row_border_data;
wire   [DEPBIT-1:0]   col_border_addr;
wire   [DEPBIT-1:0]   col_border_data;
wire   [3:0]          num_col;
wire   [3:0]          num_row;
wire                  hs_t0;
wire                  vs_t0;
wire                  de_t0;
wire   [ 1:0]         frame_cnt;
wire                  project_done_flag;

//*****************************************************
//**                    main code
//*****************************************************

rgb2ycbcr u_rgb2ycbcr(               //RGB565��YCGBR��ȡY���ҶȻ�
    //module clock
    .clk             (clk    ),            
    .rst_n           (rst_n  ),           
    .pre_frame_vsync (pre_frame_vsync),    
    .pre_frame_hsync (pre_frame_hsync),    
    .pre_frame_de    (pre_frame_de   ),    
    .rgb888_r        (pre_rgb[23:15] ),
    .rgb888_g        (pre_rgb[15:8 ] ),
    .rgb888_b        (pre_rgb[ 7:0 ] ),
    .post_frame_vsync(vs_t0),               
    .post_frame_hsync(hs_t0),              
    .post_frame_de   (de_t0),           
    .img_y           (img_y),
    .img_cb          (),
    .img_cr          ()
);

binarization u_binarization(       //��ֵ��
    //module clock
    .clk                (clk    ),          
    .rst_n              (rst_n  ),        
    .pre_frame_vsync    (vs_t0),            
    .pre_frame_hsync    (hs_t0),           
    .pre_frame_de       (de_t0),           
    .color              (img_y),       //����Ҷ�
    .post_frame_vsync   (post_frame_vsync), 
    .post_frame_hsync   (post_frame_hsync), 
    .post_frame_de      (post_frame_de   ), 
    .monoc              (monoc           ), 
    .monoc_fall         (monoc_fall      )
);

projection #(
    .NUM_ROW(NUM_ROW),
    .NUM_COL(NUM_COL),
    .H_PIXEL(H_PIXEL),
    .V_PIXEL(V_PIXEL),
    .DEPBIT (DEPBIT)
) u_projection(
    //module clock
    .clk                (clk    ),         
    .rst_n              (rst_n  ),          
    //Image data interface
    .frame_vsync        (post_frame_vsync), 
    .frame_hsync        (post_frame_hsync), 
    .frame_de           (post_frame_de   ), 
    .monoc              (monoc           ), 
    .ypos               (ypos),
    .xpos               (xpos),
    //project border ram interface
    .row_border_addr_rd (row_border_addr),
    .row_border_data_rd (row_border_data),
    .col_border_addr_rd (col_border_addr),
    .col_border_data_rd (col_border_data),
    //user interface
    .num_col            (num_col),
    .num_row            (num_row),
    .frame_cnt          (frame_cnt),
    .project_done_flag  (project_done_flag)
);

digital_recognition #(
    .NUM_ROW(NUM_ROW),
    .NUM_COL(NUM_COL),
    .H_PIXEL(H_PIXEL),
    .V_PIXEL(V_PIXEL),
    .NUM_WIDTH((NUM_ROW*NUM_COL<<2)-1)
)u_digital_recognition(
    //module clock
    .clk                (clk       ),        
    .rst_n              (rst_n     ),        
    //image data interface
    .monoc              (monoc     ),
    .monoc_fall         (monoc_fall),
    .color_rgb          (post_rgb  ),
    .xpos               (xpos      ),
    .ypos               (ypos      ),
    //project border ram interface
    .row_border_addr    (row_border_addr),
    .row_border_data    (row_border_data),
    .col_border_addr    (col_border_addr),
    .col_border_data    (col_border_data),
    .num_col            (num_col),
    .num_row            (num_row),
    //user interface
    .frame_cnt          (frame_cnt),
    .project_done_flag  (project_done_flag),
    .digit              (digit)
);

endmodule
