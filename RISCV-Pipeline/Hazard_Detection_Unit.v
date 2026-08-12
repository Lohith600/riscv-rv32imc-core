module hazard_detection_unit(       // This block handles data before the id_ex_register.
    input id_ex_memread,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] id_ex_rd,

    output reg pc_write,
    output reg if_id_stall,
    output reg id_ex_flush
);

always @(*)
begin
    if (id_ex_memread && id_ex_rd != 5'd0 && ((rs1 == id_ex_rd) || (rs2 == id_ex_rd)))
    begin
        pc_write = 1'b0;
        if_id_stall = 1'b1;
        id_ex_flush = 1'b1;
    end
    else
    begin
        pc_write = 1'b1;
        if_id_stall = 1'b0;
        id_ex_flush = 1'b0;
    end
end

endmodule