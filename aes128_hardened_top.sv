module aes128_hardened_top (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    input  logic         inject_fault,
    input  logic [3:0]   fault_round_sel,
    input  logic [6:0]   fault_bit_sel,
    output logic [127:0] ciphertext,
    output logic         valid,
    output logic         busy,
    output logic         fault_alert,
    output logic         noise_activity
);

    logic [127:0] ct_ref;
    logic [127:0] ct_dup;
    logic done_ref;
    logic done_dup;
    logic busy_ref;
    logic busy_dup;
    logic [127:0] noise_bus;
    logic [127:0] trng_out;

    trng u_trng (
        .clk(clk),
        .rst_n(rst_n),
        .enable(1'b1),
        .latch(start),
        .rng_out(trng_out)
    );

    aes128_core_masked u_ref (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .mask(trng_out),
        .fault_inject(1'b0),
        .fault_round_sel(4'd0),
        .fault_bit_sel(7'd0),
        .ciphertext(ct_ref),
        .done(done_ref),
        .busy(busy_ref)
    );

    aes128_core_masked u_dup (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .mask(trng_out),
        .fault_inject(inject_fault),
        .fault_round_sel(fault_round_sel),
        .fault_bit_sel(fault_bit_sel),
        .ciphertext(ct_dup),
        .done(done_dup),
        .busy(busy_dup)
    );

    power_noise u_noise (
        .clk(clk),
        .rst_n(rst_n),
        .enable(busy_ref | busy_dup),
        .seed(trng_out[31:0]),
        .noise_bus(noise_bus),
        .noise_activity(noise_activity)
    );

    always @(*) begin
        busy        = busy_ref | busy_dup;
        fault_alert = done_ref & done_dup & (ct_ref != ct_dup);
        valid       = done_ref & done_dup & (ct_ref == ct_dup);
        ciphertext  = ct_ref;
    end

endmodule
