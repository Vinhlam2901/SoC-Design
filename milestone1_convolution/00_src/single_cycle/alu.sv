module alu (
  input  wire  [31:0] i_op_a,
  input  wire  [31:0] i_op_b,
  input  wire         br_unsign_i,
  input  wire  [3:0]  i_alu_op,
  output wire  [31:0] o_alu_data
  );
  wire        slt, sltu;
  wire [31:0] rd_and, rd_or, rd_xor, rd_sra, rd_srl, rd_sll, rd_add, rd_sub;
  wire        cout_add, cout_sub, rd_equals, rd_equalu;
  and_32bit     and_module      (
                                .rs1_i(i_op_a),
                                .rs2_i(i_op_b),
                                .rd_o(rd_and)
                                ); //AND

  or_32bit      or_module       (
                                .rs1_i(i_op_a),
                                .rs2_i(i_op_b),
                                .rd_o(rd_or)
                                ); //OR
  xor_32bit     xor_module      (
                                .rs1_i(i_op_a),
                                .rs2_i(i_op_b),
                                .rd_o(rd_xor)
                                ); // XOR
  add_subtract  addsub_module   (
                                .a_i      (i_op_a),
                                .b_i      (i_op_b),
                                .cin_i    (i_alu_op == 4'b0001),
                                .result_o (rd_sub),
                                .cout_o   (cout_sub)
                                ); // cin_i = 0: add, cin_i = 1: subtract
  brcomp        slt_module      (
                                .i_rs1_data(i_op_a),
                                .i_rs2_data(i_op_b),
                                .i_br_un   (1'b0),
                                .o_br_less (slt),
                                .o_br_equal(rd_equals)
                                ); //SLT
  brcomp        sltu_module     (
                                .i_rs1_data  (i_op_a),
                                .i_rs2_data  (i_op_b),
                                .i_br_un     (1'b1),
                                .o_br_less   (sltu),
                                .o_br_equal  (rd_equalu)
                                ); //SLTU
  srl           srl_module      (
                                .rs1_data (i_op_a),
                                .rs2_data (i_op_b),
                                .rd_data  (rd_srl)
                                ); //SRL
  sll           sll_module      (
                                .rs1_data (i_op_a),
                                .rs2_data (i_op_b),
                                .rd_data  (rd_sll)
                                ); //SLL
  sra           sra_module      (
                                .rs1_data   (i_op_a),
                                .rs2_data   (i_op_b),
                                .rd_data    (rd_sra)
                                ); //SRA
  mux_16to1  mux1 (
                    .d0   (rd_sub),
                    .d1   (rd_sub),
                    .d2   (rd_sll),
                    .d3   ({31'b0, slt}),
                    .d4   ({31'b0, sltu}),
                    .d5   (rd_xor),
                    .d6   (rd_srl),
                    .d7   (rd_sra),
                    .d8   (rd_or),
                    .d9   (rd_and),
                    .d10  (32'b0),
                    .d11  (32'b0),
                    .d12  (32'b0),
                    .d13  (32'b0),
                    .d14  (32'b0),
                    .d15  (32'b0),
                    .s    (i_alu_op),
                    .y_o  (o_alu_data)
                );
endmodule