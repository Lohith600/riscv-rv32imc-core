module compressed_decoder(
    input [15:0] upper_16,
    input [15:0] lower_16,
    output reg compressed,
    output reg [31:0] instruction_out
);

reg [4:0] rd;
reg [4:0] rs1;
reg [4:0] rs2;

reg signed [20:0] imm_j;
reg signed [12:0] imm_b;
reg signed [11:0] imm_i;
reg signed [11:0] imm_s;

always @(*) begin
    rd = 5'd0;
    rs1 = 5'd0;
    rs2 = 5'd0;

    imm_i = 12'd0;
    imm_s = 12'd0;
    imm_b = 13'd0;
    imm_j = 21'd0;
    compressed = 1'b0;

    instruction_out = {upper_16,lower_16};
    if (lower_16[1:0] == 2'b11) begin
        compressed = 1'b0;
        instruction_out = {upper_16,lower_16};
    end
    else begin
        compressed = 1'b1;
        if (lower_16 != 16'd0) begin
            case ({lower_16[15:13],lower_16[1:0]}) 
                5'b00000: begin     // ADDI4SPN
                    rd = {2'b01, lower_16[4:2]};
                    imm_i = {
                        2'b00,
                        lower_16[10:7],
                        lower_16[12:11],
                        lower_16[5],
                        lower_16[6],
                        2'b00
                    };
                    instruction_out = {
                        imm_i,
                        5'd2,
                        3'b000,
                        rd,
                        7'b0010011
                    };
                end
                // Quadrant 0
                5'b01000: begin
                    // C.LW
                    rs1 = {2'b01,lower_16[9:7]};
                    rd  = {2'b01,lower_16[4:2]};
                    imm_i = {
                        5'b00000,
                        lower_16[5],
                        lower_16[12:11],
                        lower_16[10],
                        2'b00
                    };
                    instruction_out = {
                        imm_i,
                        rs1,
                        3'b010,
                        rd,
                        7'b0000011
                    };
                end

                5'b11000: begin
                    // C.SW
                    rs1 = {2'b01,lower_16[9:7]};
                    rs2 = {2'b01,lower_16[4:2]};
                    imm_s = {
                        5'b00000,
                        lower_16[5],
                        lower_16[12:11],
                        lower_16[10],
                        2'b00
                    };
                    instruction_out = {
                        imm_s[11:5],
                        rs2,
                        rs1,
                        3'b010,
                        imm_s[4:0],
                        7'b0100011
                    };
                end

                // Quadrant 1
                5'b00001: begin
                    // C.ADDI
                    imm_i = {
                        {6{lower_16[12]}},
                        lower_16[12],
                        lower_16[6:2]
                    };
                    rd = lower_16[11:7];

                    if (rd == 5'd0 && imm_i == 12'd0)
                        instruction_out = 32'h00000013;     // NOP instruction.
                    else
                        instruction_out = {
                            imm_i,
                            rd,
                            3'b000,
                            rd,
                            7'b0010011
                        };
                end

                5'b01001: begin
                    // C.LI
                    rd = lower_16[11:7];

                    imm_i = {
                        {6{lower_16[12]}},
                        lower_16[12],
                        lower_16[6:2]
                    };
                    instruction_out = {
                        imm_i,
                        5'd0,
                        3'b000,
                        rd,
                        7'b0010011
                    };
                end

                5'b01101: begin
                    // C.LUI
                    rd = lower_16[11:7];
                    if (rd != 5'd2) begin
                        instruction_out = {
                            {15{lower_16[12]}},
                            lower_16[12],
                            lower_16[6:2],
                            rd,
                            7'b0110111
                        };
                    end
                    else begin      // C.ADDI16SP
                        imm_i =
                        {
                            {3{lower_16[12]}},
                            lower_16[12],
                            lower_16[4:3],
                            lower_16[5],
                            lower_16[2],
                            lower_16[6],
                            4'b0000
                        };
                        instruction_out = {
                            imm_i,
                            5'd2,
                            3'b000,
                            5'd2,
                            7'b0010011
                        };
                    end
                end

                5'b10101: begin
                    // C.J
                    imm_j = {
                        {9{lower_16[12]}},    // sign extension
                        lower_16[8],          // imm[10]
                        lower_16[10:9],       // imm[9:8]
                        lower_16[6],          // imm[7]
                        lower_16[7],          // imm[6]
                        lower_16[2],          // imm[5]
                        lower_16[11],         // imm[4]
                        lower_16[5:3],        // imm[3:1]
                        1'b0                     // imm[0]
                    };


                    instruction_out = {
                        imm_j[20],
                        imm_j[10:1],
                        imm_j[11],
                        imm_j[19:12],
                        5'd0,
                        7'b1101111
                    };
                end

                5'b11001: begin
                    // C.BEQZ
                    rs1 = {2'b01, lower_16[9:7]};

                    imm_b = {
                        {4{lower_16[12]}},
                        lower_16[12],
                        lower_16[6:5],
                        lower_16[2],
                        lower_16[11:10],
                        lower_16[4:3],
                        1'b0
                    };
                    instruction_out = {
                        imm_b[12],
                        imm_b[10:5],
                        5'd0,
                        rs1,
                        3'b000,
                        imm_b[4:1],
                        imm_b[11],
                        7'b1100011
                    };
                end

                5'b11101: begin
                    // C.BNEZ
                    rs1 = {2'b01, lower_16[9:7]};

                    imm_b = {
                        {4{lower_16[12]}},
                        lower_16[12],
                        lower_16[6:5],
                        lower_16[2],
                        lower_16[11:10],
                        lower_16[4:3],
                        1'b0
                    };

                    instruction_out = {
                        imm_b[12],
                        imm_b[10:5],
                        5'd0,
                        rs1,
                        3'b001,
                        imm_b[4:1],
                        imm_b[11],
                        7'b1100011
                    };
                end
                
                5'b00010: begin         // C.SLLI
                    rd = lower_16[11:7];
                    if (rd != 5'd0) begin
                        imm_i = {
                            6'd0,
                            lower_16[12],
                            lower_16[6:2]
                        };
                        instruction_out = {
                            7'b0000000,
                            imm_i[4:0],
                            rd,
                            3'b001,
                            rd,
                            7'b0010011
                        };
                    end
                end

                5'b10001: begin
                    rd  = {2'b01, lower_16[9:7]};
                    rs2 = {2'b01, lower_16[4:2]};
                    if (lower_16[12]==0) begin
                        if(lower_16[11:10]==2'b11) begin
                            case(lower_16[6:5])
                                2'b00: instruction_out = {      // SUB
                                            7'b0100000,
                                            rs2,
                                            rd,
                                            3'b000,
                                            rd,
                                            7'b0110011
                                        };

                                2'b01: instruction_out = {      // XOR
                                            7'b0000000,
                                            rs2,
                                            rd,
                                            3'b100,
                                            rd,
                                            7'b0110011
                                        };

                                2'b10: instruction_out = {      // OR
                                            7'b0000000,
                                            rs2,
                                            rd,
                                            3'b110,
                                            rd,
                                            7'b0110011
                                        };

                                2'b11: instruction_out = {      // AND
                                            7'b0000000,
                                            rs2,
                                            rd,
                                            3'b111,
                                            rd,
                                            7'b0110011
                                        };

                                default: instruction_out = {upper_16, lower_16};

                            endcase
                        end
                        else if (lower_16[11:10] == 2'b01) begin        // C.SRAI
                            imm_i = {
                                6'd0,
                                lower_16[12],
                                lower_16[6:2]
                            };
                            instruction_out = {
                                7'b0100000,
                                imm_i[4:0],
                                rd,
                                3'b101,
                                rd,
                                7'b0010011
                            };
                        end
                        else if (lower_16[11:10] == 2'b10) begin        // C.ANDI
                            imm_i = {
                                {6{lower_16[12]}},
                                lower_16[12],
                                lower_16[6:2]
                            };
                            instruction_out = {
                                imm_i,
                                rd,
                                3'b111,
                                rd,
                                7'b0010011
                            };
                        end
                        else begin          // C.SRLI
                            imm_i = {
                                6'd0,
                                lower_16[12],
                                lower_16[6:2]
                            };
                            instruction_out = {
                                7'b0000000,
                                imm_i[4:0],
                                rd,
                                3'b101,
                                rd,
                                7'b0010011
                            };
                        end
                    end
                end

                // Quadrant 2
                5'b10010: begin
                    // C.JR , C.MV , C.JALR , C.ADD
                    rd  = lower_16[11:7];
                    rs2 = lower_16[6:2];

                    if (lower_16[12]==0 && rs2==5'd0) // C.JR
                        instruction_out = {
                            12'd0,
                            rd,
                            3'b000,
                            5'd0,
                            7'b1100111
                        };
                    else if (lower_16[12]==0) // C.MV
                        instruction_out = {
                            7'b0000000,
                            rs2,
                            5'd0,
                            3'b000,
                            rd,
                            7'b0110011
                        };
                    else if (rs2==5'd0) // C.JALR
                        instruction_out = {
                            12'd0,
                            rd,
                            3'b000,
                            5'd1,
                            7'b1100111
                        };
                    else // C.ADD
                        instruction_out = {
                            7'b0000000,
                            rs2,
                            rd,
                            3'b000,
                            rd,
                            7'b0110011
                        };
                end
                default: instruction_out = {upper_16,lower_16};
            endcase
        end
    end
end

endmodule