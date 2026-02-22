`ifndef CMD_DEFS_SV
`define CMD_DEFS_SV

localparam logic [2:0] CMD_NOP     = 3'b000;
localparam logic [2:0] CMD_READ    = 3'b001;
localparam logic [2:0] CMD_WRITE   = 3'b010;
localparam logic [2:0] CMD_REFRESH = 3'b011;
localparam logic [2:0] CMD_SCRUB   = 3'b100;

`endif