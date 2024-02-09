program ThinkInkFeatherwing
{   
    //#define ADAFRUIT_FEATHER_RP2040
    //#define CHALLENGER_RP2040_WIFI
    #define SPARKFUN_THING_PLUS_RP2040
    
    //uses "/Source/Library/Devices/AdafruitThinkInk213Mono"
    //uses "/Source/Library/Devices/AdafruitThinkInk213TriColor"
    //uses "/Source/Library/Devices/AdafruitThinkInk290TriColor"
    uses "/Source/Library/Devices/AdafruitThinkInk290Gray"
    
    uses "/Source/Library/Fonts/Hitachi5x7"
    
    const string lorumIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse iaculis tortor vitae imperdiet tempus. Quisque eget sapien ex. Donec molestie tincidunt sem imperdiet condimentum. Nulla facilisi. Class aptent taciti sociosqu ad litora vestibulum.";

    ButtonISR(byte pin, PinStatus status) 
    { 
        string pinName = PinToButton(pin);
        IO.WriteLn("    Pressed: '" + PinToButton(pin) + "'");
    }
    
    DrawText()
    {
        LED = true;
        IO.WriteLn("  DrawText");
        Display.Suspend();
        EchoToLCD = true;
        Screen.ForeColour = Colour.Black;
        Screen.BackColour = Colour.White;
        Screen.Clear();
        IO.WriteLn(lorumIpsum);
        IO.WriteLn();
        Screen.ForeColour = Colour.Red;
        IO.WriteLn(lorumIpsum);
        Screen.ForeColour = Colour.Black;
        EchoToLCD = false;
        Display.Resume();
        LED = false;
    }
    
    DrawShades()
    {
        LED = true;
        IO.WriteLn("  DrawShades");
        Display.Suspend();
        FilledRectangle(0,                      0, Display.PixelWidth/4, Display.PixelHeight, Colour.White);
        FilledRectangle(Display.PixelWidth/4,   0, Display.PixelWidth/4, Display.PixelHeight, Colour.LightGray);
        FilledRectangle(Display.PixelWidth/2,   0, Display.PixelWidth/4, Display.PixelHeight, Colour.DarkGray);
        FilledRectangle(Display.PixelWidth*3/4, 0, Display.PixelWidth/4, Display.PixelHeight, Colour.Black);
        Display.Resume(); 
        LED = false;
    }
    
    DrawBoxes(uint colour)
    {
        LED = true;
        uint backColour;
        if (colour == Colour.Black)
        {
            IO.WriteLn("  DrawBoxes: Black");
            backColour = Colour.White;
        }
        else if (colour == Colour.White)
        {
            IO.WriteLn("  DrawBoxes: White");
            backColour = Colour.Black;
        }
        else if (colour == Colour.Red)
        {
            IO.WriteLn("  DrawBoxes: Red");
            backColour = Colour.White;
        }
        else
        {
            IO.WriteLn("  DrawBoxes: colour?");
            backColour = Colour.White;
        }
        
        Display.Suspend();
        Display.Clear(backColour);
        Rectangle(0, 0, Display.PixelWidth, Display.PixelHeight, colour);
        VerticalLine(Display.PixelWidth/3, 0, Display.PixelHeight-1, colour);
        HorizontalLine(0, Display.PixelHeight/3, Display.PixelWidth-1, colour);
        Display.Resume();
        LED = false;
    }
    
    {
        
        
        //DisplayDriver.IsPortrait = true;
        //DisplayDriver.FlipX = true;
        //DisplayDriver.FlipY = true;
     
#ifdef EPD_HAS_BUTTONS        
        PinISRDelegate buttonDelegate = ButtonISR;
        if (!DeviceDriver.Begin(buttonDelegate))
        {
            IO.WriteLn("Failed to initialize display");
            return;
        }
#else
        if (!DeviceDriver.Begin())
        {
            IO.WriteLn("Failed to initialize display");
            return;
        }
#endif
        
        long start;
        long elapsed;
        long laps;
        
        Screen.Clear();
        loop
        {
            WriteLn("Laps: ");
            WriteLn(laps.ToString());
            laps++;
            Delay(250);
            
            start = Millis;
            DrawText();
            elapsed = Millis - start;
            WriteLn("Elapsed: " + elapsed.ToString());
            DelaySeconds(2);
            
            start = Millis;
            DrawShades();
            elapsed = Millis - start;
            WriteLn("Elapsed: " + elapsed.ToString());
            DelaySeconds(2);
            
            
            start = Millis;
            DrawBoxes(Colour.Black);
            elapsed = Millis - start;
            WriteLn("Elapsed: " + elapsed.ToString());
            DelaySeconds(2);
            
            start = Millis;
            DrawBoxes(Colour.White);
            elapsed = Millis - start;
            WriteLn("Elapsed: " + elapsed.ToString());
            DelaySeconds(2);
            
            start = Millis;
            DrawBoxes(Colour.Red);
            elapsed = Millis - start;
            WriteLn("Elapsed: " + elapsed.ToString());
            DelaySeconds(1);
        }
    }
}
