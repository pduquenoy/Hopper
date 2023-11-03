program Debug
{
    #define DEBUGGER
    #define JSONEXPRESS // .code and .json are generated by us so assume .json files have no errors
    
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
    
    {
        <string> arguments = System.Arguments;
        
        string filePath;
        bool showHelp;
        
        Editor.Locate(0, 0, Screen.Columns-consoleWidth, Screen.Rows);
        Parser.SetInteractive(Editor.Left+1, Editor.Top + Editor.Height-1);
        Output.Locate(Screen.Columns-consoleWidth, 0, consoleWidth, Screen.Rows);
        
        foreach (var argument in arguments)
        {
            if (filePath.Length > 0)
            {
                showHelp = true;
                break;
            }
            else
            {
                filePath = argument;
            }
        }
        
        if (filePath.Length == 0)
        {
            showHelp = true;
        }

        loop
        {
            if (!showHelp)
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
            if (!showHelp)
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
            Serial.Connect(); // use the serial port with the highest number
            
                
            Commands.Initialize();
           
            <string, variant> menubar   = MenuBar.New(); 
            <string, variant> statusbar = StatusBar.New(); 
            
            Editor.New(statusbar, menubar); 
            Editor.LoadFile(filePath);
            
            MenuBar.Draw(menubar);
            StatusBar.Draw(statusbar);
            Editor.Draw();
            Output.Clear(); // draws it
            
            ConsoleCapture.SetPath(ihexPath);
            ConsoleCapture.ClearLog();
            
            // load the ihex to the H6502
            Monitor.UploadHex(ihexPath);
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
                    // consumed by the output window
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
        } // loop
    }
}
