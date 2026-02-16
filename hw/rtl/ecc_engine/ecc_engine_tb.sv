`timescale 1ns/1ps

module ecc_engine_tb;

    // -------------------------------------------------------
    // 1. Parameters & Signals
    // -------------------------------------------------------
    localparam DATA_WIDTH = 64;
    localparam ECC_WIDTH  = 8;

    logic                   clk;
    logic                   rst_n;
    
    // CPU Interfaces
    logic [DATA_WIDTH-1:0]  wdata_cpu;
    logic                   wdata_valid;
    logic [DATA_WIDTH-1:0]  rdata_cpu;
    logic                   rdata_valid;
    
    // DRAM Interfaces (72-bit)
    logic [71:0]            dfi_wdata; 
    logic [71:0]            dfi_rdata; 
    logic                   dfi_rdata_valid;
    
    // ML Telemetry Interfaces
    logic [ECC_WIDTH-1:0]   ml_syndrome;
    logic                   ml_err_sbe;
    logic                   ml_err_dbe;
    logic                   ml_err_in_parity; // The new flag!

    // -------------------------------------------------------
    // 2. Clock Generation (50 MHz)
    // -------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // -------------------------------------------------------
    // 3. Instantiate the DUT (Device Under Test)
    // -------------------------------------------------------
    ecc_engine #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_cpu(wdata_cpu),
        .wdata_valid(wdata_valid),
        .dfi_wdata(dfi_wdata),
        .dfi_rdata(dfi_rdata),
        .dfi_rdata_valid(dfi_rdata_valid),
        .rdata_cpu(rdata_cpu),
        .rdata_valid(rdata_valid),
        .ml_syndrome(ml_syndrome),
        .ml_err_sbe(ml_err_sbe),
        .ml_err_dbe(ml_err_dbe),
        .ml_err_in_parity(ml_err_in_parity) // Hooked up!
    );

    // -------------------------------------------------------
    // 4. Test Sequence
    // -------------------------------------------------------
    initial begin
        // --- Initialization ---
        $display("==================================================");
        $display("   PredictRAM ECC Engine Verification Started     ");
        $display("==================================================");
        rst_n = 0;
        wdata_cpu = '0;
        wdata_valid = 0;
        dfi_rdata = '0;
        dfi_rdata_valid = 0;
        
        #25 rst_n = 1;
        #15;

        // ---------------------------------------------------
        // TEST 1: Clean Write & Read
        // ---------------------------------------------------
        $display("\n[TEST 1] Encoding & Decoding Clean Data...");
        @(posedge clk);
        wdata_cpu = 64'hAAAA_BBBB_CCCC_DDDD;
        wdata_valid = 1;
        @(posedge clk);
        wdata_valid = 0;
        
        #20; // Wait for write logic
        
        @(posedge clk);
        dfi_rdata = dfi_wdata; // Perfect Loopback
        dfi_rdata_valid = 1;
        @(posedge clk);
        dfi_rdata_valid = 0;
        
        #20; // Wait for read logic
        if (rdata_cpu == 64'hAAAA_BBBB_CCCC_DDDD && !ml_err_sbe && !ml_err_in_parity)
            $display("   -> PASS: Data intact, no errors flagged.");
        else
            $display("   -> FAIL: Clean read failed.");

        // ---------------------------------------------------
        // TEST 2: Single Bit Error (In Data Payload)
        // ---------------------------------------------------
        $display("\n[TEST 2] Injecting SBE on DATA Bit 5...");
        @(posedge clk);
        dfi_rdata = dfi_wdata; 
        dfi_rdata[5] = ~dfi_rdata[5]; // Flip Data Bit 5
        dfi_rdata_valid = 1;
        @(posedge clk);
        dfi_rdata_valid = 0;
        
        #20;
        if (rdata_cpu == 64'hAAAA_BBBB_CCCC_DDDD && ml_err_sbe && !ml_err_in_parity)
            $display("   -> PASS: Data Auto-Corrected! (SBE=1, Parity_Err=0)");
        else
            $display("   -> FAIL: Data SBE logic failed.");

        // ---------------------------------------------------
        // TEST 3: Single Bit Error (In Parity Overhead)
        // ---------------------------------------------------
        $display("\n[TEST 3] Injecting SBE on PARITY Bit 0 (Bit 64 of bus)...");
        @(posedge clk);
        dfi_rdata = dfi_wdata; 
        dfi_rdata[64] = ~dfi_rdata[64]; // Flip ECC Bit 0 (Overall bus bit 64)
        dfi_rdata_valid = 1;
        @(posedge clk);
        dfi_rdata_valid = 0;
        
        #20;
        if (rdata_cpu == 64'hAAAA_BBBB_CCCC_DDDD && ml_err_sbe && ml_err_in_parity)
            $display("   -> PASS: Data untouched! (SBE=1, Parity_Err=1)");
        else
            $display("   -> FAIL: Parity error isolation failed.");

        // ---------------------------------------------------
        // TEST 4: Double Bit Error (Uncorrectable)
        // ---------------------------------------------------
        $display("\n[TEST 4] Injecting Double Bit Error (Bits 10 and 11)...");
        @(posedge clk);
        dfi_rdata = dfi_wdata; 
        dfi_rdata[10] = ~dfi_rdata[10]; // Flip Bit 10
        dfi_rdata[11] = ~dfi_rdata[11]; // Flip Bit 11
        dfi_rdata_valid = 1;
        @(posedge clk);
        dfi_rdata_valid = 0;
        
        #20;
        if (ml_err_dbe && !ml_err_sbe)
            $display("   -> PASS: DBE Flagged! Hardware stopped correction.");
        else
            $display("   -> FAIL: DBE logic failed.");

        $display("\n==================================================");
        $display("   Verification Complete. Ready for Synthesis!    ");
        $display("==================================================");
        $finish;
    end

endmodule