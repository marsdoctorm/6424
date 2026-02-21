`timescale 1ns / 1ps
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
`timescale 1ns/1ps
module tb_your_top_module;
  parameter N = 4;

  // Testbench signals
  reg              clk;
  reg              reset;
  reg  [N-1:0]     a;
  reg  [N-1:0]     b;
  reg              cin;
  wire [N-1:0]     sum;
  wire             cout;

  // Instantiate the DUT (Device Under Test)
  your_top_module #(.N(N)) dut (
    .clk(clk),
    .reset(reset),
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .cout(cout)
  );

  // Clock generation block
  /* verilator lint_off STMTDLY */
  /* verilator lint_off INFINITELOOP */
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  /* verilator lint_on INFINITELOOP */
  /* verilator lint_on STMTDLY */

  // Cycle counter to schedule stimulus events
  reg [31:0] cycle;
  initial cycle = 0;

  // Single always block for stimulus on posedge clk
  always @(posedge clk) begin
    cycle <= cycle + 1;
    case (cycle)
      0: begin
        // Initialize with reset asserted
        reset <= 1;
        a     <= 0;
        b     <= 0;
        cin   <= 0;
      end
      1: begin
        // Hold reset active
        reset <= 1;
      end
      2: begin
        // Deassert reset
        reset <= 0;
      end
      3: begin
        // Test Case 1: a = 0011, b = 0101, cin = 0
        a   <= 4'b0011;
        b   <= 4'b0101;
        cin <= 1'b0;
      end
      4: begin
        // Display outputs after registers have updated
        $display("Cycle %0d: a=%b, b=%b, cin=%b --> sum=%b, cout=%b", 
                 cycle, a, b, cin, sum, cout);
      end
      5: begin
        // Test Case 2: a = 1010, b = 0101, cin = 1
        a   <= 4'b1010;
        b   <= 4'b0101;
        cin <= 1'b1;
      end
      6: begin
        $display("Cycle %0d: a=%b, b=%b, cin=%b --> sum=%b, cout=%b", 
                 cycle, a, b, cin, sum, cout);
      end
      7: begin
        // Test Case 3: a = 1111, b = 0001, cin = 0
        a   <= 4'b1111;
        b   <= 4'b0001;
        cin <= 1'b0;
      end
      8: begin
        $display("Cycle %0d: a=%b, b=%b, cin=%b --> sum=%b, cout=%b", 
                 cycle, a, b, cin, sum, cout);
      end
      9: begin
        // Test Case 4: a = 0101, b = 1010, cin = 1
        a   <= 4'b0101;
        b   <= 4'b1010;
        cin <= 1'b1;
      end
      10: begin
        $display("Cycle %0d: a=%b, b=%b, cin=%b --> sum=%b, cout=%b", 
                 cycle, a, b, cin, sum, cout);
      end
      11: begin
        $finish;  // End simulation
      end
      default: ; // Do nothing on other cycles
    endcase
  end

  // VCD dump for waveform viewing (optional)
  initial begin
    $dumpfile("tb_your_top_module.vcd");
    $dumpvars(0, tb_your_top_module);
  end

endmodule


// synthesis translate_on