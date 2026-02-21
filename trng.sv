module trng (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         enable,
    input  logic         latch,
    output logic [127:0] rng_out
);

    logic [127:0] lfsr;
    logic         feedback;

    assign feedback = lfsr[127] ^ lfsr[125] ^ lfsr[100] ^ lfsr[98] ^ lfsr[67] ^ lfsr[31];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr    <= 128'ha5a5a5a5_3c3c3c3c_96969696_f0f0f0f0;
            rng_out <= 128'h0;
        end else begin
            if (enable)
                lfsr <= {lfsr[126:0], feedback};
            if (latch)
                rng_out <= lfsr;
        end
    end

endmodule
