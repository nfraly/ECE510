module epsilon_greedy_selector #(
    parameter Q_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,

    // State location input
    input  logic [2:0] state_i,
    input  logic [2:0] state_j,

    // Q-values for this state (for 4 actions)
    input  logic [Q_WIDTH-1:0] q0,  // up
    input  logic [Q_WIDTH-1:0] q1,  // down
    input  logic [Q_WIDTH-1:0] q2,  // left
    input  logic [Q_WIDTH-1:0] q3,  // right

    // Epsilon-greedy components
    input  logic [15:0] epsilon,    // fixed-point format [0,1) = 0.XXXX (Q1.15)
    input  logic [15:0] rand_val,   // random fixed-point value ∈ [0,1)

    // Output: selected action (0 = up, 1 = down, 2 = left, 3 = right)
    output logic [1:0] selected_action
);

    // Internal wires
    logic [1:0] greedy_action;
    logic [1:0] random_action;

    // -----------------------------
    // Greedy Selection Logic (argmax)
    // -----------------------------
    always_comb begin
        if (q0 >= q1 && q0 >= q2 && q0 >= q3) greedy_action = 2'd0;
        else if (q1 >= q2 && q1 >= q3)        greedy_action = 2'd1;
        else if (q2 >= q3)                    greedy_action = 2'd2;
        else                                  greedy_action = 2'd3;
    end

    // -----------------------------
    // Random Action Logic
    // -----------------------------
    always_comb begin
        // Random action is lower 2 bits of rand_val
        random_action = rand_val[1:0];
    end

    // -----------------------------
    // Epsilon-Greedy Selection
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            selected_action <= 2'd0;
        else begin
            if (rand_val < epsilon)
                selected_action <= random_action;
            else
                selected_action <= greedy_action;
        end
    end

endmodule

