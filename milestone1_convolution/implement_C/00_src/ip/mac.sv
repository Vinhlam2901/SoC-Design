// Sequential MAC: one unsigned pixel x signed coefficient per enabled cycle.
import package_param::*;
module mac (
  input  logic                    i_clk,
  input  logic                    ni_rst,
  input  logic                    mac_clear_i,
  input  logic                    mac_en_i,
  input  logic [WIDTH_PIXEL-1:0]  opa_i,
  input  logic [WIDTH_KERNEL-1:0] opb_i,
  output logic signed [31:0]      mac_out
);
//========================DECLARATION=========================================================
  logic [WIDTH_MUL-1:0] product;
  logic signed [31:0]   product_ext;
//========================ONE MULTIPLIER=====================================================
  mul multiplier (
    .opa_i(opa_i), 
    .opb_i(opb_i), 
    .mul_o(product)
  );
  assign product_ext = {{(32-WIDTH_MUL){product[WIDTH_MUL-1]}}, product};
//========================ACCUMULATOR=========================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
      mac_out <= 32'sd0;
    end else if (mac_clear_i) begin
      mac_out <= 32'sd0;
    end else if (mac_en_i) begin
      mac_out <= mac_out + product_ext;
    end
  end
endmodule
