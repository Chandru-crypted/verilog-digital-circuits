module half_adder(input inp1, inp2,
                    output sum, carry);
    xor(sum, inp1, inp2);
    and(carry, inp1, inp2);
endmodule
