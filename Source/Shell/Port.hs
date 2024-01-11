program Port
{
    uses "/Source/System/System"
    uses "/Source/System/Serial"
    uses "/Source/System/Keyboard"
    uses "/Source/System/Screen"
    
    #define JSON_EXPRESS // .code and .json are generated by us so assume .json files have no errors
    uses "/Source/Compiler/JSON/JSON"
   
    <string, string> debugOptions;
    uint LoadPort()
    {
        // load options
        uint comCurrent;
        string optionsPath = Path.MakeOptions("Debugger.options");
        if (File.Exists(optionsPath))
        {
            <string, variant> dict;
            if (JSON.Read(optionsPath, ref dict))
            {
                debugOptions = dict["debugoptions"];
                if (debugOptions.Contains("comPort"))
                {
                    string value = debugOptions["comPort"];
                    if (UInt.TryParse(value, ref comCurrent))
                    {
                        // found a current port
                    }
                }
            }
        }
        return comCurrent;
    }
   
    SavePort(uint iport)
    {
        debugOptions["comPort"] = iport.ToString();
        
        // save options
        string optionsPath = Path.MakeOptions("Debugger.options");
        File.Delete(optionsPath);
        <string, variant> dict;
        dict["debugoptions"] = debugOptions;
        if (JSON.Write(optionsPath, dict))
        {
        }
    }
    
    {
        <string> ports = Serial.Ports;
        uint comCurrent = LoadPort();
        bool currentExists;
        uint i;
        char defCh;
        PrintLn("COM Ports:");
        string currentPort = "COM" + comCurrent.ToString();
        foreach (var port in ports)
        {
            i++;
            string content = "  " + (i.ToString()).LeftPad(' ', 3) + ": " + port;
            if (port == currentPort)
            {
                content = content + " (current)";
                defCh = char(48+i);    
                currentExists = true;
            }
            if ((defCh == char(0)) && (i == ports.Length))
            {
                content = content + " (default)";
                defCh = char(48+i);
            }
            PrintLn(content);
        }
        uint iport;        
        if (!currentExists)
        {
            // current port no longer exists
            SavePort(iport);
        }
        
        PrintLn("Press number to select COM port (or <enter> for default)");
        Key key = ReadKey();
        char ch = Keyboard.ToChar(key);
        if (key == Key.Enter)
        {
            ch = defCh;
        }
        if ((ch >= '1') && (ch <= '9'))
        {
            i = uint(ch) - 49;
            if (i < ports.Length)
            {
                string port = (ports[i]).Replace("COM", "");
                if (UInt.TryParse(port, ref iport))
                {
                    SavePort(iport);
                    PrintLn("COM" + iport.ToString() + " is now the Debug / Hopper Monitor port");
                }
            }
        }
        
    }
}
