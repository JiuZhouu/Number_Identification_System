
module myram #(
    parameter WIDTH = 1  ,               
    parameter DEPTH = 800,               
    parameter DEPBIT= 10                 
)(
    //module clock
    input                     clk  ,     /

    //ram interface
    input                     we   ,
    input  [DEPBIT- 1'b1:0]   waddr,
    input  [DEPBIT- 1'b1:0]   raddr,
    input  [WIDTH - 1'b1:0]   dq_i ,
    output [WIDTH - 1'b1:0]   dq_o

    //user interface
);

//reg define
reg [WIDTH - 1'b1:0] mem [DEPTH - 1'b1:0];

assign dq_o = mem[raddr];

always @ (posedge clk) begin
    if(we)
        mem[waddr-1] <= dq_i;
end

endmodule




