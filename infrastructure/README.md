
All the scripts to run synthesis with Yosys either locally (local-yosys) or via docker (docker-yosys).

Everything is done via ```Makefile``` targets, please read relevant ```README.md```'s. 

# Synthesis

To synthesize your own verilog, adjut the path to the source code and the name of the top module in `synth.tcl`, i.e., the values of `top_module` and `verilog_files`.

use **help** target to see available targets for each makefile. 

### `help`
- **Description**: Displays a list of available targets and their descriptions.
- **Purpose**: Serves as a quick reference for the user.  

# Verification w/ gate-level netlist

To run verification of the gate-level design, use iverilog (see Makefile for reference) w/ the implementation of the std_cells (in ```asap7-std-cells-lib-merged.v```):

To compile: 

```iverilog $your_verilog_file ./libs/asap7-std-cells-lib-merged.v -o my-tb```

Run the testbench:

```./my-tb```
