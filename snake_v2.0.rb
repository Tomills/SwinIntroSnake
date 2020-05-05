#last edited on pc

require 'rubygems'
require 'gosu'


SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
GAME_TOP = 40
SCREEN_X_CENTER = SCREEN_WIDTH / 2
SCREEN_Y_CENTER = SCREEN_HEIGHT / 2
CELL_DIM = 20
FOOD_RADIUS = 10

SCORE_BG_COLOR = Gosu::Color.rgb(0, 55, 78)
FOOD_COLOR = Gosu::Color.rgb(255, 139, 14)
SNAKE_COLOR_ARR = [Gosu::Color.rgb(102, 200, 242), Gosu::Color::BLACK]
COLOR_ARR = [Gosu::Color.rgb(17, 72, 95), Gosu::Color::GRAY, Gosu::Color::BLACK, Gosu::Color::rgb(117, 0, 0)]

module ZOrder
    BACKGROUND, MIDDLE, TOP = *0..2
end

# This class is taken from 'circle.rb', given to us in previous tasks.
class Circle 
    attr_reader :columns, :rows
  
    def initialize(radius)
        @columns = @rows = radius * 2
    
        clear, solid = 0x00.chr, 0xff.chr
    
        lower_half = (0...radius).map do |y|
            x = Math.sqrt(radius ** 2 - y ** 2).round
            right_half = "#{solid * x}#{clear * (radius - x)}"
            right_half.reverse + right_half
        end.join
        alpha_channel = lower_half.reverse + lower_half
        # Expand alpha bytes into RGBA color values.
        @blob = alpha_channel.gsub(/./) { |alpha| solid * 3 + alpha }
    end
  
    def to_blob
        @blob
    end
end
  
# Cells for snake
class Cell
    attr_accessor :x, :y, :grow, :eaten, :color

    def initialize(x, y)
        @x = x
        @y = y
        @grow = false
        @eaten = false
    end

    def draw_cell(color)
        Gosu.draw_rect(@x, @y, CELL_DIM - 1, CELL_DIM - 1, color, ZOrder::BACKGROUND, mode=:default)
    end
end

class Food
    attr_accessor :x, :y

    def initialize
        @x = x
        @y = y
    end

    def draw_food
        circle = Gosu::Image.new(Circle.new(FOOD_RADIUS))
        circle.draw(@x, @y, ZOrder::BACKGROUND, 1.0, 1.0, FOOD_COLOR)
    end
end 

class Snake
    attr_accessor :cells, :x, :y, :score, :dead

    def initialize
        @cells = Array.new

        @x = (SCREEN_X_CENTER) - (CELL_DIM * 2)
        @y = (SCREEN_Y_CENTER) - CELL_DIM

        @score = 0

        @dead = false
    end
end


class SnakeGame < Gosu::Window

    def initialize
        super SCREEN_WIDTH, SCREEN_HEIGHT

        self.caption = "Snake"

        create_snake

        @food = Food.new
        @food.x = rand(GAME_TOP .. SCREEN_WIDTH - CELL_DIM)
        @food.y = rand(GAME_TOP .. SCREEN_HEIGHT - CELL_DIM)

        @menu_font = Gosu::Font.new(self, "fonts/stonewalls_0/StoneWalls.ttf", 40)

        @font = Gosu::Font.new(self, "fonts/Cataclysmo.otf", 30)

        @start_game = false

        @highscore = 0

        @update_interval = 16.667    # 16.667 is the number of milliseconds between each Gosu update call
    end

    # Creates a new snake and sets its values
    def create_snake

        @snake = Snake.new

        @init_len = 3

        fill_snake

        @speed = 150    # speed of snake in millisecond increments

        @next_direct = "left"

        @level = 1

        @bg_color_i = 1

        @bg_color = COLOR_ARR[0]

        @snake_color_i = 1

        @snake_color = SNAKE_COLOR_ARR[0]

    end

    # This fills the initial snake array 
    def fill_snake
        @snake_arr = @snake.cells

        index = 0
        while index < @init_len
            cell = Cell.new(@snake.x + (CELL_DIM * index), @snake.y)
            @snake_arr << cell
            index += 1
        end

        @length = @snake_arr.length

    end

    def draw_snake
        i = 0
        while i < @length
            @snake_arr[i].draw_cell(@snake_color)
            i += 1
        end
    end

    # If the snake needs to grow, it will not pop the tail, and just unshift a new head.
    def add_head(new_head)
        if @head.grow == false
            @snake_arr.pop()
        end
        @snake_arr.unshift(new_head)
    end

    # This is what moves the snake constantly
    def move
        case @next_direct
        when "up"
            new_head = Cell.new(@head.x, @head.y - CELL_DIM)
            add_head(new_head)
            @prev_direct = "up"

        when "down"
            new_head = Cell.new(@head.x, @head.y + CELL_DIM)
            add_head(new_head)    
            @prev_direct = "down"

        when "left"
            new_head = Cell.new(@head.x - CELL_DIM, @head.y)
            add_head(new_head)
            @prev_direct = "left"

        when "right"
            new_head = Cell.new(@head.x + CELL_DIM, @head.y)
            add_head(new_head)
            @prev_direct = "right"

        when "stopped"
            return
        end
    end 

    def eat_food
        i = 0 
        while i < hit_box(@food.x).length
            if (hit_box(@food.x).include?(hit_box(@head.x)[i])) && (hit_box(@food.y).include?(hit_box(@head.y)[i]))
                @head.eaten = true
                @head.grow = true       # This works with the add_head function which won't pop the head if grow == true
            end
            i += 1
        end
    end
    
    def set_speed
        if Gosu.milliseconds % @speed <= @update_interval      
            move
        end
    end

    # Stops the snake from going outside the screen - loops to the other side instead
    def screen_loop 
        if @head.x < 0
            @head.x = SCREEN_WIDTH - CELL_DIM
        end
        if @head.x > SCREEN_WIDTH - CELL_DIM
            @head.x = 0
        end
        if @head.y > SCREEN_HEIGHT - CELL_DIM
            @head.y = GAME_TOP
        end
        if @head.y < GAME_TOP
            @head.y = SCREEN_HEIGHT - CELL_DIM
        end
    end

    def die
        i = 1
        while i < @length
            if @snake_arr[i].x == @head.x && @snake_arr[i].y == @head.y
                @next_direct = "stopped"
                @snake.dead = true
            end
            i += 1
        end
    end

    # Returns an array of each number within the given co-ordinates' cell
    def hit_box(coordinates)
        hit_box = (coordinates .. coordinates + CELL_DIM).to_a
    end

    # This function gets an array of coordinates (hit-box) for each cell in the snake_arr
    def get_snake_pos
        i = 0
        @snake_x_arr = Array.new
        @snake_y_arr = Array.new
        while i < @length
            x = @snake_arr[i].x
            y = @snake_arr[i].y

            @snake_x_arr << hit_box(x)
            @snake_y_arr << hit_box(y)
            i += 1
        end
    end

    # This function gets a random number and checks if it matches the co-ordinates of the snake
    # If so, it re-calls the function using recursion. NEED TO FIX THIS
    def get_new_food
        new_food_x = rand(GAME_TOP .. SCREEN_WIDTH - CELL_DIM)
        new_food_y = rand(GAME_TOP .. SCREEN_HEIGHT - CELL_DIM)

        i = 0
        while i < @length
            if @snake_x_arr[i].include?(new_food_x) && @snake_y_arr[i].include?(new_food_y)
                get_new_food
                return 
            end
            i += 1
        end
        @new_food_x = new_food_x
        @new_food_y = new_food_y
    end
    
    def game_over_text
        @font.draw_text_rel("GAME OVER", SCREEN_X_CENTER, SCREEN_Y_CENTER, 0.5, 0.5, ZOrder::TOP, 2.0, 2.0, Gosu::Color::WHITE)
        @font.draw_text_rel("Score: #{@snake.score}", SCREEN_X_CENTER, (SCREEN_Y_CENTER + @font.height * 2), 0.5, 0.5, ZOrder::TOP, 1.5, 1.5, Gosu::Color::WHITE)
        @font.draw_text_rel("Press the Space-Bar to Restart", SCREEN_X_CENTER, (SCREEN_Y_CENTER + @font.height * 4), 0.5, 0.5, ZOrder::TOP, 1.5, 1.5, Gosu::Color::WHITE)
    end

    def game_over
        if @snake.score > @highscore
            @highscore = @snake.score
        end
        
        if Gosu.button_down? Gosu::KB_SPACE
            create_snake
            @snake.dead = false
        else
            game_over_text
        end
      
    end

    def next_level
        @level += 0.5
        if @level % 1 == 0
            if @speed > 50
                @speed -= @update_interval
            end
            # This changes the background colour each level
            if @bg_color_i < COLOR_ARR.length
                @bg_color = COLOR_ARR[@bg_color_i]
                @bg_color_i += 1
            else 
                @bg_color_i = 0
                @bg_color = COLOR_ARR[@bg_color_i]
                @bg_color_i += 1
            end
            # This changes the snake colour each level
            if @snake_color_i < SNAKE_COLOR_ARR.length
                @snake_color = SNAKE_COLOR_ARR[@snake_color_i]
                @snake_color_i += 1
            else
                @snake_color_i = 0
                @snake_color = SNAKE_COLOR_ARR[@snake_color_i]
                @snake_color_i += 1
            end
        end
    end

    def draw_background
        draw_quad(0, GAME_TOP, @bg_color, SCREEN_WIDTH, GAME_TOP, @bg_color, 0, SCREEN_HEIGHT, @bg_color, SCREEN_WIDTH, SCREEN_HEIGHT, @bg_color, ZOrder::BACKGROUND)
            
        Gosu.draw_rect(0, 0, SCREEN_WIDTH, GAME_TOP, SCORE_BG_COLOR, ZOrder::BACKGROUND, mode=:default)
        
        @font.draw_text("High Score: #{@highscore}", 10, 10, ZOrder::MIDDLE, 1.0, 1.0, Gosu::Color::WHITE)
            
        @font.draw_text_rel("Score: #{@snake.score}", SCREEN_X_CENTER, GAME_TOP, 0.5, 0.5, ZOrder::MIDDLE, 1.0, 1.0, Gosu::Color::WHITE)
            
        @font.draw_text_rel("Level: #{@level.to_i}", SCREEN_WIDTH - 60, GAME_TOP, 0.5, 0.5, ZOrder::MIDDLE, 1.0, 1.0, Gosu::Color::WHITE)
    end

    def update

        set_speed

        @head = @snake_arr.first

        screen_loop

        if @start_game == true
            eat_food
        end

        @snake.score = @length - @init_len

        if @head.eaten == true
            get_snake_pos
            get_new_food
            @food.x = @new_food_x
            @food.y = @new_food_y
            if @snake.score % 2 == 0 && @snake.score > 1
                next_level
            end
            @head.eaten = false
        end

        die
    end

    def draw
        if @start_game == false
            @menu_font.draw_text_rel("Welcome to", SCREEN_X_CENTER, SCREEN_Y_CENTER - @menu_font.height * 3, 0.5, 0.5, ZOrder::MIDDLE, 0.75, 0.75, Gosu::Color::WHITE)
            @menu_font.draw_text_rel("Snake", SCREEN_X_CENTER, SCREEN_Y_CENTER - CELL_DIM, 0.5, 0.5, ZOrder::MIDDLE, 2.0, 2.0, Gosu::Color::WHITE)
            @menu_font.draw_text_rel("Press the Space-Bar to Play", SCREEN_X_CENTER, SCREEN_Y_CENTER + CELL_DIM * 3, 0.5, 0.5, ZOrder::MIDDLE, 1.0, 1.0, Gosu::Color::WHITE)
        else
            
            draw_background
            
            @food.draw_food
        end

        if @snake.dead
            game_over
        end
        
        @length = @snake_arr.length

        draw_snake
    end


    def button_down(id)
        if @start_game == true && @snake.dead != true
            if (Gosu.button_down? Gosu::KB_UP) && (@prev_direct != "down")
                @next_direct = "up"
            end
            if (Gosu.button_down? Gosu::KB_DOWN) && (@prev_direct != "up")
                @next_direct = "down"
            end
            if (Gosu.button_down? Gosu::KB_LEFT) && (@prev_direct != "right")
                @next_direct = "left"
            end
            if (Gosu.button_down? Gosu::KB_RIGHT) && (@prev_direct != "left")
                @next_direct = "right"
            end
        end
        if Gosu.button_down? Gosu::KB_SPACE
            @start_game = true
        end
        if Gosu.button_down? Gosu::KB_ESCAPE
            exit
        end
    end
end

SnakeGame.new.show if __FILE__ == $0
