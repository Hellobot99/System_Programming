#include <ncurses.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>

#define WIDTH 40
#define HEIGHT 20
#define MAX_LEN 300

typedef struct{
    int x, y;
}Position;

typedef enum {UP,DOWN,LEFT,RIGHT} Direction;

Position snake[MAX_LEN];
int snake_length = 5;
Direction dir = RIGHT;
Position food;

int game_over = 0;
int score = 0;
int paused = 0;
int quit_request = 0;

void init_game();
void ask_quit(int signum);
void pause_game(int signum);
void end_game();
void draw_snake();
void draw_food();
void draw_border();
void draw_status();
void move_snake();
void set_food_dir();
void handle_input();

int main()
{
    init_game();

    while(!game_over)
    {
        

        if(quit_request){
            mvprintw(10,2,"Are you sure you want to quit? (y/n):");
        }
        else if(paused){
            mvprintw(10,14,"== PAUSED ==");
            mvprintw(11,4,"Press 'p' or Ctrl+Z to resume");
        }
        else {
            move_snake(); 
            clear();
            draw_border();
            draw_snake();
            draw_food();
            draw_status();     
        }

        handle_input();
        
        refresh();
    
        usleep(100000);
         
    }
    
    end_game();

    return 0;
}

void set_food_dir()
{
    food.x = rand() % (WIDTH - 2) + 1;
    food.y = rand() % (HEIGHT - 2) + 1;           
}

void ask_quit(int signum)
{
    quit_request = !quit_request;  
}

void pause_game(int signum)
{
    paused = !paused;
}

void init_game()
{
    initscr();
    noecho();
    curs_set(FALSE);
    timeout(100);
    srand(time(NULL));

    for(int i=0;i<snake_length;i++){
        snake[i].x = WIDTH / 2 - i;
        snake[i].y = HEIGHT / 2;
    }

    set_food_dir();

    signal(SIGINT, ask_quit);
    signal(SIGTSTP, pause_game);
}

void end_game()
{
    echo();
    curs_set(TRUE);
    endwin();
    printf("Game Over! Final Score: %d\n", score);
}

void draw_border()
{
    for(int i=0;i<=WIDTH;i++){
        mvprintw(0,i,"#");
        mvprintw(HEIGHT,i,"#");
    }
    for(int i=0;i<=HEIGHT;i++){
        mvprintw(i,0,"#");
        mvprintw(i,WIDTH,"#");
    }
}

void draw_snake()
{
    for(int i=0;i<snake_length;i++){
        mvprintw(snake[i].y, snake[i].x, "O");
    }
}

void draw_food()
{
    mvprintw(food.y, food.x, "@");
}

void draw_status()
{
    mvprintw(HEIGHT+1,0,"Score: %d, Length: %d",score,snake_length);
}

void move_snake()
{
    Position temp;
    temp = snake[snake_length-1];

    for(int i=snake_length-1;i>0;i--){
        snake[i] = snake[i-1];
    }

    switch (dir)
    {
    case UP:
        snake[0].y--;
        break;
    case DOWN:
        snake[0].y++;
        break;
    case LEFT:
        snake[0].x--;
        break;
    case RIGHT:
        snake[0].x++;
        break;    
    }

    for(int i=1;i<snake_length;i++){
        if(snake[0].x == snake[i].x && snake[0].y == snake[i].y){
            game_over = 1;
            return;
        }
            
    }

    if(snake[0].x <= 0 || snake[0].x >= WIDTH ||
        snake[0].y <= 0 || snake[0].y >= HEIGHT){
            game_over = 1;
            return;
        }
    
    if(snake[0].x == food.x && snake[0].y == food.y){
        if(snake_length < MAX_LEN)
            snake_length++;
        score++;
        snake[snake_length-1]=temp;
       
        set_food_dir();
    }
        
}

void handle_input()
{
    int ch = getch();
    switch (ch)
    {
    case 'w':
        if(dir != DOWN) dir = UP;
        break;
    case 's':
        if(dir != UP) dir = DOWN;
        break;
    case 'a':
        if(dir != RIGHT) dir = LEFT;
        break;
    case 'd':
        if(dir != LEFT) dir = RIGHT;
        break;
    case 'p':
        paused = !paused;
        break;  
    case 'y':
        if(quit_request)
            game_over = 1;
            clear();
            mvprintw(HEIGHT/2, (WIDTH-20)/2, "Terminated by user");
            refresh();
            usleep(500000);
        break;
    case 'n':
        if(quit_request)
            quit_request = 0;
        break;  
    }
}