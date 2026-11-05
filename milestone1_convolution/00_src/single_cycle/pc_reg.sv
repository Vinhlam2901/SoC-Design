//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Program Counter Register
// File            : pc_reg.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 13/9/2025
//===========================================================================================
module pc_reg (
  input  wire  [31:0]  pc_reg,
  output reg   [31:0]  pc_o
);
  cla_nbit #(
    .WIDTH_CLA(32)
    ) PCplus4 (
    .a   (pc_reg),
    .b   (32'd4),
    .cin (1'b0),
    .sum (pc_o),
    .cout()
  );
endmodule