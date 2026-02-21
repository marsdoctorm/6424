module aes128_core (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    input  logic         fault_inject,
    output logic [127:0] ciphertext,
    output logic         done,
    output logic         busy
);

    logic [127:0] state_reg;
    logic [127:0] round_key_reg;
    logic [3:0]   round_ctr;

    function automatic logic [7:0] xtime(input logic [7:0] x);
        xtime = {x[6:0], 1'b0} ^ (8'h1b & {8{x[7]}});
    endfunction

    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] aa;
        logic [7:0] bb;
        logic [7:0] p;
        int i;
        begin
            aa = a;
            bb = b;
            p  = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0]) begin
                    p = p ^ aa;
                end
                aa = xtime(aa);
                bb = {1'b0, bb[7:1]};
            end
            gf_mul = p;
        end
    endfunction

    function automatic logic [7:0] gf_inv(input logic [7:0] x);
        logic [7:0] cand;
        int i;
        begin
            if (x == 8'h00) begin
                gf_inv = 8'h00;
            end else begin
                gf_inv = 8'h00;
                for (i = 1; i < 256; i = i + 1) begin
                    cand = i[7:0];
                    if (gf_mul(x, cand) == 8'h01) begin
                        gf_inv = cand;
                    end
                end
            end
        end
    endfunction

    function automatic logic [7:0] rotl8(input logic [7:0] x, input int sh);
        logic [7:0] y;
        begin
            case (sh)
                1: y = {x[6:0], x[7]};
                2: y = {x[5:0], x[7:6]};
                3: y = {x[4:0], x[7:5]};
                4: y = {x[3:0], x[7:4]};
                default: y = x;
            endcase
            rotl8 = y;
        end
    endfunction

    function automatic logic [7:0] aes_sbox(input logic [7:0] x);
        logic [7:0] inv;
        begin
            inv = gf_inv(x);
            aes_sbox = 8'h63 ^ inv ^ rotl8(inv, 1) ^ rotl8(inv, 2) ^ rotl8(inv, 3) ^ rotl8(inv, 4);
        end
    endfunction

    function automatic logic [127:0] add_round_key(
        input logic [127:0] in_state,
        input logic [127:0] in_key
    );
        add_round_key = in_state ^ in_key;
    endfunction

    function automatic logic [127:0] sub_bytes(input logic [127:0] in_state);
        logic [127:0] out_state;
        int i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                out_state[127 - i*8 -: 8] = aes_sbox(in_state[127 - i*8 -: 8]);
            end
            sub_bytes = out_state;
        end
    endfunction

    function automatic logic [127:0] shift_rows(input logic [127:0] in_state);
        logic [7:0] in_b [0:15];
        logic [7:0] out_b[0:15];
        logic [127:0] out_state;
        int i;
        int r;
        int c;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                in_b[i] = in_state[127 - i*8 -: 8];
            end

            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    out_b[r + 4*c] = in_b[r + 4*((c + r) % 4)];
                end
            end

            for (i = 0; i < 16; i = i + 1) begin
                out_state[127 - i*8 -: 8] = out_b[i];
            end
            shift_rows = out_state;
        end
    endfunction

    function automatic logic [127:0] mix_columns(input logic [127:0] in_state);
        logic [7:0] in_b [0:15];
        logic [7:0] out_b[0:15];
        logic [127:0] out_state;
        logic [7:0] a0;
        logic [7:0] a1;
        logic [7:0] a2;
        logic [7:0] a3;
        int c;
        int i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                in_b[i] = in_state[127 - i*8 -: 8];
            end

            for (c = 0; c < 4; c = c + 1) begin
                a0 = in_b[0 + 4*c];
                a1 = in_b[1 + 4*c];
                a2 = in_b[2 + 4*c];
                a3 = in_b[3 + 4*c];

                out_b[0 + 4*c] = gf_mul(8'h02, a0) ^ gf_mul(8'h03, a1) ^ a2 ^ a3;
                out_b[1 + 4*c] = a0 ^ gf_mul(8'h02, a1) ^ gf_mul(8'h03, a2) ^ a3;
                out_b[2 + 4*c] = a0 ^ a1 ^ gf_mul(8'h02, a2) ^ gf_mul(8'h03, a3);
                out_b[3 + 4*c] = gf_mul(8'h03, a0) ^ a1 ^ a2 ^ gf_mul(8'h02, a3);
            end

            for (i = 0; i < 16; i = i + 1) begin
                out_state[127 - i*8 -: 8] = out_b[i];
            end
            mix_columns = out_state;
        end
    endfunction

    function automatic logic [7:0] rcon(input logic [3:0] round_num);
        begin
            case (round_num)
                4'd1: rcon = 8'h01;
                4'd2: rcon = 8'h02;
                4'd3: rcon = 8'h04;
                4'd4: rcon = 8'h08;
                4'd5: rcon = 8'h10;
                4'd6: rcon = 8'h20;
                4'd7: rcon = 8'h40;
                4'd8: rcon = 8'h80;
                4'd9: rcon = 8'h1b;
                4'd10: rcon = 8'h36;
                default: rcon = 8'h00;
            endcase
        end
    endfunction

    function automatic logic [31:0] rot_word(input logic [31:0] w);
        rot_word = {w[23:0], w[31:24]};
    endfunction

    function automatic logic [31:0] sub_word(input logic [31:0] w);
        logic [31:0] sw;
        begin
            sw[31:24] = aes_sbox(w[31:24]);
            sw[23:16] = aes_sbox(w[23:16]);
            sw[15:8]  = aes_sbox(w[15:8]);
            sw[7:0]   = aes_sbox(w[7:0]);
            sub_word  = sw;
        end
    endfunction

    function automatic logic [127:0] next_round_key(
        input logic [127:0] curr_key,
        input logic [3:0]   round_num
    );
        logic [31:0] w0;
        logic [31:0] w1;
        logic [31:0] w2;
        logic [31:0] w3;
        logic [31:0] t;
        logic [31:0] nw0;
        logic [31:0] nw1;
        logic [31:0] nw2;
        logic [31:0] nw3;
        begin
            w0 = curr_key[127:96];
            w1 = curr_key[95:64];
            w2 = curr_key[63:32];
            w3 = curr_key[31:0];

            t   = sub_word(rot_word(w3)) ^ {rcon(round_num), 24'h000000};
            nw0 = w0 ^ t;
            nw1 = w1 ^ nw0;
            nw2 = w2 ^ nw1;
            nw3 = w3 ^ nw2;

            next_round_key = {nw0, nw1, nw2, nw3};
        end
    endfunction

    logic [127:0] sb_state;
    logic [127:0] sr_state;
    logic [127:0] mc_state;
    logic [127:0] new_state;
    logic [127:0] new_round_key;

    always @(*) begin
        sb_state      = sub_bytes(state_reg);
        sr_state      = shift_rows(sb_state);
        mc_state      = mix_columns(sr_state);
        new_round_key = next_round_key(round_key_reg, round_ctr);

        if (round_ctr == 4'd10) begin
            new_state = add_round_key(sr_state, new_round_key);
        end else begin
            new_state = add_round_key(mc_state, new_round_key);
        end

        if (fault_inject && (round_ctr == 4'd5)) begin
            new_state[0] = ~new_state[0];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg     <= 128'h0;
            round_key_reg <= 128'h0;
            round_ctr     <= 4'h0;
            ciphertext    <= 128'h0;
            done          <= 1'b0;
            busy          <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                state_reg     <= plaintext ^ key;
                round_key_reg <= key;
                round_ctr     <= 4'd1;
                busy          <= 1'b1;
            end else if (busy) begin
                state_reg     <= new_state;
                round_key_reg <= new_round_key;

                if (round_ctr == 4'd10) begin
                    ciphertext <= new_state;
                    done       <= 1'b1;
                    busy       <= 1'b0;
                    round_ctr  <= 4'h0;
                end else begin
                    round_ctr <= round_ctr + 4'd1;
                end
            end
        end
    end

endmodule
