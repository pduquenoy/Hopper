unit Screen
{
    // MCU version is in Hopper (no system calls)
    uses "/Source/System/Colour"
    
#ifdef DISPLAY_DRIVER    
    uses "/Source/Library/Display"
#endif

#ifdef FONT_EXISTS
    const uint cellWidth     = CellWidth +1;
    const uint cellHeight    = CellHeight+1;
    uint[cellWidth*cellHeight] cellBuffer;
#endif

    byte cursorX;
    byte cursorY;
    byte[] fontData;
    
    uint defaultForeColour = Colour.MatrixGreen;
    uint defaultBackColour = Colour.Black;
    uint ForeColour { get { return defaultForeColour; } set { defaultForeColour = value; }}
    uint BackColour { get { return defaultBackColour; } set { defaultBackColour = value; }}
    
    
    byte CursorX { get { cursorX; }}
    byte CursorY { get { cursorY; }}
#if defined(DISPLAY_DRIVER) && defined(FONT_EXISTS)
    byte Columns { get { return byte(Display.PixelWidth / cellWidth); }}
    byte Rows    { get { return byte(Display.PixelHeight / cellHeight); }}
#else
    byte Columns { get { return 0; }}
    byte Rows    { get { return 0; }}
#endif

#if defined(DISPLAY_DRIVER) && defined(FONT_EXISTS)
    byte[] FontData { get { return fontData; } set { fontData = value; } }
    renderMonoCharacter(char chr, uint foreColour, uint backColour)
    {
        uint pixelb = (backColour & 0x0FFF == 0) ? 0x0000 : 0x0FFF;
        uint pixelf = (foreColour & 0x0FFF == 0) ? 0x0000 : 0x0FFF;
        uint cellSize = cellWidth*cellHeight;
        if ((chr <= char(32)) || (chr > char(127)))
        {
            // ' '
            for (uint i = 0; i < cellSize; i++)
            {
                cellBuffer[i] = pixelb;
            }
            return;
        }
        
        uint addr = 0;
        addr = addr + (Font.CellWidth * (byte(chr)-32));
        byte[Font.CellWidth] colColours;
        for (byte x = 0; x < Font.CellWidth; x++)
        {
            colColours[x] = fontData[addr];  addr++;
        }
        
        // This presumes fonts <= 8 pixels high (bytes per character == CellWidth)
        uint bi = 0;
        for (byte y = 0; y < Font.CellHeight; y++)     // 0..6
        {
            byte yMask = (1 << y);
            for (byte x = 0; x < Font.CellWidth; x++) // 0..4
            {
                cellBuffer[bi] = (((colColours[x] & yMask) != 0) ? pixelf : pixelb); bi++;
            }
            // space on right
            cellBuffer[bi] = pixelb; bi++;
        }
    
        // bottom row
        for (byte i = 0; i < cellWidth; i++)
        {
            cellBuffer[bi] = pixelb; bi++;
        }
    }
#endif

    scrollOneLine()
    {
        
#ifdef FONT_EXISTS
        byte scrollLines = cellHeight;
#else
        byte scrollLines = 8;
#endif

#ifdef DISPLAY_DRIVER
        Display.Suspend();
        Display.ScrollUp(scrollLines);
#endif
        cursorY--;
#ifdef DISPLAY_DRIVER
        Display.Resume();
#endif
    }
    
    Clear() 
    {
#ifdef DISPLAY_DRIVER
        Display.Clear(BackColour); 
#endif
        cursorX = 0;
        cursorY = 0;
    }
    
    SetCursor(uint col, uint row)
    {
        cursorX = col;
        cursorY = row;
    }

    DrawChar(uint col, uint row, char c, uint foreColour, uint backColour)
    {
#if defined(DISPLAY_DRIVER) && defined(FONT_EXISTS)
        int x0 = int(col * cellWidth);
        int y0 = int(row * cellHeight);
        if (fontData.Count > 0)
        {
            Display.Suspend();
            renderMonoCharacter(c, foreColour, backColour);
            for (int y=0; y < cellHeight; y++)
            {
                int deltaY = y * cellWidth;
                int y1 = y+y0;
                for (int x=0; x < cellWidth; x++)
                {
                    DisplayDriver.RawSetPixel(x+x0, y1, cellBuffer[x + deltaY]);
                }
            }
            Display.Resume();
        }
#endif
    }
    Print(char c,     uint foreColour, uint backColour)
    {
#ifdef DISPLAY_DRIVER
        DrawChar(cursorX, cursorY, c, foreColour, backColour);
#endif
        cursorX++;
        if (cursorX >= Columns)
        {
            cursorX = 0;
            cursorY++;
            if (cursorY == Rows)
            {
                scrollOneLine();
            }
        }
        
    }
    Print(string s,   uint foreColour, uint backColour)
    {
#ifdef DISPLAY_DRIVER
        Display.Suspend();
#endif
        foreach (var c in s)
        {
            Print(c, foreColour, backColour);
        }
#ifdef DISPLAY_DRIVER
        Display.Resume();
#endif
    }
    PrintLn()
    {
        cursorX = 0;
        cursorY++;
        if (cursorY == Rows)
        {
            scrollOneLine();
        }
    }

    PrintLn(char c,   uint foreColour, uint backColour)
    {
#ifdef DISPLAY_DRIVER
        Display.Suspend();
#endif
        Print(c, foreColour, backColour);
        PrintLn();
#ifdef DISPLAY_DRIVER
        Display.Resume();
#endif
    }
    PrintLn(string s, uint foreColour, uint backColour)
    {
#ifdef DISPLAY_DRIVER
        Display.Suspend();
#endif
        Print(s, foreColour, backColour);
        PrintLn();
#ifdef DISPLAY_DRIVER
        Display.Resume();
#endif
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
        PrintLn(c, ForeColour, BackColour);
    }
    PrintLn(string s)
    {  
        PrintLn(s, ForeColour, BackColour);
    }
}
