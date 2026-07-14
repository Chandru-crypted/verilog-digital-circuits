`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 15:54:16
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb();

    reg i_clk;
    reg i_resetn;
    reg i_wr_en;
    reg [7:0] i_wr_data;
    reg i_rd_en;
    wire [7:0] o_r_rd_data;
    reg i_fifo_clear;
    wire o_r_flag_full;
    wire o_r_flag_empty;
    wire [2:0] o_r_count;
    wire o_r_flag_almost_empty;

fifo #(
    .DATA_WIDTH_BITS(8),
    .DEPTH_WORDS(3)
) uut (
    .i_clk(i_clk),
    .i_resetn(i_resetn),
    .i_wr_en(i_wr_en),
    .i_wr_data(i_wr_data),
    .i_rd_en(i_rd_en),
    .o_r_rd_data(o_r_rd_data),
    .i_fifo_clear(i_fifo_clear),
    .o_r_flag_full(o_r_flag_full),
    .o_r_flag_empty(o_r_flag_empty),
    .o_r_count(o_r_count),
    .o_r_flag_almost_empty(o_r_flag_almost_empty)
);

initial begin
    i_clk = 1'b0;
    i_resetn = 1'b0;
    i_wr_en = 1'b0;
    i_rd_en = 1'b0;

    repeat (5) @(posedge i_clk); i_resetn <= 1'b0;
    repeat (5) @(posedge i_clk); i_resetn <= 1'b1;
    @(posedge i_clk);    
    
    
    // checking read after write     
     i_wr_en <= 1'b1;
     i_wr_data <= 7'd1;
     @(posedge i_clk);    

     i_wr_en <= 1'b1;
     i_wr_data <= 7'd2;
     @(posedge i_clk);  

     i_wr_en <= 1'b1;
     i_wr_data <= 7'd3;
     @(posedge i_clk);  
     
     i_wr_en <= 1'b0;
     i_rd_en <= 1'b1;
     @(posedge i_clk);      

     i_wr_en <= 1'b0;
     i_rd_en <= 1'b1;
     @(posedge i_clk); 

     i_wr_en <= 1'b0;
     i_rd_en <= 1'b1;
     @(posedge i_clk);    
     @(posedge i_clk);
     @(posedge i_clk);             


    // the next line along with the always block tests the simultaneous write and read operation
     // repeat (20) @(posedge i_clk);
    
    $finish;
end

always #20 i_clk = ~i_clk;

integer i = 1;

//always @(posedge i_clk) begin
//    if (i_resetn) begin
//        if (!o_r_flag_full) begin
//            i_wr_en <= 1'b1;
//            i_wr_data <= i;
//            i <= i + 1;
//        end
//        else begin
//            i_wr_en <= 1'b0;
//        end
//        if (!o_r_flag_empty) begin
//            i_rd_en <= 1'b1;
//        end        
//        else begin
//            i_rd_en <= 1'b0;
//        end
//    end
//end

endmodule
