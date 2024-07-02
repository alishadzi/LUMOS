`include "Defines.vh"

module Fixed_Point_Unit 
#(
    parameter WIDTH = 32,
    parameter FBITS = 10
)
(
    input wire clk,
    input wire reset,
    
    input wire [WIDTH - 1 : 0] operand_1,
    input wire [WIDTH - 1 : 0] operand_2,
    
    input wire [ 1 : 0] operation,

    output reg [WIDTH - 1 : 0] result,
    output reg ready
);
    
    always @(posedge reset)
    begin
        if (reset)  ready = 0;
        else        ready = 'bz;
    end
    // ------------------- //
    // Square Root Circuit //
    // ------------------- //
    reg [WIDTH - 1 : 0] root;
    reg root_ready;
    
    // Root Calculator Circuit
    
    reg run;
    
    reg [(WIDTH - 1):0] temp = 'b0;
    reg [4:0]           msb = 'b0;
    reg [4:0]           msb_reg = 'b0;
    reg [(WIDTH - 1):0] extended_operand = 'b0;
    
    reg signed [(WIDTH - 1):0] fresult = 'b0;
    reg signed [(WIDTH - 1):0] subtraction = 'b0;
    reg signed [(WIDTH - 1):0] tsubtraction = 'b0;
    reg signed [(WIDTH - 1):0] fnumber = 'b0;
    reg signed [1:0]           bits = 'b0;
    
    localparam state_1 = 3'b000, state_2 = 3'b001, state_3 = 3'b010, state_4 = 3'b101;
    
    reg [2:0] state;
    reg [2:0] next_state;
    
    integer i;
    
    always @(*)
    begin
        next_state = state;
        
        temp  = 'b0;
        msb   = 'b0;
        bits = 'b0;
        tsubtraction = 'b0;
        fnumber     = 'b0;
        i =   0;
        
        case (state)
            state_1:
            begin
                next_state = state_1;
            end
            
            state_2:
            begin
                temp = {WIDTH{1'b0}} | operand_1;
                
                for (i = 0; i < (WIDTH - 1); i = i + 1)
                begin
                    if (temp[i] == 1'b1)
                    begin
                        msb = i + 1'b1;
                    end
                end
                
                next_state = state_3;
            end
            
            state_3:
            begin
                bits = extended_operand[(msb_reg - 1) -: 2];
                fnumber     = {subtraction[(WIDTH - 3):0], bits};
                tsubtraction = fnumber - {fresult, 2'b01};
                
                if (msb_reg == 5'b00010)
                begin
                    next_state = state_4;
                end
                else
                begin
                    next_state = state_3;
                end
            end
                    
            state_4:
            begin
                next_state = state_1;
            end
            
            default:
            begin
            end
        endcase
    end
    
    always @(posedge clk)
    begin
        state <= next_state;
        
        root_ready <= 'b0;
        
        case (state)
            state_1:
            begin
            end
            
            state_2:
            begin
                extended_operand <= temp;
                
                if (msb[0] == 1'b1)
                begin
                    msb_reg <= msb + 1'b1;
                end
                else
                begin
                    msb_reg <= msb;
                end
            end
            
            state_3:
            begin
                msb_reg <= msb_reg - 2'b10;
                
                if (tsubtraction[WIDTH - 1] == 1'b0)
                begin
                    fresult           <= {fresult[(WIDTH - 2):0], 1'b1};
                    subtraction <= tsubtraction;
                end
                else
                begin
                    fresult    <= {fresult[(WIDTH - 2):0], 1'b0};
                    subtraction <= fnumber;
                end
            end
            
            state_4:
            begin
                root <= {fresult[(WIDTH - 6):0], 5'b00000};
                
                root_ready <= 1'b1;
                
                run <= 'b0;
            end
            
            default:
            begin
                root <= 'b0;   
                run <= 'b0;
                state <= state_1;
            end
        endcase
        
        if ((operation == `FPU_SQRT) && (run == 1'b0))
        begin
            run <= 1'b1;
            
            state <= state_2;
        end
        
        if (reset == 1'b1)
        begin
            root <= 'b0;    
            run <= 'b0;
            state <= state_1;
        end
    end

    // ------------------ //
    // Multiplier Circuit //
    // ------------------ //   
    reg [64 - 1 : 0] product;
    
    // Multiplier Calculator Circuit
    
    reg     [15 : 0] multiplierCircuitInput1_1;
    reg     [15 : 0] multiplierCircuitInput1_2;
    reg     [15 : 0] multiplierCircuitInput2_1;
    reg     [15 : 0] multiplierCircuitInput2_2;
    reg     [15 : 0] multiplierCircuitInput3_1;
    reg     [15 : 0] multiplierCircuitInput3_2;
    reg     [15 : 0] multiplierCircuitInput4_1;
    reg     [15 : 0] multiplierCircuitInput4_2;
    
    wire     [31 : 0] partialProduct1;
    wire     [31 : 0] partialProduct2;
    wire     [31 : 0] partialProduct3;
    wire     [31 : 0] partialProduct4;

    Multiplier multiplier_circuit_1
    (
        .operand_1(multiplierCircuitInput1_1),
        .operand_2(multiplierCircuitInput1_2),
        .product(partialProduct1)
    );
    
    Multiplier multiplier_circuit_2
    (
        .operand_1(multiplierCircuitInput2_1),
        .operand_2(multiplierCircuitInput2_2),
        .product(partialProduct2)
    );
    
    Multiplier multiplier_circuit_3
    (
        .operand_1(multiplierCircuitInput3_1),
        .operand_2(multiplierCircuitInput3_2),
        .product(partialProduct3)
    );
    
    Multiplier multiplier_circuit_4
    (
        .operand_1(multiplierCircuitInput4_1),
        .operand_2(multiplierCircuitInput4_2),
        .product(partialProduct4)
    );
    
    always @(*)
    begin
        case (operation)
            `FPU_ADD    : begin result <= operand_1 + operand_2; ready <= 1; end
            `FPU_SUB    : begin result <= operand_1 - operand_2; ready <= 1; end
            `FPU_MUL    :
            begin
                multiplierCircuitInput1_1 = operand_1[((WIDTH / 2) - 1) : 0];
                multiplierCircuitInput1_2 = operand_2[((WIDTH / 2) - 1) : 0];
                
                multiplierCircuitInput2_1 = operand_1[(WIDTH - 1) -: (WIDTH / 2)];
                multiplierCircuitInput2_2 = operand_2[((WIDTH / 2) - 1) : 0];
                
                multiplierCircuitInput3_1 = operand_1[((WIDTH / 2) - 1) : 0];
                multiplierCircuitInput3_2 = operand_2[(WIDTH - 1) -: (WIDTH / 2)];
                
                multiplierCircuitInput4_1 = operand_1[(WIDTH - 1) -: (WIDTH / 2)];
                multiplierCircuitInput4_2 = operand_2[(WIDTH - 1) -: (WIDTH / 2)];
                
                product = (partialProduct1 + partialProduct2) + (partialProduct3 + partialProduct4);
                
                result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= 1'b1;
            end
            `FPU_SQRT   : begin result <= root; ready <= root_ready; end
            default     : begin result <= 'bz; ready <= 0; end
        endcase
    end
    
endmodule

module Multiplier
(
    input wire [15 : 0] operand_1,
    input wire [15 : 0] operand_2,

    output reg [31 : 0] product
);

    always @(*)
    begin
        product <= operand_1 * operand_2;
    end
endmodule
