import package_param::*;
module mul_wrapper (
  input  logic        i_clk,
  input  logic        i_reset_n,
  input  logic        i_mul_start,    // One request per MMIO write of START=1.
  input  logic [31:0] i_mul_a,
  input  logic [31:0] i_mul_b,

  output logic [31:0] o_mul_result,
  output logic [31:0] o_mul_status
);
  logic busy, done;
  logic [WIDTH_PIXEL-1:0]  mul_opa_reg;
  logic [WIDTH_KERNEL-1:0] mul_opb_reg;
  logic [WIDTH_MUL-1:0]    mul_o;
  logic [31:0]             mul_o_reg;

  // A: low 8 bits unsigned. B: low 8 bits signed two's complement.
  // Result is signed 16-bit, sign-extended to the 32-bit MMIO register.
  assign o_mul_status = {30'b0, done, busy};
  assign o_mul_result = mul_o_reg;

  always_ff @(posedge i_clk or negedge i_reset_n) begin
    if (!i_reset_n) begin
      busy        <= 1'b0;
      done        <= 1'b0;
      mul_opa_reg <= '0;
      mul_opb_reg <= '0;
      mul_o_reg   <= '0;
    end else begin
      if (busy) begin
        mul_o_reg <= {{(32-WIDTH_MUL){mul_o[WIDTH_MUL-1]}}, mul_o};
        busy      <= 1'b0;
        done      <= 1'b1;
      end else if (i_mul_start) begin
        mul_opa_reg <= i_mul_a[WIDTH_PIXEL-1:0];
        mul_opb_reg <= i_mul_b[WIDTH_KERNEL-1:0];
        busy        <= 1'b1;
        done        <= 1'b0;
      end
      // DONE/result persist until a new accepted request; requests while busy are ignored.
    end
  end
  mul mul (
    .opa_i(mul_opa_reg),
    .opb_i(mul_opb_reg),
    .mul_o(mul_o)
  );
endmodule
