module main

import sdl

const bg_color = [u8(20), 20, 20, 255]

enum CellStatus {
	alive
	dead
}

struct Cell {
	rect sdl.Rect
mut:
	status CellStatus = CellStatus.dead
}

struct GoL {
	width     u32
	height    u32
	cell_size u32
mut:
	cells [][]Cell
	rows  u32
	cols  u32
}

fn GoL.new(width u32, height u32, cell_size u32) GoL {
	rows := width / cell_size
	cols := height / cell_size
	mut cells := [][]Cell{len: int(rows), init: []Cell{len: int(cols)}}

	for row in 0 .. rows {
		for col in 0 .. cols {
			cell := Cell{
				rect: sdl.Rect{
					x: row * cell_size
					y: col * cell_size
					w: cell_size
					h: cell_size
				}
			}
			cells[row][col] = cell
		}
	}

	return GoL{width, height, cell_size, cells, rows, cols}
}

fn (g GoL) get_cell(x u32, y u32) &Cell {
	return &g.cells[x][y]
}

fn (g GoL) count_nbors(x u32, y u32, status CellStatus) u32 {
	mut nbors := 0
	for row in x - 1 .. x + 2 {
		for col in y - 1 .. y + 2 {
			if row == x && col == y {
				continue
			}
			if row < 0 || row >= g.rows || col < 0 || col >= g.cols {
				continue
			}
			nbors += if g.get_cell(row, col).status == status { 1 } else { 0 }
		}
	}
	return u32(nbors)
}

fn (g GoL) handle_mouse_button_down(evt sdl.MouseButtonEvent) {
	g.get_cell(u32(evt.x / g.cell_size), u32(evt.y / g.cell_size)).status = .alive
}

fn (mut g GoL) update() {
	for row in 0 .. g.rows {
		for col in 0 .. g.cols {
			mut cell := g.get_cell(row, col)
			alive_nbors := g.count_nbors(row, col, .alive)
			// dead_nbors := g.count_nbors(row, col, .dead)
			match cell.status {
				.alive {
					if alive_nbors >= 2 && alive_nbors <= 3 {
						cell.status = .alive
						continue
					} else {
						cell.status = .dead
						continue
					}
				}
				.dead {
					if alive_nbors == 3 {
						cell.status = .alive
						continue
					}
				}
			}
		}
	}
}

fn (g GoL) draw(renderer &sdl.Renderer) {
	for row in 0 .. g.rows {
		for col in 0 .. g.cols {
			cell := g.get_cell(row, col)
			match cell.status {
				.alive {
					sdl.set_render_draw_color(renderer, 255, 100, 100, 255)
					sdl.render_fill_rect(renderer, cell.rect)
				}
				else {
					sdl.set_render_draw_color(renderer, bg_color[0], bg_color[1], bg_color[2],
						bg_color[3])
					sdl.render_fill_rect(renderer, cell.rect)
				}
			}
		}
	}
}

fn main() {
	sdl.init(sdl.init_video)
	mut is_playing := false
	width := u32(500)
	height := u32(500)
	window := sdl.create_window("Conway's Game of Live (Paused)".str, 300, 300, width,
		height, 0)
	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	mut gol := GoL.new(width, height, 20)
	mut should_close := false

	for {
		evt := sdl.Event{}
		for 0 < sdl.poll_event(&evt) {
			match evt.@type {
				.quit {
					should_close = true
				}
				.keydown {
					is_playing = !is_playing
					match is_playing {
						true {
							sdl.set_window_title(window, "Conway's Game of Live (Playing)".str)
						}
						false {
							sdl.set_window_title(window, "Conway's Game of Live (Paused)".str)
						}
					}
				}
				.mousebuttondown {
					gol.handle_mouse_button_down(evt.button)
				}
				else {}
			}
		}
		if should_close {
			break
		}

		sdl.set_render_draw_color(renderer, bg_color[0], bg_color[1], bg_color[2], bg_color[3])
		sdl.render_clear(renderer)

		if is_playing {
			gol.update()
		}
		gol.draw(renderer)

		sdl.render_present(renderer)
	}

	sdl.destroy_renderer(renderer)
	sdl.destroy_window(window)
	sdl.quit()
}
