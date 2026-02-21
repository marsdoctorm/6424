# Makefile for cloning, building Yosys, and running synthesis and testbench

# Variables
YOSYS_REPO := https://github.com/YosysHQ/yosys.git
YOSYS_DIR := yosys

VERILATOR_REPO := https://github.com/verilator/verilator.git
VERILATOR_DIR := verilator

VERILOG_FILE ?= "your_design.v"

# Default target
all: .build-yosys .build-verilator

# Clone the Yosys repository
.clone-yosys:
	@if [ ! -d "$(YOSYS_DIR)" ]; then \
		git clone --recursive $(YOSYS_REPO); \
		touch .clone-yosys; \
		cd libs && unzip asap7-std-cells-lib-merged.lib.zip; \
	else \
		echo "Yosys repository already cloned."; \
	fi

# Build Yosys
.build-yosys: .clone-yosys
	@cd $(YOSYS_DIR) && make config-gcc && make -j$(nproc)
	touch .build-yosys

# Clone the Verilator repository
.clone-verilator:
	@if [ ! -d "$(VERILATOR_DIR)" ]; then \
		git clone $(VERILATOR_REPO); \
		touch .clone-verilator; \
	else \
		echo "Verilator repository already cloned."; \
	fi

# Build Verilator
.build-verilator: .clone-verilator
	@cd $(VERILATOR_DIR) && autoconf && ./configure --prefix=$(shell pwd)/verilator-install && make -j$(nproc) && make install
	touch .build-verilator

# Run synthesis with Yosys
synth: .build-yosys
	@$(YOSYS_DIR)/yosys -c synth.tcl 

# Clean up
.PHONY: clean
clean:
	@rm -rf $(YOSYS_DIR) $(VERILATOR_DIR) verilator-install *.vcd
	@rm -f .build-yosys .clone-yosys .clone-verilator .build-verilator
	@echo "Cleaned up build files."

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  .clone-yosys     - Clone the Yosys repository."
	@echo "  .build-yosys     - Build Yosys from source."
	@echo "  .clone-verilator - Clone the Verilator repository."
	@echo "  .build-verilator - Build Verilator from source."
	@echo "  synth            - Run synthesis with Yosys on input.v."
	@echo "  clean            - Clean up build files."
