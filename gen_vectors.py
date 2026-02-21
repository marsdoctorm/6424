#!/usr/bin/env python3
import argparse
import os
import secrets
import subprocess
import tempfile


def openssl_encrypt_ecb(key_hex: str, plain_hex: str) -> str:
    plain = bytes.fromhex(plain_hex)

    with tempfile.NamedTemporaryFile(delete=False) as in_file:
        in_file.write(plain)
        in_name = in_file.name

    with tempfile.NamedTemporaryFile(delete=False) as out_file:
        out_name = out_file.name

    try:
        cmd = [
            "openssl",
            "enc",
            "-aes-128-ecb",
            "-K",
            key_hex,
            "-nosalt",
            "-nopad",
            "-in",
            in_name,
            "-out",
            out_name,
        ]
        subprocess.run(cmd, check=True, capture_output=True)
        with open(out_name, "rb") as f:
            cipher = f.read()
        return cipher.hex()
    finally:
        if os.path.exists(in_name):
            os.remove(in_name)
        if os.path.exists(out_name):
            os.remove(out_name)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate AES-128 test vectors using OpenSSL")
    parser.add_argument("--count", type=int, default=12, help="number of random vectors")
    parser.add_argument(
        "--output",
        default="tb/generated_vectors.txt",
        help="output file path relative to phase1 root",
    )
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.output), exist_ok=True)

    vectors = []
    for _ in range(args.count):
        k = secrets.token_hex(16)
        p = secrets.token_hex(16)
        c = openssl_encrypt_ecb(k, p)
        vectors.append((k, p, c))

    with open(args.output, "w", encoding="ascii") as f:
        for k, p, c in vectors:
            f.write(f"{k} {p} {c}\n")

    print(f"Generated {len(vectors)} vectors at {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
