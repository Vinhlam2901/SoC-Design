//===========================================================================================================
// Project         : Multiplier Acumulator
// Module          : Multiplier Booth - Wallace - CLA
// File            : mac.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 02/07/2026
// Updated date    : 02/07/2026
//============================================================================================================
import package_param::*;
module mul (
	input  logic [WIDTH_PIXEL-1:0]  opa_i,
	input  logic [WIDTH_KERNEL-1:0] opb_i,
	output logic [WIDTH_MUL-1:0]    mul_o       // 16bit
);
//===========================DECLARATION=======================================
	logic                                         cout_o;
	logic [(WIDTH_KERNEL/2)-1:0][WIDTH_PIXEL+1:0] pp_o;
  logic [(WIDTH_KERNEL/2)-1:0][WIDTH_MUL-1:0]   concat_pp;
	logic [(WIDTH_KERNEL/2)-1:0]                  neg_o;
	logic [WIDTH_MUL-1:0]                         mul_out;
	logic [WIDTH_MUL-1:0]                         sum_partial;
	logic [WIDTH_MUL-1:0]                         carry_partial;
  logic [WIDTH_MUL-1:0]                         neg_vector;
  logic [WIDTH_MUL-1:0]                         sum1, carry1;
  logic [WIDTH_MUL-1:0]                         sum2, carry2;
//===========================INSTANTIATION=======================================
	booth_encoder booth (
		.opa_i(opa_i),
		.opb_i(opb_i),
		.neg_o(neg_o),
		.pp_o (pp_o)     // 4 partial products 10 bits
	);
  //---------------CONCATENATION_PARTIAL-------------------------
  always_comb begin : concat_partial
    concat_pp[0] = {{6{pp_o[0][9]}}, pp_o[0]           }; // 6 + 10     = 16 bit
    concat_pp[1] = {{4{pp_o[1][9]}}, pp_o[1], {2{1'b0}}}; // 4 + 10 + 2 = 20 bit
    concat_pp[2] = {{2{pp_o[2][9]}}, pp_o[2], {4{1'b0}}}; // 2 + 10 + 4 = 20 bit
    concat_pp[3] = {                 pp_o[3], {6{1'b0}}}; //     10 + 6 = 20 bit
    // Căn chỉnh Vector bù 2 (neg_o) cho hệ 20-bit
    neg_vector   = {9'b0, neg_o[3], 1'b0, neg_o[2], 1'b0, neg_o[1], 1'b0, neg_o[0]};
  end
  //---------------CARRY SAVE ADDER STAGE------------------------
  csa #(.WIDTH(WIDTH_MUL)) level1 (.a_i(concat_pp[0]),.b_i(concat_pp[1]),        .c_i(concat_pp[2]),.sum_o(sum1),       .carry_o(carry1));
  csa #(.WIDTH(WIDTH_MUL)) level2 (.a_i(sum1),        .b_i({carry1[14:0], 1'b0}),.c_i(concat_pp[3]),.sum_o(sum2),       .carry_o(carry2));
  csa #(.WIDTH(WIDTH_MUL)) level3 (.a_i(sum2),        .b_i({carry2[14:0], 1'b0}),.c_i(neg_vector),  .sum_o(sum_partial),.carry_o(carry_partial));
  //---------------FINAL CARRY LOOKAHEAD ADDER-------------------
  cla_nbit # (
    .WIDTH_CLA(WIDTH_MUL)
  ) final_cla (
    .a(sum_partial),
    .b({carry_partial[WIDTH_MUL-2:0], 1'b0}),
    .cin(1'b0),
    .sum(mul_o),
    .cout(cout_o)
  );
endmodule