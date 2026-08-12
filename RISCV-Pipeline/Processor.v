module processor(
    input clk,
    input reset
);

reg [31:0] next_pc;
wire [31:0] instruction;
reg branch_taken;
wire jump;
wire jalr;
wire [31:0] immediate;
wire [31:0] PC;
reg [31:0] register_data;

wire [31:0] if_id_pc;
wire [31:0] if_id_next_pc;
wire [31:0] if_id_instruction;
wire if_id_compressed;

wire [2:0] branch_type;
wire zero_flag;
wire [31:0] ALU_result;

wire branch;
wire ALU_src;
wire regwrite;
wire memwrite;
wire memread;
wire [1:0]memtoreg;
wire [4:0] ALU_OP;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;

wire [31:0] id_ex_rd1_data;
wire [31:0] id_ex_rd2_data;
wire [31:0] id_ex_pc;
wire [31:0] id_ex_next_pc;
wire [31:0] id_ex_immediate;
wire [4:0] id_ex_rs1;
wire [4:0] id_ex_rs2;
wire [4:0] id_ex_rd;
wire id_ex_branch;
wire id_ex_ALU_src;
wire id_ex_regwrite;
wire id_ex_memwrite;
wire id_ex_memread;
wire [1:0] id_ex_memtoreg;
wire id_ex_jump;
wire id_ex_jalr;
wire [4:0] id_ex_ALU_OP;
wire [2:0] id_ex_branch_type;
wire id_ex_stall;
wire id_ex_compressed;

wire [31:0] ex_mem_next_pc;
wire [31:0] ex_mem_ALU_result;
wire ex_mem_zero_flag;
wire ex_mem_memwrite;
wire ex_mem_memread;
wire [1:0] ex_mem_memtoreg;
wire ex_mem_regwrite;
wire [4:0] ex_mem_rd;
wire [31:0] ex_mem_rs2_data;
wire ex_mem_stall;
wire [31:0] ex_mem_pc;

wire [31:0] rd1_data;
wire [31:0] rd2_data;

wire alu_zero_src1;
wire [31:0] alu_operand1;
wire [31:0] alu_operand2;

wire [31:0] mem_out_data;

wire [31:0] mem_wb_ALU_result;
wire [31:0] mem_wb_mem_out_data;
wire mem_wb_regwrite;
wire [1:0] mem_wb_memtoreg;
wire [4:0] mem_wb_rd;
wire [31:0] mem_wb_next_pc;
wire mem_wb_stall;

wire [31:0] forwarded_input1;
wire [31:0] forwarded_input2;

wire OR_pc_write;
wire pc_write_load;
wire if_id_stall_load;
wire id_ex_flush_load;

wire id_ex_flush_j_type;
wire if_id_flush_j_type;

wire if_id_flush_b_type;
wire id_ex_flush_b_type;
wire [31:0] predicted_next_pc;
wire [31:0] correct_pc;
wire OR_if_id_flush;
wire OR_if_id_stall;

wire OR_id_ex_flush;

wire compressed;
wire [15:0] upper_16;
wire [15:0] lower_16;
wire [31:0] next_sequencial_pc; // for jump and jalr return value storing.

localparam [2:0] BEQ  = 3'b000;
localparam [2:0] BNE  = 3'b001;
localparam [2:0] BLT  = 3'b100;
localparam [2:0] BGE  = 3'b101;
localparam [2:0] BLTU = 3'b110;
localparam [2:0] BGEU = 3'b111;


// Instruction fetch.
assign OR_pc_write = pc_write_load;
Program_Counter program_Counter_block(.clk(clk), .reset(reset), .pc_write(OR_pc_write), .next_PC(next_pc), .PC(PC));
Instruction_memory instruction_mem(.PC(PC), .upper_16(upper_16), .lower_16(lower_16));
compressed_decoder compressed_decoder_unit(.lower_16(lower_16), .upper_16(upper_16), .compressed(compressed), .instruction_out(instruction));

// IF_ID_Register.
assign OR_if_id_stall = if_id_stall_load;
assign next_sequencial_pc = (compressed) ? PC + 32'd2 : PC + 32'd4;
if_id_register if_id_reg(.clk(clk), .reset(reset), .if_id_stall(OR_if_id_stall), .pc(PC), .compressed(compressed), .next_pc(next_sequencial_pc)
, .instruction(instruction), .if_id_flush(OR_if_id_flush), .if_id_pc(if_id_pc), .if_id_next_pc(if_id_next_pc), .if_id_instruction(if_id_instruction), .if_id_compressed(if_id_compressed));

// Hazard Detection Unit.
hazard_detection_unit hazard_unit(.id_ex_memread(id_ex_memread), .rs1(rs1), .rs2(rs2), .id_ex_rd(id_ex_rd), .pc_write(pc_write_load), .if_id_stall(if_id_stall_load), .id_ex_flush(id_ex_flush_load));

// Control Hazard Unit.
assign OR_id_ex_flush = (id_ex_flush_load || id_ex_flush_j_type || id_ex_flush_b_type);
control_hazard_unit control_hazard(.jump(id_ex_jump), .jalr(id_ex_jalr), .if_id_flush(if_id_flush_j_type), .id_ex_flush(id_ex_flush_j_type));

// Branch Prediction Unit.
assign OR_if_id_flush = (if_id_flush_b_type || if_id_flush_j_type);
branch_prediction_unit branch_pred_unit(.clk(clk), .branch(id_ex_branch), .if_compressed(compressed), .id_ex_compressed(id_ex_compressed), .branch_taken_status(branch_taken)
, .if_branch_pc(PC), .alu_branch_pc(id_ex_pc), .immediate(id_ex_immediate), .predicted_next_pc(predicted_next_pc), .correct_pc(correct_pc), .if_id_flush(if_id_flush_b_type), .id_ex_flush(id_ex_flush_b_type));

// Instruction decode.
decode decode_block(.instruction(if_id_instruction), .branch(branch), .ALU_src(ALU_src), .regwrite(regwrite), .memwrite(memwrite), .memread(memread), .memtoreg(memtoreg), .jump(jump), .jalr(jalr), .ALU_OP(ALU_OP), .rs1(rs1), .rs2(rs2), .rd(rd), .branch_type(branch_type), .alu_zero_src1(alu_zero_src1));
immediate_generator immed(.instruction(if_id_instruction), .immediate(immediate));
register_file reg_file(.rs1(rs1), .rs2(rs2), .rd(mem_wb_rd), .write_data(register_data), .regwrite(mem_wb_regwrite), .clk(clk), .rd1_data(rd1_data), .rd2_data(rd2_data));

// ID_EX_Register.
id_ex_register id_ex_reg(.clk(clk), .reset(reset), .compressed(if_id_compressed), .rd1_data(rd1_data), .rd2_data(rd2_data), .pc(if_id_pc), .next_pc(if_id_next_pc)
, .immediate(immediate), .rs1(rs1), .rs2(rs2), .rd(rd), .branch(branch), .ALU_src(ALU_src), .regwrite(regwrite), .memwrite(memwrite), .memread(memread),
.id_ex_flush(OR_id_ex_flush), .memtoreg(memtoreg), .jump(jump), .jalr(jalr), .ALU_OP(ALU_OP), .branch_type(branch_type)
, .id_ex_stall(id_ex_stall), .id_ex_rd1_data(id_ex_rd1_data), .id_ex_rd2_data(id_ex_rd2_data), .id_ex_pc(id_ex_pc), .id_ex_next_pc(id_ex_next_pc),
.id_ex_immediate(id_ex_immediate), .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .id_ex_rd(id_ex_rd), .id_ex_branch(id_ex_branch), .id_ex_ALU_src(id_ex_ALU_src), .id_ex_regwrite(id_ex_regwrite), .id_ex_memwrite(id_ex_memwrite),
.id_ex_memread(id_ex_memread), .id_ex_memtoreg(id_ex_memtoreg), .id_ex_jump(id_ex_jump), .id_ex_jalr(id_ex_jalr), .id_ex_ALU_OP(id_ex_ALU_OP), .id_ex_branch_type(id_ex_branch_type),
.id_ex_compressed(id_ex_compressed));

// Forwarding Unit.
forwarding_unit forward_unit(.ex_mem_regwrite(ex_mem_regwrite), .mem_wb_regwrite(mem_wb_regwrite), .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd(ex_mem_rd)
, .mem_wb_rd(mem_wb_rd), .id_ex_rs1_data(id_ex_rd1_data), .id_ex_rs2_data(id_ex_rd2_data), .ex_mem_rd_data(ex_mem_ALU_result), .mem_wb_rd_data(register_data)
, .forwarded_input1(forwarded_input1), .forwarded_input2(forwarded_input2));


// Instruction execution.
assign alu_operand1 =
    (alu_zero_src1) ? 32'd0 : forwarded_input1;
assign alu_operand2 =
    (id_ex_ALU_src) ? id_ex_immediate : forwarded_input2;

ALU alu(.data1(alu_operand1), .data2(alu_operand2), .ALU_control(id_ex_ALU_OP), .result(ALU_result), .zero_flag(zero_flag));

// Branch Calculation.
always @(*)
begin
    branch_taken = 1'b0;
    if (id_ex_branch)
    begin
        case(id_ex_branch_type)
            BEQ : branch_taken = zero_flag;
            BNE : branch_taken = ~zero_flag;
            BLT : branch_taken = ALU_result[0];
            BGE : branch_taken = ~ALU_result[0];
            BLTU : branch_taken = ALU_result[0];
            BGEU : branch_taken = ~ALU_result[0];
            default : branch_taken = 1'b0;
        endcase
    end
end

// PC value update.
always @(*)
begin
    if (if_id_flush_b_type || id_ex_flush_b_type) next_pc = correct_pc;
    else if (id_ex_jump) next_pc = (id_ex_pc + id_ex_immediate);
    else if (id_ex_jalr) next_pc = (forwarded_input1 + id_ex_immediate) & (32'hFFFFFFFE);
    else next_pc = predicted_next_pc;
end

// EX_MEM_Register.
ex_mem_register ex_mem_reg(.clk(clk), .reset(reset), .pc(id_ex_pc), .next_pc(id_ex_next_pc), .ALU_result(ALU_result), .zero_flag(zero_flag), .memwrite(id_ex_memwrite), .memread(id_ex_memread), .memtoreg(id_ex_memtoreg), .regwrite(id_ex_regwrite),
 .rd(id_ex_rd), .rs2_data(forwarded_input2), .ex_mem_stall(ex_mem_stall), .ex_mem_next_pc(ex_mem_next_pc), .ex_mem_ALU_result(ex_mem_ALU_result), .ex_mem_zero_flag(ex_mem_zero_flag), .ex_mem_memread(ex_mem_memread), .ex_mem_memwrite(ex_mem_memwrite), .ex_mem_memtoreg(ex_mem_memtoreg),
 .ex_mem_regwrite(ex_mem_regwrite), .ex_mem_rd(ex_mem_rd), .ex_mem_rs2_data(ex_mem_rs2_data), .ex_mem_pc(ex_mem_pc));

// Memory — data memory lives directly inside the processor now (no cache, no bus).
data_memory datamem(.clk(clk), .mem_read_en(ex_mem_memread), .mem_write_en(ex_mem_memwrite), .read_addr(ex_mem_ALU_result), .write_addr(ex_mem_ALU_result), .write_data(ex_mem_rs2_data), .mem_out_data(mem_out_data));

assign id_ex_stall = 1'b0;
assign ex_mem_stall = 1'b0;
assign mem_wb_stall = 1'b0;

// MEM_WB_Register.
mem_wb_register mem_wb_reg(.clk(clk), .reset(reset), .next_pc(ex_mem_next_pc), .ALU_result(ex_mem_ALU_result), .mem_out_data(mem_out_data), .regwrite(ex_mem_regwrite), .memtoreg(ex_mem_memtoreg), .mem_wb_stall(mem_wb_stall)
, .rd(ex_mem_rd), .mem_wb_ALU_result(mem_wb_ALU_result), .mem_wb_mem_out_data(mem_wb_mem_out_data), .mem_wb_regwrite(mem_wb_regwrite), .mem_wb_memtoreg(mem_wb_memtoreg), .mem_wb_rd(mem_wb_rd), .mem_wb_next_pc(mem_wb_next_pc));


// Write back.
always @(*)
begin
    case (mem_wb_memtoreg)
    2'b00 : register_data = mem_wb_ALU_result;
    2'b01 : register_data = mem_wb_mem_out_data;
    2'b10 : register_data = mem_wb_next_pc;
    default : register_data = 32'd0;
    endcase
end

endmodule
