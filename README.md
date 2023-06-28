# Life

A game of life representation in Lobster. Mainly for understanding Lobster's
quirks so I can work with it for larger projects.

## Running

If you have the [Lobster binaries](https://aardappel.github.io/lobster/getting_started.html)
you can simply run

```bash
lobster life.lobster
```

## Controls

* `q` or `ESC` quits the game
* `SPACE` resumes simulation
* The dropdown `ctl` menu can be used to do the following:
  * Change board size (rows & columns)
  * Update frame speed (number of seconds per frame)
  * Clear the board
  * Randomize the board (also changes random seed)
  * Enable debugging mode (shows grid, prints info)

---

**NOTE**: currently a WIP, and low priority.

## List of known issues & wishlist

* [x] Add support for non-square boards
* [ ] Try to optimize (look into implementing Hashlife?)
* [x] Change map into torus
* [ ] Add UI elements with ability to:
  * [x] Change grid size on the fly
  * [ ] Add common elements (shape repertoire -- gliders, etc.)
  * [x] Clear/randomize grid
  * [x] Change some flags (e.g. debugging)
  * [x] Change simulation speed


