/* module executor (
    output wire begin;

    input wire done;
    input wire store;
    input wire load;
    output wire is_store;

    input wire [3:0] tf;
    input wire [2:0] se;
    input wire [2:0] rt;
    input wire [5:0] imm;
    input wire l;

    input wire r2_or_imm;
    input wire shft;

    output wire addr[ALEN-1:0] // THINK/ASK ABOUT THIS
    output wire [7:0] store_val;
    input wire [7:0] load_val;

    output wire in_reg;
    input wire out_reg;
    output wire we;
); */

module executor #(
    parameter ALEN = 8,
    parameter IALEN = 11
)(
    input  wire clk,
    input  wire rst,

    // Controller Interface
    input  wire begin_executor,
    output reg  executor_done,

    // Decoder Inputs
    input  wire store,
    input  wire load,
    input  wire [3:0] tf,      // [3:1] = rd/ra/ro, [0] = is_ro
    input  wire [2:0] se,      // r1 index
    input  wire [2:0] rt,      // r2 index
    input  wire [5:0] imm,
    input  wire l,             // Shift Left/Right
    input  wire r2_or_imm,
    input  wire shft,

    // Loader/Storer (LSI) Interface
    output reg  lsi_begin,
    input  wire lsi_done,
    output wire is_store,
    output wire [ALEN-1:0] addr,
    output wire [7:0] store_val,
    input  wire [7:0] load_val,

    // Register Digger (RDI) Interface
    output reg  [7:0] in_reg,  // Value to write to reg
    input  wire [7:0] out_reg, // Value read from reg
    output reg  we,            // Write Enable for Register File
    // Note: Assuming you have a way to select WHICH reg is active 
    // via 'se', 'rt', or 'tf[3:1]' externally or via additional ports.

    // PC Interface (for BLT)
    output reg  [IALEN-1:0] pc_new_addr,
    output reg  pc_we,
    output reg  pc_incr,
    input  wire [IALEN-1:0] current_pc
);

    // State Definitions
    typedef enum reg [3:0] {
        IDLE        = 4'd0,
        READ_R1     = 4'd1,
        READ_R2     = 4'd2,
        EXECUTE_ALU = 4'd3,
        MEM_START   = 4'd4,
        MEM_WAIT    = 4'd5,
        WRITE_BACK  = 4'd6,
        BRANCH_EVAL = 4'd7,
        DONE        = 4'd8
    } state_t;

    state_t state;

    // Internal Registers to hold operands
    reg [7:0] reg_val1;
    reg [7:0] reg_val2;
    reg [7:0] result;

    // LSI assignments
    assign is_store  = store;
    assign addr      = reg_val1; // Based on rv = mem[ra], r1 is ra
    assign store_val = reg_val2; // Based on mem[ra] = rv, r2 is rv

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            executor_done <= 0;
            we <= 0;
            lsi_begin <= 0;
            pc_we <= 0;
            pc_incr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    executor_done <= 0;
                    pc_we <= 0;
                    pc_incr <= 0;
                    if (begin_executor) state <= READ_R1;
                end

                // Step 1: Get first operand (r1 / ra)
                READ_R1: begin
                    // Logic: Point Register Digger to index 'se'
                    reg_val1 <= out_reg; 
                    state <= READ_R2;
                end

                // Step 2: Get second operand (r2 / rv) or use Immediate
                READ_R2: begin
                    if (r2_or_imm) begin
                        reg_val2 <= {{2{imm[5]}}, imm}; // Sign extend
                        state <= (load || store) ? MEM_START : EXECUTE_ALU;
                    end else begin
                        reg_val2 <= out_reg; // Logic: Point Reg Digger to index 'rt'
                        state <= (load || store) ? MEM_START : EXECUTE_ALU;
                    end
                    
                    // Special Case: BLT uses 'ro' which is in tf[3:1]
                    if (tf[0]) begin // If this is a BLT/Branch instr
                         state <= BRANCH_EVAL;
                    end
                end

                EXECUTE_ALU: begin
                    if (shft) begin
                        result <= l ? (reg_val1 << reg_val2[2:0]) : (reg_val1 >> reg_val2[2:0]);
                    end else if (/* Opcode for NAND */) begin
                        result <= ~(reg_val1 & reg_val2);
                    end else begin
                        result <= reg_val1 + reg_val2; // ADD / ADDI
                    end
                    state <= WRITE_BACK;
                end

                MEM_START: begin
                    lsi_begin <= 1;
                    state <= MEM_WAIT;
                end

                MEM_WAIT: begin
                    lsi_begin <= 0;
                    if (lsi_done) begin
                        if (load) begin
                            result <= load_val;
                            state <= WRITE_BACK;
                        end else begin
                            state <= DONE; // Store is finished
                        end
                    end
                end

                WRITE_BACK: begin
                    in_reg <= result;
                    we <= 1; // Logic: Point Reg Digger to index 'tf[3:1]'
                    pc_incr <= 1; // Normal instruction finishes
                    state <= DONE;
                end

                BRANCH_EVAL: begin
                    // BLT: pc = r1 < r2 ? pc + ro : pc
                    if (reg_val1 < reg_val2) begin
                        pc_new_addr <= current_pc + reg_val2; // reg_val2 holds 'ro' value here
                        pc_we <= 1;
                    end else begin
                        pc_incr <= 1;
                    end
                    state <= DONE;
                end

                DONE: begin
                    we <= 0;
                    pc_we <= 0;
                    pc_incr <= 0;
                    executor_done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule