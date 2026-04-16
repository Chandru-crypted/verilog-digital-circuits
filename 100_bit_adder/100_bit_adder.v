module full_addr(input a, b, cin, 
                 output sum, cout);
    assign sum = a ^ b ^ cin;
    assign cout = ((a & b) | (cin & a) | (cin & b));
endmodule

module top_module( 
    input [99:0] a, b,
    input cin,
    output cout,
    output [99:0] sum );
	
    wire [100:0] c_in_temp;
    assign c_in_temp[0] = cin;
    assign cout = c_in_temp[100];
    genvar i; // Loop variable
    generate
        for (i = 0; i < 100; i = i + 1) begin : FULL_ADDR_INST
            full_addr fa(.a(a[i]), 
                         .b(b[i]), 
                         .cin(c_in_temp[i]),
                         .sum(sum[i]), 
                         .cout(c_in_temp[i + 1]));
        end
    endgenerate 
endmodule
