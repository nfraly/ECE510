
set datafile separator ","
set key outside
set xlabel "Epoch"
set ylabel "Value"
set grid

set terminal png size 800,600
set output sprintf("%s_training_plot.png", gate)

plot sprintf("%s_training_log.csv", gate) using 1:2 with lines title "Weight1", \
     sprintf("%s_training_log.csv", gate) using 1:3 with lines title "Weight2", \
     sprintf("%s_training_log.csv", gate) using 1:4 with lines title "Bias"
