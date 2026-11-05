module full_adder_32bit (
    input       [31:0] A_i,
    input       [31:0] Y_i,
    input              C_i,
    output wire [31:0] Sum_o,
    output wire        c_o
);
  wire [30:0] c;
  wire w1, w2, w3;
  //Structural code for one bit full adder
  // assign w1       = A_i[0] ^ Y_i[0];
  // assign w2       = A_i[0] & Y_i[0];
  // assign w3       = w1 & C_i;
  // assign Sum_o[0] = w1 ^ C_i;
  // assign c[0]     = w2 | w3;
  assign Sum_o[0]  =  A_i[0]  ^ Y_i[0]   ^ C_i;
  assign c[0]      = (A_i[0]  & Y_i[0])  | ((A_i[0] ^ Y_i[0]) & C_i);
  assign Sum_o[1]  =  A_i[1]  ^ Y_i[1]   ^ c[0];
  assign c[1]      = (A_i[1]  & Y_i[1])  | ((A_i[1] ^ Y_i[1]) & c[0]);
  assign Sum_o[2]  =  A_i[2]  ^ Y_i[2]   ^ c[1];
  assign c[2]      = (A_i[2]  & Y_i[2])  | ((A_i[2] ^ Y_i[2]) & c[1]);
  assign Sum_o[3]  =  A_i[3]  ^ Y_i[3]   ^ c[2];
  assign c[3]      = (A_i[3]  & Y_i[3])  | ((A_i[3] ^ Y_i[3]) & c[2]);
  assign Sum_o[4]  =  A_i[4]  ^ Y_i[4]   ^ c[3];
  assign c[4]      = (A_i[4]  & Y_i[4])  | ((A_i[4] ^ Y_i[4]) & c[3]);
  assign Sum_o[5]  =  A_i[5]  ^ Y_i[5]   ^ c[4];
  assign c[5]      = (A_i[5]  & Y_i[5])  | ((A_i[5] ^ Y_i[5]) & c[4]);
  assign Sum_o[6]  =  A_i[6]  ^ Y_i[6]   ^ c[5];
  assign c[6]      = (A_i[6]  & Y_i[6])  | ((A_i[6] ^ Y_i[6]) & c[5]);
  assign Sum_o[7]  =  A_i[7]  ^ Y_i[7]   ^ c[6];
  assign c[7]      = (A_i[7]  & Y_i[7])  | ((A_i[7] ^ Y_i[7]) & c[6]);
  assign Sum_o[8]  =  A_i[8]  ^ Y_i[8]   ^ c[7];
  assign c[8]      = (A_i[8]  & Y_i[8])  | ((A_i[8] ^ Y_i[8]) & c[7]);
  assign Sum_o[9]  =  A_i[9]  ^ Y_i[9]   ^ c[8];
  assign c[9]      = (A_i[9]  & Y_i[9])  | ((A_i[9] ^ Y_i[9]) & c[8]);
  assign Sum_o[10] =  A_i[10] ^ Y_i[10]  ^ c[9];
  assign c[10]     = (A_i[10] & Y_i[10]) | ((A_i[10] ^ Y_i[10]) & c[9]);
  assign Sum_o[11] =  A_i[11] ^ Y_i[11]  ^ c[10];
  assign c[11]     = (A_i[11] & Y_i[11]) | ((A_i[11] ^ Y_i[11]) & c[10]);
  assign Sum_o[12] =  A_i[12] ^ Y_i[12]  ^ c[11];
  assign c[12]     = (A_i[12] & Y_i[12]) | ((A_i[12] ^ Y_i[12]) & c[11]);
  assign Sum_o[13] =  A_i[13] ^ Y_i[13]  ^ c[12];
  assign c[13]     = (A_i[13] & Y_i[13]) | ((A_i[13] ^ Y_i[13]) & c[12]);
  assign Sum_o[14] =  A_i[14] ^ Y_i[14]  ^ c[13];
  assign c[14]     = (A_i[14] & Y_i[14]) | ((A_i[14] ^ Y_i[14]) & c[13]);
  assign Sum_o[15] =  A_i[15] ^ Y_i[15]  ^ c[14];
  assign c[15]     = (A_i[15] & Y_i[15]) | ((A_i[15] ^ Y_i[15]) & c[14]);
  assign Sum_o[16] =  A_i[16] ^ Y_i[16]  ^ c[15];
  assign c[16]     = (A_i[16] & Y_i[16]) | ((A_i[16] ^ Y_i[16]) & c[15]);
  assign Sum_o[17] =  A_i[17] ^ Y_i[17]  ^ c[16];
  assign c[17]     = (A_i[17] & Y_i[17]) | ((A_i[17] ^ Y_i[17]) & c[16]);
  assign Sum_o[18] =  A_i[18] ^ Y_i[18]  ^ c[17];
  assign c[18]     = (A_i[18] & Y_i[18]) | ((A_i[18] ^ Y_i[18]) & c[17]);
  assign Sum_o[19] =  A_i[19] ^ Y_i[19]  ^ c[18];
  assign c[19]     = (A_i[19] & Y_i[19]) | ((A_i[19] ^ Y_i[19]) & c[18]);
  assign Sum_o[20] =  A_i[20] ^ Y_i[20]  ^ c[19];
  assign c[20]     = (A_i[20] & Y_i[20]) | ((A_i[20] ^ Y_i[20]) & c[19]);
  assign Sum_o[21] =  A_i[21] ^ Y_i[21]  ^ c[20];
  assign c[21]     = (A_i[21] & Y_i[21]) | ((A_i[21] ^ Y_i[21]) & c[20]);
  assign Sum_o[22] =  A_i[22] ^ Y_i[22]  ^ c[21];
  assign c[22]     = (A_i[22] & Y_i[22]) | ((A_i[22] ^ Y_i[22]) & c[21]);
  assign Sum_o[23] =  A_i[23] ^ Y_i[23]  ^ c[22];
  assign c[23]     = (A_i[23] & Y_i[23]) | ((A_i[23] ^ Y_i[23]) & c[22]);
  assign Sum_o[24] =  A_i[24] ^ Y_i[24]  ^ c[23];
  assign c[24]     = (A_i[24] & Y_i[24]) | ((A_i[24] ^ Y_i[24]) & c[23]);
  assign Sum_o[25] =  A_i[25] ^ Y_i[25]  ^ c[24];
  assign c[25]     = (A_i[25] & Y_i[25]) | ((A_i[25] ^ Y_i[25]) & c[24]);
  assign Sum_o[26] =  A_i[26] ^ Y_i[26]  ^ c[25];
  assign c[26]     = (A_i[26] & Y_i[26]) | ((A_i[26] ^ Y_i[26]) & c[25]);
  assign Sum_o[27] =  A_i[27] ^ Y_i[27]  ^ c[26];
  assign c[27]     = (A_i[28] & Y_i[27]) | ((A_i[27] ^ Y_i[27]) & c[26]);
  assign Sum_o[28] =  A_i[28] ^ Y_i[28]  ^ c[27];
  assign c[28]     = (A_i[28] & Y_i[28]) | ((A_i[28] ^ Y_i[28]) & c[27]);
  assign Sum_o[29] =  A_i[29] ^ Y_i[29]  ^ c[28];
  assign c[29]     = (A_i[29] & Y_i[29]) | ((A_i[29] ^ Y_i[29]) & c[28]);
  assign Sum_o[30] =  A_i[30] ^ Y_i[30]  ^ c[29];
  assign c[30]     = (A_i[30] & Y_i[30]) | ((A_i[30] ^ Y_i[30]) & c[29]);
  assign Sum_o[31] =  A_i[31] ^ Y_i[31]  ^ c[30];
  assign c_o       = (A_i[31] & Y_i[31]) | ((A_i[31] ^ Y_i[31]) & c[30]);

endmodule