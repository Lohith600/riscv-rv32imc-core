`timescale 1ns / 1ps
module processor_tb;
reg clk;
reg reset;

processor uut(
    .clk(clk),
    .reset(reset)
);

initial begin
    $dumpfile("output.vcd");
    $dumpvars(0, processor_tb);
end

initial begin
    reset = 1;
    #3 reset = 0;
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// initial begin
//     $monitor(
//         "Time=%0t PC=%h Instruction=%h",
//         $time,
//         uut.PC,
//         uut.instruction
//     );
// end

initial begin               // values for debugging.
    #1000;

    $display("x1 = %0d",
        uut.reg_file.reg_mem[1]);
    $display("x2 = %0d",
        uut.reg_file.reg_mem[2]);
    $display("x3 = %0d",
        uut.reg_file.reg_mem[3]);
    $display("x4 = %0d",
        uut.reg_file.reg_mem[4]);
    $display("x5 = %0d",
        uut.reg_file.reg_mem[5]);
    $display("x6 = %0d",
        uut.reg_file.reg_mem[6]);
    $display("x7 = %0d",
        uut.reg_file.reg_mem[7]);
    $display("x8 = %0d",
        uut.reg_file.reg_mem[8]);
    $display("x9 = %0d",
        uut.reg_file.reg_mem[9]);
    $display("x10 = %0d",
        uut.reg_file.reg_mem[10]);
    $display("x11 = %0d",
        uut.reg_file.reg_mem[11]);
    $display("x12 = %0d",
        uut.reg_file.reg_mem[12]);
    $display("x13 = %0d",
        uut.reg_file.reg_mem[13]);
    $display("x14 = %0d",
        uut.reg_file.reg_mem[14]);
    $display("x15 = %0d",
        uut.reg_file.reg_mem[15]);
    $display("x16 = %0d",
        uut.reg_file.reg_mem[16]);

    $display("datamem[25] = %0d",
        uut.datamem.memory[25]);
    $display("datamem[26] = %0d",
        uut.datamem.memory[26]);
    $display("datamem[27] = %0d",
        uut.datamem.memory[27]);
    end

initial
#1000 $finish;

endmodule
