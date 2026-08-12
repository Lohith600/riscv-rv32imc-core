module id_ex_register(
    input clk,
    input reset,

    input compressed,
    input [31:0] rd1_data,
    input [31:0] rd2_data,
    input [31:0] pc,
    input [31:0] next_pc,
    input [31:0] immediate,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input branch,
    input ALU_src,
    input regwrite,
    input memwrite,
    input memread,
    input id_ex_flush,
    input [1:0]memtoreg,
    input jump,
    input jalr,
    input [4:0] ALU_OP,
    input [2:0] branch_type,
    input id_ex_stall,

    output reg [31:0] id_ex_rd1_data,
    output reg [31:0] id_ex_rd2_data,
    output reg [31:0] id_ex_pc,
    output reg [31:0] id_ex_next_pc,
    output reg [31:0] id_ex_immediate,
    output reg [4:0] id_ex_rs1,
    output reg [4:0] id_ex_rs2,
    output reg [4:0] id_ex_rd,

    output reg id_ex_branch,
    output reg id_ex_ALU_src,
    output reg id_ex_regwrite,
    output reg id_ex_memwrite,
    output reg id_ex_memread,
    output reg [1:0] id_ex_memtoreg,
    output reg id_ex_jump,
    output reg id_ex_jalr,
    output reg [4:0] id_ex_ALU_OP,
    output reg [2:0] id_ex_branch_type,
    output reg id_ex_compressed
);

always @(posedge clk or posedge reset)
begin
    if (reset) begin
        id_ex_rd1_data     <= 32'd0;
        id_ex_rd2_data     <= 32'd0;
        id_ex_pc           <= 32'd0;
        id_ex_next_pc      <= 32'd0;
        id_ex_immediate    <= 32'd0;
        id_ex_rs1          <= 5'd0;
        id_ex_rs2          <= 5'd0;
        id_ex_rd           <= 5'd0;
        id_ex_branch       <= 1'b0;
        id_ex_ALU_src      <= 1'b0;
        id_ex_regwrite     <= 1'b0;
        id_ex_memwrite     <= 1'b0;
        id_ex_memread      <= 1'b0;
        id_ex_jump         <= 1'b0;
        id_ex_jalr         <= 1'b0;
        id_ex_memtoreg     <= 2'd0;
        id_ex_ALU_OP       <= 4'd0;
        id_ex_branch_type  <= 3'd0;
        id_ex_compressed   <= 1'b0;
    end
    else if(id_ex_flush) begin
        id_ex_branch       <= 1'b0;
        id_ex_ALU_src      <= 1'b0;
        id_ex_regwrite     <= 1'b0;
        id_ex_memwrite     <= 1'b0;
        id_ex_memread      <= 1'b0;
        id_ex_jump         <= 1'b0;
        id_ex_jalr         <= 1'b0;
        id_ex_memtoreg     <= 2'd0;
        id_ex_ALU_OP       <= 4'd0;
        id_ex_branch_type  <= 3'd0;
        id_ex_compressed   <= 1'b0;
    end
    else if (id_ex_stall) begin
        id_ex_branch       <= id_ex_branch;
        id_ex_ALU_src      <= id_ex_ALU_src;
        id_ex_regwrite     <= id_ex_regwrite;
        id_ex_memwrite     <= id_ex_memwrite;
        id_ex_memread      <= id_ex_memread;
        id_ex_jump         <= id_ex_jump;
        id_ex_jalr         <= id_ex_jalr;
        id_ex_memtoreg     <= id_ex_memtoreg;
        id_ex_ALU_OP       <= id_ex_ALU_OP;
        id_ex_branch_type  <= id_ex_branch_type;
        id_ex_compressed   <= id_ex_compressed;
    end
    else begin
        id_ex_rd1_data    <= rd1_data;
        id_ex_rd2_data    <= rd2_data;
        id_ex_pc          <= pc;
        id_ex_next_pc     <= next_pc;
        id_ex_immediate   <= immediate;
        id_ex_rs1         <= rs1;
        id_ex_rs2         <= rs2;
        id_ex_rd          <= rd;
        id_ex_branch      <= branch;
        id_ex_ALU_src     <= ALU_src;
        id_ex_regwrite    <= regwrite;
        id_ex_memwrite    <= memwrite;
        id_ex_memread     <= memread;
        id_ex_jump        <= jump;
        id_ex_jalr        <= jalr;
        id_ex_memtoreg    <= memtoreg;
        id_ex_ALU_OP      <= ALU_OP;
        id_ex_branch_type <= branch_type;
        id_ex_compressed   <= compressed;
    end
end

endmodule
