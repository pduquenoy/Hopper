unit Display
{
    uses "/Source/Library/Displays/HT16K33"
    
    <byte> modules;
    Add(byte i2cAddress)
    {
        modules.Append(i2cAddress);
    }
    bool Begin()
    {
        foreach (var module in modules)
        {
            DisplayDriver.begin(module);
        }
        return true;
    }
    Write(string text)
    {
        string remainder = text;
        remainder = remainder.Pad(' ', (modules.Count * 4));
        string current;
        foreach (var module in modules)
        {
            current = remainder.Substring(0, 4);
            remainder = remainder.Substring(4);  
            DisplayDriver.write(module, current[0], current[1], current[2], current[3]);
        }
    }
    uint Modules { get { return modules.Count; } }
    byte Brightness { set
        {
            foreach (var module in modules)
            {
                DisplayDriver.setBrightness(module, value);
            }
        }
    }
    BlinkRate Blink { set
        {
            foreach (var module in modules)
            {
                DisplayDriver.setBlinkRate(module, value);
            }
        }
    }
}