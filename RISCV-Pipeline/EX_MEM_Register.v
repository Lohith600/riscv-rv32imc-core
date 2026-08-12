module ex_mem_register(
    input clk,
    input reset,

    input [31:0] pc,
    input [31:0] next_pc,

    input [31:0] ALU_result,
    input zero_flag,

    input memwrite,
    input memread,
    input [1:0] memtoreg,
    input regwrite,
    input [4:0] rd,
    input [31:0] rs2_data,
    input ex_mem_stall,

    output reg [31:0] ex_mem_next_pc,
    output reg [31:0] ex_mem_ALU_result,
    output reg ex_mem_zero_flag,
    output reg ex_mem_memwrite,
    output reg ex_mem_memread,
    output reg [1:0] ex_mem_memtoreg,
    output reg ex_mem_regwrite,
    output reg [4:0] ex_mem_rd,
    output reg [31:0] ex_mem_rs2_data,
    output reg [31:0] ex_mem_pc
);

always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        ex_mem_ALU_result    <= 32'd0;
        ex_mem_zero_flag     <= 1'd0;
        ex_mem_memwrite      <= 1'd0;
        ex_mem_memread       <= 1'd0;
        ex_mem_memtoreg      <= 2'd0;
        ex_mem_regwrite      <= 1'd0;
        ex_mem_rd            <= 5'd0;
        ex_mem_rs2_data      <= 32'd0;
        ex_mem_next_pc       <= 32'd0;
        ex_mem_pc            <= 32'd0;
    end
    else if (ex_mem_stall) begin
        ex_mem_ALU_result    <= ex_mem_ALU_result;
        ex_mem_zero_flag     <= ex_mem_zero_flag;
        ex_mem_memwrite      <= ex_mem_memwrite;
        ex_mem_memread       <= ex_mem_memread;
        ex_mem_memtoreg      <= ex_mem_memtoreg;
        ex_mem_regwrite      <= ex_mem_regwrite;
        ex_mem_rd            <= ex_mem_rd;
        ex_mem_rs2_data      <= ex_mem_rs2_data;
        ex_mem_next_pc       <= ex_mem_next_pc;
        ex_mem_pc            <= ex_mem_pc;
    end
    else
    begin
        ex_mem_ALU_result    <= ALU_result;
        ex_mem_zero_flag     <= zero_flag;
        ex_mem_memwrite      <= memwrite;
        ex_mem_memread       <= memread;
        ex_mem_memtoreg      <= memtoreg;
        ex_mem_regwrite      <= regwrite;
        ex_mem_rd            <= rd;
        ex_mem_rs2_data      <= rs2_data;
        ex_mem_next_pc       <= next_pc;
        ex_mem_pc            <= pc;
    end
end

endmodule
