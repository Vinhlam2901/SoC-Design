
//===========================================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Control Unit
// File            : control_unit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 13/9/2025
// Updated date    : 6/11/2025 - Finished
//=============================================================================================================
import package_param::*;
module control_unit (
  input  wire  [31:0] instruction,
  output reg          pc_sel,
  output reg          o_insn_vld,
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
  wire [9:0] rtype;
  wire [8:0] itype;
  wire [5:0] btype;
//==========================RTYPE=========================================================================
  always_comb begin : inst_valid
    o_insn_vld = 1'b0;
    case(instruction[6:0])
      RTYPE:  o_insn_vld = |rtype;
      ITYPE:  o_insn_vld = |itype;
      ILTYPE: case (instruction[14:12])
                3'b000, 3'b001, 3'b010, 3'b100, 3'b101: o_insn_vld = 1'b1;
                default: o_insn_vld = 1'b0;
              endcase
      STYPE:  case (instruction[14:12])
                3'b000, 3'b001, 3'b010: o_insn_vld = 1'b1;
                default: o_insn_vld = 1'b0;
              endcase
      BTYPE:  o_insn_vld = |btype;
      IITYPE: o_insn_vld = (instruction[14:12] == 3'b000);
      IJTYPE,
      U1TYPE,
      U2TYPE: o_insn_vld = 1'b1;
      default: o_insn_vld = 1'b0;
    endcase
  end
//==========================RTYPE=========================================================================
  //is_add
  assign is_add   = ~instruction[12] & ~instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_sub
  assign is_sub   = ~instruction[12] & ~instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0100000);
  //is_sll
  assign is_sll   =  instruction[12] & ~instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_slt
  assign is_slt   = ~instruction[12] &  instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_sltu
  assign is_sltu  =  instruction[12] &  instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_xor
  assign is_xor   = ~instruction[12] & ~instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_sra
  assign is_sra   =  instruction[12] & ~instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0100000);
  //is_srl
  assign is_srl   =  instruction[12] & ~instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_or
  assign is_or    = ~instruction[12] &  instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_and
  assign is_and   =  instruction[12] &  instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0000000);
  // concatenat
  assign rtype = {is_add, is_sub, is_sll, is_slt, is_sltu, is_xor, is_srl, is_sra, is_or, is_and};
//==========================ITYPE=========================================================================
  //is_addi
  assign is_addi  = ~instruction[12] & ~instruction[13] & ~instruction[14];
  //is_sll
  assign is_slli  =  instruction[12] & ~instruction[13] & ~instruction[14] & (instruction[31:25] == 7'b0000000);
  //is_slt
  assign is_slti  = ~instruction[12] & instruction[13]  & ~instruction[14];
  //is_sltiu
  assign is_sltiu =  instruction[12] & instruction[13]  & ~instruction[14];
  //is_xori
  assign is_xori  = ~instruction[12] & ~instruction[13] &  instruction[14];
  //is_srai
  assign is_srai  =  instruction[12] & ~instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0100000);
  //is_srli
  assign is_srli  =  instruction[12] & ~instruction[13] &  instruction[14] & (instruction[31:25] == 7'b0000000);
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
    br_unsign   = 1'b0;
    wb_sel      = 2'b00;
    pc_sel      = 1'b0;
    op1_sel     = 1'b0;
    op2_sel     = 1'b0;
    alu_opcode  = 4'b0000;
    rd_wren     = o_insn_vld && (instruction[6:0] != STYPE) &&
                              (instruction[6:0] != BTYPE);
    mem_wren    = o_insn_vld && (instruction[6:0] == STYPE);
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
              10'b0000000001 : alu_opcode = 4'b1001;  // and
              default        : alu_opcode = 4'b0000;
            endcase
      ITYPE: case (itype)
              9'b100000000 : alu_opcode = 4'b0000;  // addi
              9'b010000000 : alu_opcode = 4'b0010;  // slli
              9'b001000000 : alu_opcode = 4'b0011;  // slti
              9'b000100000 : alu_opcode = 4'b0100;  // sltiu
              9'b000010000 : alu_opcode = 4'b0101;  // xori
              9'b000001000 : alu_opcode = 4'b0110;  // srli
              9'b000000100 : alu_opcode = 4'b0111;  // srai
              9'b000000010 : alu_opcode = 4'b1000;  // ori
              9'b000000001 : alu_opcode = 4'b1001;  // andi
              default       : alu_opcode = 4'b0000;
            endcase
      BTYPE: case (btype)
              6'b000010,
              6'b000001: br_unsign = 1'b1;          // bltu, bgeu
              default:   br_unsign = 1'b0;
            endcase
      default: alu_opcode = 4'b0000;                // address generation
    endcase
//==================================WRITE_BACK===============================================
    case (instruction[6:0])
      RTYPE: begin
        wb_sel  = 2'b00; // ALU result
      end
      ITYPE: begin
        op2_sel = 1'b1;  // immediate
      end
      ILTYPE: begin
        wb_sel  = 2'b11; // load data
        op2_sel = 1'b1;
      end
      BTYPE: begin
        wb_sel  = 2'b01; // branch target or PC + 4
        pc_sel  = o_insn_vld;
        op1_sel = 1'b1;  // PC
        op2_sel = 1'b1;
      end
      STYPE: begin
        op2_sel = 1'b1;
      end
      IJTYPE: begin
        wb_sel  = 2'b10; // return address = PC + 4
        pc_sel  = 1'b1;
        op1_sel = 1'b1;  // target = PC + immediate
        op2_sel = 1'b1;
      end
      IITYPE: begin
        wb_sel  = 2'b10;
        pc_sel  = o_insn_vld;
        op2_sel = 1'b1;  // target = rs1 + immediate
      end
      U1TYPE,
      U2TYPE: begin
        op2_sel = 1'b1;  // LUI/AUIPC operand 1 is selected in single_cycle
      end
      default: begin end
    endcase
  end
endmodule
