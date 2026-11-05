module multiply_extension (
  input  wire [31:0] i_op_a,
  input  wire [31:0] i_op_b,
  output reg [31:0] o_mul
);
// check bit lsb to msb of op_a equal to 1 ?
// is 1 -> hold op_b; is 0 -> clear
// check the next bit n of op_a equal to 1 ?
// is 1 -> accumulate op_b then shift left n bit.
// repeat to msb of op_a
// but just need the 32bit o_mul -> so just mul 16 bit op_a and op_b -> so check from bit 0 to bit 16 of op_a.
  reg [31:0] op_a, op_b;
  reg [31:0] convert_a, convert_b;
  wire sign_a, sign_b;
  reg [31:0] op_b1, op_b2, op_b3, op_b4, op_b5, op_b6,
             op_b7, op_b8, op_b9, op_b10, op_b11, op_b12,
             op_b13, op_b14, op_b15, op_b16;
  reg [31:0] o_temp1, o_temp2, o_temp3, o_temp4, o_temp5,
             o_temp6, o_temp7, o_temp8, o_temp9, o_temp10,
             o_temp11, o_temp12, o_temp13, o_temp14, o_temp15;
  reg [31:0] o_temp1_shifted, o_temp2_shifted, o_temp3_shifted, o_temp4_shifted, o_temp5_shifted,
             o_temp6_shifted, o_temp7_shifted, o_temp8_shifted, o_temp9_shifted, o_temp10_shifted,
             o_temp11_shifted, o_temp12_shifted, o_temp13_shifted, o_temp14_shifted, o_temp15_shifted;
  wire        cout;

  assign op_a = {{16{i_op_a[15]}}, i_op_a[15:0]};
  assign op_b = {{16{i_op_b[15]}}, i_op_b[15:0]};
  assign sign_a = (i_op_a[15]) ? 1'b1: 1'b0;
  assign sign_b = (i_op_b[15]) ? 1'b1: 1'b0;
  assign convert_a = (sign_a) ? (~op_a + 1) : op_a;
  assign convert_b = (sign_b) ? (~op_b + 1) : op_b;
//=============================LSB=======================================================================================
  assign op_b1 = (convert_a[0] == 1'b1) ? convert_b : 32'b0;
  // check the next bit
  assign op_b2 = (convert_a[1] == 1'b1) ? convert_b : 32'b0;
  assign o_temp1_shifted = op_b2 << 1;
  // adder
  full_adder_32bit full_adder1 (.A_i(op_b1),.Y_i(o_temp1_shifted),.C_i(1'b0),.Sum_o(o_temp1),.c_o(cout));
//====================================================================================================================
  assign op_b3 = (convert_a[2] == 1'b1) ? convert_b : 32'b0;
  assign o_temp2_shifted = op_b3 << 2;
  // adder
  full_adder_32bit full_adder2 (.A_i(o_temp1),.Y_i(o_temp2_shifted),.C_i(1'b0),.Sum_o(o_temp2),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b4 = (convert_a[3] == 1'b1) ? convert_b : 32'b0;
  assign o_temp3_shifted = op_b4 << 3;
  // adder
  full_adder_32bit full_adder3 (.A_i(o_temp2),.Y_i(o_temp3_shifted),.C_i(1'b0),.Sum_o(o_temp3),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b5 = (convert_a[4] == 1'b1) ? convert_b : 32'b0;
  assign o_temp4_shifted = op_b5 << 4;
  // adder
  full_adder_32bit full_adder4 (.A_i(o_temp3),.Y_i(o_temp4_shifted),.C_i(1'b0),.Sum_o(o_temp4),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b6 = (convert_a[5] == 1'b1) ? convert_b : 32'b0;
  assign o_temp5_shifted = op_b6 << 5;
  // adder
  full_adder_32bit full_adder5 (.A_i(o_temp4),.Y_i(o_temp5_shifted),.C_i(1'b0),.Sum_o(o_temp5),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b7 = (convert_a[6] == 1'b1) ? convert_b : 32'b0;
  assign o_temp6_shifted = op_b7 << 6;
  // adder
  full_adder_32bit full_adder6 (.A_i(o_temp5),.Y_i(o_temp6_shifted),.C_i(1'b0),.Sum_o(o_temp6),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b8 = (convert_a[7] == 1'b1) ? convert_b : 32'b0;
  assign o_temp7_shifted = op_b8 << 7;
  // adder
  full_adder_32bit full_adder7 (.A_i(o_temp6),.Y_i(o_temp7_shifted),.C_i(1'b0),.Sum_o(o_temp7),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b9 = (convert_a[8] == 1'b1) ? convert_b : 32'b0;
  assign o_temp8_shifted = op_b9 << 8;
  // adder
  full_adder_32bit full_adder8 (.A_i(o_temp7),.Y_i(o_temp8_shifted),.C_i(1'b0),.Sum_o(o_temp8),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b10 = (convert_a[9] == 1'b1) ? convert_b : 32'b0;
  assign o_temp9_shifted = op_b10 << 9;
  // adder
  full_adder_32bit full_adder9 (.A_i(o_temp8),.Y_i(o_temp9_shifted),.C_i(1'b0),.Sum_o(o_temp9),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b11 = (convert_a[10]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp10_shifted = op_b11 << 10;
  // adder
  full_adder_32bit full_adder10 (.A_i(o_temp9),.Y_i(o_temp10_shifted),.C_i(1'b0),.Sum_o(o_temp10),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b12 = (convert_a[11]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp11_shifted = op_b12 << 11;
  // adder
  full_adder_32bit full_adder11 (.A_i(o_temp10),.Y_i(o_temp11_shifted),.C_i(1'b0),.Sum_o(o_temp11),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b13 = (convert_a[12]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp12_shifted = op_b13 << 12;
  // adder
  full_adder_32bit full_adder12 (.A_i(o_temp11),.Y_i(o_temp12_shifted),.C_i(1'b0),.Sum_o(o_temp12),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b14 = (convert_a[13]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp13_shifted = op_b14 << 13;
  // adder
  full_adder_32bit full_adder13 (.A_i(o_temp12),.Y_i(o_temp13_shifted),.C_i(1'b0),.Sum_o(o_temp13),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b15 = (convert_a[14]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp14_shifted = op_b15 << 14;
  // adder
  full_adder_32bit full_adder14 (.A_i(o_temp13),.Y_i(o_temp14_shifted),.C_i(1'b0),.Sum_o(o_temp14),.c_o(cout));
//====================================================================================================================
  // check the next bit
  assign op_b16 = (convert_a[15]== 1'b1)  ? convert_b : 32'b0;
  assign o_temp15_shifted = op_b16 << 15;
  // adder
  full_adder_32bit full_adder15 (.A_i(o_temp14),.Y_i(o_temp15_shifted),.C_i(1'b0),.Sum_o(o_temp15),.c_o(cout));
  //===============================================================================================================
  assign o_mul = (sign_a != sign_b) ? (~o_temp15 + 1) : o_temp15;

endmodule