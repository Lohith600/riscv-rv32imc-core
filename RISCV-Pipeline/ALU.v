module ALU(
    input [31:0] data1,
    input [31:0] data2,
    input [4:0] ALU_control,

    output reg [31:0] result,
    output reg zero_flag
);

localparam [4:0] ADD_OP    = 5'b00000;
localparam [4:0] SUB_OP    = 5'b00001;
localparam [4:0] AND_OP    = 5'b00010;
localparam [4:0] OR_OP     = 5'b00011;
localparam [4:0] XOR_OP    = 5'b00100;
localparam [4:0] SLL_OP    = 5'b00101;
localparam [4:0] SRL_OP    = 5'b00110;
localparam [4:0] SRA_OP    = 5'b00111;
localparam [4:0] SLT_OP    = 5'b01000;
localparam [4:0] SLTU_OP   = 5'b01001;

// RV32M
localparam [4:0] MUL_OP    = 5'b10000;
localparam [4:0] MULH_OP   = 5'b10001;
localparam [4:0] MULHSU_OP = 5'b10010;
localparam [4:0] MULHU_OP  = 5'b10011;
localparam [4:0] DIV_OP    = 5'b10100;
localparam [4:0] DIVU_OP   = 5'b10101;
localparam [4:0] REM_OP    = 5'b10110;
localparam [4:0] REMU_OP   = 5'b10111;

wire signed [63:0] mul_signed_signed   = $signed({{32{data1[31]}}, data1}) * $signed({{32{data2[31]}}, data2});
wire        [63:0] mul_unsigned_unsigned = {32'd0, data1} * {32'd0, data2};

// MULHSU (signed data1 * unsigned data2) via magnitude method, to avoid
// Verilog's mixed signed/unsigned multiply operand-context pitfalls.
// data1_mag is the 32-bit two's-complement magnitude of signed data1 -
// negating the raw zero-extended bits directly (rather than this) would
// compute the wrong magnitude for negative inputs.
wire [31:0] mulhsu_data1_mag = data1[31] ? (~data1 + 32'd1) : data1;
wire [63:0] mulhsu_raw       = {32'd0, mulhsu_data1_mag} * {32'd0, data2};
wire [63:0] mulhsu_signed    = data1[31] ? (~mulhsu_raw + 64'd1) : mulhsu_raw;

always @(*)
begin
    result = 32'd0;

    case(ALU_control)

        ADD_OP  : result = data1 + data2;
        SUB_OP  : result = data1 - data2;

        AND_OP  : result = data1 & data2;
        OR_OP   : result = data1 | data2;
        XOR_OP  : result = data1 ^ data2;

        SLL_OP  : result = data1 << data2[4:0];
        SRL_OP  : result = data1 >> data2[4:0];
        SRA_OP  : result = $signed(data1) >> data2[4:0];

        SLT_OP  : result = ($signed(data1) < $signed(data2));
        SLTU_OP : result = (data1 < data2);

        MUL_OP    : result = data1 * data2;                 // low 32 bits, sign-agnostic
        MULH_OP   : result = mul_signed_signed[63:32];
        MULHSU_OP : result = mulhsu_signed[63:32];
        MULHU_OP  : result = mul_unsigned_unsigned[63:32];

        DIV_OP :
            if (data2 == 32'd0) result = 32'hFFFFFFFF;                              // divide by zero
            else if (data1 == 32'h80000000 && data2 == 32'hFFFFFFFF) result = data1; // overflow
            else result = $signed(data1) / $signed(data2);

        DIVU_OP :
            if (data2 == 32'd0) result = 32'hFFFFFFFF;
            else result = data1 / data2;

        REM_OP :
            if (data2 == 32'd0) result = data1;                                     // divide by zero
            else if (data1 == 32'h80000000 && data2 == 32'hFFFFFFFF) result = 32'd0; // overflow
            else result = $signed(data1) % $signed(data2);

        REMU_OP :
            if (data2 == 32'd0) result = data1;
            else result = data1 % data2;

        default : result = 32'd0;

    endcase

    zero_flag = (result == 32'd0);

end

endmodule
