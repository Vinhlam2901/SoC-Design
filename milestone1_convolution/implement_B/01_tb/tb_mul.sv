//===========================================================================================================
// Project         : Multiplier Accumulator / Convolution Accelerator
// Module          : Self-Checking Testbench for Multiplier (tb_mul)
// File            : tb_mul.sv
// Specification   : Unsigned Pixel (opa_i) x Signed Kernel (opb_i)
//============================================================================================================

`timescale 1ns/1ps


module tb_mul;
import package_param::*;


  logic        [WIDTH_PIXEL-1:0] opa_i; // Unsigned
  logic signed [WIDTH_KERNEL-1:0] opb_i; // Signed
  logic        [WIDTH_MUL-1:0] mul_o;

  int total_tests  = 0;
  int passed_tests = 0;
  int failed_tests = 0;

  logic signed [WIDTH_MUL-1:0] expected_mul;

  mul dut (
    .opa_i (opa_i),
    .opb_i (opb_i),
    .mul_o (mul_o)
  );

  // Task check vector cho Unsigned Pixel x Signed Kernel
  task automatic check_vector(
    input logic        [WIDTH_PIXEL-1:0] a, // Unsigned Pixel
    input logic signed [WIDTH_KERNEL-1:0] b, // Signed Kernel
    input string category = "DIRECTED"
  );
    logic signed [WIDTH_MUL-1:0] actual_signed;
    
    opa_i = a;
    opb_i = b;
    #5;

    // GOLDEN MODEL: ep a sang kieu duong bang cách pad bit 0 o MSB, b giu nguyen signed
    expected_mul  = $signed({1'b0, a}) * $signed(b);
    actual_signed = $signed(mul_o);

    total_tests++;

    if (actual_signed === expected_mul) begin
      passed_tests++;
      $display("[PASS] [%-12s] Test #%-4d | opa = 0x%0h (%3u) | opb = 0x%0h (%3d) | DUT = %6d | Exp = %6d",
               category, total_tests, a, a, b, b, actual_signed, expected_mul);
    end else begin
      failed_tests++;
      $error("[FAIL] [%-12s] Test #%-4d | opa = 0x%0h (%3u) | opb = 0x%0h (%3d) | DUT = %6d | Exp = %6d",
             category, total_tests, a, a, b, b, actual_signed, expected_mul);
    end
  endtask

  initial begin
    $display("===============================================================================");
    $display("    VERIFICATION SUITE: UNSIGNED PIXEL (8-bit) x SIGNED KERNEL (5-bit)        ");
    $display("===============================================================================");

    // Group 1: Zero Cases
    check_vector(8'h00,  5'sd0,  "ZERO");
    check_vector(8'hFF,  5'sd0,  "ZERO");
    check_vector(8'h00, -5'sd5,  "ZERO");

    // Group 2: Boundary & Corner Cases (Unsigned Pixel: 0..255, Signed Kernel: -16..+15)
    check_vector(8'd255,  5'sd15, "MAX_UNS_X_MAX_SGD"); // 255 * 15 = 3825
    check_vector(8'd255, -5'sd16, "MAX_UNS_X_MIN_SGD"); // 255 * (-16) = -4080
    check_vector(8'd128, -5'sd1,  "MID_UNS_X_NEG1");    // 128 * (-1) = -128
    check_vector(8'hAA,   5'sd7,  "PATTERN_POS");
    check_vector(8'hAA,  -5'sd7,  "PATTERN_NEG");

    // Group 3: Random Testing (1000 Iterations)
    $display("\n--- CONSTRAINED RANDOM TESTING ---");
    for (int k = 0; k < 1000; k++) begin
      logic        [WIDTH_PIXEL-1:0] rand_a;
      logic signed [WIDTH_KERNEL-1:0] rand_b;
      
      rand_a = $urandom_range(0, 255);            // Pixel ngau nhien (0 -> 255)
      rand_b = $clog2($urandom) ? $urandom_range(0, 15) : -$urandom_range(1, 16); // Kernel (-16 -> +15)

      check_vector(rand_a, rand_b, "RANDOM");
    end

    $display("\n===============================================================================");
    $display(" Total Executed: %0d | Passed: %0d | Failed: %0d", total_tests, passed_tests, failed_tests);
    if (failed_tests == 0)
      $display(" >>> ALL TESTS PASSED FOR UNSIGNED PIXEL x SIGNED KERNEL! <<<");
    else
      $display(" >>> FAILED WITH %0d ERRORS! <<<", failed_tests);
    $display("===============================================================================\n");

    $finish;
  end

endmodule