module half_adder(a, b, s, c);
input a, b;
output s, c;
assign s = a ^ b;
assign c = a && b;
endmodule

module adder_tb;

reg a, b;
wire s, c;

initial begin
    $monitor ("a=%b,b=%b,s=%b,c=%b", a, b, s, c);
    #10 a = 0; b = 0;
    #10 a = 0; b = 1;
    #10 a = 1; b = 0;
    #10 a = 1; b = 1;
    $finish;
end

half_adder ha(
    .a (a),
    .b (b),
    .s (s),
    .c (c));
endmodule
