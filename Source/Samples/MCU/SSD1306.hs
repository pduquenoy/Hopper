program SSD1306Demo
{
    //#define PIMORONI_TINY2040
    #define RP2040_PICOW
    
    //#define DISPLAY_DIAGNOSTICS
    
    uses "/Source/Library/Displays/OLEDSSD1306"
    //uses "/Source/Library/Fonts/Hitachi5x7"
    //uses "/Source/Library/Fonts/Verdana5x8"
    //uses "/Source/Library/Fonts/System5x7"
    uses "/Source/Library/Fonts/Arduino6x8"
    
    TestDrawRect()
    {
        Screen.Clear();
        int ph = Display.PixelHeight;
        int pw = Display.PixelWidth;
        for(int i=0; i< ph / 2; i += 2)
        {
            Rectangle(i, i, pw-2*i, ph-2*i, Colour.White);
        }
    }

    TestFillRect()
    {
        Screen.Clear();
        int ph = Display.PixelHeight;
        int pw = Display.PixelWidth;
        for(int i=0; i<ph / 2; i += 3)
        {
            // Colour.Inverse is used so rectangles alternate white/black
            FilledRectangle(i, i, pw-i*2, ph-i*2, Colour.Invert);
        }
    }
    
    TestDrawLines() 
    {
        int i;
        int ph = Display.PixelHeight;
        int pw = Display.PixelWidth;
        Display.Suspend();
        Screen.Clear();
        for(i=0; i<pw; i += 4) 
        {
            Line(0, 0, i, ph-1, Colour.White);
        }
        for(i=0; i< ph; i += 4) 
        {
            Line(0, 0, pw-1, i, Colour.White);
        }
        Display.Resume();
        
        Display.Suspend();
        Screen.Clear();
        for(i=0; i< pw; i += 4)
        {
            Line(0, ph-1, i, 0, Colour.Red);
        }
        for(i= ph-1; i>=0; i -= 4)
        {
            Line(0, ph-1, pw-1, i, Colour.Red);
        }
        Display.Resume();
        
        Display.Suspend(); 
        Screen.Clear();
        for(i= pw-1; i>=0; i -= 4)
        {
            Line(pw-1, ph-1, i, 0, Colour.Green);
        }
        for(i= ph-1; i>=0; i -= 4)
        {
            Line(pw-1, ph-1, 0, i, Colour.Green);
        }
        Display.Resume();

        Display.Suspend();
        Screen.Clear();
        for(i=0; i< ph; i += 4)
        {
            Line(pw-1, 0, 0, i, Colour.Blue);
        }
        for(i=0; i< pw; i += 4)
        {
            Line(pw-1, 0, i, ph-1, Colour.Blue);
        }
        Display.Resume();
    }
    
    
    {
        EchoToLCD = true;
        
        DisplayDriver.I2CController = 1;
        DisplayDriver.I2CSDAPin = 14;
        DisplayDriver.I2CSCLPin = 15;

        if (!Display.Begin())
        {
            IO.WriteLn("Failed to initialize display");
            return;
        }
        
        
        long start;
        long elapsed;
        long laps;
        
        Screen.Clear();
        loop
        {
            Display.Suspend();
            WriteLn("Laps: ");
            WriteLn(laps.ToString());
            Display.Resume();
            laps++;
            start = Millis;
            Display.Clear(Colour.Black);
            elapsed = Millis - start;
            Display.Suspend();
            WriteLn("Clear: ");
            WriteLn(elapsed.ToString());
            Display.Resume();
            Delay(1000);
            
            start = Millis;
            TestDrawRect();
            elapsed = Millis - start;
            Display.Suspend();
            WriteLn("TestDrawRect: ");
            WriteLn(elapsed.ToString());
            Display.Resume();
            Delay(1000);
            
            start = Millis;
            TestFillRect();   
            elapsed = Millis - start;
            Display.Suspend();
            WriteLn("TestFillRect: ");
            WriteLn(elapsed.ToString());
            Display.Resume();
            Delay(1000);
            
            start = Millis;
            TestDrawLines();
            elapsed = Millis - start;
            Display.Suspend();
            WriteLn("TestDrawLines: ");
            WriteLn(elapsed.ToString());
            Display.Resume();
            Delay(1000);
        }
    }
}
