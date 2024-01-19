unit Screen
{
    uses "/Source/System/Colour"

    byte CursorX { get system; }
    byte CursorY { get system; }
    byte Columns { get system; }
    byte Rows    { get system; }
    
    uint defaultForeColour = Colour.MatrixGreen;
    uint defaultBackColour = Colour.Black;
    uint ForeColour { get { return defaultForeColour; } set { defaultForeColour = value; }}
    uint BackColour { get { return defaultBackColour; } set { defaultBackColour = value; }}
    
#ifndef HOPPER_6502
    Suspend() system;
    
    // if !isInteractive then Resume will pump messages (not needed if we are processing keystrokes)
    Resume(bool isInteractive) system;
#endif

    Clear() system;
    
    SetCursor(uint col, uint row) system;

    DrawChar(uint col, uint row, char c, uint foreColour, uint backColour) system;
    
    Print(char c,     uint foreColour, uint backColour) system;
    Print(string s,   uint foreColour, uint backColour) system;
    PrintLn() system;

    PrintLn(char c,   uint foreColour, uint backColour)
    {
        Print(c, foreColour, backColour);
        PrintLn();
    }
    PrintLn(string s, uint foreColour, uint backColour)
    {
        Print(s, foreColour, backColour);
        PrintLn();
    }
    
    Print(char c)
    {
        Print(c, ForeColour, BackColour);
    }
    Print(string s)
    {
        Print(s, ForeColour, BackColour);
    }
    PrintLn(char c)
    {  
        Print(c, ForeColour, BackColour);
        PrintLn();
    }
    PrintLn(string s)
    {  
        Print(s, ForeColour, BackColour);
        PrintLn();
    } 
}
