
import numpy as np
import random
import time

BOARD_ROWS = 5
BOARD_COLS = 5
START = (0, 0)
WIN_STATE = (4, 4)
HOLE_STATE = [(1,0),(3,1),(4,2),(1,3)]

class State:
    def __init__(self, state=START):
        self.state = state
        self.isEnd = False        

    def getReward(self):
        for i in HOLE_STATE:
            if self.state == i:
                return -5
        if self.state == WIN_STATE:
            return 1       
        else:
            return -1

    def isEndFunc(self):
        if (self.state == WIN_STATE):
            self.isEnd = True
        for i in HOLE_STATE:
            if self.state == i:
                self.isEnd = True

    def nxtPosition(self, action):     
        if action == 0:                
            nxtState = (self.state[0] - 1, self.state[1])              
        elif action == 1:
            nxtState = (self.state[0] + 1, self.state[1]) 
        elif action == 2:
            nxtState = (self.state[0], self.state[1] - 1)
        else:
            nxtState = (self.state[0], self.state[1] + 1)

        if (nxtState[0] >= 0) and (nxtState[0] <= 4):
            if (nxtState[1] >= 0) and (nxtState[1] <= 4):    
                return nxtState     
        return self.state 

class Agent:
    def __init__(self):
        self.states = []
        self.actions = [0,1,2,3]
        self.State = State()
        self.alpha = 0.5
        self.gamma = 0.9
        self.epsilon = 0.1
        self.isEnd = self.State.isEnd
        self.Q = {}
        self.new_Q = {}
        self.rewards = 0
        for i in range(BOARD_ROWS):
            for j in range(BOARD_COLS):
                for k in range(len(self.actions)):
                    self.Q[(i, j, k)] = 0
                    self.new_Q[(i, j, k)] = 0

    def Action(self):
        rnd = random.random()
        mx_nxt_reward = -10
        action = None
        if(rnd > self.epsilon):
            for k in self.actions:
                i,j = self.State.state
                nxt_reward = self.Q[(i,j,k)]
                if nxt_reward >= mx_nxt_reward:
                    action = k
                    mx_nxt_reward = nxt_reward
        else:
            action = np.random.choice(self.actions)
        position = self.State.nxtPosition(action)
        return position, action

    def Q_Learning(self, episodes):
        x = 0
        while(x < episodes):
            if self.isEnd:
                reward = self.State.getReward()
                i,j = self.State.state
                for a in self.actions:
                    self.new_Q[(i,j,a)] = round(reward, 3)
                self.State = State()
                self.isEnd = self.State.isEnd
                x += 1
            else:
                mx_nxt_value = -10
                next_state, action = self.Action()
                i,j = self.State.state
                reward = self.State.getReward()
                for a in self.actions:
                    nxtStateAction = (next_state[0], next_state[1], a)
                    q_value = (1 - self.alpha) * self.Q[(i,j,action)] + self.alpha * (reward + self.gamma * self.Q[nxtStateAction])
                    if q_value >= mx_nxt_value:
                        mx_nxt_value = q_value
                self.State = State(state=next_state)
                self.State.isEndFunc()
                self.isEnd = self.State.isEnd
                self.new_Q[(i,j,action)] = round(mx_nxt_value, 3)
            self.Q = self.new_Q.copy()

if __name__ == "__main__":
    ag = Agent()
    episodes = 10000
    start = time.time()
    ag.Q_Learning(episodes)
    elapsed = time.time() - start
    print(f"CPU version runtime: {elapsed:.4f} seconds")
