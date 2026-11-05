
// parameters_pkg.sv
package package_param;
//=======================================================
//=====================PARAMETER=========================
//=======================================================
  parameter WIDTH_PIXEL   = 8;
  parameter WIDTH_KERNEL  = 4;      							// 4bit for kernel's coefficiency from [-8:7]
  parameter WIDTH         = 256;                  // Image Width
  parameter LENGTH        = 256;                 	// Image Height
  parameter WIDTH_MUL_MAC = 22;                  	// WC (10bit) * PX (8bit) = 18bit + 4 bit guard for MAC
  parameter WIDTH_MAC     = 15;
  parameter WIDTH_MUL     = 12;
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
