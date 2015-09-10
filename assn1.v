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