module register_file(
    input [4:0] rs1,    // receives at cycle 2
    input [4:0] rs2,    // receives at cycle 2
    input [4:0] rd,     // receives at cycle 5
    input [31:0] write_data,
    input regwrite,
    input clk,
    output [31:0] rd1_data,
    output [31:0] rd2_data
);

reg [31:0] reg_mem [0:31];

integer i;

initial begin
    for(i=0; i<32; i=i+1)
        reg_mem[i] = 32'd0;
end

assign rd1_data = (rs1 == 5'd0) ? 32'd0 : (regwrite && rd == rs1 && rd != 5'd0) ? write_data : reg_mem[rs1];
assign rd2_data = (rs2 == 5'd0) ? 32'd0 : (regwrite && rd == rs2 && rd != 5'd0) ? write_data : reg_mem[rs2];

always @(posedge clk)
begin
    if (regwrite && rd != 5'd0) reg_mem[rd] <= write_data;
end

endmodule