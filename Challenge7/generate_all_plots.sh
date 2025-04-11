
#!/bin/bash

GATES=("and" "or" "nand" "nor" "xor")

for gate in "${GATES[@]}"; do
    echo "Generating plot for $gate..."
    gnuplot -e "ARG1='$gate'" plot_training.gnuplot
done

echo "All plots generated."
