// Milestone 1: valid 3x3, stride 1, one multiplier, signed 32-bit raw outputs.
import package_param::*;
module convolution #(
  parameter MAX_WIDTH = 16,
  parameter MAX_HEIGHT = 16
)(
  input  logic        i_clk,
  input  logic        ni_rst,
  input  logic        i_conv_wren,   // One cycle per aligned CPU SW in the CONV page.
  input  logic [11:0] i_conv_addr,   // Global MMIO low 12 bits: 0x200..0x224.
  input  logic [31:0] i_conv_wdata,
  output logic [31:0] o_conv_rdata
);
//========================LOCAL STORAGE / MMIO REGISTERS======================================
  localparam IMAGE_DEPTH  = MAX_WIDTH * MAX_HEIGHT;
  localparam OUTPUT_DEPTH = (MAX_WIDTH-2) * (MAX_HEIGHT-2);
  logic               conv_start_reg, busy, done;
  logic               start_conv, config_valid;
  logic        [7:0]  image_mem  [0:IMAGE_DEPTH-1];
  logic        [7:0]  kernel_mem [0:8];
  logic signed [31:0] output_mem [0:OUTPUT_DEPTH-1];
  logic        [31:0] img_width, img_height, img_addr, ker_addr, out_addr;
  assign start_conv   = i_conv_wren && i_conv_addr == 12'h200 && i_conv_wdata[0];
  assign config_valid = img_width  >= 3 && img_width <= MAX_WIDTH &&
                        img_height >= 3 && img_height <= MAX_HEIGHT;
//========================COUNTERS / ADDRESS GENERATOR========================================
  typedef enum logic [2:0] {IDLE, CLEAR_ACC, READ_TAP, ACCUMULATE, WRITE_OUT} state_t;
  state_t state;
  logic        [1:0]  kernel_row, kernel_col;       // window 3x3
  logic        [3:0]  tap_index;                    // coordinate of kernel
  logic        [7:0]  pixel_reg, kernel_reg;
  logic        [31:0] width_reg, height_reg;
  logic        [31:0] out_row, out_col, out_index;
  logic        [31:0] row_base, tap_row_base;
  logic        [31:0] pixel_addr;
  logic signed [31:0] accumulator;
  // Row bases advance by addition; no address-generation multiplier is needed.
  assign pixel_addr = tap_row_base + {30'b0, kernel_col};
  mac mac (
    .i_clk       (i_clk), 
    .ni_rst      (ni_rst),
    .mac_clear_i (state == CLEAR_ACC), 
    .mac_en_i    (state == ACCUMULATE),
    .opa_i       (pixel_reg), 
    .opb_i       (kernel_reg), 
    .mac_out     (accumulator)
  );
//========================CPU READ INTERFACE==================================================
  always_comb begin
    o_conv_rdata = 32'b0;
    case (i_conv_addr)
      12'h200:                              o_conv_rdata = {31'b0, conv_start_reg};       // conv_ctrl
      12'h204:                              o_conv_rdata = {30'b0, done, busy};           // conv_status
      12'h208:                              o_conv_rdata = img_width;                     // img_width
      12'h20c:                              o_conv_rdata = img_height;                    // img_height
      12'h210:                              o_conv_rdata = img_addr;                      // img_addr
      12'h214: if (img_addr < IMAGE_DEPTH)  o_conv_rdata = {24'b0, image_mem[img_addr]};  // img_data
      12'h218:                              o_conv_rdata = ker_addr;                      // ker_addr
      12'h21c: if (ker_addr < 9)            o_conv_rdata = {24'b0, kernel_mem[ker_addr]}; // ker_data
      12'h220:                              o_conv_rdata = out_addr;                      // out_addr
      12'h224: if (out_addr < OUTPUT_DEPTH) o_conv_rdata = output_mem[out_addr];          // out_data
      default:                              o_conv_rdata = 32'b0;
    endcase
  end
//========================LOCAL MEMORY ACCESS=================================================
  // No reset of memory arrays: software loads image/kernel before START.
  always_ff @(posedge i_clk) begin
    if (ni_rst) begin
      if (!busy && i_conv_wren) begin
        if (i_conv_addr == 12'h214 && img_addr < IMAGE_DEPTH) begin     // IMG_DATA
          image_mem[img_addr] <= i_conv_wdata[7:0];
        end
        if (i_conv_addr == 12'h21c && ker_addr < 9) begin               // KER_DATA
          kernel_mem[ker_addr] <= i_conv_wdata[7:0];
        end
      end
      if (state == READ_TAP) begin
        pixel_reg  <= image_mem[pixel_addr];
        kernel_reg <= kernel_mem[tap_index];
      end
      if (state == WRITE_OUT) begin
        output_mem[out_index] <= accumulator;
      end
    end
  end
//========================MMIO CONFIGURATION==================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
      img_width      <= 0; 
      img_height     <= 0;
      img_addr       <= 0; 
      ker_addr       <= 0; 
      out_addr       <= 0; 
      conv_start_reg <= 0;
    end else if (i_conv_wren) begin
      // Output index may be selected while computing; read valid outputs after DONE.
      if (i_conv_addr == 12'h220) begin               // OUT_ADDR
        out_addr <= i_conv_wdata;
      end else if (!busy) begin
        unique case (i_conv_addr)
          12'h200: conv_start_reg <= i_conv_wdata[0]; // CONV_CTRL
          12'h208: img_width      <= i_conv_wdata;    // IMG_WIDTH
          12'h20c: img_height     <= i_conv_wdata;    // IMG_HEIGHT
          12'h210: img_addr       <= i_conv_wdata;    // IMG_ADDR
          12'h218: ker_addr       <= i_conv_wdata;    // KER_ADDR
          default: begin end
        endcase
      end
    end
  end
//========================FSMD===============================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
      state       <= IDLE; 
      busy         <= 0; 
      done         <= 0;
      width_reg    <= 0; 
      height_reg   <= 0;
      out_row      <= 0; 
      out_col      <= 0; 
      out_index    <= 0;
      row_base     <= 0; 
      tap_row_base <= 0;
      kernel_row   <= 0; 
      kernel_col   <= 0; 
      tap_index    <= 0;
    end else begin
      case (state)
        IDLE: if (start_conv && config_valid) begin
          width_reg  <= img_width; 
          height_reg <= img_height;
          out_row    <= 0; 
          out_col    <= 0; 
          out_index  <= 0; 
          row_base   <= 0;
          busy       <= 1; 
          done       <= 0; 
          state      <= CLEAR_ACC;
        end
        CLEAR_ACC: begin
          kernel_row   <= 0; 
          kernel_col   <= 0; 
          tap_index    <= 0;
          tap_row_base <= row_base + out_col;
          state        <= READ_TAP;
        end
        READ_TAP: begin
          state <= ACCUMULATE;
        end
        ACCUMULATE: begin
          if (tap_index == 8) begin
            state <= WRITE_OUT;
          end else begin
            tap_index <= tap_index + 1'b1;
            if (kernel_col == 2) begin                  // end of col then transit to next row
              kernel_col   <= 0; 
              kernel_row   <= kernel_row + 1'b1;
              tap_row_base <= tap_row_base + width_reg;
            end else begin
              kernel_col <= kernel_col + 1'b1;
            end
            state <= READ_TAP;
          end
        end
        WRITE_OUT: begin
          // The ninth product was accumulated at the preceding edge.
          if (out_col == width_reg-3 && out_row == height_reg-3) begin
            busy <= 0; 
            done <= 1; 
            state <= IDLE;
          end else begin
            out_index <= out_index + 1'b1;
            if (out_col == width_reg-3) begin
              out_col <= 0; 
              out_row <= 
              out_row + 1'b1;
              row_base <= row_base + width_reg;
            end else begin
              out_col <= out_col + 1'b1;
            end
            state <= CLEAR_ACC;
          end
        end
        default: begin 
          state <= IDLE; 
          busy <= 0; 
        end
      endcase
    end
  end
endmodule
