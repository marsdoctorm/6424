yosys -import

# Specify the top module of the design (edit for your design)
set top_module your_top_module

# Specify the design files (edit paths for your design)
set verilog_files "./your_design.v"

# Read the design files
read_verilog $verilog_files

# Specify the design's top module
prep -top $top_module

# Read all Liberty files for different process corners
read_liberty -ignore_miss_func ./libs/asap7-std-cells-lib-merged.lib

# Perform generic synthesis
synth -top $top_module

# Map the design to the flip flop cells in Liberty files
dfflibmap -liberty ./libs/asap7-std-cells-lib-merged.lib

# Map the design to the standard cells in Liberty files
abc -liberty ./libs/asap7-std-cells-lib-merged.lib

# Perform technology mapping
opt_clean -purge

# Write the synthesized netlist
write_verilog -noattr gate_level_${top_module}.v

# Write the design statistics
stat

# End of script
