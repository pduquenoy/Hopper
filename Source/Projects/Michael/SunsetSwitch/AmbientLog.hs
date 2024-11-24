program AmbiantLog
{
    uses "/Source/Library/Boards/AdafruitFeatherRP2350Hstx"
    
    uses "/Source/System/DateTime"
    
    const string logPath = "/SD/Logs/Data.csv";
    const uint   logFrequency = 15; // log every nth minute
    uint totalMinutes;
    uint totalDays;
    
    record Log
    {
        uint Day;
        uint Minute;
        uint Light;
    }
    <Log> data;
    
    Save()
    {
        bool cardDetected = DigitalRead(GP0);
        if (cardDetected)
        {
            if (!SD.Mount()) // let SD library initialize SPI before call to SPI.Begin() in DisplayDriver.begin()
            {
                IO.WriteLn("Failed to initialize SD");
            }
            else
            {
                IO.WriteLn("SD card detected.");
                file f = File.Create(logPath);
                foreach (var log in data)
                {
                    string line = (log.Day).ToString() + "," + (log.Minute).ToString() + "," + (log.Light).ToString();
                    f.Append(line + Char.EOL);
                    if (!f.IsValid())
                    {
                        IO.WriteLn("Append Invalid.");
                    }
                    IO.WriteLn(line); // debugging
                }
                f.Flush();
                if (f.IsValid())
                {
                    IO.WriteLn("Flushed.");
                    SD.Eject();
                }
                else
                {
                    IO.WriteLn("Flush Invalid.");
                }
            }
        }
        else
        {
            IO.WriteLn("No card detected");
        }
    }
    Hopper()
    {
        // Settings for Hopper SD unit:
        SD.SPIController = 0;
        SD.ClkPin = SPI0SCK;
        SD.TxPin  = SPI0Tx;
        SD.RxPin  = SPI0Rx;
        SD.CSPin  = SPI0SS; 
        PinMode(GP0, PinModeOption.Input); // Card Detect
        
        // on reset, set time from debugger
        if (Runtime.InDebugger)
        {
            string dateTime = Runtime.DateTime;  
            string date = dateTime.Substring(0, 10);
            string time = dateTime.Substring(11);
            _ = DateTime.TryTimeToMinutes(time, ref totalMinutes);
            _ = DateTime.TryDateToDays(date, ref totalDays);
            IO.WriteLn("Time set to " + totalMinutes.ToString() + " minutes");
            IO.WriteLn("Day set to " + totalDays.ToString());
        }
        else
        {
            return; // failed : restarted not in debugger (don't override data)
        }
        
        
        uint ticks;
        long accumulator;
        uint samples;
        loop
        {
            uint light = AnalogRead(A0);
            accumulator += light;
            samples++;
            //IO.WriteLn(ticks.ToString() + ": " + light.ToString());
            IO.Write(".");
            Delay(1000);
            ticks++;
            if (ticks == 60)
            {
                IO.WriteLn(".");
                ticks = 0;
                totalMinutes++;
                
                if (totalMinutes % logFrequency == 0)
                {
                    accumulator /= samples;
                    IO.WriteLn("Day: " + totalDays.ToString() 
                           + ", Time: " + totalMinutes.ToString()
                           + ", Average: " + accumulator.ToString());
                    Log log;
                    log.Day     = totalDays;
                    log.Minute  = totalMinutes;
                    log.Light   = uint(accumulator);
                    data.Append(log);
                    Save();
                           
                    accumulator = 0;
                    samples = 0;
                }
                
                if (totalMinutes >= 1440)
                {
                    totalMinutes = 0;
                    totalDays++;
                }
            }
        }
    }
}
