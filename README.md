# 6424

## Verilog synthesis infrastructure

Yosys-based synthesis and verification setup for this project.

See **[infrastructure/README.md](infrastructure/README.md)** for usage.

### Layout

- **infrastructure/local-yosys/** — Build and run Yosys (and Verilator) locally; edit `synth.tcl` and `your_design.v`.
- **infrastructure/docker-yosys/** — Same workflow in Docker; edit `workdir/synth.tcl` and `workdir/your_design.v`.

Use `make help` in either directory for targets.
