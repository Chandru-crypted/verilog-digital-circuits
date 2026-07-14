`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 15:53:51
// Design Name: 
// Module Name: fifo
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



//The following test cases the FIFO must work 

//Reading happens after write

//1. Full write no read
//   1. write upto the end and check if the full flag is set. 
//   2. check the length of data digested is the max and equal to the FIFO capacity
//2. over writing when the FIFO is full
//   1. When the full flag is set any write operation is ignored and the wr pointer shd remain unchanged
//   2. check the write pointer it shd remain unchanged (since wr ptr points always to the next position to write)
//3. Full read no write
//   1. fill the FIFO to full
//   2. read upto the start and check if the empty flag is set. 
//   3. check the length of data read is the max and equal to the FIFO capacity
//4. over reading when the FIFO is empty
//   1. When the empty flag is set, any read operation is ignored and the rd pointer shd stay at 0
//   2. check the read pointer it shd be equal to 0, and the empty flag should not change (since rd ptr points always to the next position to read)
//5. if the FIFO is filled above half and also read, and writing a FIFO length and then reading shd give all the contents that is written

//Reading and writing separately

//1. When the fifo is filled half and also read, simulateneous read and write shd not change the count 
//2. When fifo is filled full, and both read and write flags are high 
//3. When fifo is emptied both read and write flags are high
//   1. The empty flag shd become zero since its written right
//   2. (Technically the read en shd not be set the consumer when its empty)
//4. When fifo is full both read and write flags are high
//   1. The complete flag shd become zero since its read 
//   2. (Technicallly write en shd not be set by the consumer when its full)

//After reset the 
//full flag must be 0 
//empty flag must be 1

//At reset the empty flag is high when no write is happening it should continue to stay high


// Assuming the minimum depth is greater than 2
module fifo #(
    DATA_WIDTH_BITS = 8,
    DEPTH_WORDS = 16,
    COUNTER_WIDTH_BITS = 4 // always log2(DEPTH_WORDS)
) 
(
    input i_clk,
    input i_resetn,
    input i_wr_en,
    input [DATA_WIDTH_BITS - 1 : 0] i_wr_data,
    input i_rd_en,
    output reg [DATA_WIDTH_BITS - 1 : 0] o_r_rd_data,
    input i_fifo_clear,
    output reg o_r_flag_full,
    output reg o_r_flag_empty,
    output reg [DEPTH_WORDS - 1 : 0] o_r_count,
    output reg o_r_flag_almost_empty
);


reg [DATA_WIDTH_BITS - 1 : 0] fifo [DEPTH_WORDS - 1 : 0];

reg [COUNTER_WIDTH_BITS - 1 : 0] rd_ptr, wr_ptr;
wire [COUNTER_WIDTH_BITS - 1 : 0] incr_wr_ptr, incr_rd_ptr, next_wr_ptr, next_rd_ptr;

assign incr_wr_ptr = wr_ptr + 1'b1;
assign incr_rd_ptr = rd_ptr + 1'b1;
assign next_wr_ptr = (incr_wr_ptr == DEPTH_WORDS) ? 1'b0 : incr_wr_ptr;
assign next_rd_ptr = (incr_rd_ptr == DEPTH_WORDS) ? 1'b0 : incr_rd_ptr;

always @(posedge i_clk) begin
    if (!i_resetn) begin
        rd_ptr <= {DEPTH_WORDS{1'b0}};
        wr_ptr <= {DEPTH_WORDS{1'b0}};
        o_r_flag_full <= 1'b0;
        o_r_flag_empty <= 1'b0;
        o_r_count <= {DEPTH_WORDS{1'b0}};
        o_r_flag_full <= 1'b0;
        o_r_flag_empty <= 1'b1;
    end
    else begin
        // write operation takes precedance over read operation
        if (i_wr_en) begin
            if (o_r_count < DEPTH_WORDS) begin
                wr_ptr <= next_wr_ptr;
                fifo[wr_ptr] <= i_wr_data;
            end
        end
        if (i_rd_en) begin
            if (o_r_count > 1'b0) begin
                rd_ptr <= next_rd_ptr;
                o_r_rd_data <= fifo[rd_ptr];           
            end
        end
    
        // no change in count if both read and write flag are high, no incr or decr
        if (i_wr_en && !i_rd_en)
            o_r_count <= o_r_count + 1'b1;
        if (!i_wr_en && i_rd_en)
            o_r_count <= o_r_count - 1'b1;           

        // --- EMPTY FLAG LOGIC ---
        if ((o_r_count == 1) && i_rd_en && !i_wr_en) begin
            o_r_flag_empty <= 1'b1; // Last item is being read
        end else if ((o_r_count == 0) && !i_wr_en) begin
            o_r_flag_empty <= 1'b1; // Catch/hold state for reset/empty stability
        end else if (i_wr_en) begin
            o_r_flag_empty <= 1'b0; // Any write means we aren't empty anymore
        end

        // --- FULL FLAG LOGIC ---
        if ((o_r_count == (DEPTH_WORDS - 1)) && i_wr_en && !i_rd_en) begin
            o_r_flag_full <= 1'b1;  // Last slot is being filled
        end else if ((o_r_count == DEPTH_WORDS) && !i_rd_en) begin
            o_r_flag_full <= 1'b1;  // Catch/hold state for full stability
        end else if (i_rd_en) begin
            o_r_flag_full <= 1'b0;  // Any read means we aren't full anymore
        end
        
    end
end
endmodule
