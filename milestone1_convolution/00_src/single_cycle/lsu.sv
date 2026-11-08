
//===========================================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Load Store Unit
// File            : lsu.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//============================================================================================================
import package_param::*;
module lsu (
  input  logic        i_clk,
  input  logic        i_reset,

  input  logic [31:0] i_lsu_addr,
  input  logic [31:0] i_st_data,
  input  logic        i_lsu_wren,
  input  logic [2:0]  i_func3,

  input  logic [31:0] i_gpio_in,
  input  logic [31:0] i_mul_status,   // bit[0]: busy, bit[1]: done. Read 1 to check if the multiplication is done.
  input  logic [31:0] i_mul_result,
  input  logic [31:0] i_conv_status,  // bit[0]: busy, bit[1]: done. Read 1 to check if the convolution is done.

  output logic [31:0] i_mul_a,
  output logic [31:0] i_mul_b,
  output logic [31:0] i_mul_ctrl,     // bit[0]: start. Write 1 to start the multiplication, bit[1]: reset. Write 1 to reset the multiplier.

  output logic [31:0] i_conv_ctrl,    // bit[0]: start. Write 1 to start the convolution.

  output logic [31:0] i_img_width,
  output logic [31:0] i_img_height,
  output logic [31:0] i_img_addr,
  output logic [31:0] i_img_data,
  output logic [31:0] i_ker_addr,
  output logic [31:0] i_ker_data,

  output logic [31:0] o_out_addr,
  output logic [31:0] o_out_data,
  
  output logic [31:0] o_ld_data,
  output logic [31:0] o_led_out
);

//====================================DECLARATION==============================================================
  logic        is_ledr;
  logic        is_gpio_in;
  logic        is_led_out;
  logic        is_mul_a;
  logic        is_mul_b;
  logic        is_mul_ctrl;
  logic        is_mul_status;
  logic        is_mul_result;
  logic        is_conv_ctrl;
  logic        is_conv_status;
  logic        is_img_width;
  logic        is_img_height;
  logic        is_img_addr;
  logic        is_img_data;
  logic        is_ker_addr;
  logic        is_ker_data;

  logic        is_dmem;
  logic        is_mmio;

  logic [15:0] dmem_ptr;

  logic        mem_wren;

  logic        is_sbyte;
  logic        is_ubyte;
  logic        is_shb;
  logic        is_uhb;
  logic        is_word;

  logic [31:0] dmem;

  logic [31:0] led_out_next;
  logic [31:0] mul_a_next;
  logic [31:0] mul_b_next;
  logic [31:0] mul_ctrl_next;
  logic [31:0] mul_status_next;
  logic [31:0] mul_result_next;
  logic [31:0] conv_ctrl_next; 
  logic [31:0] conv_status_next;
  logic [31:0] img_width_next;
  logic [31:0] img_height_next;
  logic [31:0] img_addr_next;
  logic [31:0] img_data_next;
  logic [31:0] ker_addr_next;
  logic [31:0] ker_data_next;
  logic [31:0] out_addr_next;
  logic [31:0] out_data_next;

  logic [31:0] st_wdata;
  logic [31:0] ld_data;
  logic [15:0] halfword_out;
  logic [7:0]  byte_out;

  logic [3:0]  bmask_align;
  logic [3:0]  bmask_misalign;

//====================================MISALIGN====================================================================
  always_comb begin
    is_ubyte       = 1'b0;
    is_sbyte       = 1'b0;
    is_uhb         = 1'b0;
    is_shb         = 1'b0;
    is_word        = 1'b0;
    bmask_align    = 4'b0;
    bmask_misalign = 4'b0;
    case (i_func3)
      3'b000: is_sbyte = 1'b1;
      3'b001: is_shb   = 1'b1;
      3'b010: is_word  = 1'b1;
      3'b100: is_ubyte = 1'b1;
      3'b101: is_uhb   = 1'b1;
      default: begin
              is_ubyte = 1'b0;
              is_sbyte = 1'b0;
              is_uhb   = 1'b0;
              is_shb   = 1'b0;
              is_word  = 1'b0;
              end
    endcase
    if( is_sbyte || is_ubyte) begin : bmask_align_sort
      case (i_lsu_addr[1:0])                      // check number of immediate
        2'b00: begin
                bmask_align    = 4'b0001;                 // byte 1
                bmask_misalign = 4'b0000;
               end
        2'b01: begin
                bmask_align    = 4'b0010;                 // byte 2
                bmask_misalign = 4'b0000;
               end
        2'b10: begin
                bmask_align    = 4'b0100;                 // byte 3
                bmask_misalign = 4'b0000;
               end
        2'b11: begin
                bmask_align    = 4'b1000;                 // byte 4
                bmask_misalign = 4'b0000;
               end
        default: begin
                bmask_align    = 4'b0000;
                bmask_misalign = 4'b0000;
               end
      endcase
    end else if ( is_shb || is_uhb) begin
      case (i_lsu_addr[1:0])                      // check number of immediate
        2'b00: begin
                bmask_align    = 4'b0011;                 // byte 1, 2
                bmask_misalign = 4'b0000;
               end
        2'b01: begin
                bmask_align    = 4'b0110;
                bmask_misalign = 4'b0000;
               end
        2'b10: begin
                bmask_align    = 4'b1100;                 // byte 3, 4
                bmask_misalign = 4'b0000;
               end
        2'b11: begin
                bmask_align    = 4'b1000;
                bmask_misalign = 4'b0001;
               end
        default: begin
                bmask_align    = 4'b0000;
                bmask_misalign = 4'b0000;
        end
      endcase
    end else if (is_word) begin
      case(i_lsu_addr[1:0])
          2'b00: begin
              bmask_align    = 4'b1111;
              bmask_misalign = 4'b0000;
          end
          2'b01: begin
              bmask_align    = 4'b1110;
              bmask_misalign = 4'b0001;
          end
          2'b10: begin
              bmask_align    = 4'b1100;
              bmask_misalign = 4'b0011;
          end
          2'b11: begin
              bmask_align    = 4'b1000;
              bmask_misalign = 4'b0111;
          end
        default: begin
              bmask_align    = 4'b0000;
              bmask_misalign = 4'b0000;
          end
      endcase
    end
  end
//================================================ADDRESS DECODING========================================================
  // ==============================================================================
  // DATA MEMORY (Giả sử RAM nằm ở vùng 0x0000_XXXX)
  // ==============================================================================
  assign dmem_ptr  =  i_lsu_addr[15:0];
  assign is_dmem   = (i_lsu_addr[31:28] == 4'h0); 
  // ==============================================================================
  // MEMORY-MAPPED I/O (MMIO) - Base Address: 0x4000_XXXX
  // ==============================================================================
  assign is_mmio = (i_lsu_addr[31:28] == 4'h4);
  // 1. Nhóm Peripherals cơ bản (Offset 0x000)
  assign is_gpio_in    = is_mmio && (i_lsu_addr[11:0] == 12'h000); // RO
  assign is_led_out    = is_mmio && (i_lsu_addr[11:0] == 12'h004); // RW\
  // 2. Nhóm Multiplier Accelerator (Offset 0x100)
  assign is_mul_a      = is_mmio && (i_lsu_addr[11:0] == 12'h100); // RW
  assign is_mul_b      = is_mmio && (i_lsu_addr[11:0] == 12'h104); // RW
  assign is_mul_ctrl   = is_mmio && (i_lsu_addr[11:0] == 12'h108); // RW
  assign is_mul_status = is_mmio && (i_lsu_addr[11:0] == 12'h10C); // RO
  assign is_mul_result = is_mmio && (i_lsu_addr[11:0] == 12'h110); // RO
  // 3. Nhóm Convolution Accelerator (Offset 0x200)
  assign is_conv_ctrl   = is_mmio && (i_lsu_addr[11:0] == 12'h200); // RW
  assign is_conv_status = is_mmio && (i_lsu_addr[11:0] == 12'h204); // RO
  assign is_img_width   = is_mmio && (i_lsu_addr[11:0] == 12'h208); // RW
  assign is_img_height  = is_mmio && (i_lsu_addr[11:0] == 12'h20C); // RW
  assign is_img_addr    = is_mmio && (i_lsu_addr[11:0] == 12'h210); // RW
  assign is_img_data    = is_mmio && (i_lsu_addr[11:0] == 12'h214); // RW
  assign is_ker_addr    = is_mmio && (i_lsu_addr[11:0] == 12'h218); // RW
  assign is_ker_data    = is_mmio && (i_lsu_addr[11:0] == 12'h21C); // RW
  assign is_out_addr    = is_mmio && (i_lsu_addr[11:0] == 12'h220); // RW
  assign is_out_data    = is_mmio && (i_lsu_addr[11:0] == 12'h224); // RO
//==================================MEMORY INSTANTIATION========================================================
  memory memory (
                .i_clk  (i_clk),
                .i_reset(i_reset),
                .i_func3(i_func3),
                .i_addr (dmem_ptr),
                .i_wdata(i_st_data),
                .i_bmask_align(bmask_align),
                .i_bmask_misalign(bmask_misalign),
                .i_wren (mem_wren),
                .o_rdata(dmem)
              );

  always_comb begin : st_data
    mem_wren  = 1'b0;
    ld_data   = 32'b0;
    st_wdata  = i_st_data;
    led_out_next = o_led_out;
    if(is_dmem) begin
      if(i_lsu_wren) begin
        mem_wren = 1'b1;
        case (bmask_align)
          4'b0000: mem_wren = 1'b0;
          4'b0001,
          4'b0010,
          4'b0100: st_wdata = {24'b0, i_st_data[7:0]};
          4'b1000: st_wdata = i_st_data;
          4'b0011: st_wdata = {16'b0, i_st_data[15:0]};
          4'b1100: st_wdata = {       i_st_data[15:0], 16'b0};
          4'b1111: st_wdata =         i_st_data;
          default: begin
                   st_wdata = 32'b0;
                   mem_wren = 1'b0;
          end
        endcase
      end else begin
        ld_data = dmem;
      end
    end else if (i_lsu_wren && is_led_out) begin
      led_out_next = st_wdata;
    end else if (i_lsu_wren && is_mul_a) begin
      mul_a_next = st_wdata;
    end else if (i_lsu_wren && is_mul_b) begin
      mul_b_next = st_wdata;
    end else if (i_lsu_wren && is_mul_ctrl) begin
      mul_ctrl_next = st_wdata;
    end else if (i_lsu_wren && is_conv_ctrl) begin
      conv_ctrl_next = st_wdata;
    end else if (i_lsu_wren && is_img_width) begin
      ld_data = i_img_width;
    end else if (i_lsu_wren && is_img_height) begin
      ld_data = i_img_height;
    end else if (is_img_addr) begin
      ld_data = i_img_addr;
    end else if (is_img_data) begin
      ld_data = i_img_data;
    end else if (is_ker_addr) begin
      ld_data = i_ker_addr;
    end else if (is_ker_data) begin
      ld_data = i_ker_data;
    end else if (is_out_addr) begin
      ld_data = o_out_addr;
    end else if (~i_lsu_wren && is_mul_status) begin
      ld_data = i_mul_status;
    end else if (~i_lsu_wren && is_mul_result) begin
      ld_data = i_mul_result;
    end else if (~i_lsu_wren && is_conv_status) begin
      ld_data = i_conv_status;
    end else if (~i_lsu_wren && is_out_data) begin
      ld_data = o_out_data;
    end else if (~i_lsu_wren && is_gpio_in) begin
      ld_data = i_gpio_in;
    end
  end
  always_ff @(posedge i_clk or negedge i_reset) begin
    if (~i_reset) begin
        o_led_out <= 32'b0;
    end else if (i_lsu_wren) begin
        o_led_out <= led_out_next;
    end
  end
  always_comb begin
    o_ld_data = ld_data;
  end
endmodule
