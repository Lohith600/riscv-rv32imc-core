module branch_prediction_unit(
    input clk,
    input branch,
    input branch_taken_status,
    input if_compressed,
    input [31:0] if_branch_pc,
    input [31:0] alu_branch_pc,
    input [31:0] immediate,
    input id_ex_compressed,
    output reg [31:0] predicted_next_pc,
    output reg [31:0] correct_pc,
    output reg if_id_flush,
    output reg id_ex_flush
);

reg [1:0] pht[0:255];
reg [32:0] btb[0:255];

wire prediction;

integer i;
initial begin
    for(i=0;i<256;i=i+1) begin
        pht[i] = 2'b00;
        btb[i] = 33'd0;
    end
end

assign prediction = pht[alu_branch_pc[8:1]][1];

always @(posedge clk) begin
    if (branch) begin       // After ALU operations.     
        if (branch_taken_status == prediction) begin
            if (branch_taken_status) begin
                pht[alu_branch_pc[8:1]] <= 2'b11;

                if (alu_branch_pc + immediate != btb[alu_branch_pc[8:1]][31:0]) begin
                    btb[alu_branch_pc[8:1]][31:0] <= alu_branch_pc + immediate;
                    btb[alu_branch_pc[8:1]][32] <= 1'b1;
                end
            end
            else begin
                pht[alu_branch_pc[8:1]] <= 2'b00;
            end
        end
        else begin
            case(pht[alu_branch_pc[8:1]])
                2'b00 : pht[alu_branch_pc[8:1]] <= 2'b01;
                2'b01 : pht[alu_branch_pc[8:1]] <= 2'b10;
                2'b10 : pht[alu_branch_pc[8:1]] <= 2'b01;
                2'b11 : pht[alu_branch_pc[8:1]] <= 2'b10;
            endcase
            if (branch_taken_status) begin
                btb[alu_branch_pc[8:1]][31:0] <= alu_branch_pc + immediate;
                btb[alu_branch_pc[8:1]][32] <= 1'b1;
            end
        end
    end
end


always @(*) begin

    if_id_flush = 1'b0;
    id_ex_flush = 1'b0;
    correct_pc = alu_branch_pc + 32'd4;

    if (branch) begin          // This happens after alu completes its ALU operations.
        if (branch_taken_status == prediction) begin
            if (branch_taken_status) begin
                if (alu_branch_pc + immediate != btb[alu_branch_pc[8:1]][31:0]) begin
                    if_id_flush = 1'b1;
                    id_ex_flush = 1'b1;
                    correct_pc = alu_branch_pc + immediate;
                end
            end
        end
        else begin

            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;

            if (branch_taken_status)
                correct_pc = alu_branch_pc + immediate;
            else
                if (id_ex_compressed) correct_pc = alu_branch_pc + 32'd2;
                else correct_pc = alu_branch_pc + 32'd4;
        end
    end
end

always @(*) begin

    predicted_next_pc =
        if_compressed ? (if_branch_pc + 32'd2) : (if_branch_pc + 32'd4);

    if (btb[if_branch_pc[8:1]][32]) begin
        if (pht[if_branch_pc[8:1]][1])
            predicted_next_pc = btb[if_branch_pc[8:1]][31:0];
    end

end

endmodule