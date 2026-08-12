module data_memory(
    input clk,

    input mem_read_en,
    input mem_write_en,

    input [31:0] read_addr,
    input [31:0] write_addr,

    input [31:0] write_data,

    output [31:0] mem_out_data
);

reg [31:0]memory[0:1023];

integer i;
initial begin
    for(i=0; i<1024; i=i+1)
        memory[i] = 32'd0;
    memory[26] = 32'd10;
    memory[27] = 32'd10;
    memory[28] = 32'd10;
    memory[29] = 32'd10;
    memory[30] = 32'd10;
    memory[31] = 32'd10;
    memory[32] = 32'd10;
    memory[35] = 32'd10;
end

assign mem_out_data = (mem_read_en) ? memory[read_addr[11:2]] : 32'd0;

always @(posedge clk)
begin
    if (mem_write_en)
        memory[write_addr[11:2]] <= write_data;
end

endmodule