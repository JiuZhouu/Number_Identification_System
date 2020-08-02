
//****************************************************************************************//

module projection #(
    parameter NUM_ROW =  1 ,
    parameter NUM_COL =  3 ,
    parameter H_PIXEL = 1280,
    parameter V_PIXEL = 720,
    parameter DEPBIT  = 13
)(
    //module clock
    input                      clk               ,    
    input                      rst_n             ,   

    //Image data interface
    input                      frame_vsync       ,    
    input                      frame_hsync       ,   
    input                      frame_de          ,    
    input                      monoc             ,   
    input         [10:0]       xpos              ,
    input         [10:0]       ypos              ,

    //project border ram interface
    input         [DEPBIT-1:0] row_border_addr_rd,
    output        [DEPBIT-1:0] row_border_data_rd,
    input         [DEPBIT-1:0] col_border_addr_rd,
    output        [DEPBIT-1:0] col_border_data_rd,

    //user interface
    output   reg    [3:0]      num_col           ,    
    output   reg    [3:0]      num_row           ,    
    output   reg    [1:0]      frame_cnt         ,    
    output   reg               project_done_flag      
);

//localparam define
localparam st_init    = 2'b00;
localparam st_project = 2'b01;
localparam st_process = 2'b10;

//reg define
reg [ 1:0]          cur_state         ;
reg [ 1:0]          nxt_state         ;
reg [10:0]          cnt               ;
reg                 h_we              ;
reg [10:0]          h_waddr           ;
reg [10:0]          h_raddr           ;
reg                 h_di              ;
reg                 h_do_d0           ;
reg                 v_we              ;
reg [10:0]          v_waddr           ;
reg [10:0]          v_raddr           ;
reg                 v_di              ;
reg                 v_do_d0           ;
reg                 frame_vsync_d0    ;
reg [DEPBIT-1:0]    col_border_addr_wr;
reg [DEPBIT-1:0]    col_border_data_wr;
reg                 col_border_ram_we ;
reg [DEPBIT-1:0]    row_border_addr_wr;
reg [DEPBIT-1:0]    row_border_data_wr;
reg                 row_border_ram_we ;
reg [3:0]           num_col_t         ;
reg [3:0]           num_row_t         ;

//wire define
wire                frame_vsync_fall  ;
wire                h_do              ;
wire                v_do              ;
wire                h_rise            ;
wire                h_fall            ;
wire                v_rise            ;
wire                v_fall            ;

//*****************************************************
//**                    main code
//*****************************************************

assign h_rise =  h_do & ~h_do_d0;
assign h_fall = ~h_do &  h_do_d0;
assign v_rise =  v_do & ~v_do_d0;
assign v_fall = ~v_do &  v_do_d0;
assign frame_vsync_fall = frame_vsync_d0 & ~frame_vsync;

always @(*) begin
    if(project_done_flag && cur_state == st_process)begin
        num_col = num_col_t;
        num_row = num_row_t;
     end
	  else begin
        num_col = num_col;
        num_row = num_row;
     end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_do_d0 <= 1'b0;
        v_do_d0 <= 1'b0;
    end
    else begin
        h_do_d0 <= h_do;
        v_do_d0 <= v_do;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        frame_vsync_d0 <= 1'b0;
    else
        frame_vsync_d0 <= frame_vsync;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        frame_cnt <= 2'd0;
    else if(frame_cnt == 2'd3)
        frame_cnt <= 2'd0;
    else if(frame_vsync_fall)
        frame_cnt <= frame_cnt + 1'd1;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
      cur_state <= st_init;
  else
      cur_state <= nxt_state;
end

always @( * ) begin
    case(cur_state)
        st_init: begin
            if(frame_cnt == 2'd1)      // initial myram
                nxt_state = st_project;
            else
                nxt_state = st_init;
        end
        st_project:begin
            if(frame_cnt == 2'd2)
                nxt_state = st_process;
            else
                nxt_state = st_project;
        end
        st_process:begin
            if(frame_cnt == 2'd0)
                nxt_state = st_init;
            else
                nxt_state = st_process;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_we    <= 1'b0;
        h_waddr <= 11'b0;
        h_raddr <= 11'b0;
        h_di    <= 1'b0;
        v_we    <= 1'b0;
        v_waddr <= 11'b0;
        v_raddr <= 11'b0;
        v_di    <= 1'b0;
        cnt     <= 11'd0;
        num_col_t <=4'b0;
        num_row_t <=4'b0;
        col_border_ram_we<= 1'b0;
        row_border_ram_we<= 1'b0;
        project_done_flag<= 1'b0;
    end
    else case(nxt_state)
        st_init: begin
            if(cnt == H_PIXEL) begin
                cnt     <=  'd0;
                h_we    <= 1'b0;
                h_waddr <=  'd0;
                h_raddr <=  'd0;
                v_raddr <=  'd0;
                num_col_t <=4'b0;
                num_row_t <=4'b0;
                h_di    <= 1'b0;
                v_we    <= 1'b0;
                v_waddr <=  'd0;
                v_di    <= 1'b0;
                col_border_addr_wr <= 0;
                row_border_addr_wr <= 0;
            end
            else begin
                cnt  <= cnt +1'b1;
                h_we <= 1'b1;
                h_waddr <= h_waddr + 1'b1;
                h_di <= 1'b0;
                v_we <= 1'b1;
                v_waddr <= v_waddr + 1'b1;
                v_di <= 1'b0;
            end
        end
        st_project:begin
            if(frame_de &&(!monoc)) begin
                h_we <= 1'b1;
                h_waddr <= xpos;
                h_di <= 1'b1;
                v_we <= 1'b1;
                v_waddr <= ypos;
                v_di <= 1'b1;
            end
            else begin
                h_we <= 1'b0;
                h_waddr <= 'd0;
                h_di <= 1'b0;
                v_we <= 1'b0;
                v_waddr <= 'd0;
                v_di <= 1'b0;
            end
        end
        st_process:begin
            if(h_raddr == H_PIXEL)
                project_done_flag <= 1'b1;
            else begin
                cnt <= 'd0;
                h_raddr <= h_raddr + 1'b1;
                v_raddr <= (v_raddr == V_PIXEL) ? v_raddr : (v_raddr + 1'b1);
                project_done_flag <= 1'b0;
            end
            if(h_rise) begin
                num_col_t <= num_col_t + 1'b1;
                col_border_addr_wr <= col_border_addr_wr + 1'b1;
                col_border_data_wr <= h_raddr - 2'd2;
                col_border_ram_we  <= 1'b1;
            end
            else if(h_fall) begin
                col_border_addr_wr <= col_border_addr_wr + 1'b1;
                col_border_data_wr <= h_raddr + 2'd2;
                col_border_ram_we  <= 1'b1;
            end
            else
                col_border_ram_we <= 1'b0;
            if(v_rise) begin
                num_row_t <= num_row_t + 1'b1;
                row_border_addr_wr <= row_border_addr_wr + 1'b1;
                row_border_data_wr <= v_raddr - 2'd2;
                row_border_ram_we  <= 1'b1;
            end
            else if(v_fall) begin
                row_border_addr_wr <= row_border_addr_wr + 1'b1;
                row_border_data_wr <= v_raddr + 2'd2;
                row_border_ram_we  <= 1'b1;
            end
            else
                row_border_ram_we  <= 1'b0;
        end
    endcase
end

myram #(
    .WIDTH(1  ),
    .DEPTH(H_PIXEL),
    .DEPBIT(DEPBIT)
)u_h_myram(
    //module clock
    .clk(clk),
    //ram interface
    .we(h_we),
    .waddr(h_waddr),
    .raddr(h_raddr),
    .dq_i(h_di),
    .dq_o(h_do)
);

myram #(
    .WIDTH(1  ),
    .DEPTH(V_PIXEL),
    .DEPBIT(DEPBIT)
)u_v_myram(
    //module clock
    .clk(clk),
    //ram interface
    .we(v_we),
    .waddr(v_waddr),
    .raddr(v_raddr),
    .dq_i(v_di),
    .dq_o(v_do)
);

myram #(
    .WIDTH(11),
    .DEPTH(2 * NUM_COL),
    .DEPBIT(DEPBIT)
)u_col_border_myram(
    //module clock
    .clk    (clk),
    //ram interface
    .we     (col_border_ram_we ),
    .waddr  (col_border_addr_wr),
    .raddr  (col_border_addr_rd),
    .dq_i   (col_border_data_wr),
    .dq_o   (col_border_data_rd)
);

myram #(
    .WIDTH(11),
    .DEPTH(2 * NUM_ROW),
    .DEPBIT(DEPBIT)
)u_row_border_myram(
    //module clock
    .clk    (clk),
    //ram interface
    .we     (row_border_ram_we ),
    .waddr  (row_border_addr_wr),
    .raddr  (row_border_addr_rd),
    .dq_i   (row_border_data_wr),
    .dq_o   (row_border_data_rd)
);

endmodule