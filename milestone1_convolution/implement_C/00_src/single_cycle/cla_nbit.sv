module cla_nbit #(
  parameter WIDTH_CLA = 5
)(
  input  logic [WIDTH_CLA-1:0] a,
  input  logic [WIDTH_CLA-1:0] b,
  input  logic                 cin,
  output logic [WIDTH_CLA-1:0] sum,
  output logic                 cout
);
//========================PROPAGATE / GENERATE================================================
  // Pad to complete 4-bit groups; sum/cout still use the requested width.
  localparam PAD_WIDTH = ((WIDTH_CLA + 3) / 4) * 4;
  wire [PAD_WIDTH-1:0] a_ext, b_ext, p, g;
  wire [PAD_WIDTH:0] c;
  assign a_ext = {{(PAD_WIDTH-WIDTH_CLA){1'b0}}, a};
  assign b_ext = {{(PAD_WIDTH-WIDTH_CLA){1'b0}}, b};
  assign p = a_ext ^ b_ext;
  assign g = a_ext & b_ext;
  assign c[0] = cin;
//========================4-BIT CARRY LOOKAHEAD================================================
  genvar i;
  generate
    for (i = 0; i < PAD_WIDTH; i = i + 4) begin : gen_cla_group
      // All four carries depend directly on the group's carry-in c[i].
      assign c[i+1] = g[i] | (p[i] & c[i]);
      assign c[i+2] = g[i+1] | (p[i+1] & g[i]) |
                     (p[i+1] & p[i] & c[i]);
      assign c[i+3] = g[i+2] | (p[i+2] & g[i+1]) |
                     (p[i+2] & p[i+1] & g[i]) |
                     (p[i+2] & p[i+1] & p[i] & c[i]);
      assign c[i+4] = g[i+3] | (p[i+3] & g[i+2]) |
                     (p[i+3] & p[i+2] & g[i+1]) |
                     (p[i+3] & p[i+2] & p[i+1] & g[i]) |
                     (p[i+3] & p[i+2] & p[i+1] & p[i] & c[i]);
    end
  endgenerate
//========================SUM / CARRY OUT=====================================================
  assign sum = p[WIDTH_CLA-1:0] ^ c[WIDTH_CLA-1:0];
  assign cout = c[WIDTH_CLA];
endmodule
