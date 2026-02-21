module aes128_hardened_top (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    input  logic         inject_fault,
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

    aes128_core u_ref (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .fault_inject(1'b0),
        .ciphertext(ct_ref),
        .done(done_ref),
        .busy(busy_ref)
    );

    aes128_core u_dup (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .fault_inject(inject_fault),
        .ciphertext(ct_dup),
        .done(done_dup),
        .busy(busy_dup)
    );

    power_noise u_noise (
        .clk(clk),
        .rst_n(rst_n),
        .enable(busy_ref | busy_dup),
        .seed(key[31:0] ^ plaintext[127:96]),
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
