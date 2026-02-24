`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 13:33:33
// Design Name: 
// Module Name: tb_full_adder
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

module tb_full_adder();

    wire sum, carry_out;
    reg inp1 , inp2, carry_in; // need for concatenation operator unloading so thats why declared as reg
    
    reg [2:0] input_vec [0:7]; // {carry_in, inp2, inp1}
    reg [1:0] expected_out_vec [0:7]; // {carry_out, sum}
    
    
    full_adder fa1(.inp1(inp1), 
                   .inp2(inp2),
                   .carry_in(carry_in),
                   .sum(sum),
                   .carry_out(carry_out)
                   );    

    integer test_loop_indx;    
    initial begin
        input_vec[0] = 3'b000;
        input_vec[1] = 3'b001;
        input_vec[2] = 3'b010;
        input_vec[3] = 3'b011;
        input_vec[4] = 3'b100;
        input_vec[5] = 3'b101;
        input_vec[6] = 3'b110;
        input_vec[7] = 3'b111;
        
        expected_out_vec[0] = 2'b00;
        expected_out_vec[1] = 2'b01;
        expected_out_vec[2] = 2'b01;
        expected_out_vec[3] = 2'b10;
        expected_out_vec[4] = 2'b01;
        expected_out_vec[5] = 2'b10;
        expected_out_vec[6] = 2'b10;
        expected_out_vec[7] = 2'b11;        
        
        $display("Testing Full adder \n");
        for (test_loop_indx = 0; test_loop_indx < 8; test_loop_indx = test_loop_indx + 1) begin
            {carry_in, inp2, inp1} = input_vec[test_loop_indx];
            #1 // propagation delay
            if ({carry_out, sum} !== expected_out_vec[test_loop_indx]) begin  // !== to compare x, z also
                $display("X Failed [%0d] case \n", test_loop_indx);
            end
            else begin
                $display("Passed [%0d] case \n", test_loop_indx);            
            end
        end    
    end  
    
endmodule
