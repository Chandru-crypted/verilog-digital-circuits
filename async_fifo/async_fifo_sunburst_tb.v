`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2026 17:32:30
// Design Name: 
// Module Name: async_fifo_sunburst_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_fifo_sunburst_tb();

    reg i_wrclk;
    reg i_rdclk;
    reg i_wrresetn;
    reg i_rdresetn;
    reg i_wrinc;
    reg [7:0] i_wrdata;
    reg i_rdinc;
    wire [7:0] o_w_rddata;
    wire o_w_wrfull;
    wire o_w_rdempty;

async_fifo_sunburst #(
    .DATA_WIDTH_BITS(8),
    .FIFO_DEPTH_BITS(3)
) uut (
    .i_rdclk(i_rdclk),
    .i_rdresetn(i_rdresetn),
    .i_rdinc(i_rdinc),
    .o_w_rddata(o_w_rddata),
    .i_wrclk(i_wrclk),
    .i_wrresetn(i_wrresetn),
    .i_wrinc(i_wrinc),
    .i_wrdata(i_wrdata),
    .o_w_wrfull(o_w_wrfull),
    .o_w_rdempty(o_w_rdempty)
    );
    
initial begin
    i_rdclk = 1'b0;
    i_wrclk = 1'b0;
    
    i_wrresetn = 1'b0;
    i_rdresetn = 1'b0;

    i_wrinc = 1'b0;
    i_rdinc = 1'b0;

    repeat (5) @(posedge i_wrclk); i_wrresetn <= 1'b0; 
    repeat (5) @(posedge i_rdclk); i_rdresetn <= 1'b0; 
    
    repeat (5) @(posedge i_wrclk); i_wrresetn <= 1'b1; 
    repeat (5) @(posedge i_rdclk); i_rdresetn = 1'b1;
    
    @(posedge i_wrclk);  
    @(posedge i_rdclk);    
    
//    // checking read after write     
//     @(posedge i_wrclk);     
//     i_wrinc <= 1'b1;
//     i_wrdata <= 7'd1;
//     @(posedge i_wrclk);     

//     i_wrinc <= 1'b1;
//     i_wrdata <= 7'd2;
//     @(posedge i_wrclk);  

//     i_wrinc <= 1'b1;
//     i_wrdata <= 7'd3;
//     @(posedge i_wrclk);  
     
//     i_wrinc <= 1'b0;
//     @(posedge i_wrclk);  
//     i_rdinc <= 1'b1;
//     @(posedge i_rdclk);      

//     i_wrinc <= 1'b0;
//     i_rdinc <= 1'b1;
//     @(posedge i_rdclk); 

//     i_wrinc <= 1'b0;
//     i_rdinc <= 1'b1;
//     @(posedge i_rdclk);    
//     @(posedge i_rdclk);
//     @(posedge i_rdclk);             


     // the next line along with the always block tests the simultaneous write and read operation
      // slowest clock
      repeat (20) @(posedge i_rdclk);
    
    $finish;
end

always #10 i_wrclk = ~i_wrclk;
always #20 i_rdclk = ~i_rdclk;

integer i = 1;

always @(posedge i_wrclk) begin
    if (i_wrresetn) begin
        if (!o_w_wrfull) begin
            i_wrinc <= 1'b1;
            i_wrdata <= i;
            i <= i + 1;
        end
        else begin
            i_wrinc <= 1'b0;
        end
    end
end    

always @(posedge i_rdclk) begin        
    if (i_rdresetn) begin
        if (!o_w_rdempty) begin
            i_rdinc <= 1'b1;
        end        
        else begin
            i_rdinc <= 1'b0;
        end
    end
end

endmodule
