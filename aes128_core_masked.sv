module aes128_core_masked (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    input  logic [127:0] mask,
    input  logic         fault_inject,
    input  logic [3:0]   fault_round_sel,
    input  logic [6:0]   fault_bit_sel,
    output logic [127:0] ciphertext,
    output logic         done,
    output logic         busy
);

    logic [127:0] state_reg;
    logic [127:0] round_key_reg;
    logic [127:0] mask_reg;
    logic [3:0]   round_ctr;
    logic [7:0]   r_byte;
    logic [8:0]   init_cnt;
    logic         init_done;
    logic [7:0]   masked_sbox [0:255];

    // ---------------------------------------------------------------
    // GF(2^8) helpers (unchanged from aes128_core)
    // ---------------------------------------------------------------

    function automatic logic [7:0] xtime(input logic [7:0] x);
        xtime = {x[6:0], 1'b0} ^ (8'h1b & {8{x[7]}});
    endfunction

    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] aa, bb, p;
        int i;
        begin
            aa = a; bb = b; p = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0]) p = p ^ aa;
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
                    if (gf_mul(x, cand) == 8'h01)
                        gf_inv = cand;
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
            aes_sbox = 8'h63 ^ inv ^ rotl8(inv,1) ^ rotl8(inv,2) ^ rotl8(inv,3) ^ rotl8(inv,4);
        end
    endfunction

    // ---------------------------------------------------------------
    // AES round-function helpers (unchanged)
    // ---------------------------------------------------------------

    function automatic logic [127:0] add_round_key(
        input logic [127:0] in_state,
        input logic [127:0] in_key
    );
        add_round_key = in_state ^ in_key;
    endfunction

    function automatic logic [127:0] shift_rows(input logic [127:0] in_state);
        logic [7:0] in_b [0:15];
        logic [7:0] out_b[0:15];
        logic [127:0] out_state;
        int i, r, c;
        begin
            for (i = 0; i < 16; i = i + 1)
                in_b[i] = in_state[127 - i*8 -: 8];
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    out_b[r + 4*c] = in_b[r + 4*((c + r) % 4)];
            for (i = 0; i < 16; i = i + 1)
                out_state[127 - i*8 -: 8] = out_b[i];
            shift_rows = out_state;
        end
    endfunction

    function automatic logic [127:0] mix_columns(input logic [127:0] in_state);
        logic [7:0] in_b [0:15];
        logic [7:0] out_b[0:15];
        logic [127:0] out_state;
        logic [7:0] a0, a1, a2, a3;
        int c, i;
        begin
            for (i = 0; i < 16; i = i + 1)
                in_b[i] = in_state[127 - i*8 -: 8];
            for (c = 0; c < 4; c = c + 1) begin
                a0 = in_b[0 + 4*c]; a1 = in_b[1 + 4*c];
                a2 = in_b[2 + 4*c]; a3 = in_b[3 + 4*c];
                out_b[0 + 4*c] = gf_mul(8'h02,a0) ^ gf_mul(8'h03,a1) ^ a2 ^ a3;
                out_b[1 + 4*c] = a0 ^ gf_mul(8'h02,a1) ^ gf_mul(8'h03,a2) ^ a3;
                out_b[2 + 4*c] = a0 ^ a1 ^ gf_mul(8'h02,a2) ^ gf_mul(8'h03,a3);
                out_b[3 + 4*c] = gf_mul(8'h03,a0) ^ a1 ^ a2 ^ gf_mul(8'h02,a3);
            end
            for (i = 0; i < 16; i = i + 1)
                out_state[127 - i*8 -: 8] = out_b[i];
            mix_columns = out_state;
        end
    endfunction

    function automatic logic [7:0] rcon(input logic [3:0] round_num);
        begin
            case (round_num)
                4'd1:  rcon = 8'h01; 4'd2:  rcon = 8'h02;
                4'd3:  rcon = 8'h04; 4'd4:  rcon = 8'h08;
                4'd5:  rcon = 8'h10; 4'd6:  rcon = 8'h20;
                4'd7:  rcon = 8'h40; 4'd8:  rcon = 8'h80;
                4'd9:  rcon = 8'h1b; 4'd10: rcon = 8'h36;
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
        logic [31:0] w0, w1, w2, w3, t, nw0, nw1, nw2, nw3;
        begin
            w0 = curr_key[127:96]; w1 = curr_key[95:64];
            w2 = curr_key[63:32];  w3 = curr_key[31:0];
            t   = sub_word(rot_word(w3)) ^ {rcon(round_num), 24'h000000};
            nw0 = w0 ^ t;
            nw1 = w1 ^ nw0;
            nw2 = w2 ^ nw1;
            nw3 = w3 ^ nw2;
            next_round_key = {nw0, nw1, nw2, nw3};
        end
    endfunction

    // ---------------------------------------------------------------
    // Masked SubBytes via precomputed table (generate block)
    // ---------------------------------------------------------------

    logic [127:0] sb_state;

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : masked_sub
            assign sb_state[127 - gi*8 -: 8] = masked_sbox[state_reg[127 - gi*8 -: 8]];
        end
    endgenerate

    // ---------------------------------------------------------------
    // Combinational round datapath
    // ---------------------------------------------------------------

    logic [127:0] sr_state;
    logic [127:0] mc_state;
    logic [127:0] new_state;
    logic [127:0] new_round_key;
    logic [127:0] next_mask;

    always @(*) begin
        sr_state      = shift_rows(sb_state);
        mc_state      = mix_columns(sr_state);
        new_round_key = next_round_key(round_key_reg, round_ctr);

        if (round_ctr == 4'd10) begin
            next_mask = shift_rows(mask_reg);
            new_state = add_round_key(sr_state, new_round_key);
        end else begin
            next_mask = mix_columns(shift_rows(mask_reg));
            new_state = add_round_key(mc_state, new_round_key);
        end

        if (fault_inject && (round_ctr == fault_round_sel) && (fault_bit_sel <= 7'd127))
            new_state[fault_bit_sel] = ~new_state[fault_bit_sel];
    end

    // ---------------------------------------------------------------
    // FSM: start -> init (256 cycles) -> 10 rounds -> done
    // ---------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg     <= 128'h0;
            round_key_reg <= 128'h0;
            mask_reg      <= 128'h0;
            round_ctr     <= 4'h0;
            r_byte        <= 8'h0;
            init_cnt      <= 9'd0;
            init_done     <= 1'b0;
            ciphertext    <= 128'h0;
            done          <= 1'b0;
            busy          <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                r_byte        <= mask[7:0];
                mask_reg      <= {16{mask[7:0]}};
                state_reg     <= (plaintext ^ key) ^ {16{mask[7:0]}};
                round_key_reg <= key;
                round_ctr     <= 4'd1;
                init_cnt      <= 9'd0;
                init_done     <= 1'b0;
                busy          <= 1'b1;

            end else if (busy && !init_done) begin
                masked_sbox[init_cnt[7:0]] <= aes_sbox(init_cnt[7:0] ^ r_byte) ^ r_byte;
                if (init_cnt == 9'd255)
                    init_done <= 1'b1;
                init_cnt <= init_cnt + 9'd1;

            end else if (busy && init_done) begin
                state_reg     <= new_state;
                round_key_reg <= new_round_key;
                mask_reg      <= next_mask;

                if (round_ctr == 4'd10) begin
                    ciphertext <= new_state ^ next_mask;
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
