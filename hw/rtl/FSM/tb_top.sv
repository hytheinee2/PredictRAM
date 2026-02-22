`timescale 1ns/1ps
`include "../src/cmd_defs.sv"

module tb_top;

    logic clk, rst_n;

    logic fifo_valid;
    logic [2:0] fifo_cmd;
    logic [31:0] fifo_addr;
    logic fifo_pop;

    logic refresh_req, scrub_req;

    logic dfi_cs_n, dfi_ras_n, dfi_cas_n, dfi_we_n, dfi_cke;
    logic [13:0] dfi_addr;
    logic [2:0]  dfi_bank;

    top_control dut (
        .clk(clk),
        .rst_n(rst_n),
        .fifo_valid(fifo_valid),
        .fifo_cmd(fifo_cmd),
        .fifo_addr(fifo_addr),
        .fifo_pop(fifo_pop),
        .refresh_req(refresh_req),
        .scrub_req(scrub_req),
        .dfi_cs_n(dfi_cs_n),
        .dfi_ras_n(dfi_ras_n),
        .dfi_cas_n(dfi_cas_n),
        .dfi_we_n(dfi_we_n),
        .dfi_cke(dfi_cke),
        .dfi_addr(dfi_addr),
        .dfi_bank(dfi_bank)
    );

    // Clock 100MHz (10ns period)
    always #5 clk = ~clk;

    // Helper: present one FIFO cmd until popped
    task send_fifo_cmd(input logic [2:0] cmd, input logic [31:0] addr);
        begin
            fifo_cmd   = cmd;
            fifo_addr  = addr;
            fifo_valid = 1'b1;
            // wait until popped
            wait (fifo_pop == 1'b1);
            @(posedge clk);
            fifo_valid = 1'b0;
        end
    endtask

    initial begin
        // init
        clk = 0;
        rst_n = 0;
        fifo_valid = 0;
        fifo_cmd = CMD_NOP;
        fifo_addr = 0;
        refresh_req = 0;
        scrub_req = 0;

        // reset
        repeat (5) @(posedge clk);
        rst_n = 1;

        // -------- Test 1: FIFO READ ----------
        $display("TEST1: FIFO READ");
        send_fifo_cmd(CMD_READ, 32'h0000_1000);
        repeat (30) @(posedge clk);

        // -------- Test 2: FIFO WRITE ----------
        $display("TEST2: FIFO WRITE");
        send_fifo_cmd(CMD_WRITE, 32'h0000_2000);
        repeat (30) @(posedge clk);

        // -------- Test 3: REFRESH wins ----------
        $display("TEST3: REFRESH priority");
        refresh_req = 1'b1;
        repeat (2) @(posedge clk);
        refresh_req = 1'b0;
        repeat (30) @(posedge clk);

        // -------- Test 4: SCRUB wins over FIFO ----------
        $display("TEST4: SCRUB priority over FIFO");
        scrub_req = 1'b1;
        fifo_cmd = CMD_READ;
        fifo_addr = 32'h0000_3000;
        fifo_valid = 1'b1;

        repeat (2) @(posedge clk);
        scrub_req = 1'b0;

        // wait for fifo to be popped eventually
        wait (fifo_pop == 1'b1);
        @(posedge clk);
        fifo_valid = 1'b0;

        repeat (50) @(posedge clk);

        $display("DONE");
        $stop;
    end

endmodule