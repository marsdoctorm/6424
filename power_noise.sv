module power_noise (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [31:0] seed,
    output logic [127:0] noise_bus,
    output logic        noise_activity
);

    logic [127:0] lfsr;
    logic [127:0] mixed;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= {4{seed}} ^ 128'h1f2e3d4c5b6a7988a7b6c5d4e3f20110;
        end else if (enable) begin
            lfsr <= {
                lfsr[126:0],
                lfsr[127] ^ lfsr[125] ^ lfsr[100] ^ lfsr[98] ^ lfsr[67] ^ lfsr[31]
            };
        end
    end

    always @(*) begin
        mixed          = lfsr ^ {lfsr[63:0], lfsr[127:64]} ^ 128'hc3d2e1f00123456789abcdef10293847;
        noise_bus      = enable ? mixed : 128'h0;
        noise_activity = ^noise_bus;
    end

endmodule
