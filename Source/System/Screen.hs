unit Screen
{
    uses "/Source/System/Color"

    byte CursorX { get system; }
    byte CursorY { get system; }
    byte Columns { get system; }
    byte Rows    { get system; }

#ifndef H6502
    Suspend() system;
    
    // if !isInteractive then Resume will pump messages (not needed if we are processing keystrokes)
    Resume(bool isInteractive) system;
#endif
    


    Clear() system;

    SetCursor(uint x, uint y) system;
    //SetForeColour(uint foreColour) system;
    //SetBackColour(uint backColour) system;
    
    DrawChar(uint x, uint y, char c, uint foreColour, uint backColour) system;

    Print(char c,     uint foreColour, uint backColour) system;
#ifdef PORTABLE
    Print(string s,   uint foreColour, uint backColour)
    {
        foreach (var ch in s)
        {
            Print(ch, foreColour, backColour);
        }
    }
#else    
    Print(string s,   uint foreColour, uint backColour) system;
#endif    
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
        Print(c, Color.MatrixGreen, Color.Black);
    }
    Print(string s)
    {
        Print(s, Color.MatrixGreen, Color.Black);
    }
    PrintLn(char c)
    {  
        Print(c, Color.MatrixGreen, Color.Black);
        PrintLn();
    }
    PrintLn(string s)
    {  
        Print(s, Color.MatrixGreen, Color.Black);
        PrintLn();
    } 
}
