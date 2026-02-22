`include "cmd_defs.sv"

module arbiter (
    input  logic        clk,
    input  logic        rst_n,

    // From FIFO (normal commands)
    input  logic        fifo_valid,
    input  logic [2:0]  fifo_cmd,
    input  logic [31:0] fifo_addr,
    output logic        fifo_pop,

    // From refresh timer / ML
    input  logic        refresh_req,
    input  logic        scrub_req,

    // To FSM
    output logic        out_valid,
    output logic [2:0]  out_cmd,
    output logic [31:0] out_addr,
    input  logic        out_ready
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_cmd   <= CMD_NOP;
            out_addr  <= 32'd0;
            fifo_pop  <= 1'b0;
        end else begin
            fifo_pop <= 1'b0;

            // If current command accepted, clear valid
            if (out_valid && out_ready)
                out_valid <= 1'b0;

            // If FSM ready and no pending command, choose next
            if (out_ready && !out_valid) begin
                if (refresh_req) begin
                    out_valid <= 1'b1;
                    out_cmd   <= CMD_REFRESH;
                    out_addr  <= 32'd0;
                end else if (scrub_req) begin
                    out_valid <= 1'b1;
                    out_cmd   <= CMD_SCRUB;
                    out_addr  <= 32'd0;
                end else if (fifo_valid) begin
                    out_valid <= 1'b1;
                    out_cmd   <= fifo_cmd;     // READ or WRITE
                    out_addr  <= fifo_addr;
                    fifo_pop  <= 1'b1;          // pop only when we take fifo cmd
                end else begin
                    out_valid <= 1'b0;
                    out_cmd   <= CMD_NOP;
                end
            end
        end
    end

endmodule