import package_param::*;
module single_cycle (
  input  logic         i_clk     ,
  input  logic         i_reset   ,
  input  logic [31:0]  i_io_sw   ,
  output logic [31:0]  o_io_ledr ,
  output logic [31:0]  o_io_ledg ,
  output logic [ 6:0]  o_io_hex0 ,
  output logic [ 6:0]  o_io_hex1 ,
  output logic [ 6:0]  o_io_hex2 ,
  output logic [ 6:0]  o_io_hex3 ,
  output logic [ 6:0]  o_io_hex4 ,
  output logic [ 6:0]  o_io_hex5 ,
  output logic [ 6:0]  o_io_hex6 ,
  output logic [ 6:0]  o_io_hex7 ,
  output logic [31:0]  o_io_lcd  ,
  output logic [31:0]  o_pc_debug,
  output logic         o_insn_vld
  );
//==================Declaration================================================================================
  logic [31:0]  inst;
  logic [31:0]  next_pc;
  logic [31:0]  jmp_pc;
  logic [31:0]  pc_plus4;
  logic         pc_sel;
  logic [1:0]   wb_sel;
  logic         op1_sel;
  logic         op2_sel;
  logic [3:0]   alu_op;
  logic         rd_wren;
  logic         mem_wren;
  logic         br_unsign;
  logic         br_less;
  logic         br_equal;
  logic [31:0]  rs1_data;
  logic [31:0]  op1;
  logic [31:0]  rs2_data;
  logic [31:0]  op2;
  logic [31:0]  imm_ex;
  logic [31:0]  wb_data_o;
  logic [31:0]  rd_data_o;
  logic [31:0]  wr_data;
  logic [31:0]  read_data;
  logic [31:0]  mem           [0:2047];   //8kB
//==================Instance=====================================================================================
//==================PC=============================================================================================
  always_ff @(posedge i_clk or negedge i_reset) begin: pc_reg
    if (~i_reset) begin
        o_pc_debug <= 32'b0;
    end else begin
        o_pc_debug <= next_pc;
    end
  end
  pc_reg PCplus4 (
                  .pc_reg(o_pc_debug),
                  .pc_o(pc_plus4)
                 );
  assign next_pc = (pc_sel) ? jmp_pc : pc_plus4;
//==================IMEM=========================================================================================
  initial begin : instruction
    $readmemh("../03_test/isa_4b.hex", mem);
  end
	assign inst = mem[o_pc_debug[31:2]];
//==================REGFILE========================================================================================
  regfile       regfile      (
                              .i_clk      (i_clk       ),
                              .i_reset    (i_reset     ),
                              .i_rs1_addr (inst[19:15] ),
                              .i_rs2_addr (inst[24:20] ),
                              .i_rd_addr  (inst[11:7]  ),
                              .i_rd_data  (wb_data_o   ),
                              .i_rd_wren  (rd_wren     ),
                              .o_rs1_data (rs1_data    ),
                              .o_rs2_data (rs2_data    )
                             );
//==================CONTROL_UNIT=====================================================================================
  control_unit  control_unit (
                              .instruction(inst      ),
										.o_insn_vld (o_insn_vld),
                              .pc_sel     (pc_sel    ),
                              .br_unsign  (br_unsign ),
                              .op1_sel    (op1_sel   ),
                              .op2_sel    (op2_sel   ),
                              .alu_opcode (alu_op    ),
                              .rd_wren    (rd_wren   ),
                              .wb_sel     (wb_sel    ),
                              .mem_wren   (mem_wren  )
                              );
//==================IMMGEN==============================================================================================
  immgen        immgen       (
                              .inst_i (inst   ),
                              .imm_o  (imm_ex )
                             );
//==================BRCOMP=========================================================================================
  brcomp        branch_compare (
                              .i_rs1_data (rs1_data),
                              .i_rs2_data (rs2_data),
                              .i_br_un    (br_unsign),
                              .o_br_less  (br_less),
                              .o_br_equal (br_equal)
                              );
//==================OPERATION_1=======================================================================================
  always_comb begin : op1_sel_branch
	op1 = rs1_data;
    if(inst[6:0] == STYPE && op1_sel) begin
      case (inst[14:12])
        3'b000: op1 = ( br_equal                         ) ? o_pc_debug : rs1_data; // beq
        3'b001: op1 = (~br_equal                         ) ? o_pc_debug : rs1_data; // bne
        3'b100: op1 = ( br_less                          ) ? o_pc_debug : rs1_data; // blt
        3'b101: op1 = (~br_less || br_equal              ) ? o_pc_debug : rs1_data; // bge > or =
        3'b110: op1 = ( br_less && br_unsign             ) ? o_pc_debug : rs1_data; // bltu
        3'b111: op1 = (~br_less || br_equal && br_unsign ) ? o_pc_debug : rs1_data; // bgeu
        default:op1 = op1;
      endcase
    end else if (inst[6:0] == U1TYPE) begin
      op1 = 32'b0;
    end else if (inst[6:0] == U2TYPE) begin
      op1 = o_pc_debug;
    end else begin
      op1 = (op1_sel) ? o_pc_debug : rs1_data;
    end
  end
//==================OPERATION_2=======================================================================================
  assign op2 = (op2_sel) ? imm_ex : rs2_data;
//==================ALU=================================================================================================
  alu     alu  (
                 .i_op_a      (op1),
                 .i_op_b      (op2),
                 .br_unsign_i (br_unsign),
                 .i_alu_op    (alu_op),
                 .o_alu_data  (rd_data_o)
                );
//==================LSU=================================================================================================
  always_comb begin
    // has rs2'data if stype to store rs2'data to mem
    wr_data    = 32'b0;
    if(inst[6:0] == STYPE || inst[6:0] == ILTYPE) begin
      if(inst[6:0] == STYPE) begin
        wr_data = rs2_data;
      end else if (inst[6:0] == ILTYPE) begin
        wr_data = rs1_data;
      end
      case (inst[14:12])                            // check func3
        3'b000,
        3'b100:   wr_data = wr_data & 32'h000000FF;
        3'b001,
        3'b101:   wr_data = wr_data & 32'h0000FFFF;
        3'b010:   wr_data = wr_data & 32'hFFFFFFFF;
        3'b100:   wr_data = wr_data & 32'h000000FF;
        3'b101:   wr_data = wr_data & 32'h0000FFFF;
        default : wr_data = wr_data & 32'hFFFFFFFF;
      endcase
    end
  end
  lsu lsu (
            .i_clk      (i_clk),
            .i_reset    (i_reset),
            .i_lsu_addr (rd_data_o),
            .i_st_data  (wr_data),
            .i_lsu_wren (mem_wren),
            .i_func3    (inst[14:12]),
            .i_io_sw    (i_io_sw),
            .o_io_hex0  (o_io_hex0),
            .o_io_hex1  (o_io_hex1),
            .o_io_hex2  (o_io_hex2),
            .o_io_hex3  (o_io_hex3),
            .o_io_hex4  (o_io_hex4),
            .o_io_hex5  (o_io_hex5),
            .o_io_hex6  (o_io_hex6),
            .o_io_hex7  (o_io_hex7),
            .o_ld_data  (read_data),
            .o_io_ledr  (o_io_ledr),
            .o_io_ledg  (o_io_ledg),
            .o_io_lcd   (o_io_lcd)
          );
//==================WRITEBACK=========================================================================================
  always_comb begin : write_back
  // giá trị mặc định cho mọi đường đi
  wb_data_o = 32'b0;
  jmp_pc    = 32'b0;
  case (wb_sel)
    2'b00: begin
      wb_data_o   = ((inst[11:7]) == 5'b00000) ? 32'b0 : rd_data_o;
      jmp_pc = 32'b0;
    end
    2'b01: begin  : pc_jump
      // jmp_pc thực hiện dựa trên func3
      case (inst[14:12])
        3'b000: jmp_pc = ( br_equal)                           ? rd_data_o : (o_pc_debug + 32'd4); // beq
        3'b001: jmp_pc = (~br_equal)                           ? rd_data_o : (o_pc_debug + 32'd4); // bne
        3'b100: jmp_pc = ( br_less)                            ? rd_data_o : (o_pc_debug + 32'd4); // blt
        3'b101: jmp_pc = (~br_less || br_equal)                ? rd_data_o : (o_pc_debug + 32'd4); // bge
        3'b110: jmp_pc = ( br_less && br_unsign)               ? rd_data_o : (o_pc_debug + 32'd4); // bltu
        3'b111: jmp_pc = (~br_less || (br_equal && br_unsign)) ? rd_data_o : (o_pc_debug + 32'd4); // bgeu
        default: jmp_pc = rd_data_o; // JALR hoặc fallback
      endcase
      // wb_data_o giữ giá trị mặc định nếu không cần ghi
    end
    2'b10: begin
      wb_data_o = pc_plus4;
      jmp_pc    = rd_data_o;
    end
    2'b11: wb_data_o = read_data;
    default: wb_data_o = 32'b0;
  endcase
end
endmodule