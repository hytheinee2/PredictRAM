`timescale 1ns / 1ps

module ecc_engine_tb;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ECC_WIDTH  = 8;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // CPU Side (Write)
    logic [DATA_WIDTH-1:0] wdata_cpu;
    logic                  wdata_valid;

    // DRAM Side (72-bit Raw Data)
    logic [DATA_WIDTH+ECC_WIDTH-1:0] dfi_wdata;
    logic                            dfi_wdata_valid;
    logic [DATA_WIDTH+ECC_WIDTH-1:0] dfi_rdata;
    logic                            dfi_rdata_valid;

    // CPU Side (Read)
    logic [DATA_WIDTH-1:0] rdata_cpu;
    logic                  rdata_valid;

    // Telemetry
    logic [ECC_WIDTH-1:0] ml_syndrome;
    logic                 ml_err_sbe;
    logic                 ml_err_dbe;
    logic                 ml_err_in_parity;

    // Instantiate DUT
    ecc_engine #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wdata_cpu(wdata_cpu),
        .wdata_valid(wdata_valid),
        .dfi_wdata(dfi_wdata),
		  .dfi_wdata_valid(dfi_wdata_valid),
        .dfi_rdata(dfi_rdata),
        .dfi_rdata_valid(dfi_rdata_valid),
        .rdata_cpu(rdata_cpu),
        .rdata_valid(rdata_valid),
        .ml_syndrome(ml_syndrome),
        .ml_err_sbe(ml_err_sbe),
        .ml_err_dbe(ml_err_dbe),
        .ml_err_in_parity(ml_err_in_parity) // Hooked up!
    );

    // Clock Generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Verification Task
    // ------------------------------------------------------------------------
    task run_test(
        input string test_name,
        input logic [63:0] test_data,
        input string err_type, // "CLEAN", "SBE_DATA", "SBE_ECC", "DBE", "INVALID"
        input int bit1,        // Bit to flip (if SBE or DBE)
        input int bit2         // Second bit to flip (if DBE)
    );
        logic [71:0] encoded_data;
        logic [71:0] corrupted_data;
        logic        data_match;
        string       status;
        logic        handshake_pass;

        // --- 1. WRITE PHASE (CPU -> ECC) ---
        @(posedge clk);
        wdata_cpu   = test_data;
        wdata_valid = 1'b1;
        
        @(posedge clk);
        wdata_valid = 1'b0;
        #1; // Wait for flip-flop delay
        
        // Capture the perfectly encoded 72-bit word and check the valid flag
        encoded_data = dfi_wdata; 
        handshake_pass = dfi_wdata_valid; // Should be 1 right now

        // --- 2. ERROR INJECTION (Simulate DRAM Corruption) ---
        corrupted_data = encoded_data;
        if (err_type == "SBE_DATA" || err_type == "SBE_ECC") begin
            corrupted_data[bit1] = ~corrupted_data[bit1];
        end else if (err_type == "DBE") begin
            corrupted_data[bit1] = ~corrupted_data[bit1];
            corrupted_data[bit2] = ~corrupted_data[bit2];
        end

        // --- 3. READ PHASE (DRAM -> ECC -> CPU) ---
        @(posedge clk);
        dfi_rdata = corrupted_data;
        if (err_type == "INVALID") dfi_rdata_valid = 1'b0;
        else                       dfi_rdata_valid = 1'b1;
        
        @(posedge clk);
        dfi_rdata_valid = 1'b0;
        #1; // Wait for flip-flop delay

        // --- 4. SELF-CHECKING LOGIC ---
        data_match = (rdata_cpu == test_data);
        status = "PASS";

        // Check new handshake logic
        if (err_type != "INVALID" && !handshake_pass) begin
             status = "FAIL (No Write Valid)";
        end
        // Validate expectations based on error type
        else if (err_type == "INVALID") begin
            if (ml_err_sbe || ml_err_dbe || ml_err_in_parity) status = "FAIL (Flags Active)";
        end else if (err_type == "CLEAN") begin
            if (ml_err_sbe || ml_err_dbe || !data_match) status = "FAIL";
        end else if (err_type == "SBE_DATA") begin
            if (!ml_err_sbe || ml_err_dbe || !data_match) status = "FAIL";
        end else if (err_type == "SBE_ECC") begin
            if (!ml_err_sbe || !ml_err_in_parity || !data_match) status = "FAIL";
        end else if (err_type == "DBE") begin
            // For DBE, data should NOT match (uncorrectable), and DBE flag must be high
            if (!ml_err_dbe || ml_err_sbe || data_match) status = "FAIL";
        end

        // --- 5. PRINT RESULTS ---
        $display("%-22s | %-8s |   %b   |   %b   |    %b    |    %b    || %s", 
                 test_name, err_type, ml_err_sbe, ml_err_dbe, ml_err_in_parity, data_match, status);
    endtask

    // ------------------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        // Init
        rst_n = 0;
        wdata_cpu = 0;
        wdata_valid = 0;
        dfi_rdata = 0;
        dfi_rdata_valid = 0;

        // Reset system
        #20 rst_n = 1;
        #10;

        $display("=======================================================================================");
        $display("                           PredictRAM ECC Engine Verification                          ");
        $display("=======================================================================================");
        $display("Test Case              | Err Type |  SBE  |  DBE  | Parity Err | Corrected || Status ");
        $display("---------------------------------------------------------------------------------------");

        // 1. Clean Data Cases
        run_test("All Zeros",          64'h0000000000000000, "CLEAN", 0, 0);
        run_test("All Ones",           64'hFFFFFFFFFFFFFFFF, "CLEAN", 0, 0);
        run_test("Random Pattern",     64'hDEADBEEFCAFEBABE, "CLEAN", 0, 0);

        // 2. Single Bit Errors in Data (Should be corrected, SBE=1)
        run_test("SBE Data Bit 0",     64'h1234567890ABCDEF, "SBE_DATA", 0, 0);
        run_test("SBE Data Bit 31",    64'h1234567890ABCDEF, "SBE_DATA", 31, 0);
        run_test("SBE Data Bit 63",    64'h1234567890ABCDEF, "SBE_DATA", 63, 0);

        // 3. Single Bit Errors in ECC/Parity Bits (Should flag Parity_Err, Data remains clean)
        run_test("SBE ECC Bit 64",     64'hAABBCCDDEEFF0011, "SBE_ECC", 64, 0);
        run_test("SBE ECC Bit 71",     64'hAABBCCDDEEFF0011, "SBE_ECC", 71, 0);

        // 4. Double Bit Errors (Should flag DBE, Data Uncorrectable)
        run_test("DBE Bits 0 & 1",     64'hFACEFEEDC001CAFE, "DBE", 0, 1);
        run_test("DBE Bits 31 & 32",   64'hFACEFEEDC001CAFE, "DBE", 31, 32);
        run_test("DBE Data & ECC",     64'hFACEFEEDC001CAFE, "DBE", 15, 66); // One in data, one in parity

        // 5. Invalid Data Read (Telemetry should not trigger on garbage data if valid=0)
        run_test("Invalid Read Data",  64'h0000000000000000, "INVALID", 0, 0);

        $display("=======================================================================================");
        $finish;
    end

endmodule