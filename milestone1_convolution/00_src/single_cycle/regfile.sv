//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Register File
// File            : regfile.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module regfile (
  input  wire         i_clk,
  input  wire         i_reset,
  input  wire  [4:0]  i_rs1_addr,
  input  wire  [4:0]  i_rs2_addr,
  input  wire  [4:0]  i_rd_addr,
  input  wire  [31:0] i_rd_data,
  input  wire         i_rd_wren,
  output reg   [31:0] o_rs1_data,
  output reg   [31:0] o_rs2_data
);
//==================================Declaration=========================================================
  wire [31:0]       data_o;
  wire [31:0]       q_o0;
  wire [31:0][31:0] data_out;
  wire [31:1]       enb;
  //===========================================================================================
  decoder_5to32 d1 (.a_i(i_rd_addr), .out_o(data_o));
  genvar i;
  generate
    for (i = 1; i < 32; i = i + 1) begin : gen_enb
      assign enb[i] = i_rd_wren & data_o[i];
    end
  endgenerate
  register_32bit r0 (
    .i_clk (i_clk), 
    .nrst_i(1'b0),    
    .en_i  (1'b1),    
    .d_i   (32'b0),     
    .q_o   (q_o0) 
    );
  genvar j;
  generate
    for (j = 1; j < 32; j = j + 1) begin : gen_regfile
      register_32bit register_nth (
        .i_clk (i_clk), 
        .nrst_i(i_reset), 
        .en_i  (enb[j]),  
        .d_i   (i_rd_data), 
        .q_o   (data_out[j]) 
      );
    end
  endgenerate

  mux_32to1 mux_rs1 (
                      .d0 (q_o0),        .d1 (data_out[1]), .d2 (data_out[2]), .d3 (data_out[3]),
                      .d4 (data_out[4]), .d5 (data_out[5]), .d6 (data_out[6]), .d7 (data_out[7]),
                      .d8 (data_out[8]), .d9 (data_out[9]), .d10(data_out[10]),.d11(data_out[11]),
                      .d12(data_out[12]),.d13(data_out[13]),.d14(data_out[14]),.d15(data_out[15]),
                      .d16(data_out[16]),.d17(data_out[17]),.d18(data_out[18]),.d19(data_out[19]),
                      .d20(data_out[20]),.d21(data_out[21]),.d22(data_out[22]),.d23(data_out[23]),
                      .d24(data_out[24]),.d25(data_out[25]),.d26(data_out[26]),.d27(data_out[27]),
                      .d28(data_out[28]),.d29(data_out[29]),.d30(data_out[30]),.d31(data_out[31]),
                      .s  (i_rs1_addr),  .y_o(o_rs1_data)
                    );
  mux_32to1 mux_rs2 (
                      .d0 (q_o0),        .d1 (data_out[1]), .d2 (data_out[2]), .d3 (data_out[3]),
                      .d4 (data_out[4]), .d5 (data_out[5]), .d6 (data_out[6]), .d7 (data_out[7]),
                      .d8 (data_out[8]), .d9 (data_out[9]), .d10(data_out[10]),.d11(data_out[11]),
                      .d12(data_out[12]),.d13(data_out[13]),.d14(data_out[14]),.d15(data_out[15]),
                      .d16(data_out[16]),.d17(data_out[17]),.d18(data_out[18]),.d19(data_out[19]),
                      .d20(data_out[20]),.d21(data_out[21]),.d22(data_out[22]),.d23(data_out[23]),
                      .d24(data_out[24]),.d25(data_out[25]),.d26(data_out[26]),.d27(data_out[27]),
                      .d28(data_out[28]),.d29(data_out[29]),.d30(data_out[30]),.d31(data_out[31]),
                      .s  (i_rs2_addr),  .y_o(o_rs2_data)
                    );
endmodule