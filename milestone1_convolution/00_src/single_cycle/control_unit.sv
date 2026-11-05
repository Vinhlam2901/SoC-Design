import package_param::*;
module control_unit (
  input  wire  [31:0] instruction,
  output reg          o_insn_vld,
  output reg          pc_sel,
  output reg          br_unsign,
  output reg          op1_sel,
  output reg          op2_sel,
  output reg  [3:0]   alu_opcode,
  output reg          rd_wren,
  output reg  [1:0]   wb_sel,
  output reg          mem_wren
);
//===================================DECLARATION==================================================
  wire is_add, is_sub, is_and, is_or, is_xor, is_slt, is_sltu, is_sra, is_srl, is_sll;
  wire is_addi, is_xori, is_ori, is_andi, is_slli, is_srli, is_srai, is_slti, is_sltiu;
  wire is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
  wire [31:0] pc_addr, rs1_data, rs2_data;
  wire [9:0] rtype;
  wire [8:0] itype;
  wire [4:0] iltype;
  wire [2:0] stype;
  wire [5:0] btype;
  
  always_comb begin
	case(instruction[6:0])
    RTYPE,
    ITYPE,
    ILTYPE,
    STYPE,
    BTYPE,
    IJTYPE,
    U1TYPE,
    U2TYPE:  o_insn_vld = 1'b1;
	  default: o_insn_vld = 1'b0;
	endcase
	end
  //==========================RTYPE=========================================================================
  //is_add
  assign is_add   = ~instruction[12] & ~instruction[13] & ~instruction[14] & ~instruction[30];
  //is_sub
  assign is_sub   = ~instruction[12] & ~instruction[13] & ~instruction[14] & instruction[30];
  //is_sll
  assign is_sll   =  instruction[12] & ~instruction[13] & ~instruction[14];
  //is_slt
  assign is_slt   = ~instruction[12] & instruction[13]  & ~instruction[14];
  //is_sltu
  assign is_sltu  =  instruction[12] & instruction[13]  & ~instruction[14];
  //is_xor
  assign is_xor   = ~instruction[12] & ~instruction[13] &  instruction[14];
  //is_sra
  assign is_sra   =  instruction[12] & ~instruction[13] &  instruction[14]  &  instruction[30];
  //is_srl
  assign is_srl   =  instruction[12] & ~instruction[13] &  instruction[14]  & ~instruction[30];
  //is_or
  assign is_or    = ~instruction[12] & instruction[13]  &  instruction[14];
  //is_and
  assign is_and   =  instruction[12] & instruction[13]  &  instruction[14];
  // concatenat
  assign rtype = {is_add, is_sub, is_sll, is_slt, is_sltu, is_xor, is_srl, is_sra, is_or, is_and};
//==========================ITYPE=========================================================================
  //is_addi
  assign is_addi  = ~instruction[12] & ~instruction[13] & ~instruction[14];
  //is_sll
  assign is_slli  =  instruction[12] & ~instruction[13] & ~instruction[14];
  //is_slt
  assign is_slti  = ~instruction[12] & instruction[13]  & ~instruction[14];
  //is_sltiu
  assign is_sltiu =  instruction[12] & instruction[13]  & ~instruction[14];
  //is_xori
  assign is_xori  = ~instruction[12] & ~instruction[13] &  instruction[14];
  //is_srai
  assign is_srai  =  instruction[12] & ~instruction[13] &  instruction[14]  & instruction[30];
  //is_srli
  assign is_srli  =  instruction[12] & ~instruction[13] &  instruction[14]  & ~instruction[30];
  //is_ori
  assign is_ori   = ~instruction[12] & instruction[13]  &  instruction[14];
  //is_andi
  assign is_andi  =  instruction[12] & instruction[13]  &  instruction[14];
  // concat
  assign itype = {is_addi, is_slli, is_slti, is_sltiu, is_xori, is_srli, is_srai, is_ori, is_andi};
//==========================BTYPE=========================================================================
  //is_beq
  assign is_beq  = ~instruction[12]  & ~instruction[13] & ~instruction[14];
  //is_bne
  assign is_bne  =  instruction[12]  & ~instruction[13] & ~instruction[14];
   //is_blt
  assign is_blt  = ~instruction[12]  & ~instruction[13] &  instruction[14];
  //is_bge
  assign is_bge  =  instruction[12]  & ~instruction[13] &  instruction[14];
  //is_bltu
  assign is_bltu = ~instruction[12]  & instruction[13]  &  instruction[14];
  //is_bgeu
  assign is_bgeu =  instruction[12]  & instruction[13]  &  instruction[14];
  // concat
  assign btype = {is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu};
//==========================ALU_OPCODE=========================================================================
  always_comb begin : signal_sel
    br_unsign   = 1'b1;
    wb_sel      = 2'b00;
    pc_sel      = 1'b0;
    rd_wren     = ( instruction[6:0] == STYPE  ||
                    instruction[6:0] == BTYPE   )  ? 1'b0 : 1'b1;
    mem_wren    = ( instruction[6:0] == STYPE)     ? 1'b1 : 1'b0;
    case (instruction[6:0])
      RTYPE: case (rtype)
              10'b1000000000 : alu_opcode = 4'b0000;  // add
              10'b0100000000 : alu_opcode = 4'b0001;  // sub
              10'b0010000000 : alu_opcode = 4'b0010;  // sll
              10'b0001000000 : alu_opcode = 4'b0011;  // slt
              10'b0000100000 : alu_opcode = 4'b0100;  // sltu
              10'b0000010000 : alu_opcode = 4'b0101;  // xor
              10'b0000001000 : alu_opcode = 4'b0110;  // srl
              10'b0000000100 : alu_opcode = 4'b0111;  // sra
              10'b0000000010 : alu_opcode = 4'b1000;  // or
              10'b0000000001 : alu_opcode = 4'b1001;  // amd
              default        : alu_opcode = 4'b0000;
            endcase
      ITYPE: case (itype)
              9'b100000000   : begin
                alu_opcode = 4'b0000;   // addi
                br_unsign  = 1'b0;
              end
              9'b010000000   : alu_opcode = 4'b0010;  // slli
              9'b001000000   : alu_opcode = 4'b0011;  // slti
              9'b000100000   : alu_opcode = 4'b0100;  // sltiu
              9'b000010000   : alu_opcode = 4'b0101;  // xori
              9'b000001000   : alu_opcode = 4'b0110;  // srli
              9'b000000100   : begin
                alu_opcode = 4'b0111;                 // is_srai
                br_unsign  = 1'b0;
              end
              9'b000000010   : alu_opcode = 4'b1000;   // ori
              9'b000000001   : alu_opcode = 4'b1001;   // andi
              default        : alu_opcode = 4'b0000;
            endcase
      ILTYPE,
      STYPE:                  alu_opcode = 4'b0000;    // alu using add
      BTYPE: case (btype)
              6'b100000  : begin                       // beq
                alu_opcode = 4'b0000;
                br_unsign = 1'b0;
                end
              6'b010000 : begin                        // bne
                alu_opcode = 4'b0000;
                br_unsign = 1'b0;
                end
              6'b001000 : begin                        // blt
                alu_opcode = 4'b0000;
                br_unsign = 1'b0;
                end
              6'b000100: begin                         // bge
                alu_opcode = 4'b0000;
                br_unsign = 1'b0;
                end
              6'b000010: begin
                alu_opcode = 4'b0000;         // bltu
                br_unsign  = 1'b1;
                end
              6'b000001: begin
                alu_opcode = 4'b0000;
                br_unsign  = 1'b1;
                end
              default  : alu_opcode = 4'b0000;
            endcase
      IJTYPE:            alu_opcode = 4'b0000;
      IITYPE:            alu_opcode = 4'b0000;
      U1TYPE:            alu_opcode = 4'b0000;         // lui using imm + 0
      U2TYPE:            alu_opcode = 4'b0000;         // auipc using pc + imm
      default:           alu_opcode = 4'b0000;
    endcase
//==================================WRITE_BACK===============================================
  case (instruction[6:0])
    RTYPE: begin                     // opcode rd, r1, r2
      wb_sel   = 2'b00; // rd
      pc_sel   = 1'b0;  // pc + 4
      op1_sel  = 1'b0;  //rs1
      op2_sel  = 1'b0;  //rs2;
    end
    ITYPE: begin
      wb_sel   = 2'b00; // rd
      pc_sel   = 1'b0;  // pc + 4
      op1_sel  = 1'b0;  // rs1
      op2_sel  = 1'b1;  // imm
    end
    ILTYPE: begin
      wb_sel   = 2'b11; // read_data
      pc_sel   = 1'b0;  // pc + 4
      op1_sel  = 1'b0;  // rs1
      op2_sel  = 1'b1;  // imm_ex;
    end
    BTYPE: begin
      wb_sel   = 2'b01;   //jmp_pc
      pc_sel   = 1'b1;    // jmp_pc
      op1_sel  = 1'b1;    // pc
      op2_sel  = 1'b1;    // imm
    end
    STYPE: begin
      op1_sel  = 1'b0; // rs1
      op2_sel  = 1'b1; // imm
      pc_sel   = 1'b0; // pc + 4
      mem_wren = 1'b1;
    end
    IJTYPE: begin
      wb_sel  = 2'b10; // rd = pc +4
      pc_sel  = 1'b1;  // jmp_pc
      op1_sel = 1'b1;  // pc
      op2_sel = 1'b1;  // imm
    end
    IITYPE: begin
      wb_sel  = 2'b10; // pc = rs1 + imm
      pc_sel  = 1'b1;  // jmp_pc
      op1_sel = 1'b0;  // rs1
      op2_sel = 1'b1;  // imm
    end
    U1TYPE,
    U2TYPE: begin
      wb_sel  = 2'b00; // rd
      pc_sel  = 1'b0;  // pc + 4
      op1_sel = 1'b0;
      op2_sel = 1'b1;  // imm
    end
    default: begin
      op1_sel = 1'b0; // rs1_data
      op2_sel = 1'b0; // rs2_data
      pc_sel  = 1'b0;
      wb_sel  = 2'b00;
    end
  endcase
end
endmodule
