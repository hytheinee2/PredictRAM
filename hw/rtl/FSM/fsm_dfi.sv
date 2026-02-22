`include "cmd_defs.sv"

module fsm_dfi #(
    parameter int ADDR_W = 14,
    parameter int BANK_W = 3,

    // Small timing values for simulation
    parameter int tRCD = 4,
    parameter int CL   = 4,
    parameter int tRP  = 4,
    parameter int tRFC = 8
)(
    input  logic        clk,
    input  logic        rst_n,

    // From arbiter
    input  logic        cmd_valid,
    input  logic [2:0]  cmd_type,
    input  logic [31:0] cmd_addr,

    output logic        fsm_ready,

    // DFI-like command pins
    output logic        dfi_cs_n,
    output logic        dfi_ras_n,
    output logic        dfi_cas_n,
    output logic        dfi_we_n,
    output logic        dfi_cke,
    output logic [ADDR_W-1:0] dfi_addr,
    output logic [BANK_W-1:0] dfi_bank
);

    typedef enum logic [3:0] {
        S_IDLE       = 4'd0,
        S_ACT        = 4'd1,
        S_WAIT_TRCD  = 4'd2,
        S_RD_WR      = 4'd3,
        S_WAIT_CL    = 4'd4,
        S_PRE        = 4'd5,
        S_WAIT_TRP   = 4'd6,
        S_REF        = 4'd7,
        S_WAIT_TRFC  = 4'd8
    } state_t;

    state_t state, next_state;

    logic [7:0] timer;
    logic [2:0] lat_cmd;
    logic [31:0] lat_addr;

    // Ready only in IDLE
    always_comb begin
        fsm_ready = (state == S_IDLE);
    end

    // Default DFI outputs = NOP
    // NOP: CS#=0, RAS=1 CAS=1 WE=1 (or CS#=1 depending style)
    always_comb begin
        dfi_cke   = 1'b1;
        dfi_cs_n  = 1'b0;     // keep selected for simplicity
        dfi_ras_n = 1'b1;
        dfi_cas_n = 1'b1;
        dfi_we_n  = 1'b1;

        dfi_addr  = '0;
        dfi_bank  = '0;

        case (state)
            S_ACT: begin
                // ACT: RAS=0 CAS=1 WE=1
                dfi_ras_n = 1'b0;
                dfi_cas_n = 1'b1;
                dfi_we_n  = 1'b1;
                dfi_addr  = lat_addr[13:0];  // placeholder row
                dfi_bank  = 3'd0;
            end

            S_RD_WR: begin
                if (lat_cmd == CMD_READ || lat_cmd == CMD_SCRUB) begin
                    // READ: RAS=1 CAS=0 WE=1
                    dfi_ras_n = 1'b1;
                    dfi_cas_n = 1'b0;
                    dfi_we_n  = 1'b1;
                    dfi_addr  = lat_addr[13:0]; // placeholder col
                    dfi_bank  = 3'd0;
                end else if (lat_cmd == CMD_WRITE) begin
                    // WRITE: RAS=1 CAS=0 WE=0
                    dfi_ras_n = 1'b1;
                    dfi_cas_n = 1'b0;
                    dfi_we_n  = 1'b0;
                    dfi_addr  = lat_addr[13:0];
                    dfi_bank  = 3'd0;
                end
            end

            S_PRE: begin
                // PRE: RAS=0 CAS=1 WE=0
                dfi_ras_n = 1'b0;
                dfi_cas_n = 1'b1;
                dfi_we_n  = 1'b0;
                dfi_addr  = '0;
                dfi_bank  = 3'd0;
            end

            S_REF: begin
                // REF: RAS=0 CAS=0 WE=1
                dfi_ras_n = 1'b0;
                dfi_cas_n = 1'b0;
                dfi_we_n  = 1'b1;
            end

            default: begin
                // NOP already set
            end
        endcase
    end

    // State register + timer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            timer   <= 8'd0;
            lat_cmd <= CMD_NOP;
            lat_addr<= 32'd0;
        end else begin
            state <= next_state;

            // countdown timer
            if (timer != 0)
                timer <= timer - 1;

            // latch cmd in IDLE when accepted
            if (state == S_IDLE && cmd_valid) begin
                lat_cmd  <= cmd_type;
                lat_addr <= cmd_addr;
            end

            // load timer on entering wait states
            if (state == S_ACT) begin
                timer <= tRCD[7:0];
            end else if (state == S_RD_WR) begin
                timer <= CL[7:0];
            end else if (state == S_PRE) begin
                timer <= tRP[7:0];
            end else if (state == S_REF) begin
                timer <= tRFC[7:0];
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (cmd_valid) begin
                    if (cmd_type == CMD_REFRESH)
                        next_state = S_REF;
                    else
                        next_state = S_ACT; // READ/WRITE/SCRUB all start with ACT
                end
            end

            S_ACT: begin
                next_state = S_WAIT_TRCD;
            end

            S_WAIT_TRCD: begin
                if (timer == 0)
                    next_state = S_RD_WR;
            end

            S_RD_WR: begin
                next_state = S_WAIT_CL;
            end

            S_WAIT_CL: begin
                if (timer == 0)
                    next_state = S_PRE;
            end

            S_PRE: begin
                next_state = S_WAIT_TRP;
            end

            S_WAIT_TRP: begin
                if (timer == 0)
                    next_state = S_IDLE;
            end

            S_REF: begin
                next_state = S_WAIT_TRFC;
            end

            S_WAIT_TRFC: begin
                if (timer == 0)
                    next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

endmodule