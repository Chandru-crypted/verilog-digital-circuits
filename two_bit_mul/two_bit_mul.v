`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:59:15
// Design Name: 
// Module Name: two_bit_mul
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


module two_bit_mul(input [1:0] inp1, inp2,
                            output [3:0] res);
    wire [3:0] partial_prod;
    assign partial_prod[0] = inp2[0] & inp1[0];
    assign partial_prod[1] = inp2[1] & inp1[0];
    assign partial_prod[2] = inp2[0] & inp1[1];
    assign partial_prod[3] = inp2[1] & inp1[1];
    
    assign res[0] = partial_prod[0];
    
    wire carry_part_add;
    
    half_adder ha1(
        .inp1(partial_prod[1]),
        .inp2(partial_prod[2]),
        .sum(res[1]),
        .carry(carry_part_add)        
    );
    
    half_adder ha2(
        .inp1(carry_part_add),
        .inp2(partial_prod[3]),
        .sum(res[2]),
        .carry(res[3])        
    );   
     
endmodule
