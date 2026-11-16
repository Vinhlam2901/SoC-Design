//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Module Adder and Subtractor Selectable
// File            : add_subtract.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module add_subtract (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input              cin_i,     // 0: Cộng, 1: Trừ
    output wire [31:0] result_o,
    output             cout_o
);
  wire [31:0] b_mod_i;
  wire raw_cout;
  assign b_mod_i = b_i ^ {32{cin_i}}; // nếu b_i là [3:0] và cin_i là 1 bit
  cla_nbit #(
    .WIDTH_CLA(32)
    ) cla0 (
    .a   (a_i),
    .b   (b_mod_i),
    .cin (cin_i),
    .sum (result_o),
    .cout(raw_cout)
  );
  assign cout_o = cin_i ? ~((a_i[31] & b_mod_i[31]) | ((a_i[31] ^ b_mod_i[31]) & raw_cout)) :
                            (a_i[31] & b_mod_i[31]) | ((a_i[31] ^ b_mod_i[31]) & raw_cout);
endmodule