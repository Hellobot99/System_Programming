#include <curses.h>
#include <signal.h>

int x = 10, y = 5;
int max_x, max_y;

void handle_resize(int sig)
{
    endwin();
    refresh();
    clear();
    getmaxyx(stdscr,max_y,max_x);

    if(x>=max_x-1)x=max_x-2;
    if(y>=max_y-1)y=max_y-2;
}

void draw_walls()
{
    for(int i=0;i<max_x;i++){
        mvaddch(0,i,'#');
        mvaddch(max_y-1,i,'#');
    }
    for(int i=0;i<max_y;i++){
        mvaddch(i,0,'#');
        mvaddch(i,max_x-1,'#');
    }
}

int main()
{
    int ch;

    initscr();
    noecho();
    cbreak();
    curs_set(0);

    getmaxyx(stdscr,max_y,max_x);

    signal(SIGWINCH, handle_resize);

    while(1)
    {
        clear();

        draw_walls();

        mvaddch(y,x,'@');

        mvprintw(1,2,"Current Position: (%d, %d), Window: (%d, %d)", y, x,max_y, max_x);
        mvprintw(2,2,"Press arrow keys to move, 'q' to quit");

        refresh();

        ch = getch();
        if(ch == 'q') break;

        switch (ch)
        {
        case 'w':
            if(y > 1) y--;
            break;
        case 's':
            if(y < max_y - 2) y++;
            break;
        case 'a':
            if(x > 1) x--;
            break;
        case 'd': 
            if(x < max_x - 2) x++;
            break;        
        default:
            break;
        }
    }

    endwin();
    return 0;
}