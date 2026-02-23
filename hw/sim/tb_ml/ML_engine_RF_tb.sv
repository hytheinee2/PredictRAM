`timescale 1ns / 1ps

module ML_engine_RF_tb;

    // Inputs
    logic [15:0] total_errors;
    logic [15:0] read_errors;
    logic [15:0] write_errors;
    logic [15:0] scrub_errors;
    logic [15:0] unique_rows;
    logic [15:0] unique_cols;
    logic [15:0] max_row_hits;
    logic [15:0] max_col_hits;
    logic [15:0] error_rate_int;

    // Output
    logic [1:0] final_action;

    // Instantiate the Unit Under Test (DUT)
    ML_engine_RF dut (
        .total_errors(total_errors),
        .read_errors(read_errors),
        .write_errors(write_errors),
        .scrub_errors(scrub_errors),
        .unique_rows(unique_rows),
        .unique_cols(unique_cols),
        .max_row_hits(max_row_hits),
        .max_col_hits(max_col_hits),
        .error_rate_int(error_rate_int),
        .final_action(final_action)
    );

    // Task to apply vectors and print results neatly
    task apply_test(
        input string test_name,
        input logic [15:0] t_err, r_err, w_err, s_err, u_row, u_col, m_r_hit, m_c_hit, e_rate
    );
    begin
        total_errors   = t_err;
        read_errors    = r_err;
        write_errors   = w_err;
        scrub_errors   = s_err;
        unique_rows    = u_row;
        unique_cols    = u_col;
        max_row_hits   = m_r_hit;
        max_col_hits   = m_c_hit;
        error_rate_int = e_rate;
        
        #10; // Wait for combinational logic to settle
        
        $display("%-20s | %8d | %8d | %8d | %9d ||    %d", 
                 test_name, max_row_hits, unique_rows, unique_cols, error_rate_int, final_action);
    end
    endtask

    initial begin
        // Print Header
        $display("=========================================================================================");
        $display("                              PredictRAM Hybrid ML Engine Testbench                      ");
        $display("=========================================================================================");
        $display("Test Case            | MaxRHits | UniqRows | UniqCols | ErrorRate || ACTION (1=S, 2=R) ");
        $display("-----------------------------------------------------------------------------------------");

        // 1. Baseline: Absolute Zero (Should be 0)
        apply_test("1. All Zeros",         0, 0, 0, 0, 0, 0, 0, 0, 0);

        // 2. Hard Rule 1a Edge: Exact boundary of Row Hammer (Should be 1 - SCRUB)
        apply_test("2. RowHits Edge (64)", 64, 0, 0, 0, 10, 5, 64, 5, 10);

        // 3. Hard Rule 1b Edge: (unique_rows * 5 < total_errors). 
        // 10 * 5 = 50. Total = 51. (50 < 51 is TRUE). (Should be 1 - SCRUB)
        apply_test("3. Ratio Rule (<0.2)", 51, 0, 0, 0, 10, 5, 10, 5, 10);

        // 4. Hard Rule 1b Miss: 10 * 5 = 50. Total = 50. (50 < 50 is FALSE). 
        // ML takes over. (Likely 0)
        apply_test("4. Ratio Edge (=0.2)", 50, 0, 0, 0, 10, 5, 10, 5, 10);

        // 5. Hard Rule 2 Edge: Exact boundary of Refresh (Should be 2 - REFRESH)
        apply_test("5. Rate+Col Edge",     100, 0, 0, 0, 50, 8, 5, 5, 50);

        // 6. Hard Rule 2 Miss: High rate, but unique_cols is 7 (Fails rule). 
        // ML takes over. (Tests the handoff to ML)
        apply_test("6. High Rate/Low Col", 100, 0, 0, 0, 50, 7, 5, 5, 150);

        // 7. ML Domain: No hard rules hit, purely random low-level noise. 
        // Let the RF decide!
        apply_test("7. ML pure decision",  15, 5, 5, 5, 4, 4, 3, 3, 20);

        $display("=========================================================================================");
        $finish;
    end

endmodule