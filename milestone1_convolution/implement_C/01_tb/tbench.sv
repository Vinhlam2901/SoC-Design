// Compatibility top for the shared CPU regression.
// Compile tests/tb_cpu.sv as well; define IP_PORTS for B/C and CONV_PORTS for C.
module tbench;
  tb_cpu regression();
endmodule
