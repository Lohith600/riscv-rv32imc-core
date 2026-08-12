module control_hazard_unit(
    input jump,
    input jalr,

    output id_ex_flush,
    output if_id_flush
);

assign if_id_flush = (jump || jalr);
assign id_ex_flush = (jump || jalr);

endmodule