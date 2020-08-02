module lcd_driver(
    input              lcd_clk,      
    input              sys_rst_n,    
    output             lcd_hs,       
    output             lcd_vs,       
    output             lcd_de,       
    output             lcd_bl,       
    output             lcd_rst,     
    output             lcd_pclk,     

    output             data_req  ,   
    output     [10:0]  pixel_xpos,   
    output     [10:0]  pixel_ypos,   
    input      [15:0]  ID_lcd       
    );

//parameter define
// 4.3' 480*272
parameter  H_SYNC_4342   =  11'd41;    
parameter  H_BACK_4342   =  11'd2;      
parameter  H_DISP_4342   =  11'd480;    
parameter  H_FRONT_4342  =  11'd2;      
parameter  H_TOTAL_4342  =  11'd525;    

parameter  V_SYNC_4342   =  11'd10;     
parameter  V_BACK_4342   =  11'd2;      
parameter  V_DISP_4342   =  11'd272;    
parameter  V_FRONT_4342  =  11'd2;      
parameter  V_TOTAL_4342  =  11'd286;    

// 7' 800*480
parameter  H_SYNC_7084   =  11'd128;    
parameter  H_BACK_7084   =  11'd88;     
parameter  H_DISP_7084   =  11'd800;    
parameter  H_FRONT_7084  =  11'd40;     
parameter  H_TOTAL_7084  =  11'd1056;   

parameter  V_SYNC_7084   =  11'd2;      
parameter  V_BACK_7084   =  11'd33;     
parameter  V_DISP_7084   =  11'd480;    
parameter  V_FRONT_7084  =  11'd10;    
parameter  V_TOTAL_7084  =  11'd525;    

// 7' 1024*600
parameter  H_SYNC_7016   =  11'd20;     
parameter  H_BACK_7016   =  11'd140;    
parameter  H_DISP_7016   =  11'd1024;   
parameter  H_FRONT_7016  =  11'd160;    
parameter  H_TOTAL_7016  =  11'd1344;   

parameter  V_SYNC_7016   =  11'd3;    
parameter  V_BACK_7016   =  11'd20;    
parameter  V_DISP_7016   =  11'd600;    
parameter  V_FRONT_7016  =  11'd12;    
parameter  V_TOTAL_7016  =  11'd635;    

// 10.1' 1280*720
parameter  H_SYNC_1018   =  11'd40;    
parameter  H_BACK_1018   =  11'd220;    
parameter  H_DISP_1018   =  11'd1280;  
parameter  H_FRONT_1018  =  11'd110;     
parameter  H_TOTAL_1018  =  11'd1650;   

parameter  V_SYNC_1018   =  11'd5;     
parameter  V_BACK_1018   =  11'd20;    
parameter  V_DISP_1018   =  11'd720;   
parameter  V_FRONT_1018  =  11'd5;     
parameter  V_TOTAL_1018  =  11'd750;    

parameter  ID_4342 =   0;
parameter  ID_7084 =   1;
parameter  ID_7016 =   2;
parameter  ID_1018 =   5;

//reg define
reg  [10:0] cnt_h;
reg  [10:0] cnt_v;
reg  [10:0] h_sync ;
reg  [10:0] h_back ;
reg  [10:0] h_disp ;
reg  [10:0] h_total;
reg  [10:0] v_sync ;
reg  [10:0] v_back ;
reg  [10:0] v_disp ;
reg  [10:0] v_total;

//wire define
wire       lcd_en;

//*****************************************************
//**                    main code
//*****************************************************
assign lcd_bl   = 1'b1;          
assign lcd_rst  = 1'b1;           
assign lcd_pclk = lcd_clk;       

assign lcd_de  = lcd_en;          
assign lcd_hs  = cnt_h >= h_sync;
assign lcd_vs  = cnt_v >= v_sync;

assign lcd_en  = (((cnt_h >= h_sync+h_back) && (cnt_h < h_sync+h_back+h_disp))
                 &&((cnt_v >= v_sync+v_back) && (cnt_v < v_sync+v_back+v_disp)))
                 ?  1'b1 : 1'b0;

assign data_req = (((cnt_h >= h_sync+h_back-1'b1) && (cnt_h < h_sync+h_back+h_disp-1'b1))
                  && ((cnt_v >= v_sync+v_back) && (cnt_v < v_sync+v_back+v_disp)))
                  ?  1'b1 : 1'b0;

assign pixel_xpos = data_req ? (cnt_h - (h_sync + h_back - 1'b1)) : 11'd0;
assign pixel_ypos = data_req ? (cnt_v - (v_sync + v_back - 1'b1)) : 11'd0;

always @(*) begin
    case(ID_lcd)
    ID_4342 : begin
        h_sync  = H_SYNC_4342;
        h_back  = H_BACK_4342;
        h_disp  = H_DISP_4342;
        h_total = H_TOTAL_4342;
        v_sync  = V_SYNC_4342;
        v_back  = V_BACK_4342;
        v_disp  = V_DISP_4342;
        v_total = V_TOTAL_4342;
    end
    ID_7084 : begin
        h_sync  = H_SYNC_7084;
        h_back  = H_BACK_7084;
        h_disp  = H_DISP_7084;
        h_total = H_TOTAL_7084;
        v_sync  = V_SYNC_7084;
        v_back  = V_BACK_7084;
        v_disp  = V_DISP_7084;
        v_total = V_TOTAL_7084;
    end
    ID_7016 : begin
        h_sync  = H_SYNC_7016;
        h_back  = H_BACK_7016;
        h_disp  = H_DISP_7016;
        h_total = H_TOTAL_7016;
        v_sync  = V_SYNC_7016;
        v_back  = V_BACK_7016;
        v_disp  = V_DISP_7016;
        v_total = V_TOTAL_7016;
    end
    ID_1018 : begin
        h_sync  = H_SYNC_1018;
        h_back  = H_BACK_1018;
        h_disp  = H_DISP_1018;
        h_total = H_TOTAL_1018;
        v_sync  = V_SYNC_1018;
        v_back  = V_BACK_1018;
        v_disp  = V_DISP_1018;
        v_total = V_TOTAL_1018;
    end
    default : begin
        h_sync  = H_SYNC_4342;
        h_back  = H_BACK_4342;
        h_disp  = H_DISP_4342;
        h_total = H_TOTAL_4342;
        v_sync  = V_SYNC_4342;
        v_back  = V_BACK_4342;
        v_disp  = V_DISP_4342;
        v_total = V_TOTAL_4342;
    end
    endcase
end

always @(posedge lcd_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_h <= 11'd0;
    else begin
        if(cnt_h < h_total - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else
            cnt_h <= 11'd0;
    end
end

always @(posedge lcd_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_v <= 11'd0;
    else if(cnt_h == h_total - 1'b1) begin
        if(cnt_v < v_total - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else
            cnt_v <= 11'd0;
    end
end

endmodule