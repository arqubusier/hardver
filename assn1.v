module half_adder(a, b, s, c);
	input a, b;
	output s, c;

	assign s = a ^ b;
	assign c = a & b;
endmodule

module full_adder(a, b, c_in, s_out, c_out);
	input a, b, c_in;
	output s_out, c_out;

	wire s1, c1, c2;

	half_adder ha1(a, b, s1, c1), ha2(c_in, s1, s_out, c2);

	assign c_out = c2 | c1;
endmodule

module rca8(
    input [7:0] a, b,
    input c_0,
    output [7:0] s,
    output c_out);

    wire c_1, c_2, c_3, c_4, c_5, c_6, c_7;

    full_adder FA0(a[0], b[0], c_0, s[0], c_1),
    FA1(a[1], b[1], c_1, s[1], c_2),
    FA2(a[2], b[2], c_2, s[2], c_3),
    FA3(a[3], b[3], c_3, s[3], c_4),
    FA4(a[4], b[4], c_4, s[4], c_5),
    FA5(a[5], b[5], c_5, s[5], c_6),
    FA6(a[6], b[6], c_6, s[6], c_7),
    FA7(a[7], b[7], c_7, s[7], c_out);

endmodule


module mux2(
    input [7:0] a, b,
    input sw,
    output [7:0] out);
    
    // maybe we should change this later
    assign out = (sw) ? b : a;
endmodule
    

module alu8(
    input [7:0] a, b,
    input [3:0] op, // k i j c_in
    output [3:0] flg; // c_out, z, v, n,
    output [7:0] res); 

    wire [7:0] b_alt, s, and_out, or_out, and_or_out, xor_out, logic_out;

    assign b_alt[0] = ~(b[0] & op[2]) ^ ~op[1]; //(b[0] ~& op[2]) ^ ~op[1]; <- it does'nt work in acl2!!
    assign b_alt[1] = ~(b[1] & op[2]) ^ ~op[1];
    assign b_alt[2] = ~(b[2] & op[2]) ^ ~op[1];
    assign b_alt[3] = ~(b[3] & op[2]) ^ ~op[1];
    assign b_alt[4] = ~(b[4] & op[2]) ^ ~op[1];
    assign b_alt[5] = ~(b[5] & op[2]) ^ ~op[1];
    assign b_alt[6] = ~(b[6] & op[2]) ^ ~op[1];
    assign b_alt[7] = ~(b[7] & op[2]) ^ ~op[1];
    
    rca8 adder(a, b_alt, op[0], s, c_out);

    assign and_out = a & b;
    assign or_out = a | b;
    assign xor_out = a ^ b;

    mux2 mux2_and_or(and_out, or_out, op[2], and_or_out),
    mux2_logic_out(and_or_out, xor_out, op[1], logic_out),
    mux2_r(logic_out, s, op[3], res);

    // flags
    assign z = ~s[7] & ~s[6] & ~s[5] & ~s[4] & ~s[3] & ~s[2] & ~s[1] & ~s[0];
    assign v = (a[7] & b[7] & ~s[7]) | (~a[7] & ~b[7] & s[7]);
    assign n = s[7];

    assign flg[0] = n;
    assign flg[1] = v;
    assign flg[2] = z;
    assign flg[3] = c_out;

endmodule


module adder_tb;

reg a, b, c;
wire s, c_out;

initial begin
    $monitor ("a=%b,b=%b,c=%b,s=%b,c_out=%b", a, b, c, s, c_out);
    #10 a = 0; b = 0; c = 0;
    #10 a = 0; b = 1; c = 0;
    #10 a = 1; b = 0; c = 1;
    #10 a = 1; b = 1; c = 1;
    $finish;
end

full_adder fa(
    a,
    b,
    c,
    s,
    c_out);
endmodule
