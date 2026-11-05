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
	output logic [WIDTH_MUL-1:0]    mul_o       // 15bit
);
//===========================DECLARATION=======================================
	logic                                         cout_o;
	logic [(WIDTH_KERNEL/2)-1:0][WIDTH_PIXEL+1:0] pp_o;
  logic [(WIDTH_KERNEL/2)-1:0][WIDTH_MUL-1:0]   concat_pp;
	logic [(WIDTH_KERNEL/2)-1:0]                  neg_o;
	logic [WIDTH_MUL-1:0]                         mul_out;
	logic [WIDTH_MUL-1:0]                         sum_partial;
	logic [WIDTH_MUL-1:0]                         carry_partial;
  logic [WIDTH_MUL-1:0]                         neg_vector;  // Thêm vector chứa các bit bù từ Booth Encoder
//===========================INSTANTIATION=======================================
	booth_encoder booth (
		.opa_i(opa_i),
		.opb_i(opb_i),
		.neg_o(neg_o),
		.pp_o(pp_o)     // 8bit
	);
  //---------------CONCATENATION_PARTIAL-------------------------
	always_comb begin : concat_partial
		concat_pp[0] = {{(WIDTH_MUL-(WIDTH_PIXEL+2)){pp_o[0][WIDTH_PIXEL+1]}}, pp_o[0]};
		concat_pp[1] = {pp_o[1], 2'b0};
    //---------------NEGATION VECTOR ALIGNMENT---------------------
    // Đưa neg_o[0] vào bit 0 và neg_o[1] vào bit 2 để thực hiện phép bù 2 hoàn chỉnh cùng với Carry Save Adder
    neg_vector = {{(WIDTH_MUL-3){1'b0}}, neg_o[1], 1'b0, neg_o[0]};
	end
  //---------------CARRY SAVE ADDER STAGE------------------------
  csa #(
    .WIDTH(WIDTH_MUL)
  ) csa_stage (
    .a_i    (concat_pp[0]),
    .b_i    (concat_pp[1]),
    .c_i    (neg_vector),
    .sum_o  (sum_partial),
    .carry_o(carry_partial)
  );
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
  // assign mul_o = {{(WIDTH_MAC - WIDTH_MUL){mul_out[WIDTH_MUL-1]}}, mul_out};
endmodule