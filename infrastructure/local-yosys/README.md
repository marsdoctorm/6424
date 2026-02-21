# Yosys and Icarus Verilog Build Makefile

## Overview
This Makefile automates the process of cloning, building, and using Yosys (an open-source synthesis tool) and Icarus Verilog (a simulation tool) for digital design and verification.

## Prerequisites
- Git
- Make
- GCC
- Autoconf
- Basic development tools

## Targets

### Main Targets
- `all`: Default target that builds Yosys
- `synth`: Run synthesis using Yosys
- `clean`: Remove all generated files and reset the environment
- `help`: Display available make targets

### Detailed Target Descriptions

#### Build Targets
- `.clone-yosys`: Clones the Yosys repository from GitHub
- `.build-yosys`: Compiles Yosys from source
- `.clone-iverilog`: Clones the Icarus Verilog repository
- `.build-iverilog`: Builds and installs Icarus Verilog

### Configuration
- `YOSYS_REPO`: GitHub repository URL for Yosys
- `IVERILOG_REPO`: GitHub repository URL for Icarus Verilog
- `VERILOG_FILE`: Specifies the Verilog design file for simulation (default: "your_design.v")

## Usage Examples

### Clone and Build Yosys
```bash
make .build-yosys
```

### Run Synthesis
```bash
make synth
```

### Clean Environment
```bash
make clean
```

## Notes
- Requires internet connection for initial repository cloning
- Build process may take several minutes depending on your system
- Ensure all prerequisites are installed before running

## Troubleshooting
- Check that all required development tools are installed
- Verify internet connectivity
- Ensure sufficient disk space for repository cloning and building
