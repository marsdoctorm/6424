`timescale 1ns/1ps

module tb_aes_hardened;

    logic clk;
    logic rst_n;
    logic start;
    logic [127:0] plaintext;
    logic [127:0] key;
    logic inject_fault;
    logic [127:0] ciphertext;
    logic valid;
    logic busy;
    logic fault_alert;
    logic noise_activity;

    integer vec_fd;
    integer status;
    integer vec_count;
    integer pass_count;

    logic [127:0] v_key;
    logic [127:0] v_plain;
    logic [127:0] v_expect;

    aes128_hardened_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .inject_fault(inject_fault),
        .ciphertext(ciphertext),
        .valid(valid),
        .busy(busy),
        .fault_alert(fault_alert),
        .noise_activity(noise_activity)
    );

    always #5 clk = ~clk;

    task automatic run_case(
        input logic [127:0] in_key,
        input logic [127:0] in_plain,
        input logic [127:0] in_expect
    );
        begin
            @(posedge clk);
            key         <= in_key;
            plaintext   <= in_plain;
            inject_fault <= 1'b0;
            start       <= 1'b1;
            @(posedge clk);
            start       <= 1'b0;

            wait (valid || fault_alert);
            @(posedge clk);

            if (fault_alert) begin
                $display("[FAIL] Unexpected fault alert for key=%h pt=%h", in_key, in_plain);
                $fatal(1);
            end

            if (ciphertext !== in_expect) begin
                $display("[FAIL] Cipher mismatch");
                $display("       key    = %h", in_key);
                $display("       plain  = %h", in_plain);
                $display("       expect = %h", in_expect);
                $display("       got    = %h", ciphertext);
                $fatal(1);
            end

            pass_count = pass_count + 1;
        end
    endtask

    task automatic run_fault_detection_case(
        input logic [127:0] in_key,
        input logic [127:0] in_plain
    );
        begin
            @(posedge clk);
            key          <= in_key;
            plaintext    <= in_plain;
            inject_fault <= 1'b1;
            start        <= 1'b1;
            @(posedge clk);
            start        <= 1'b0;

            wait (valid || fault_alert);
            @(posedge clk);

            if (!fault_alert) begin
                $display("[FAIL] Fault injection did not trigger fault alert");
                $fatal(1);
            end
        end
    endtask

    initial begin
        $display("[INFO] Starting tb_aes_hardened");
        clk          = 1'b0;
        rst_n        = 1'b0;
        start        = 1'b0;
        inject_fault = 1'b0;
        plaintext    = 128'h0;
        key          = 128'h0;
        vec_count    = 0;
        pass_count   = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        run_case(
            128'h000102030405060708090a0b0c0d0e0f,
            128'h00112233445566778899aabbccddeeff,
            128'h69c4e0d86a7b0430d8cdb78070b4c55a
        );

        vec_fd = $fopen("tb/generated_vectors.txt", "r");
        if (vec_fd == 0) begin
            $display("[FAIL] Could not open vector file tb/generated_vectors.txt");
            $fatal(1);
        end

        while (!$feof(vec_fd)) begin
            status = $fscanf(vec_fd, "%h %h %h\n", v_key, v_plain, v_expect);
            if (status == 3) begin
                vec_count = vec_count + 1;
                run_case(v_key, v_plain, v_expect);
            end
        end
        $fclose(vec_fd);

        run_fault_detection_case(
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h6bc1bee22e409f96e93d7e117393172a
        );

        $display("[PASS] AES hardened validation complete. vectors=%0d pass=%0d", vec_count, pass_count);
        $finish;
    end

    initial begin
        #2000000;
        $display("[FAIL] Timeout waiting for test completion");
        $fatal(1);
    end

endmodule
