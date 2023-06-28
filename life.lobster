// Testing language functionality with GOL

import color
import gl
import imgui
import std
import vec


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
    // def countNeighbors(row: int, col: int, torus: bool = true) -> int:
    //     let rowmin = clamp(row - 1, 0, rowsize - 1)
    //     let rowmax = clamp(row + 1, 0, rowsize - 1)
    //     let colmin = clamp(col - 1, 0, colsize - 1)
    //     let colmax = clamp(col + 1, 0, colsize - 1)
    //     var aliveCount = 0
    //
    //     if torus:
    //         if row - 1 == -1
    //             var topleft  = xy_i { col - 1, rowsize - 1 }
    //             var topright = xy_i { col + 1, rowsize - 1 }
    //             if col - 1 == -1: topleft = xy_i { topleft.x, colsize - 1 }
    //             elif col + 1 == colsize:
    //                 if cells[rowsize - 1][0].status == alive: aliveCount++
    //             // otherwise add the two corners
    //             else:
    //                 if cells[rowsize - 1][col - 1] == alive: aliveCount++
    //     for_range_incl(rowmin, rowmax) i:
    //         for_range_incl(colmin, colmax) j:
    //             if not equal([row,col],[i,j]):
    //                 if (cells[i][j].status == alive): aliveCount++
    //
    //     return aliveCount

    // count the number of alive adjacent neighbors for a cell
    def countNeighbors(row: int, col: int) -> int:
        var aliveCount = 0
        let dirs = [[-1, -1], [-1, 0], [-1, 1],
                    [0, -1], [0, 1],
                    [1, -1], [1, 0], [1, 1]]

        for(dirs) dir:
            var r, c = row + dir[0], col + dir[1]

            r = (r + rowsize) % rowsize
            c = (c + colsize) % colsize

            if cells[r][c].status == alive: aliveCount++

        return aliveCount


    // draw the board with GL
    def drawBoard():
        let window_size = gl_window_size()
        let units = float(window_size) / xy_f { colsize, rowsize }
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

// constants, seed
var seed = 1
rnd_seed(seed)

var DEBUG = false // FIXME: refactor to be lowercase
let EMPTY = false
let N = 50
let M = 50
var update_speed = 0.1
    
// initialize a random board
def initializeBoard(rows: int, cols: int, empty: bool = false) -> Board:
    return Board {
        map(rows): map(cols): Cell { CellStatus(if empty: 0 else: rnd(2)) },
        rows,
        cols
    }

// UI for controls
class ui:
    def init():
        im_init(true)
        let im_fontsize = 32.0
        // check(im_add_font("data/fonts/Droid_Sans/DroidSans.ttf", im_fontsize), "cannot load imgui font")
        check(im_add_font("data/fonts/Inconsolata/Inconsolata-Bold.ttf", im_fontsize), "cannot load imgui font")

    def resume(gameState :: GameState):
        im_frame():
            im_window("ctl", im_window_always_autoresize):
                im_show_engine_stats()
                
                // option to change update speed
                update_speed = im_sliderfloat("Update speed", update_speed, 0.01, 1.)
                im_separator()

                // change rows
                let i = string_to_int(im_input_text("Rows", "{board.rowsize}"))
                if i != board.rowsize:
                    board = initializeBoard(i, board.colsize)
                // change columns
                let j = string_to_int(im_input_text("Columns", "{board.colsize}"))
                if j != board.colsize:
                    board = initializeBoard(board.rowsize, j)
                
                // empty board
                if im_button("Clear board"):
                    board = initializeBoard(board.rowsize, board.colsize, true)

                im_same_line()
                // randomize
                if im_button("Randomize"):
                    seed++
                    rnd_seed(seed)
                    board = initializeBoard(board.rowsize, board.colsize)

                im_same_line()
                // debug mode
                if im_checkbox("Debug", DEBUG):
                    DEBUG = true
                else:
                    DEBUG = false


// init params for instance
// FIXME: variable names are inconsistent
var time_since = 0.
let board      = initializeBoard(N, M, EMPTY)
let gameState  = GameState { board }
let bg_color   = if DEBUG: color_red else: color_black
var playGame   = false

// starting UI
let uier = ui {}
uier.init()

// graphics loop
while gl_frame():
    if gl_button("escape") or gl_button("q"): return
    if DEBUG: gl_clear(color_red) else: gl_clear(bg_color)
    gl_color(color_white)

    // draw the board
    gameState.board.drawBoard()

    // draw the UI
    uier.resume(gameState)

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
        let norm_pos = (float(gl_mouse_pos(0)) / float(gl_window_size())) * xy_f { gameState.board.colsize, gameState.board.rowsize }
        gameState.changeCell(int(norm_pos.y), int(norm_pos.x))

    // allow for space to "play" the animation
    if gl_button("space") == 1: 
        playGame = not playGame

    // animation loop, if enabled
    if playGame: 
        if (gl_time() - time_since) > update_speed: 
            gameState.tick(DEBUG)
            time_since = gl_time()

