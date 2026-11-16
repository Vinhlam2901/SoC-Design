
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
  output logic [31:0] o_ld_data,
  output logic [31:0] o_led_out
);

//====================================DECLARATION==============================================================
  logic is_gpio_in, is_led_out, is_dmem, is_mmio;
  logic is_conv_ctrl, is_conv_status, is_img_width, is_img_height;
  logic is_img_addr, is_img_data, is_ker_addr, is_ker_data, is_out_addr, is_out_data;
  logic is_sbyte, is_ubyte, is_shb, is_uhb, is_word;
  logic [15:0] dmem_ptr;
  logic mem_wren, conv_selected;
  logic [31:0] dmem, conv_rdata, led_out_next;
  logic [3:0] bmask_align, bmask_misalign;

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
  // DATA MEMORY: 2 KiB at 0x0000_0000..0x0000_07FF
  // ==============================================================================
  assign dmem_ptr  =  i_lsu_addr[15:0];
  assign is_dmem   = (i_lsu_addr[31:11] == 21'b0);
  // ==============================================================================
  // MEMORY-MAPPED I/O: exact 0x4000_0000 page; registers use aligned lw/sw
  // ==============================================================================
  assign is_mmio = (i_lsu_addr[31:12] == 20'h40000);
  // Nhóm Peripherals cơ bản (Offset 0x000)
  assign is_gpio_in    = is_mmio && (i_lsu_addr[11:0] == 12'h000); // RO
  assign is_led_out    = is_mmio && (i_lsu_addr[11:0] == 12'h004); // RW
  // Nhóm Convolution Accelerator (Offset 0x200)
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
                .i_clk           (i_clk),
                .i_reset         (i_reset),
                .i_func3         (i_func3),
                .i_addr          (dmem_ptr),
                .i_wdata         (i_st_data),
                .i_bmask_align   (bmask_align),
                .i_bmask_misalign(bmask_misalign),
                .i_wren          (mem_wren),
                .o_rdata         (dmem)
              );
//==================================CONVOLUTION IP==============================================================
  assign conv_selected = is_conv_ctrl || is_conv_status || is_img_width || is_img_height ||
                         is_img_addr  || is_img_data    || is_ker_addr  || is_ker_data ||
                         is_out_addr  || is_out_data;
  convolution conv (
    .i_clk       (i_clk), 
    .ni_rst      (i_reset),
    .i_conv_wren (i_lsu_wren && is_word && conv_selected),
    .i_conv_addr (i_lsu_addr[11:0]), 
    .i_conv_wdata(i_st_data), 
    .o_conv_rdata(conv_rdata)
  );
//==================================READ / WRITE ROUTING=========================================================
  always_comb begin : st_data
    mem_wren = 1'b0;
    o_ld_data = 32'b0;
    led_out_next = o_led_out;
    if (is_dmem) begin
      if (i_lsu_wren) begin
        mem_wren = |bmask_align;
      end else begin
        o_ld_data = dmem;
      end 
    end else if (is_word) begin
      if (i_lsu_wren && is_led_out) begin
        led_out_next = i_st_data;
      end else if (!i_lsu_wren) begin
        if (is_gpio_in) begin
          o_ld_data = i_gpio_in;
        end else if (is_led_out) begin
          o_ld_data = o_led_out;
        end else if (conv_selected) begin
          o_ld_data = conv_rdata;
        end
      end
    end
  end
  always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset) begin
      o_led_out <= 32'b0;
    end else begin
      o_led_out <= led_out_next;
    end
  end
endmodule
