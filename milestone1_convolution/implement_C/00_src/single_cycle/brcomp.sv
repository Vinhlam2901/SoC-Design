module brcomp (
  input wire [31:0] i_rs1_data, i_rs2_data,
  input wire i_br_un,
  output wire o_br_equal, o_br_less
);
  assign o_br_equal = i_rs1_data == i_rs2_data;
  assign o_br_less = i_br_un ? (i_rs1_data < i_rs2_data) :
                              ($signed(i_rs1_data) < $signed(i_rs2_data));
endmodule
