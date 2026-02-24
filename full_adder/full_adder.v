`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 13:32:29
// Design Name: 
// Module Name: full_adder
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

module full_adder(input inp1, inp2, carry_in,
                    output sum, carry_out);
    wire temp_sum1, temp_carry1, temp_carry2;
    half_adder ha1(
        .inp1(inp1),
        .inp2(inp2),
        .sum(temp_sum1),
        .carry(temp_carry1)
        );
    half_adder ha2(
        .inp1(temp_sum1),
        .inp2(carry_in),
        .sum(sum),
        .carry(temp_carry2)
    );
    or(carry_out, temp_carry1, temp_carry2); 
endmodule
