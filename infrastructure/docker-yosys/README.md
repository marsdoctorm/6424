# Docker Yosys and Icarus Verilog Makefile

## Overview
Automates Yosys synthesis and Icarus Verilog simulation using Docker containerization.

## Prerequisites
- Docker -> How to install docker: https://docs.docker.com/engine/install/
- Make

## Targets

### Main Targets
- `all`: Run synthesis
- `run-synth`: Run Yosys synthesis
- `clean`: Remove generated files
- `help`: Display available targets

## Configuration
- `DOCKER_IMAGE`: Docker image name
- `DOCKER_CONTAINER`: Container name
- `workdir_DIR`: Working directory for files

## Usage Examples

### Build and Run Everything
```bash
make all
```

### Run Synthesis
```bash
make run-synth
```

### Clean Environment
```bash
make clean
```

## Workflow
1. Builds Docker container
2. Mounts local `workdir` directory
3. Runs Yosys synthesis or Icarus Verilog simulation inside container

## Notes
- Requires Docker installation
- Ensures consistent environment across different systems
- Simplifies setup and dependency management
