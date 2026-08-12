module mem_wb_register(
    input clk,
    input reset,

    input [31:0] next_pc,

    input [31:0] ALU_result,
    input [31:0] mem_out_data,
    input regwrite,
    input [1:0] memtoreg,
    input [4:0] rd,
    input mem_wb_stall,

    output reg [31:0] mem_wb_ALU_result,
    output reg [31:0] mem_wb_mem_out_data,
    output reg mem_wb_regwrite,
    output reg [1:0] mem_wb_memtoreg,
    output reg [4:0] mem_wb_rd,
    output reg [31:0] mem_wb_next_pc
);

always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        mem_wb_ALU_result   <= 32'd0;
        mem_wb_mem_out_data <= 32'd0;
        mem_wb_regwrite     <= 1'd0;
        mem_wb_memtoreg     <= 2'd0;
        mem_wb_rd           <= 5'd0;
        mem_wb_next_pc      <= 32'd0;
    end
    else if (mem_wb_stall) begin
        mem_wb_ALU_result   <= mem_wb_ALU_result;
        mem_wb_mem_out_data <= mem_wb_mem_out_data;
        mem_wb_regwrite     <= mem_wb_regwrite;
        mem_wb_memtoreg     <= mem_wb_memtoreg;
        mem_wb_rd           <= mem_wb_rd;
        mem_wb_next_pc      <= mem_wb_next_pc;
    end
    else
    begin
        mem_wb_ALU_result   <= ALU_result;
        mem_wb_mem_out_data <= mem_out_data;
        mem_wb_regwrite     <= regwrite;
        mem_wb_memtoreg     <= memtoreg;
        mem_wb_rd           <= rd;
        mem_wb_next_pc      <= next_pc;
    end
end

endmodule
