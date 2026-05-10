module executor #(
    parameter ALEN  = 8,
    parameter IALEN = 11,
    parameter NREGS = 8,
    parameter WIDTH = 8
) (
    input  wire clk,
    input  wire rst,
    
    input  wire store,
    input  wire load,

    // w/ controller
    input  wire begin_execute,
    output reg executor_done,

    // w/ decoder
    input  wire [3:0] tf,
    input  wire [2:0] se,
    input  wire [2:0] rt, 
    input  wire [5:0] imm,
    input  wire l,
    input  wire r2_or_imm,
    input  wire shft,
    input  wire nand_op,

    // w/ loader/storer 
    output reg lsi_begin,
    input  wire lsi_done,
    output reg is_store,
    output reg [ALEN-1:0] lsi_addr,
    output reg [WIDTH-1:0] store_val,
    input wire [WIDTH-1:0] load_val,

    // w/ pc
    input  wire [IALEN-1:0] new_addr,
    output reg pc_we,
    output reg  [IALEN-1:0] pc_new_addr

);

    reg [WIDTH-1:0] regs [0:NREGS-1];
 
    reg [WIDTH-1:0] reg_r1;
    reg [WIDTH-1:0] reg_r2;
    reg [2:0] rd;

    wire [2:0] f_rd  = tf[3:1];
    wire f_blt = tf[0]; 
 
    // State machine
    localparam IDLE = 2'd0;
    localparam EXEC = 2'd1;
    localparam MEM_WAIT = 2'd2;
 
    reg [1:0] state;
 
    integer i;
 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            executor_done <= 1'b0;
            lsi_begin <= 1'b0;
            is_store <= 1'b0;
            lsi_addr <= {ALEN{1'b0}};
            store_val <= {WIDTH{1'b0}};
            pc_we <= 1'b0;
            pc_new_addr <= {IALEN{1'b0}};
            rd <= 3'b0;
            reg_r1 <= {WIDTH{1'b0}};
            reg_r2 <= {WIDTH{1'b0}};
            state <= IDLE;
            for (i = 0; i < NREGS; i = i + 1)
                regs[i] <= {WIDTH{1'b0}};
        end else begin
            // Default: clear one-pulse outputs
            executor_done <= 1'b0;
            lsi_begin <= 1'b0;
            pc_we  <= 1'b0;
 
            case (state)
 
                // Wait for controller to kick off execution
                IDLE: begin
                    if (begin_execute) begin
                        // Latch register values and destination
                        reg_r1 <= regs[se];
                        reg_r2 <= r2_or_imm ? {{(WIDTH-6){1'b0}}, imm}
                                            : regs[rt];
                        rd <= f_rd;
                        state  <= EXEC;
                    end
                end
 
                // Execute the instruction
                EXEC: begin
                    if (load || store) begin
                        // LOAD/STORE: address comes from reg[ra=tf[3:1]]
                        // For STORE: value to write comes from reg[rv=se]
                        lsi_addr  <= regs[f_rd][ALEN-1:0];
                        is_store  <= store;
                        store_val <= store ? regs[se] : {WIDTH{1'b0}};
                        lsi_begin <= 1'b1;
                        state <= MEM_WAIT;
 
                    end else if (f_blt) begin
                        // BLT: if r1 < r2, jump to pc + ro (sign-extended)
                        // ro = tf[3:1], sign-extended to IALEN bits
                        if (reg_r1 < reg_r2) begin
                            pc_we <= 1'b1;
                            pc_new_addr <= new_addr
                                          + {{(IALEN-3){tf[3]}}, tf[3:1]};
                        end
                        executor_done <= 1'b1;
                        state <= IDLE;
 
                    end else if (shft) begin
                        // SHFT / SHFTI: l=1 left shift, l=0 right shift
                        // reg_r2 already holds r2 or imm depending on r2_or_imm
                        regs[rd] <= l ? (reg_r1 << reg_r2[2:0])
                                           : (reg_r1 >> reg_r2[2:0]);
                        executor_done <= 1'b1;
                        state <= IDLE;
 
                    end else if (nand_op) begin
                        // NAND
                        regs[rd] <= ~(reg_r1 & reg_r2);
                        executor_done <= 1'b1;
                        state <= IDLE;
 
                    end else begin
                        // ADD / ADDI: reg_r2 already holds r2 or imm
                        regs[rd] <= reg_r1 + reg_r2;
                        executor_done <= 1'b1;
                        state <= IDLE;
                    end
                end
 
                // Wait for loader/storer to finish
                MEM_WAIT: begin
                    if (lsi_done) begin
                        // For LOAD, write result into rv (= se register)
                        if (load)
                            regs[se] <= load_val;
                        executor_done <= 1'b1;
                        state <= IDLE;
                    end
                end
 
                default: state <= IDLE;
 
            endcase
        end
    end
 
endmodule
    