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

    localparam DATA_WIDTH_BITS = 8;
    localparam FIFO_DEPTH_BITS = 3;
    localparam MEM_SIZE = 1 << FIFO_DEPTH_BITS; // 2 ^ 3 = 8 memory locations
    
    logic i_wrclk;
    logic i_rdclk;
    logic i_wrresetn;
    logic i_rdresetn;
    logic i_wrinc;
    logic [DATA_WIDTH_BITS - 1:0] i_wrdata;
    logic i_rdinc;
    logic [DATA_WIDTH_BITS - 1:0] o_w_rddata;
    logic o_w_wrfull;
    logic o_w_rdempty;

async_fifo_sunburst #(
    .DATA_WIDTH_BITS(DATA_WIDTH_BITS),
    .FIFO_DEPTH_BITS(FIFO_DEPTH_BITS)
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

task write_into_fifo(input logic [DATA_WIDTH_BITS - 1:0] in_data);     
     @(posedge i_wrclk);     
     i_wrinc <= 1'b1;
     i_wrdata <= in_data;
     @(posedge i_wrclk);
     i_wrinc <= 1'b0;
endtask

task read_from_fifo();
     @(posedge i_rdclk);     
     i_rdinc <= 1'b1;
     @(posedge i_rdclk);
     i_rdinc <= 1'b0;
endtask

task reset_fifo_both_clks();
    i_wrinc = 1'b0;
    i_rdinc = 1'b0;

    repeat (5) @(posedge i_wrclk); i_wrresetn <= 1'b0; 
    repeat (5) @(posedge i_rdclk); i_rdresetn <= 1'b0; 
    repeat (5) @(posedge i_wrclk); i_wrresetn <= 1'b1; 
    repeat (5) @(posedge i_rdclk); i_rdresetn = 1'b1;
    @(posedge i_wrclk);  
    @(posedge i_rdclk);    
    
endtask
task test_simultaneous_rw(input int num_transactions);
    $display("[TC5 Started] Testing Simultaneous Read and Write...");
    reset_fifo_both_clks();

    fork
        // Write Process Thread
        begin
            $display("Write task started");
            for (int w = 0; w < num_transactions; w++) begin
                // Wait if FIFO is full before writing
                 $display("Before while write %d", w);
                while (o_w_wrfull) @(posedge i_wrclk);
                $display("After while write %d", w);
                write_into_fifo(w + 1);
            end
            $display("Write task end");
            i_wrinc <= 1'b0;
        end

        // Read Process Thread
        begin
            $display("Read task started");
            for (int r = 0; r < num_transactions; r++) begin
                // Wait if FIFO is empty before reading
                $display("Before while read %d", r);
                while (o_w_rdempty) @(posedge i_rdclk);
                $display("After while read %d", r);
                read_from_fifo();
            end
            $display("Read task end");
            i_rdinc <= 1'b0;
        end
    join

    // Allow clock domain synchronization to settle
    repeat (5) @(posedge i_wrclk);
    repeat (5) @(posedge i_rdclk);

endtask

initial begin
    i_rdclk = 1'b0;
    i_wrclk = 1'b0;
    
    i_wrresetn = 1'b0;
    i_rdresetn = 1'b0;

    // Test 0: Out of reset empty flag shd be set and full flag low
    reset_fifo_both_clks();
    assert (o_w_wrfull == 1'b0) else $display("TC0 Failed");
    assert (o_w_rdempty == 1'b1) else $display("TC0 Failed");
    
    // Test 1: Full write and assert full flag is 1
    reset_fifo_both_clks();
    // writing until fifo fulls
    for (int i = 0; i < MEM_SIZE; i++) begin
        write_into_fifo(8'd0 + i);
    end
    @(posedge i_wrclk);  
    assert (o_w_wrfull == 1'b1) else $display("TC1 Failed");
    
    // Test 2: Full write and Full memory read and see if empty flag set is 1
    reset_fifo_both_clks();
    // writing until fifo fulls
    for (int i = 0; i < MEM_SIZE; i++) begin
        write_into_fifo(8'd0 + i);
    end
    @(posedge i_wrclk); 
    @(posedge i_rdclk);
    for (int i = 0; i < MEM_SIZE; i++) begin
        read_from_fifo();
    end
    @(posedge i_rdclk);  
    assert (o_w_rdempty == 1'b1) else $display("TC2 Failed");
    
    // Test 3: One write and empty flag shd go low
     reset_fifo_both_clks();
     write_into_fifo(8'd0);
     repeat (3) @(posedge i_rdclk); // Supposed to make empty flag go low after 2 rd clocks itself
     assert (o_w_rdempty == 1'b0) else $display("TC3 Failed");
     
     // Test 4: Full write and one read shd make full flag go low
     reset_fifo_both_clks();
    // writing until fifo fulls
     for (int i = 0; i < MEM_SIZE; i++) begin
         write_into_fifo(8'd0 + i);
     end
     read_from_fifo();
     repeat (3) @(posedge i_wrclk); 
     assert (o_w_wrfull == 1'b0) else $display("TC4 Failed");

    // Test 5: Reading and writing simultaneosuly but wr clk > rd clk, 
    // Writing exactly 20 items and not writing when full flag is set
    // Reading exactly 20 items and not reading when empty flag is set
    // After equal writes and reads, FIFO should be empty and not full
    $display("Before TC5") ;
    test_simultaneous_rw(20);
    $display("After TC5") ;
    assert (o_w_rdempty == 1'b1) else $display("TC5 Failed: Expected empty flag high");
    assert (o_w_wrfull == 1'b0)  else $display("TC5 Failed: Expected full flag low");
    $display("[TC5 Passed] Simultaneous Read/Write completed successfully.");
              
    $display("All TC passed");
    
     // the next line along with the always block tests the simultaneous write and read operation
      // slowest clock
      // repeat (20) @(posedge i_rdclk);
    
    $finish;
end

always #10 i_wrclk = ~i_wrclk;
always #20 i_rdclk = ~i_rdclk;

//integer i = 1;

//always @(posedge i_wrclk) begin
//    if (i_wrresetn) begin
//        if (!o_w_wrfull) begin
//            i_wrinc <= 1'b1;
//            i_wrdata <= i;
//            i <= i + 1;
//        end
//        else begin
//            i_wrinc <= 1'b0;
//        end
//    end
//end    

//always @(posedge i_rdclk) begin        
//    if (i_rdresetn) begin
//        if (!o_w_rdempty) begin
//            i_rdinc <= 1'b1;
//        end        
//        else begin
//            i_rdinc <= 1'b0;
//        end
//    end
//end

endmodule
