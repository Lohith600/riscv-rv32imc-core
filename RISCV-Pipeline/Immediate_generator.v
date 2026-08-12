module immediate_generator(
    input [31:0] instruction,
    output reg [31:0] immediate
);

wire [6:0]opcode;

localparam [6:0]R_type = 7'b0110011;
localparam [6:0]I_type = 7'b0010011;
localparam [6:0]S_type = 7'b0100011;
localparam [6:0]B_type = 7'b1100011;
localparam [6:0]I_l_type = 7'b0000011;
localparam [6:0]J_type = 7'b1101111;
localparam [6:0]JR_type = 7'b1100111;
localparam [6:0]U_type = 7'b0110111;

assign opcode = instruction[6:0];

always @(*)
begin

    case(opcode)

        I_type,
        I_l_type,
        JR_type:
            immediate =
            {{20{instruction[31]}},
              instruction[31:20]};

        S_type:
            immediate =
            {{20{instruction[31]}},
             instruction[31:25],
             instruction[11:7]};

        B_type:
            immediate =
            {{19{instruction[31]}},
             instruction[31],
             instruction[7],
             instruction[30:25],
             instruction[11:8],
             1'b0};

        J_type:
            immediate =
            {{11{instruction[31]}},
             instruction[31],
             instruction[19:12],
             instruction[20],
             instruction[30:21],
             1'b0};

        U_type:
            immediate =
            {{12{1'b0}},instruction[31:12]};

        default:
            immediate = 32'd0;

    endcase

end

endmodule