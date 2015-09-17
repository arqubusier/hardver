// Small design of an 8 bit core processor
// Template solution to be given to students

`include "assn1.v"

module core8 (clk,rst,inst);
input clk;
input rst; // reset is active high
input [15:0] inst; // instruction to be executed
// Note that we would normally fetch the instruction from memory.
// To simplify we have it as input.

// -------------------------- ALU8 -------------------------------
wire[7:0] abus; // abus in for the ALU
wire[7:0] bbus; // bbus in for the ALU
wire[7:0] cbus; // cbus out for the ALU
wire[3:0] op$alu; // ALU opcode
wire[3:0] flg; // ALU flags
alu8 ALU (.a(abus),.b(bbus),.op(op$alu),.flg(flg),.res(cbus));
// --------------------------------------------------------------

//-------------------------- SREG -------------------------------
// Status register


wire SREG$ie;
wire [3:0] sreg$out, clrf; 
sreg4 sreg (.clk(clk),.rst(rst),.ie(SREG$ie),
            .in(flg),.clr(clrf),.flags(sreg$out));

//---------------------------------------------------------------


//-------------------------- IR ---------------------------------
// instruction are encoded over 16 bits
// instruction register is a special register (spr)
wire IRie; // input enable wire for the IR register (input written in when IRie = 1)
wire [15:0] IRout; // output of the IR
spr16 IR (.clk(clk),.rst(rst),.ie(IRie),.inbus(inst),.outbus(IRout));
//---------------------------------------------------------------

//---------------------------- GPR ------------------------------
// General purpose registers
wire REGS$sel; // = 1 means reg pointed by REGS$ra is written
wire REGS$aoe; // = 1 means reg pointed by REGS$ra drives REGS$abus;
wire REGS$boe; // =1 means reg pointed by REGS$rb drives REGS$abus;
wire[3:0] REGS$rb; // driven by the execution unit
wire[7:0] REGS$abus;
wire[7:0] REGS$bbus;
// IR is always driving selector ra.
gpr8 gpr (.clk(clk),.rst(rst),.sel(REGS$sel),
          .ra(IRout[7:4]),.rb(REGS$rb),
          .abus(REGS$abus),.bbus(REGS$bbus),.cbus(cbus),
	  .aoe(REGS$aoe),.boe(REGS$boe));
//----------------------------------------------------------------

//----------------------------- EX -------------------------------
// Execution unit
ex8 ex (.clk (clk), .rst(rst), .ir(IRout), 
        .abusin(REGS$abus), .bbusin(REGS$bbus),
        .flg (sreg$out),.sie (SREG$ie), .sel(REGS$sel),
        .abus (abus), .bbus(bbus), .alu(op$alu),
        .clrf (clrf), 
        .irie (IRie), .raoe(REGS$aoe), .rboe (REGS$boe),
        .rb (REGS$rb)); 
//----------------------------------------------------------------

endmodule // END CORE8












//----------------- SREG4 ----------------------------------------
// module to store, clear, and set the four flags.
module sreg4 (clk,rst,ie,in,clr,flags); 
input clk, rst,ie;
input [3:0] clr; // clear vector
// clear all flags marked with a 0 in the vector. 
output[3:0] flags;
input [3:0] in;

reg [3:0] content;

always @(posedge clk)
   content <= rst ? 4'b0 : ( ie ? in & clr: content & clr);
// content is masqued with the clear vector. 
// All positions marked with a 0 in clr will also be zero in content.      

assign flags = content;

endmodule


//----------------------------------------------------------------


//----------------- MODULE EX8 -----------------------------------
module ex8 (clk,rst,ir,abusin,bbusin,flg,sie,abus,bbus,alu,
            clrf,irie,raoe,rboe,rb,sel);
input clk, rst;
input[15:0] ir; // instruction register
input[7:0] abusin, bbusin;
input[3:0] flg;
output[7:0] abus,bbus;
output[3:0] alu,clrf;
output irie, raoe, rboe,sel,sie;
output[3:0] rb;
//----------- Transition Function ------------
// transition function
// currently only three states
// Fetch : 2'b00
// Decode : 2'b01
// Execute : 2'b10
// The FSM simply goes from Fetch to Decode to Execute to Fetch
// For the instructions we have now, Decode and Execute 
// are only one state, called IDEX
reg[1:0] xst; // state of the execution unit
always @(posedge clk)
        xst <= rst ? 2'b00 : // IFETCH = 2'b0
             ((xst == 2'b00) ? 2'b01 : // IDEX = 2'b1
             ((xst == 2'b01) ? 2'b00 : 2'b00));
		
//------------------------------------------------

//---------- Output Function ---------------------

// Decoding the instruction

if (xst == 2'b0)
    begin
        assign irie = 1'b1;
        assign sie = 1'b0;
        assign sel = 1'b0;
	assign raoe = 1'b0;
	assign rboe = 1'b0;
    end
else
    begin
        assign irie = 1'b0;
        assign sie = 1'b1;
        assign sel = 1'b1;

	assign abus = abusin;
	assign raoe = 1'b1;

        case (ir[14])
	    1'b0: 	// instruction format 1: 2 register
		begin
		    

		    assign rboe = 1'b1;
		    assign rb = ir[3:0];
		    assign bbus = bbusin;

	            case (ir[15:10])
		        6'b000111: // ADC
                            begin
				if (flg[0])
			            assign alu = 4'b1100;
				else
				    assign alu = 4'b1101;
				assign clrf = 4'b1111;
		   	    end
                    endcase
		end
		
	    //1'b1:	// instruction format 2: 1 register + 1 value in the instruction
		
        endcase
    end


// alu
// ALU8
// computes the following operations
// op = kijcin
// 4'b1000              a
// 4'b1001              a+1
// 4'b1010              a-1
// 4'b1100              a+b
// 4'b1101              a+b+1
// 4'b1110              a+!b
// 4'b1111              a-b
// 4'b0000              a & b
// 4'b0010              a ^ b
// 4'b0100              a | b

endmodule
//--------------------------------------------------

//-------------- MODULE SPR16 ----------------------
module spr16 (clk,rst,ie,inbus,outbus);
input clk,rst,ie;
input [15:0] inbus;
output [15:0] outbus;

reg[15:0] content;
always @(posedge clk)
   content <= rst ? 16'b0 : (ie ? inbus : content);
assign outbus = content;

endmodule
//---------------------------------------------------

//--------- General Purpose Registers ---------------
module gpr8 (clk, rst, sel, ra, rb, abus, bbus, 
             cbus, aoe, boe);
// GPRs are drivint the abus and the bbus
// REGS.sel is 1 means write enable
// ra selects which register is written to
// ra selects which register drives the abus
// rb selects which register drives the bbus
// aoe is 1 when abus is driven
// boe is 1 when bbus is driven
input clk,rst,sel,aoe,boe;
input[3:0] ra,rb;
input[7:0] cbus;
output[7:0] abus, bbus;


// actual registers
reg[7:0] R0;
reg[7:0] R1;
reg[7:0] R2;
reg[7:0] R3;

// update of each register for writing
always @(posedge clk)
   if (rst) 
       R0 <= 8'b0;
   else if (sel & (ra == 4'b0000))  
       R0 <= cbus;

always @(posedge clk)
   if (rst) 
       R1 <= 8'b0;
   else if (sel & (ra == 4'b0001))
       R1 <= cbus;

always @(posedge clk)
   if (rst)
       R2 <= 8'b0;
   else if (sel & (ra == 4'b0010))
       R2 <= cbus;

always @(posedge clk)
   if (rst)
       R3 <= 8'b0;
   else if (sel & (ra == 4'b0011))
       R3 <= cbus;

// updating all combinatorial output

wire[7:0] aout = R2;
assign aout = (ra == 4'b0000) ? R0 : 
	     ((ra == 4'b0001) ? R1 : 
	     ((ra == 4'b0010) ? R2 :
             ((ra == 4'b0011) ? R3 : R0 )));

wire[7:0] bout;
assign bout = (rb == 4'b0000) ? R0 : 
             ((rb == 4'b0001) ? R1 :
             ((rb == 4'b0010) ? R2 :
             ((rb == 4'b0011) ? R3 : R0)));

assign abus = aoe ? aout : 8'bz;
assign bbus = boe ? bout : 8'bz;

endmodule
//------------------------------------------------
