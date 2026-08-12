module Instruction_memory(
    input [31:0] PC,
    output [15:0] upper_16,
    output [15:0] lower_16
);

reg [15:0] int_mem [0:511];

integer i;

initial begin
    for(i=0;i<512;i=i+1)
        int_mem[i] = 16'd0;

    $readmemh("program.mem", int_mem);
end

assign lower_16 = int_mem[PC[31:1]];
assign upper_16 = int_mem[PC[31:1] + 32'd1];

endmodule

/* The instruction memory is designed in a way that it 
outputs the 32 bits instruction as 16 upper and 16 lower bits always , 
but using this approach wastes memory bandwidth as even for compressed instruction 
we are fetching the upper 16 bits which is discarded later. */