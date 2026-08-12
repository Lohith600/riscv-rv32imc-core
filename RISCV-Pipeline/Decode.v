module decode(
    input [31:0] instruction,
    output reg branch,
    output reg ALU_src,
    output reg regwrite,
    output reg memwrite,
    output reg memread,
    output reg [1:0]memtoreg,
    output reg jump,
    output reg jalr,
    output reg [4:0] ALU_OP,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output reg [2:0] branch_type,
    output reg alu_zero_src1
);
wire [6:0] opcode;

localparam [6:0]R_type = 7'b0110011;
localparam [6:0]I_type = 7'b0010011;
localparam [6:0]S_type = 7'b0100011;
localparam [6:0]B_type = 7'b1100011;
localparam [6:0]I_l_type = 7'b0000011;
localparam [6:0]J_type = 7'b1101111;
localparam [6:0]JR_type = 7'b1100111;
localparam [6:0]U_type = 7'b0110111;

wire [2:0] funct3;
wire [6:0] funct7;

assign opcode = instruction [6:0];

assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];
assign rd = instruction[11:7];

always @(*)
begin
    branch = 1'b0;
    ALU_src = 1'b0;
    regwrite = 1'b0;
    memwrite = 1'b0;
    memread = 1'b0;
    memtoreg = 2'b00;
    jump = 1'b0;
    jalr = 1'b0;
    ALU_OP = 5'b11111;
    branch_type = 3'b111;
    alu_zero_src1 = 1'b0;

    case (opcode)
    R_type :
    begin
        regwrite = 1'b1;

        if (funct7 == 7'b0000001) begin
            // RV32M
            case (funct3)
                3'b000: ALU_OP = 5'b10000; // MUL
                3'b001: ALU_OP = 5'b10001; // MULH
                3'b010: ALU_OP = 5'b10010; // MULHSU
                3'b011: ALU_OP = 5'b10011; // MULHU
                3'b100: ALU_OP = 5'b10100; // DIV
                3'b101: ALU_OP = 5'b10101; // DIVU
                3'b110: ALU_OP = 5'b10110; // REM
                3'b111: ALU_OP = 5'b10111; // REMU
                default: ALU_OP = 5'b11111;
            endcase
        end
        else if      (funct3 == 3'b000 && funct7 == 7'b0000000) ALU_OP = 5'b00000; // ADD
        else if (funct3 == 3'b000 && funct7 == 7'b0100000) ALU_OP = 5'b00001; // SUB

        else if (funct3 == 3'b111 && funct7 == 7'b0000000) ALU_OP = 5'b00010; // AND
        else if (funct3 == 3'b110 && funct7 == 7'b0000000) ALU_OP = 5'b00011; // OR
        else if (funct3 == 3'b100 && funct7 == 7'b0000000) ALU_OP = 5'b00100; // XOR

        else if (funct3 == 3'b001 && funct7 == 7'b0000000) ALU_OP = 5'b00101; // SLL
        else if (funct3 == 3'b101 && funct7 == 7'b0000000) ALU_OP = 5'b00110; // SRL
        else if (funct3 == 3'b101 && funct7 == 7'b0100000) ALU_OP = 5'b00111; // SRA

        else if (funct3 == 3'b010 && funct7 == 7'b0000000) ALU_OP = 5'b01000; // SLT
        else if (funct3 == 3'b011 && funct7 == 7'b0000000) ALU_OP = 5'b01001; // SLTU

        else ALU_OP = 5'b11111;
    end

    I_type :
    begin
        ALU_src = 1'b1;
        regwrite = 1'b1;

        if      (funct3 == 3'b000) ALU_OP = 5'b00000;   // ADDI
        else if (funct3 == 3'b111) ALU_OP = 5'b00010;   // ANDI
        else if (funct3 == 3'b110) ALU_OP = 5'b00011;    // ORI
        else if (funct3 == 3'b100) ALU_OP = 5'b00100;   // XORI
        else if (funct3 == 3'b010) ALU_OP = 5'b01000;   // SLTI
        else if (funct3 == 3'b011) ALU_OP = 5'b01001;  // SLTIU

        else if (funct3 == 3'b001)
            ALU_OP = 5'b00101;                          // SLLI

        else if (funct3 == 3'b101 && funct7 == 7'b0000000)
            ALU_OP = 5'b00110;                          // SRLI

        else if (funct3 == 3'b101 && funct7 == 7'b0100000)
            ALU_OP = 5'b00111;                          // SRAI

        else ALU_OP = 5'b11111;
    end

    I_l_type :
    begin
        ALU_src = 1'b1;
        memtoreg = 2'b01;
        regwrite = 1'b1;
        memread = 1'b1;

        ALU_OP = 5'b00000;
    end

    B_type:
    begin
        branch = 1'b1;
        branch_type = funct3;
        case(funct3)

            3'b000: ALU_OP = 5'b00001;  // BEQ
            3'b001: ALU_OP = 5'b00001;  // BNE

            3'b100: ALU_OP = 5'b01000;  // BLT
            3'b101: ALU_OP = 5'b01000;  // BGE

            3'b110: ALU_OP = 5'b01001; // BLTU
            3'b111: ALU_OP = 5'b01001; // BGEU

            default: ALU_OP = 5'b11111;

        endcase

    end

    S_type :
    begin
        ALU_src   = 1'b1;
        memwrite  = 1'b1;

        ALU_OP    = 5'b00000; // adding the immediate with the register address to obtain the final address to store.
    end

    J_type :
    begin
        jump = 1'b1;
        memtoreg = 2'b10;
        regwrite = 1'b1;

        ALU_OP = 5'b11111;   // NOTHING

    end

    JR_type :
    begin
        if(funct3 == 3'b000)
        begin
            jalr = 1'b1;

            regwrite = 1'b1;
            memtoreg = 2'b10;

            ALU_src = 1'b1;
            ALU_OP  = 5'b00000;  // ADD
        end
        else
            ALU_OP = 5'b11111;       // default value, no operation.
    end

    U_type :
    begin
        regwrite = 1'b1;
        ALU_OP = 5'b00000;
        alu_zero_src1 = 1'b1;
        ALU_src = 1'b1;
    end

    default :
    begin
        ALU_OP = 5'b11111;
    end

    endcase
end

endmodule
