
module fa(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

    assign cout = (a & b) | (cin & (a | b));
    assign sum = a ^ b ^ cin;
endmodule
module main_adder #(parameter N = 4) ( // Parameterized for N-bit addition
    input  [N-1:0] a,       // N-bit input a
    input  [N-1:0] b,       // N-bit input b
    input          cin,     // Carry-in
    output [N-1:0] sum,     // N-bit sum output
    output         cout
);

    wire [N:0] carry; // Carry signals, N+1 for carry-out

    assign carry[0] = cin; // Initial carry-in

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : FA_STAGE
            fa fa_inst (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign cout = carry[N];  // Final carry-out

endmodule

module your_top_module #(parameter N = 4) (
    input clk,             // Clock signal
    input reset,             // Synchronous reset
    input [N-1:0] a,       // N-bit input a
    input [N-1:0] b,       // N-bit input b
    input cin,             // Carry-in
    output [N-1:0] sum, // Registered sum output
    output cout        // Registered carry-out
);

    // Registered inputs
    reg [N-1:0] a_reg, b_reg;
    reg cin_reg;

    // Output wires
    wire [N-1:0] sum_wire;
    wire cout_wire;

    // Registered outputs
    reg [N-1:0] sum_reg;
    reg cout_reg_sample;

    // Input registers
    always @(posedge clk) begin
        if (reset) begin
            a_reg <= 0;
            b_reg <= 0;
            cin_reg <= 0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            cin_reg <= cin;
        end
    end

    // Instantiation of ripple carry adder
    main_adder #(N) rca (
        .a(a_reg),
        .b(b_reg),
        .cin(cin_reg),
        .sum(sum_wire),
        .cout(cout_wire)
    );

    // Output registers
    always @(posedge clk) begin
        if (reset) begin
            sum_reg <= 0;
            cout_reg_sample <= 0;
        end else begin
            sum_reg <= sum_wire;
            cout_reg_sample <= cout_wire;
        end
    end
    assign sum = sum_reg;
    assign cout = cout_reg_sample;
endmodule

// synthesis translate_off
module tb_main_adder;

    parameter N = 16; // Number of bits for the adder

    reg [N-1:0] a;       // N-bit input a
    reg [N-1:0] b;       // N-bit input b
    reg cin;             // Carry-in

    wire [N-1:0] sum;    // N-bit sum output
    wire cout;           // Carry-out

    // DUT instantiation
    main_adder #(N) dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    // Variables to hold expected values
    reg [N-1:0] expected_sum;
    reg expected_cout;

    // Testbench logic
    initial begin
        // Open a log file for debugging
        $dumpfile("main_adder.vcd");
        $dumpvars(0, tb_main_adder);

        // Randomized testing
        repeat (100) begin
            // Generate random inputs
            a = $random;
            b = $random;
            cin = $random % 2;
            expected_sum = a + b + cin;
            expected_cout = (({1'b0, a} + {1'b0, b} + cin) >> N) & 1;
            // Wait for a small delay to simulate propagation delay
            #5;

            // Check the outputs against expected values
            if (sum !== expected_sum || cout !== expected_cout) begin
                $display("Test failed for inputs: a=%d, b=%d, cin=%d", a, b, cin);
                $display("comp (s, cout) = (%d, %d) : golden = (%d, %d) ", sum, cout, expected_sum, expected_cout);
                // $stop;
            end
        end

        $display("All tests passed!");
        $finish;
    end

endmodule
// synthesis translate_on
