`timescale 1 ns / 1 ns

`include "Defines.vh"

module Fixed_Point_Unit_Testbench;

time clock_period = 10;

parameter WIDTH = 32;
parameter FBITS = 10;

reg clk   = 'b0;
reg reset = 'b0;

reg [WIDTH - 1 : 0] operand_1 = 'b0;
reg [WIDTH - 1 : 0] operand_2 = 'b0;

reg [ 1 : 0] operation = 'b0;

wire [WIDTH - 1 : 0] result;
wire                 ready;

Fixed_Point_Unit
#(
    .WIDTH(WIDTH),
    .FBITS(FBITS)
)
uut
(
    .clk(clk),
    .reset(reset),
    
    .operand_1(operand_1),
    .operand_2(operand_2),
    
    .operation(operation),

    .result(result),
    .ready(ready)
);

initial
begin
    forever #(clock_period / 2) clk = ~clk;
end

initial
begin
    #(clock_period / 4);
    
    reset = 1'b1;
    
    #(clock_period);
    
    reset = 'b0;
    
    operand_1 = 32'b0000000000000000001111_1100000000;
    operand_2 = 32'b0000000000000000000100_1010000000;
    
    operation = `FPU_MUL;
    
    #(clock_period);
        
    operand_1 = 32'b0000000000000001100011_1100000000;
    operand_2 = 32'b0000000000000000000000_0000000000;

    operation = `FPU_SQRT;

    #(clock_period * 13);
    
    $finish;
end

endmodule

