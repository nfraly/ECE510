
frame_skip = 10
frame_delay = 2

set datafile separator ","
set key outside
set xlabel "Input1"
set ylabel "Input2"
set grid
set xrange [-0.5:1.5]
set yrange [-0.5:1.5]

set terminal gif animate delay frame_delay size 800,600
set output sprintf("%s_training_animation.gif", gate)

frames = system(sprintf("wc -l < lines_%s.csv", gate)) - 1

do for [i=1:frames:frame_skip] {
    set title sprintf("Epoch %d", i-1)
    slope = real(word(system(sprintf("awk -F',' 'NR==%d{print $2}' lines_%s.csv", i+1, gate)), 1))
    intercept = real(word(system(sprintf("awk -F',' 'NR==%d{print $3}' lines_%s.csv", i+1, gate)), 1))

    plot slope * x + intercept with lines title "Decision Boundary", \
         sprintf("points_%s.csv", gate) using 1:2:3 with points palette title "Training Data"
}
