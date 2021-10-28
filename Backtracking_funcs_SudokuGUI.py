#!/usr/bin/python

def valid_num(board, row, col, num):
    '''
    Function that checks for number validity for board creation and solving
    :param board ~ 2d sudoku board either empty or partially full
    :param row ~ int row number
    :param col ~ int col number
    :param num ~ int num being checked for uniqueness by row, col, and box
    :return ~ bool, True if check successful, False if any check fails
    '''
    # check row
    for i in range(9):
        if board[row][i] == num:
            return False

    # check col
    for i in range(9):
        if board[i][col] == num:
            return False

    # check 3x3 box
    box_x = row - row%3
    box_y = col - col%3
    for x in range(3):
        for y in range(3):
            if board[box_x + x][box_y + y] == num:
                return False

    # valid num
    return True


def empty_spot(board, pos):
    '''
    :param board~ 2d initialized sudoku board
    :param pos ~ position of board in backtracking algorithm(starting (0,0)), reassigned to new empty position found
    :return Bool~ True for finding empty position, False for not
    '''

    #checking for empty(0) positions
    for x in range(9):
        for y in range(9):
            if board[x][y] == 0:
                pos[0] = x
                pos[1] = y
                return True
    return False


def new_valid_board(board, nums = (list(range(1,10)))):
    '''
    Uses backtracking to create valid, solveable sudoku puzzle
    :param board ~ a 0-ed 9x9 list/array (blank sudoku board) ex. board = [[0 for j in range(9)] for i in range(9)]
    :param nums ~ default list of ints 1-9
    :return ~ valid randomized solution
    '''
    import random

    #variable of x,y in empty_spot
    pos = [0,0]

    #Checking for empty space on board, if no empty space, done and returns board.
    if not empty_spot(board, pos):
        return True

    row = pos[0]
    col = pos[1]

    #randomly shuffling number vals for creation
    random.shuffle(nums)

    #Looping through available, randomized nums
    for num in nums:

        #preliminarily checking for validity
        if valid_num(board, row ,col, num):

            #tentative assignment
            board[row][col] = num

            #Returns if new number works
            if new_valid_board(board):
                return True

            #resets num if failed
            board[row][col] = 0

    #triggers backtracking by for loop completion
    return False


def new_game(board, difficulty):
    '''
    Function that makes a game based on easy, medium, or hard victory
    :param difficulty ~ string 'EASY','MEDIUM','HARD','OUCH' that correlates
                        to how many starting numbers on board
    :param board ~ a fully solved 9x9 sudoku puzzle board
    :return new_game ~ valid game board based on difficulty
    '''
    import random
    import copy

    #init settings for difficuty
    easy = 45
    medium = 35
    hard = 25
    OUCH = 20

    #reassigning valid, solved sudoku board
    new_game = copy.deepcopy(board)

    #Randomly generating board position numbers([[y]x] 0:80) that will stay on the board based on difficulty
    if difficulty == 'EASY':
        init_pos = random.sample(range(81),easy)
    elif difficulty == 'MEDIUM':
        init_pos = random.sample(range(81),medium)
    elif difficulty == 'HARD':
        init_pos = random.sample(range(81),hard)
    elif difficulty == 'OUCH':
        init_pos = random.sample(range(81),OUCH)

    #Deleting position numbers not in initial start
    for x in range(9):
        for y in range(9):
            if x * 9 + y not in init_pos:
                new_game[x][y] = 0
            else:
                    continue

    #A valid game board ready to play
    return new_game
