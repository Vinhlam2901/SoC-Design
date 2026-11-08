
// parameters_pkg.sv
package package_param;
//=======================================================
//=====================PARAMETER=========================
//=======================================================
  parameter WIDTH_PIXEL   = 8;
  parameter WIDTH_KERNEL  = 8;      							// 4bit for kernel's coefficiency from [-8:7]
  parameter WIDTH         = 256;                  // Image Width
  parameter LENGTH        = 256;                 	// Image Height
  parameter WIDTH_MAC     = 20;
  parameter WIDTH_MUL     = 16;
	parameter RTYPE         = 7'b0110011;
	parameter ITYPE         = 7'b0010011;
	parameter IITYPE        = 7'b1100111;
	parameter ILTYPE        = 7'b0000011;
	parameter IJTYPE        = 7'b1101111;
	parameter STYPE         = 7'b0100011;
	parameter BTYPE         = 7'b1100011;
	parameter U1TYPE        = 7'b0110111;
	parameter U2TYPE        = 7'b0010111;

endpackage
