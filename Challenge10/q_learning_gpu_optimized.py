# Q-Learning with GPU support in PyTorch
# Includes both single-episode and batched parallel episode versions

import torch
import random
import matplotlib.pyplot as plt
import time
import subprocess
import sys

# Environment configuration
BOARD_ROWS = 5
BOARD_COLS = 5
NUM_ACTIONS = 4
START = (0, 0)
WIN_STATE = (4, 4)
HOLE_STATES = {(1, 0), (3, 1), (4, 2), (1, 3)}

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Q-table: [BOARD_ROWS x BOARD_COLS x NUM_ACTIONS]
Q = torch.zeros((BOARD_ROWS, BOARD_COLS, NUM_ACTIONS), dtype=torch.float32, device=device)

# Rewards map
rewards = torch.full((BOARD_ROWS, BOARD_COLS), -1.0, device=device)
for r, c in HOLE_STATES:
    rewards[r, c] = -5.0
rewards[WIN_STATE] = 1.0

# Parameters
alpha = 0.5
gamma = 0.9
epsilon = 0.1

action_offsets = torch.tensor([
    [-1, 0],  # up
    [1, 0],   # down
    [0, -1],  # left
    [0, 1]    # right
], device=device)

def is_terminal(state):
    return tuple(state.tolist()) == WIN_STATE or tuple(state.tolist()) in HOLE_STATES

def get_valid_next_state(state, action):
    next_state = state + action_offsets[action]
    next_state[0] = torch.clamp(next_state[0], 0, BOARD_ROWS - 1)
    next_state[1] = torch.clamp(next_state[1], 0, BOARD_COLS - 1)
    return next_state

def choose_action(state):
    if random.random() < epsilon:
        return random.randint(0, NUM_ACTIONS - 1)
    else:
        row, col = state
        return torch.argmax(Q[row, col]).item()

def q_learning_single(episodes):
    rewards_per_episode = []
    for _ in range(episodes):
        state = torch.tensor(START, device=device)
        total_reward = 0
        while not is_terminal(state):
            action = choose_action(state)
            next_state = get_valid_next_state(state, action)
            r = rewards[next_state[0], next_state[1]]
            next_max = torch.max(Q[next_state[0], next_state[1]])
            row, col = state
            Q[row, col, action] = (1 - alpha) * Q[row, col, action] + alpha * (r + gamma * next_max)
            total_reward += r.item()
            state = next_state
        rewards_per_episode.append(total_reward)
    return rewards_per_episode

def q_learning_batch(episodes, batch_size):
    rewards_per_episode = []
    for _ in range(episodes):
        states = torch.tensor([START] * batch_size, device=device)
        dones = torch.zeros(batch_size, dtype=torch.bool, device=device)
        episode_rewards = torch.zeros(batch_size, device=device)

        while not torch.all(dones):
            actions = torch.randint(0, NUM_ACTIONS, (batch_size,), device=device)
            next_states = states.clone()

            for i in range(batch_size):
                if not dones[i]:
                    a = actions[i]
                    next_states[i] = get_valid_next_state(states[i], a)
                    r = rewards[next_states[i][0], next_states[i][1]]
                    row, col = states[i]
                    next_q = torch.max(Q[next_states[i][0], next_states[i][1]])
                    Q[row, col, a] = (1 - alpha) * Q[row, col, a] + alpha * (r + gamma * next_q)
                    episode_rewards[i] += r
                    if is_terminal(next_states[i]):
                        dones[i] = True
            states = next_states
        rewards_per_episode.append(episode_rewards.mean().item())
    return rewards_per_episode

def benchmark():
    Q.zero_()
    start_time = time.time()
    q_learning_single(1000)
    single_time = time.time() - start_time

    Q.zero_()
    start_time = time.time()
    q_learning_batch(500, batch_size=32)
    batch_time = time.time() - start_time

    result_text = f"GPU Version:\n" \
                  f"Single-episode runtime: {single_time:.4f} seconds\n" \
                  f"Batched-episode runtime: {batch_time:.4f} seconds\n\n"

    print(result_text)
    print("Results written to benchmark_results.txt")
    with open("benchmark_results.txt", "w") as f:
        f.write("GPU Benchmark Timing Results")
        f.write("-----------------------------")
        f.write(result_text)

    # Run CPU version as subprocess and append output
    try:
        result = subprocess.run([sys.executable, "q_learning_original.py"], capture_output=True, text=True, timeout=300)
        with open("benchmark_results.txt", "a") as f:
            f.write("CPU Version (q_learning_original.py output):\n")
            f.write(result.stdout)
    except Exception as e:
        with open("benchmark_results.txt", "a") as f:
            f.write(f"Error running CPU version: {str(e)}\n")

if __name__ == "__main__":
    benchmark()

