module Program_Counter(         // The next PC_value is calculated elsewhere and be given as input to PC.v file.
    input clk,
    input reset,
    input pc_write,
    input [31:0] next_PC,
    output reg [31:0] PC
);

always @(posedge clk or posedge reset)
begin
    if (reset)
        PC <= 32'd0;
    else if(pc_write)
        PC <= next_PC;
end

endmodule