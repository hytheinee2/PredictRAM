module ML_engine_RF (
    input  logic [15:0] total_errors,
    input  logic [15:0] read_errors,
    input  logic [15:0] write_errors,
    input  logic [15:0] scrub_errors,
    input  logic [15:0] unique_rows,
    input  logic [15:0] unique_cols,
    input  logic [15:0] max_row_hits,
    input  logic [15:0] max_col_hits,
    input  logic [15:0] error_rate_int,
    output logic [1:0]  final_action
);

logic [1:0] vote_0;
logic [1:0] vote_1;
logic [1:0] vote_2;
logic [1:0] vote_3;
logic [1:0] vote_4;

// Tree 0
always_comb begin
  if (scrub_errors <= 4) begin
    if (unique_cols <= 7) begin
      if (max_row_hits <= 5) begin
        vote_0 = 2'd0;
      end else begin
        if (write_errors <= 0) begin
          vote_0 = 2'd1;
        end else begin
          vote_0 = 2'd1;
        end
      end
    end else begin
      if (read_errors <= 39) begin
        if (scrub_errors <= 0) begin
          if (unique_cols <= 11) begin
            if (unique_cols <= 9) begin
              vote_0 = 2'd2;
            end else begin
              vote_0 = 2'd0;
            end
          end else begin
            vote_0 = 2'd2;
          end
        end else begin
          vote_0 = 2'd0;
        end
      end else begin
        if (max_row_hits <= 8) begin
          vote_0 = 2'd0;
        end else begin
          vote_0 = 2'd1;
        end
      end
    end
  end else begin
    if (error_rate_int <= 93) begin
      if (unique_rows <= 5) begin
        if (scrub_errors <= 5) begin
          if (total_errors <= 6) begin
            vote_0 = 2'd0;
          end else begin
            if (total_errors <= 8) begin
              vote_0 = 2'd1;
            end else begin
              vote_0 = 2'd1;
            end
          end
        end else begin
          if (total_errors <= 7) begin
            if (max_col_hits <= 3) begin
              vote_0 = 2'd0;
            end else begin
              vote_0 = 2'd1;
            end
          end else begin
            if (max_row_hits <= 6) begin
              vote_0 = 2'd0;
            end else begin
              vote_0 = 2'd1;
            end
          end
        end
      end else begin
        if (unique_cols <= 45) begin
          if (unique_rows <= 28) begin
            vote_0 = 2'd0;
          end else begin
            if (unique_rows <= 107) begin
              vote_0 = 2'd1;
            end else begin
              vote_0 = 2'd0;
            end
          end
        end else begin
          vote_0 = 2'd1;
        end
      end
    end else begin
      if (max_row_hits <= 4) begin
        if (scrub_errors <= 15) begin
          vote_0 = 2'd0;
        end else begin
          vote_0 = 2'd0;
        end
      end else begin
        vote_0 = 2'd1;
      end
    end
  end
end
// Tree 1
always_comb begin
  if (read_errors <= 7) begin
    if (total_errors <= 5) begin
      vote_1 = 2'd0;
    end else begin
      if (max_row_hits <= 5) begin
        vote_1 = 2'd0;
      end else begin
        if (total_errors <= 10) begin
          if (max_row_hits <= 6) begin
            if (unique_rows <= 1) begin
              vote_1 = 2'd1;
            end else begin
              vote_1 = 2'd0;
            end
          end else begin
            if (unique_rows <= 1) begin
              vote_1 = 2'd1;
            end else begin
              vote_1 = 2'd0;
            end
          end
        end else begin
          vote_1 = 2'd1;
        end
      end
    end
  end else begin
    if (unique_cols <= 7) begin
      if (read_errors <= 38) begin
        if (error_rate_int <= 0) begin
          if (unique_rows <= 6) begin
            vote_1 = 2'd1;
          end else begin
            vote_1 = 2'd0;
          end
        end else begin
          if (unique_rows <= 6) begin
            vote_1 = 2'd1;
          end else begin
            if (total_errors <= 4635) begin
              vote_1 = 2'd0;
            end else begin
              vote_1 = 2'd1;
            end
          end
        end
      end else begin
        if (total_errors <= 5077) begin
          if (error_rate_int <= 2) begin
            if (unique_rows <= 50) begin
              vote_1 = 2'd1;
            end else begin
              vote_1 = 2'd0;
            end
          end else begin
            vote_1 = 2'd0;
          end
        end else begin
          vote_1 = 2'd1;
        end
      end
    end else begin
      if (unique_rows <= 3) begin
        vote_1 = 2'd1;
      end else begin
        if (unique_cols <= 50) begin
          if (max_col_hits <= 21) begin
            if (read_errors <= 40) begin
              vote_1 = 2'd2;
            end else begin
              vote_1 = 2'd1;
            end
          end else begin
            if (unique_rows <= 50) begin
              vote_1 = 2'd0;
            end else begin
              vote_1 = 2'd0;
            end
          end
        end else begin
          if (scrub_errors <= 22) begin
            if (unique_rows <= 14) begin
              vote_1 = 2'd1;
            end else begin
              vote_1 = 2'd0;
            end
          end else begin
            vote_1 = 2'd1;
          end
        end
      end
    end
  end
end
// Tree 2
always_comb begin
  if (max_row_hits <= 3) begin
    if (scrub_errors <= 0) begin
      vote_2 = 2'd0;
    end else begin
      vote_2 = 2'd0;
    end
  end else begin
    if (unique_rows <= 3) begin
      if (error_rate_int <= 540) begin
        if (max_col_hits <= 5) begin
          if (total_errors <= 8) begin
            if (total_errors <= 6) begin
              vote_2 = 2'd0;
            end else begin
              vote_2 = 2'd0;
            end
          end else begin
            if (scrub_errors <= 9) begin
              vote_2 = 2'd1;
            end else begin
              vote_2 = 2'd1;
            end
          end
        end else begin
          if (total_errors <= 10) begin
            if (unique_rows <= 1) begin
              vote_2 = 2'd1;
            end else begin
              vote_2 = 2'd0;
            end
          end else begin
            vote_2 = 2'd1;
          end
        end
      end else begin
        if (total_errors <= 7) begin
          vote_2 = 2'd0;
        end else begin
          vote_2 = 2'd1;
        end
      end
    end else begin
      if (error_rate_int <= 199) begin
        if (max_row_hits <= 15) begin
          if (error_rate_int <= 21) begin
            vote_2 = 2'd0;
          end else begin
            if (total_errors <= 36) begin
              vote_2 = 2'd0;
            end else begin
              vote_2 = 2'd1;
            end
          end
        end else begin
          if (scrub_errors <= 2) begin
            vote_2 = 2'd0;
          end else begin
            if (total_errors <= 82) begin
              vote_2 = 2'd1;
            end else begin
              vote_2 = 2'd1;
            end
          end
        end
      end else begin
        if (scrub_errors <= 0) begin
          vote_2 = 2'd2;
        end else begin
          if (error_rate_int <= 623) begin
            vote_2 = 2'd2;
          end else begin
            vote_2 = 2'd1;
          end
        end
      end
    end
  end
end
// Tree 3
always_comb begin
  if (unique_cols <= 7) begin
    if (error_rate_int <= 0) begin
      if (max_row_hits <= 5) begin
        vote_3 = 2'd0;
      end else begin
        if (unique_rows <= 70) begin
          if (max_row_hits <= 6) begin
            if (unique_rows <= 1) begin
              vote_3 = 2'd1;
            end else begin
              vote_3 = 2'd0;
            end
          end else begin
            vote_3 = 2'd1;
          end
        end else begin
          vote_3 = 2'd0;
        end
      end
    end else begin
      if (write_errors <= 3) begin
        if (total_errors <= 15216) begin
          if (max_col_hits <= 2) begin
            vote_3 = 2'd0;
          end else begin
            if (max_col_hits <= 11) begin
              vote_3 = 2'd1;
            end else begin
              vote_3 = 2'd0;
            end
          end
        end else begin
          if (max_row_hits <= 149) begin
            vote_3 = 2'd1;
          end else begin
            vote_3 = 2'd1;
          end
        end
      end else begin
        vote_3 = 2'd1;
      end
    end
  end else begin
    if (max_row_hits <= 39) begin
      if (read_errors <= 7) begin
        vote_3 = 2'd1;
      end else begin
        if (read_errors <= 42) begin
          if (scrub_errors <= 82) begin
            if (error_rate_int <= 28) begin
              vote_3 = 2'd1;
            end else begin
              vote_3 = 2'd2;
            end
          end else begin
            vote_3 = 2'd1;
          end
        end else begin
          if (unique_rows <= 45) begin
            vote_3 = 2'd1;
          end else begin
            vote_3 = 2'd0;
          end
        end
      end
    end else begin
      if (scrub_errors <= 17) begin
        vote_3 = 2'd1;
      end else begin
        vote_3 = 2'd1;
      end
    end
  end
end
// Tree 4
always_comb begin
  if (max_row_hits <= 6) begin
    if (unique_cols <= 7) begin
      if (scrub_errors <= 2) begin
        if (read_errors <= 4) begin
          vote_4 = 2'd0;
        end else begin
          if (total_errors <= 6) begin
            if (scrub_errors <= 0) begin
              vote_4 = 2'd0;
            end else begin
              vote_4 = 2'd1;
            end
          end else begin
            vote_4 = 2'd0;
          end
        end
      end else begin
        if (total_errors <= 6) begin
          if (max_row_hits <= 5) begin
            vote_4 = 2'd0;
          end else begin
            vote_4 = 2'd1;
          end
        end else begin
          vote_4 = 2'd0;
        end
      end
    end else begin
      if (scrub_errors <= 0) begin
        if (read_errors <= 20) begin
          vote_4 = 2'd2;
        end else begin
          vote_4 = 2'd0;
        end
      end else begin
        vote_4 = 2'd0;
      end
    end
  end else begin
    if (unique_rows <= 42) begin
      if (max_col_hits <= 7) begin
        if (total_errors <= 73) begin
          vote_4 = 2'd1;
        end else begin
          if (read_errors <= 59) begin
            if (unique_rows <= 8) begin
              vote_4 = 2'd1;
            end else begin
              vote_4 = 2'd0;
            end
          end else begin
            vote_4 = 2'd1;
          end
        end
      end else begin
        vote_4 = 2'd1;
      end
    end else begin
      if (max_col_hits <= 137) begin
        vote_4 = 2'd2;
      end else begin
        if (total_errors <= 1576) begin
          vote_4 = 2'd0;
        end else begin
          vote_4 = 2'd1;
        end
      end
    end
  end
end
// Majority Voter Logic
logic [3:0] count_0, count_1, count_2;
logic [1:0] hard_rule_action;
logic [1:0] ml_vote;
always_comb begin
  count_0 = 4'd0; count_1 = 4'd0; count_2 = 4'd0;
  if (vote_0 == 2'd0) count_0 = count_0 + 4'd1;
  if (vote_0 == 2'd1) count_1 = count_1 + 4'd1;
  if (vote_0 == 2'd2) count_2 = count_2 + 4'd1;
  if (vote_1 == 2'd0) count_0 = count_0 + 4'd1;
  if (vote_1 == 2'd1) count_1 = count_1 + 4'd1;
  if (vote_1 == 2'd2) count_2 = count_2 + 4'd1;
  if (vote_2 == 2'd0) count_0 = count_0 + 4'd1;
  if (vote_2 == 2'd1) count_1 = count_1 + 4'd1;
  if (vote_2 == 2'd2) count_2 = count_2 + 4'd1;
  if (vote_3 == 2'd0) count_0 = count_0 + 4'd1;
  if (vote_3 == 2'd1) count_1 = count_1 + 4'd1;
  if (vote_3 == 2'd2) count_2 = count_2 + 4'd1;
  if (vote_4 == 2'd0) count_0 = count_0 + 4'd1;
  if (vote_4 == 2'd1) count_1 = count_1 + 4'd1;
  if (vote_4 == 2'd2) count_2 = count_2 + 4'd1;

  // --- PARALLEL EXPERT RULES (SAFETY LAYER) ---
  // Note: (unique_rows/total_errors) < 0.2 converted to integer math to avoid division
  if (max_row_hits >= 64 || (unique_rows * 5 < total_errors)) begin
    hard_rule_action = 2'd1; // SCRUB
  end else if (error_rate_int >= 50 && unique_cols >= 8) begin
    hard_rule_action = 2'd2; // REFRESH
  end else begin
    hard_rule_action = 2'd0; // NO_ACTION
  end

  // --- FINAL DECISION MULTIPLEXER ---
  if (count_1 >= count_0 && count_1 >= count_2)
    ml_vote = 2'd1; // SCRUB
  else if (count_2 >= count_0 && count_2 >= count_1)
    ml_vote = 2'd2; // REFRESH
  else
    ml_vote = 2'd0; // NO_ACTION

  // Hard rules override ML if triggered, guaranteeing reliability
  final_action = (hard_rule_action != 2'd0) ? hard_rule_action : ml_vote;
end

endmodule
