# 6424

## AES correctness validation (OpenSSL reference)

Correctness is demonstrated by comparing the RTL AES output to a trusted reference: **OpenSSL** AES-128-ECB.

### Flow

1. **Generate test vectors** — `gen_vectors.py` produces random (key, plaintext) pairs and uses OpenSSL to compute the expected ciphertext:
   ```bash
   openssl enc -aes-128-ecb -K <key_hex> -nosalt -nopad -in <plain> -out <cipher>
   ```
   It writes `key_hex plain_hex openssl_cipher_hex` per line to `tb/generated_vectors.txt`.

2. **Run simulation** — The testbench `tb_aes_hardened.sv` drives the RTL with each (key, plaintext), reads the expected ciphertext from that file, and compares the RTL output to the OpenSSL result. Any mismatch causes a fatal failure.

3. **One command** — From the repo root, run:
   ```bash
   ./run_validation.sh
   ```
   This regenerates vectors with OpenSSL, compiles the testbench, runs the simulation, and prints PASS if all RTL outputs match the OpenSSL reference.

**Requirements:** `python3`, OpenSSL, and Icarus Verilog (`iverilog`). Install with e.g. `sudo apt install iverilog` if needed.
