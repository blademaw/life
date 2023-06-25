// Testing language functionality with GOL

import gl
import color
import std

enum CellStatus:
    dead  = 0
    alive = 1

struct Cell:
    status:CellStatus

struct Board:
    cells:[[Cell]]
    rowsize:int
    colsize:int

    // count the number of alive adjacent neighbors to a cell's position
    def countNeighbors(row: int, col: int) -> int:
        let rowmin = clamp(row - 1, 0, rowsize - 1)
        let rowmax = clamp(row + 1, 0, rowsize - 1)
        let colmin = clamp(col - 1, 0, colsize - 1)
        let colmax = clamp(col + 1, 0, colsize - 1)
        var aliveCount = 0

        for_range_incl(rowmin, rowmax) i:
            for_range_incl(colmin, colmax) j:
                if not equal([row,col],[i,j]):
                    if (cells[i][j].status == alive): aliveCount++

        return aliveCount

    // draw the board with GL
    def drawBoard():
        let window_size = gl_window_size()
        let units = float(window_size) / xy_f { rowsize, colsize }

        gl_scale(units):
            for(rowsize) i: for(colsize) j:
                gl_translate(xy_f { j, i }):
                    let cellColor = if (cells[i][j].status == alive): color_white else: color_black
                    gl_color(cellColor):
                        gl_rect(xy_f { 0.95, 0.95 })


    // return the next state
    def tick(debug: bool = false) -> [[Cell]]:
        let newcells = deepcopy(cells, 2)

        for(rowsize) i:
            for(colsize) j:
                // count current alive
                let neighbors = countNeighbors(i,j)
                var newstatus: CellStatus = alive

                if cells[i][j].status == alive:
                    switch neighbors:
                        case 0..1, 4..8: newstatus = dead
                else:
                    switch neighbors:
                        case 0..2, 4..8: newstatus = dead
                newcells[i][j] = Cell { newstatus }

                if debug and cells[i][j].status == alive:
                    print("Cell {i},{j} has {neighbors} neighbors")

        if debug: 
            print("-----------------------------")
            print("tick at {gl_time()}")
        return newcells

    // switch a cell status
    def changeCell(row: int, col: int) -> [[Cell]]:
        let newcells = deepcopy(cells, 2)
        let newstatus: CellStatus = if cells[row][col].status == alive: dead else: alive
        newcells[row][col] = Cell { newstatus }
        return newcells
 
class GameState:
    board: Board

    // advance a game state
    def tick(debug: bool = false):
        board = Board { board.tick(debug), board.rowsize, board.colsize }

    // change a cell
    def changeCell(row: int, col: int):
        board = Board { board.changeCell(row, col), board.rowsize, board.colsize }

// Start the display
let WINDOW_HEIGHT = 500
let WINDOW_WIDTH  = WINDOW_HEIGHT
fatal(gl_window("Game of Life", WINDOW_WIDTH, WINDOW_HEIGHT))

// initialize a random board
def initializeBoard(rows: int, cols: int, empty: bool = false) -> Board:
    var cells = []::[Cell]
    for (rows):
        var temp = []::Cell
        for (cols):
            temp = temp.append([Cell { CellStatus(if empty: 0 else: rnd(2)) }])
        cells = cells.append([temp])

    return Board { cells, rows, cols }

rnd_seed(30)
let DEBUG = false
let EMPTY = false
let N = 50
let M = 50
var time_since = 0.
let board = initializeBoard(N, M, EMPTY)
let gameState = GameState { board }

let bg_color = if DEBUG: color_red else: color_black
// drawing loop
while gl_frame():
    if gl_button("escape") or gl_button("q"): return
    gl_clear(bg_color)
    gl_color(color_white)

    // draw the board
    gameState.board.drawBoard()

    // user ticks time
    if gl_button("right") == 1:
        gameState.tick(DEBUG)
        time_since = gl_time()
    elif gl_button("right") > 1:
        if gl_time() - time_since > 0.1:
            gameState.tick(DEBUG)
            time_since = gl_time()

    // handle user changing cells
    if gl_button("mouse1") == 1:
        let mpos = gl_mouse_pos(0) 
        let norm_pos = xy_f { mpos.x, mpos.y } / (float(gl_window_size()) / xy_f { board.rowsize, board.colsize })
        if DEBUG: print("Mouse clicked at {mpos}, cell {norm_pos}")
        gameState.changeCell(int(norm_pos.y), int(norm_pos.x))
