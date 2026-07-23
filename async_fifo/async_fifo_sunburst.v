`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 16:29:19
// Design Name: 
// Module Name: async_fifo_sunburst
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

// the pointers 
// read does not have any gate is because, reading the same thing does not going to cause any problem
// 
module fifo_mem #(
    DATA_WIDTH_BITS = 8,
    FIFO_DEPTH_BITS = 8
)(
    input i_rdclk,
    input [FIFO_DEPTH_BITS - 1 : 0] i_rdaddr,
    output [DATA_WIDTH_BITS - 1 : 0] o_w_rddata,
    input i_wrclk,
    input i_wrclken,
    input [FIFO_DEPTH_BITS - 1 : 0] i_wraddr,
    input [DATA_WIDTH_BITS - 1 : 0] i_wrdata
);

    // if vendor given ram is present that is preffered
    // for sim, just use verilog array
    localparam FIFO_DEPTH = 1 << FIFO_DEPTH_BITS;
    reg [DATA_WIDTH_BITS - 1 : 0] mem [0 : FIFO_DEPTH - 1];
    
    assign o_w_rddata = mem[i_rdaddr]; // See its combinational, rd_addr is already registered by the r_empty module
    
    always @(posedge i_wrclk) begin
        if (i_wrclken) begin
            mem[i_wraddr] <= i_wrdata;  // memory checks are done here, restrict writing beyond full condition preserve  
        end
    end
    
endmodule

module bin_to_grey #(
    ADDRESS_WIDTH_BITS = 8
)(
    input [ADDRESS_WIDTH_BITS - 1 : 0] i_bin,
    output [ADDRESS_WIDTH_BITS - 1 : 0] o_grey
);
    wire [ADDRESS_WIDTH_BITS : 0] ext_bin;
    assign ext_bin[ADDRESS_WIDTH_BITS] = 1'b0;
    assign ext_bin[ADDRESS_WIDTH_BITS - 1 : 0] = i_bin;
    
    genvar i;
    for (i = 0; i < ADDRESS_WIDTH_BITS; i = i + 1) begin: BIN_TO_GREY_XOR
        assign o_grey[i] =  i_bin[i] ^ ext_bin[i + 1];
    end
endmodule

// generic module that must be instantiated inside 
// empty or full logic that actually decides to increment
// the module always outputs the next ptr to either read or write from
module ptr_inc #(
    ADDRESS_WIDTH_BITS = 8,
    PTR_WIDTH_BITS = ADDRESS_WIDTH_BITS + 1
)
(
    input i_clk,
    input i_resetn,
    input i_inc, // this is condition signal to increment, also called as enable (like write_enable or read_enable)
    input i_stop, // for read - previous empty signal, write - previous full signal
    output o_w_clken,
    output [ADDRESS_WIDTH_BITS - 1 : 0] o_w_ptr_bin, // actual reg holding 
    output reg [PTR_WIDTH_BITS - 1 : 0] o_r_ptr_grey
);
    
    reg [PTR_WIDTH_BITS - 1 : 0] reg_ptr_bin;
    wire inc_gate;
    wire [PTR_WIDTH_BITS - 1 : 0] ptr_bin_inc; // length of the incremented binary is one more bit more than the output
    // since it naturally makes the last MSB high after written a full length of FIFO
    wire [PTR_WIDTH_BITS - 1 : 0] ptr_grey;
    assign inc_gate = i_inc & ~i_stop;
    assign o_w_clken = inc_gate;
    assign ptr_bin_inc = reg_ptr_bin + inc_gate;
    assign o_w_ptr_bin = reg_ptr_bin[ADDRESS_WIDTH_BITS - 1 : 0];

    // Note: Here since we are converting n+1 vbinary pointer to grey we are paremeterzing it with one extra
    bin_to_grey #(.ADDRESS_WIDTH_BITS(PTR_WIDTH_BITS)) b_to_g (
        .i_bin(ptr_bin_inc),
        .o_grey(ptr_grey)
    );
    
    always @(posedge i_clk) begin
        if (!i_resetn) begin
            reg_ptr_bin <= {PTR_WIDTH_BITS{1'b0}};
            o_r_ptr_grey <= {PTR_WIDTH_BITS{1'b0}};
        end
        else begin
            reg_ptr_bin <= ptr_bin_inc;
            o_r_ptr_grey <= ptr_grey;
        end
    end
endmodule

module write_full #(
    ADDRESS_WIDTH_BITS = 8,
    PTR_WIDTH_BITS = ADDRESS_WIDTH_BITS + 1
) (
    input i_wrclk,
    input i_wrresetn,
    input i_wrinc, // this is condition signal to increment, also called as enable (like write_enable or read_enable)
    input [PTR_WIDTH_BITS - 1 : 0] i_wq2_rdgrey_ptr,   
    output [ADDRESS_WIDTH_BITS - 1 : 0] o_w_wraddr,
    output o_w_wrclken,
    output o_w_wrfull,
    output [PTR_WIDTH_BITS - 1 : 0] o_w_wrgrey_ptr
);

    ptr_inc  #(.ADDRESS_WIDTH_BITS(ADDRESS_WIDTH_BITS)) wr_ptr_inc
    (
        .i_clk(i_wrclk),
        .i_resetn(i_wrresetn),
        .i_inc(i_wrinc),
        .i_stop(o_w_wrfull),
        .o_w_clken(o_w_wrclken),
        .o_w_ptr_bin(o_w_wraddr),
        .o_r_ptr_grey(o_w_wrgrey_ptr)
    );
    
    // The MSB two bits must not be equal and other bits must be equal
    assign o_w_wrfull = ((i_wq2_rdgrey_ptr[PTR_WIDTH_BITS - 1] != o_w_wrgrey_ptr[PTR_WIDTH_BITS - 1]) 
                        && (i_wq2_rdgrey_ptr[PTR_WIDTH_BITS - 2] != o_w_wrgrey_ptr[PTR_WIDTH_BITS - 2])
                        && (i_wq2_rdgrey_ptr[PTR_WIDTH_BITS - 3 : 0] == o_w_wrgrey_ptr[PTR_WIDTH_BITS - 3 : 0])
                        );
      
    
endmodule


module read_empty #(
    ADDRESS_WIDTH_BITS = 8,
    PTR_WIDTH_BITS = ADDRESS_WIDTH_BITS + 1
) 
(
    input i_rdclk,
    input i_rdresetn,
    input i_rdinc, // this is condition signal to increment, also called as enable (like write_enable or read_enable)
    input [PTR_WIDTH_BITS - 1 : 0] i_rq2_wrgrey_ptr,   
    output [ADDRESS_WIDTH_BITS - 1 : 0] o_w_rdaddr,
    output o_w_rdclken,
    output o_w_rdempty,
    output [PTR_WIDTH_BITS - 1 : 0] o_w_rdgrey_ptr
);

    ptr_inc  #(.ADDRESS_WIDTH_BITS(ADDRESS_WIDTH_BITS)) rd_ptr_inc
    (
        .i_clk(i_rdclk),
        .i_resetn(i_rdresetn),
        .i_inc(i_rdinc),
        .i_stop(o_w_rdempty),
        .o_w_clken(o_w_rdclken),
        .o_w_ptr_bin(o_w_rdaddr),
        .o_r_ptr_grey(o_w_rdgrey_ptr)
    );
    
    assign o_w_rdempty =  (i_rq2_wrgrey_ptr == o_w_rdgrey_ptr);
endmodule 

module two_stage_FF_sync #(
    WIDTH_BITS = 8)
(
    input i_clk, 
    input i_resetn,
    input [WIDTH_BITS - 1 : 0] i_async_val,
    output [WIDTH_BITS - 1 : 0] o_w_sync_val
);
    reg [WIDTH_BITS - 1 : 0] q1_val, q2_val;
    assign o_w_sync_val = q2_val;
    always @(posedge i_clk) begin
        if (!i_resetn) begin
             q1_val <= {WIDTH_BITS{1'b0}};
             q2_val <= {WIDTH_BITS{1'b0}};
        end
        else begin
            q1_val <= i_async_val;
            q2_val <= q1_val;        
        end
    end
endmodule

module async_fifo_sunburst #(
    DATA_WIDTH_BITS = 8,
    FIFO_DEPTH_BITS = 8
)(
    input i_rdclk,
    input i_rdresetn,
    input i_rdinc, // this is condition signal to increment, also called as enable (like write_enable or read_enable)
    output [DATA_WIDTH_BITS - 1 : 0] o_w_rddata,
    input i_wrclk,
    input i_wrresetn,
    input i_wrinc, // this is condition signal to increment, also called as enable (like write_enable or read_enable)
    input [DATA_WIDTH_BITS - 1 : 0] i_wrdata,
    output o_w_wrfull,
    output o_w_rdempty
    );
    
    wire [FIFO_DEPTH_BITS : 0] wq2_rdgrey_ptr, wrgrey_ptr;
    wire [FIFO_DEPTH_BITS - 1 : 0] wraddr;
    wire wr_clken;
    wire [FIFO_DEPTH_BITS: 0] rq2_wrgrey_ptr, rdgrey_ptr;
    wire [FIFO_DEPTH_BITS - 1 : 0] rdaddr;
    wire rd_clken;
    
    // Since in two stage FF sync, the input is (n + 1).
    two_stage_FF_sync #(.WIDTH_BITS(FIFO_DEPTH_BITS + 1)) rdgrey_sync (
        .i_clk(i_wrclk),
        .i_resetn(i_wrresetn),
        .i_async_val(rdgrey_ptr),
        .o_w_sync_val(wq2_rdgrey_ptr)    
    );
    
    two_stage_FF_sync #(.WIDTH_BITS(FIFO_DEPTH_BITS + 1)) wrgrey_sync (
        .i_clk(i_rdclk),
        .i_resetn(i_rdresetn),
        .i_async_val(wrgrey_ptr),
        .o_w_sync_val(rq2_wrgrey_ptr)
    );

    write_full #(.ADDRESS_WIDTH_BITS(FIFO_DEPTH_BITS)) wr_full_gen (
        .i_wrclk(i_wrclk),
        .i_wrresetn(i_wrresetn),
        .i_wrinc(i_wrinc),
        .i_wq2_rdgrey_ptr(wq2_rdgrey_ptr),
        .o_w_wraddr(wraddr),
        .o_w_wrclken(wr_clken),
        .o_w_wrfull(o_w_wrfull),
        .o_w_wrgrey_ptr(wrgrey_ptr)
    );
    
    read_empty #(.ADDRESS_WIDTH_BITS(FIFO_DEPTH_BITS)) rd_empty_gen (
        .i_rdclk(i_rdclk),
        .i_rdresetn(i_rdresetn),
        .i_rdinc(i_rdinc) ,
        .i_rq2_wrgrey_ptr(rq2_wrgrey_ptr),   
        .o_w_rdaddr(rdaddr),
        .o_w_rdclken(rd_clken),
        .o_w_rdempty(o_w_rdempty),
        .o_w_rdgrey_ptr(rdgrey_ptr)        
    );
    
    fifo_mem #(
        .DATA_WIDTH_BITS(DATA_WIDTH_BITS),
        .FIFO_DEPTH_BITS(FIFO_DEPTH_BITS)
    ) mem (
        .i_rdclk(i_rdclk),
        .i_rdaddr(rdaddr),
        .o_w_rddata(o_w_rddata),
        .i_wrclk(i_wrclk),
        .i_wrclken(wr_clken),
        .i_wraddr(wraddr),
        .i_wrdata(i_wrdata)        
    );
            
endmodule
