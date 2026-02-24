#!/usr/bin/env python3
"""
Generate AES-128 test vectors using OpenSSL.
Includes random vectors and boundary/edge-case vectors.
"""
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


def get_boundary_vectors() -> list[tuple[str, str, str]]:
    """
    Return a fixed set of boundary/edge-case (key, plaintext) pairs.
    These cover all-zeros, all-ones, alternating patterns, and
    known NIST FIPS-197 test vectors.
    """
    raw = [
        # all-zeros key, all-zeros plaintext
        ("00000000000000000000000000000000",
         "00000000000000000000000000000000"),
        # all-ones key, all-ones plaintext
        ("ffffffffffffffffffffffffffffffff",
         "ffffffffffffffffffffffffffffffff"),
        # all-zeros key, all-ones plaintext
        ("00000000000000000000000000000000",
         "ffffffffffffffffffffffffffffffff"),
        # all-ones key, all-zeros plaintext
        ("ffffffffffffffffffffffffffffffff",
         "00000000000000000000000000000000"),
        # alternating 0x55 / 0xAA key and plaintext
        ("55555555555555555555555555555555",
         "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
        ("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
         "55555555555555555555555555555555"),
        # single-bit key/plaintext
        ("80000000000000000000000000000000",
         "00000000000000000000000000000000"),
        ("00000000000000000000000000000001",
         "00000000000000000000000000000000"),
        ("00000000000000000000000000000000",
         "80000000000000000000000000000000"),
        ("00000000000000000000000000000000",
         "00000000000000000000000000000001"),
        # NIST FIPS-197 Appendix B vector
        ("2b7e151628aed2a6abf7158809cf4f3c",
         "6bc1bee22e409f96e93d7e117393172a"),
        # repeated-byte patterns
        ("01010101010101010101010101010101",
         "01010101010101010101010101010101"),
        ("deadbeefdeadbeefdeadbeefdeadbeef",
         "cafebabecafebabecafebabecafebabe"),
    ]
    vectors = []
    for k, p in raw:
        c = openssl_encrypt_ecb(k, p)
        vectors.append((k, p, c))
    return vectors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate AES-128 test vectors using OpenSSL"
    )
    parser.add_argument(
        "--count",
        type=int,
        default=200,
        help="number of random vectors (default: 200)",
    )
    parser.add_argument(
        "--output",
        default="tb/generated_vectors.txt",
        help="output file path",
    )
    parser.add_argument(
        "--no-boundary",
        action="store_true",
        help="skip boundary/edge-case vectors",
    )
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.output) if os.path.dirname(args.output) else ".", exist_ok=True)

    # 1. Boundary vectors
    boundary_vectors = [] if args.no_boundary else get_boundary_vectors()

    # 2. Random vectors
    random_vectors = []
    for _ in range(args.count):
        k = secrets.token_hex(16)
        p = secrets.token_hex(16)
        c = openssl_encrypt_ecb(k, p)
        random_vectors.append((k, p, c))

    all_vectors = boundary_vectors + random_vectors

    with open(args.output, "w", encoding="ascii") as f:
        for k, p, c in all_vectors:
            f.write(f"{k} {p} {c}\n")

    print(f"Generated {len(boundary_vectors)} boundary vectors + "
          f"{len(random_vectors)} random vectors = "
          f"{len(all_vectors)} total vectors")
    print(f"Output: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
