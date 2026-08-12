module if_id_register(
    input clk,
    input reset,
    input if_id_stall,
    input [31:0]pc,
    input compressed,
    input [31:0]next_pc,
    input [31:0]instruction,
    input if_id_flush,
    output reg if_id_compressed,
    output reg [31:0]if_id_pc,
    output reg [31:0]if_id_next_pc,
    output reg [31:0]if_id_instruction
);

always @(posedge clk or posedge reset)
begin
    if (reset) begin
        if_id_pc <= 32'd0;
        if_id_next_pc <= 32'd0;
        if_id_instruction <= 32'd0;
        if_id_compressed <= 1'b0;
    end
    else if (if_id_flush) begin
        if_id_pc <= 32'd0;
        if_id_next_pc <= 32'd0;
        if_id_instruction <= 32'd0;
        if_id_compressed <= 1'b0;
    end
    else if (if_id_stall) begin
        if_id_pc <= if_id_pc;
        if_id_next_pc <= if_id_next_pc;
        if_id_instruction <= if_id_instruction;
        if_id_compressed <= if_id_compressed;
    end
    else begin
        if_id_pc <= pc;
        if_id_next_pc <= next_pc;
        if_id_instruction <= instruction;
        if_id_compressed <= compressed;
    end
end

endmodule