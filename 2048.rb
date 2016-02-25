#!/usr/bin/env ruby

require 'io/console'

# Reads keypresses from the user including 2 and 3 escape character sequences. Credit: https://gist.github.com/acook/4190379
def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

# Get input
def read_single_key
  c = read_char

  case c
  when "\e[A"
    return "UP"
  when "\e[B"
    return "DOWN"
  when "\e[C"
    return "RIGHT"
  when "\e[D"
    return "LEFT"
  when "\u0003"
    return "QUIT"
  end
end

class Game

  # Init game
  def initialize(row, col)
    puts "Arrow keys to move. CTRL-C to quit"
    @row = row
    @col = col
    @game = Array.new(row * col, 0)
    spawn_number
  end

  # Spawn new number in game
  def spawn_number
    empty_tile_count = @game.select { |num| num == 0 }.count
    return if empty_tile_count == 0
    target = rand(empty_tile_count)
    (@row * @col).times do |i|
      if @game[i] == 0 and i == target
        @game[i] = 2
      elsif i == target
        target += 1
      end
    end
  end

  # Output current game state
  def print_game_state
    @row.times do |r|
      puts @game[(r*@col)...(r*@col+@col)].join ' '
    end
    puts
  end

  # Convert to 2d array
  def to_2d_array(game)
    array = []
    @row.times do |r|
      array << game[(r*@col)...(r*@col+@col)]
    end
    array
  end

  # Rotate array clockwise
  def rotate_clockwise(game)
    new_array = []
    # Transpose flips array, need to swap columns
    to_2d_array(game).transpose.each do |row|
      new_array << row.reverse
    end
    new_array.reduce(&:+)
  end

  # Rotate array counter clockwise
  def rotate_counter_clockwise(game)
    # Transpose flips array, need to swap rows
    to_2d_array(game).transpose.reverse.reduce(&:+)
  end

  # Merge numbers on each row to the right
  def merge_numbers
    array = to_2d_array(@game)
    new_array = []
    @row.times do |r|
      # Remove all 0
      row = array[r].reject { |i| i == 0 }
      (0...(row.count-1)).each do |c|
        # Merge numbers into 1 tile
        if row[c] == row[c+1]
          row[c] = 0
          row[c+1] *= 2
        end
      end
      # Add back 0
      row.unshift(0) while row.count < @col
      new_array << row
    end
    @game = new_array.reduce(&:+)
  end

  # Push numbers on each row to the right
  def push_numbers
    array = to_2d_array(@game)
    new_array = []
    @row.times do |r|
      # Remove all 0
      row = array[r].reject { |i| i == 0 }
      # Add back 0
      row.unshift(0) while row.count < @col
      new_array << row
    end
    @game = new_array.reduce(&:+)
  end

  # Update game state from input
  def update_game_state(action)
    case action
    when "UP"
      @game = rotate_clockwise(@game)
      merge_numbers
      push_numbers
      @game = rotate_counter_clockwise(@game)
    when "DOWN"
      @game = rotate_counter_clockwise(@game)
      merge_numbers
      push_numbers
      @game = rotate_clockwise(@game)
    when "RIGHT"
      merge_numbers
      push_numbers
    when "LEFT"
      @game = rotate_counter_clockwise(rotate_counter_clockwise(@game))
      merge_numbers
      push_numbers
      @game = rotate_counter_clockwise(rotate_counter_clockwise(@game))
    when "QUIT"
      puts action
      exit 0
    end
    spawn_number
    empty_tile_count = @game.select { |num| num == 0 }.count
    if empty_tile_count == 0
      print_game_state
      puts 'GAME OVER'
      exit 0
    end
  end

  # Main game loop
  def loop
    while true
      print_game_state
      input = read_single_key
      update_game_state(input)
    end
  end
end

game = Game.new(4, 4)
game.loop
