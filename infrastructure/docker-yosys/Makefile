# Makefile for running Yosys and Icarus Verilog inside a Docker container

# Variables
DOCKER_IMAGE := yosys-iverilog
DOCKER_CONTAINER := yosys_iverilog_container
workdir_DIR := workdir

# Default target
all: run-synth

# Create the Docker container
.build-container:
	docker build -t $(DOCKER_IMAGE) .
	touch .build-container
	@if [ -f workdir/libs/asap7-std-cells-lib-merged.lib.zip ]; then \
		cd workdir/libs && unzip -o asap7-std-cells-lib-merged.lib.zip; \
	fi

# Ensure the workdir directory exist
.ensure-dirs:
	@mkdir -p $(workdir_DIR) 

# Run synthesis with Yosys inside the container
run-synth: .build-container .ensure-dirs
	docker run --rm -v $(shell pwd)/../..:/workspace \
	           $(DOCKER_IMAGE) bash -c "cd /workspace/infrastructure/docker-yosys/workdir && yosys -c synth.tcl"

# Clean up
.PHONY: clean
clean:
	@rm -f .build-container
	@echo "Cleaned up build files and directories."

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all            - Build the container and run synthesis."
	@echo "  run-synth      - Run synthesis with Yosys inside the container."
	@echo "  clean          - Clean up build files and directories."

