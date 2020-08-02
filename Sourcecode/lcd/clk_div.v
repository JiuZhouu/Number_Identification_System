module clk_div(
    input                 clk    ,
    input                 rst_n  ,
    input  [15:0]         ID_lcd , 
    output reg            clk_lcd  

);

//parameter define
parameter  ID_4342 =  0;
parameter  ID_7084 =  1;
parameter  ID_7016 =  2;
parameter  ID_1018 =  5;

//wire define 
wire  clk_33m;

//reg define 
reg  [1:0]  state_33m_0;
reg  [1:0]  state_33m_1;
reg  [2:0]  cnt_10m;
reg         clk_50m;
reg         clk_10m;

//*****************************************************
//**                    main code
//*****************************************************

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_50m <= 1'b0;
    else 
        clk_50m <= ~ clk_50m ;
end 

//33.3m hz时钟分频
always @ (posedge clk ) begin 
    case (state_33m_0)
        2'b00 : state_33m_0 <= 2'b01;
        2'b01 : state_33m_0 <= 2'b10;
        2'b10 : state_33m_0 <= 2'b00;
    default : state_33m_0 <= 2'b00;
    endcase
end 

always @ (negedge clk ) begin 
    case (state_33m_1)
        2'b00 : state_33m_1 <= 2'b01;
        2'b01 : state_33m_1 <= 2'b10;
        2'b10 : state_33m_1 <= 2'b00;
    default : state_33m_1 <= 2'b00;
    endcase
end 

assign clk_33m = state_33m_0[1] | state_33m_1[1];

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_10m  <= 3'd0;
    else if(cnt_10m == 3'd4)
        cnt_10m <= 3'd0;
    else 
        cnt_10m <= cnt_10m + 1'b1;
end 

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        clk_10m <= 1'b0;
    else if(cnt_10m == 3'd4)
        clk_10m <= ~ clk_10m;
    else
        clk_10m <= clk_10m;
end 
            
always @ ( * ) begin
    case(ID_lcd)
        ID_4342: clk_lcd = clk_10m;
        ID_7084: clk_lcd = clk_33m;
        ID_7016: clk_lcd = clk_50m;
        ID_1018: clk_lcd = clk_50m;
    default : clk_lcd = clk_10m;
    endcase
end 

endmodule 