module forwarding_unit(
  input ex_mem_regwrite,
  input mem_wb_regwrite,
  input [4:0] id_ex_rs1,
  input [4:0] id_ex_rs2,
  input [4:0] ex_mem_rd,
  input [4:0] mem_wb_rd,
  input [31:0] id_ex_rs1_data,
  input [31:0] id_ex_rs2_data,
  input [31:0] ex_mem_rd_data,
  input [31:0] mem_wb_rd_data,
  output reg [31:0] forwarded_input1,
  output reg [31:0] forwarded_input2
);

always @(*)
begin
    if (ex_mem_regwrite && ex_mem_rd != 5'd0 && (id_ex_rs1 == ex_mem_rd))
      forwarded_input1 = ex_mem_rd_data;
    else if(mem_wb_regwrite && mem_wb_rd != 5'd0 && (id_ex_rs1 == mem_wb_rd))
      forwarded_input1 = mem_wb_rd_data;
    else
      forwarded_input1 = id_ex_rs1_data;
end

always @(*)
begin
    if (ex_mem_regwrite && ex_mem_rd != 5'd0 && (id_ex_rs2 == ex_mem_rd))
      forwarded_input2 = ex_mem_rd_data;
    else if(mem_wb_regwrite && mem_wb_rd != 5'd0 && (id_ex_rs2 == mem_wb_rd))
      forwarded_input2 = mem_wb_rd_data;
    else
      forwarded_input2 = id_ex_rs2_data;
end

endmodule
