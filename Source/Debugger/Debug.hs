program Debug
{
    #define DEBUGGER
    #define JSON_EXPRESS // .code and .json are generated by us so assume .json files have no errors
    #define SHORT_CALLS  // use CALLB to save space
    
    uses "/Source/System/System"
    uses "/Source/System/Screen"
    uses "/Source/System/Keyboard"
    uses "/Source/System/Diagnostics"
    
    uses "/Source/Editor/Panel"
    uses "/Source/Editor/MenuBar"
    uses "/Source/Editor/StatusBar"
    uses "/Source/Editor/Editor"
    uses "/Source/Editor/Commands"
    
    uses "/Source/Compiler/Tokens/Parser"
    
    uses "/Source/Debugger/Source"
    uses "/Source/Debugger/Output"
    uses "/Source/Debugger/6502/Monitor"
    
    uses "/Source/Debugger/ConsoleCapture"
    
    const byte consoleWidth = 56;
    
    string optionsPath;
    string OptionsPath { get { return optionsPath; } }
    bool attached;
    bool Attached { get { return attached; } set { attached = value; } }
    
    bool IsTinyHopper { get { return false; } } // to keep peephole code happy (even though it is not used)
    
    {
        <string> arguments = System.Arguments;
        
        string filePath;
        bool showHelp;
        
        Editor.Locate(0, 0, Screen.Columns-consoleWidth, Screen.Rows);
        Parser.SetInteractive(Editor.Left+1, Editor.Top + Editor.Height-1);
        Output.Locate(Screen.Columns-consoleWidth, 0, consoleWidth, Screen.Rows);
        
        foreach (var argument in arguments)
        {
            if (filePath.Length > 0) // more than one?
            {
                showHelp = true;
                break;
            }
            else
            {
                filePath = argument;
            }
        }
        
        loop
        {
            if (!showHelp && (filePath.Length != 0))
            {
                loop
                {
                    // check the file
                    string fullPath;
                    if (File.Exists(filePath))
                    {
                        break;
                    }
                    fullPath = Path.Combine(System.CurrentDirectory, filePath);
                    if (File.Exists(fullPath))
                    {
                        filePath = fullPath;
                        break;
                    }
                    string extension = Path.GetExtension(filePath);
                    if (extension == ".")
                    {
                        string filePathExt = filePath + ".hs";
                        if (File.Exists(filePathExt))
                        {
                            filePath = filePathExt;
                            break;
                        }
                        string fullPathExt = Path.Combine(System.CurrentDirectory, filePathExt);
                        if (File.Exists(fullPathExt))
                        {
                            filePath = fullPathExt;
                            break;
                        }
                    }
                    if (!File.Exists(fullPath))
                    {
                        showHelp = true;
                    }
                    break;
                } // loop
            }
            string ihexPath;
            if (!showHelp && (filePath.Length != 0))
            {
                ihexPath = Path.GetFileName(filePath);
                string extension = Path.GetExtension(filePath);
                ihexPath = ihexPath.Replace(extension, ".hex");
                ihexPath = Path.Combine("/bin", ihexPath);
                if (!File.Exists(ihexPath))
                {
                    showHelp = true;
                }
            }
            if (showHelp)
            {
                PrintLn("DEBUG <filepath>");
                break;
            }
            
            Screen.Clear();
            
            
            // if "Debugger.options" exists, see it has a comPort set by Port.hexe:
            uint comPort;
            optionsPath = Path.MakeOptions("Debugger.options");
            if (File.Exists(optionsPath))
            {
                <string, variant> dict;
                if (JSON.Read(optionsPath, ref dict))
                {
                    <string, string> debugOptions = dict["debugoptions"];
                    if (debugOptions.Contains("comPort"))
                    {
                        string value = debugOptions["comPort"];
                        if (UInt.TryParse(value, ref comPort))
                        {
                            // found a current port
                        }
                    }
                    if (comPort != 0)
                    {
                        string currentPort = "COM" + comPort.ToString();
                        <string> ports = Serial.Ports;
                        if (!ports.Contains(currentPort))
                        {
                            // current port no longer exists
                            comPort = 0;
                            debugOptions["comPort"] = comPort.ToString();
                            File.Delete(optionsPath);
                            dict["debugoptions"] = debugOptions;
                            if (JSON.Write(optionsPath, dict))
                            {
                            }
                        }
                    }
                }
            }
            
            
            if (comPort == 0)
            {
                Serial.Connect(); // use the serial port with the highest number
            }
            else
            {
                Serial.Connect(comPort);
            }
            
            // send a <ctrl><C> in case there is a program running
            Monitor.SendBreak();
            
            if (ihexPath.Length == 0)
            {
                Pages.LoadPageData(0);
                uint crc = Monitor.GetCurrentCRC();
                PrintLn("CRC:" + crc.ToHexString(4));
                if (crc != 0)
                {
                    if (Monitor.FindCurrentHex(crc))
                    {
                        ihexPath = Monitor.CurrentHexPath;
                    }
                }
                PrintLn("Found: '" + ihexPath + "'");
            }
            if (ihexPath.Length == 0)
            {
                break;
            }
            Commands.Initialize();
           
            <string, variant> menubar   = MenuBar.New(); 
            <string, variant> statusbar = StatusBar.New(); 
            
            Editor.New(statusbar, menubar); 
            
            if (filePath.Length == 0)
            {
                Source.LoadSymbols(false);
                if (Source.SymbolsLoaded)
                {
                    <uint> mainOverloads = Symbols.GetFunctionOverloads(0x0000); // main
                    <string, string> mainStart = Symbols.GetOverloadStart(mainOverloads[0]);
                    filePath = mainStart["source"];
                    Source.ClearSymbols();
                }
                if (filePath.Length == 0)
                {
                    PrintLn("Source and symbols not found.");
                    break;
                }
                Attached = true;
            }
            
            Editor.LoadFile(filePath);
            
            MenuBar.Draw(menubar);
            StatusBar.Draw(statusbar);
            Editor.Draw();
            Output.Clear(); // draws it
            
            ConsoleCapture.SetPath(ihexPath);
            ConsoleCapture.ClearLog();
            
            // load the ihex to the remove device
            if (Attached)
            {
                DebugCommand.AttachDebugger();
            }
            else
            {
                Monitor.UploadHex(ihexPath);
            }
            loop
            {
                Key key = ReadKey();
               
                // offer the key to the menus
                if (MenuBar.OnKey(menubar, key))
                {
                    // consumed by menus
                }
                else if (StatusBar.OnKey(statusbar, key))
                {
                    // consumed by status bar
                }
                else if (Output.OnKey(key))
                {
                    // consumed by the output window (only consumes mouse up clicks)
                }
                else
                {
                    string commandName = Commands.KeyToCommand(key);
                    if (commandName.Length > 0) // checks IsEnabled too
                    {
                        Commands.Execute(commandName);
                    }
                    else if (Editor.OnKey(key)) // to Editor last since it is greedy about eating keys
                    {
                        // consumed by editor
                    }
                }
                if (ExitCommand.IsExiting())
                {
                    break;
                }
            } // key loop
            Serial.Close();
            if (DebugOptions.IsCaptureConsoleMode)
            {
                ConsoleCapture.FlushLog();
            }
            break;
        } // main loop
    }
}
