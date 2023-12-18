program HopperMonitor
{
    #define JSONEXPRESS // .code and .json are generated by us so assume .json files have no errors
    
    //#define CAPTURESERIAL
    
    uses "/Source/System/System"
    uses "/Source/System/IO"
    
    
    uses "/Source/Editor/Highlighter"
    
    uses "/Source/Debugger/Source"
    uses "/Source/Debugger/Output"
    uses "/Source/Debugger/6502/Pages"
    uses "/Source/Debugger/6502/Monitor"
    
    uses "/Source/Compiler/JSON/JSON"
    
    string optionsPath;
    string OptionsPath { get { return string optionsPath; } }
    
    <Key> keyboardBuffer;
    InjectKey(Key key)
    {
        keyboardBuffer.Append(key);
    }
    InjectText(string keys)
    {
        foreach (var ch in keys)
        {
            ch = ch.ToUpper();
            Key key;
            switch (ch) // lame solution for Key key = Key(ch):
            {
                case ' ': { key = Key.Space; }
                case 'A': { key = Key.A; }
                case 'B': { key = Key.B; }
                case 'C': { key = Key.C; }
                case 'D': { key = Key.D; }
                case 'E': { key = Key.E; }
                case 'F': { key = Key.F; }
                case 'G': { key = Key.G; }
                case 'H': { key = Key.H; }
                case 'I': { key = Key.I; }
                case 'J': { key = Key.J; }
                case 'K': { key = Key.K; }
                case 'L': { key = Key.L; }
                case 'M': { key = Key.M; }
                case 'N': { key = Key.N; }
                case 'O': { key = Key.O; }
                case 'P': { key = Key.P; }
                case 'Q': { key = Key.Q; }
                case 'R': { key = Key.R; }
                case 'S': { key = Key.S; }
                case 'T': { key = Key.T; }
                case 'U': { key = Key.U; }
                case 'V': { key = Key.V; }
                case 'W': { key = Key.W; }
                case 'X': { key = Key.X; }
                case 'Y': { key = Key.Y; }
                case 'Z': { key = Key.Z; }
                
                case '0': { key = Key.N0; }
                case '1': { key = Key.N1; }
                case '2': { key = Key.N2; }
                case '3': { key = Key.N3; }
                case '4': { key = Key.N4; }
                case '5': { key = Key.N5; }
                case '6': { key = Key.N6; }
                case '7': { key = Key.N7; }
                case '8': { key = Key.N8; }
                case '9': { key = Key.N9; }
                
                default:
                {
                    Die(0x0A); // not implemented
                }
            }
            keyboardBuffer.Append(key);
        }
    }
    
    Profile(string dataString, string profilePath)
    {
        if (File.Exists(profilePath))
        {
            File.Delete(profilePath);
        }
        file profileFile = File.Create(profilePath);
        
        string ln;
        bool sysCalls = false; // TODO LIBCALL
        foreach (var c in dataString)
        {
            if (c == char(0x0D))
            {
                ln = ln.Trim();
                if (ln.Length > 0)
                {
                    string addressString = "0x" + ln.Substring(0, 4);
                    uint address;
                    ln = ln.Substring(4);
                    if (UInt.TryParse(addressString, ref address))
                    {
                        address = address - 0x0800;
                        address = address / 2;
                        if (address > 255)
                        {
                            address = address - 256; // sysCall
                            sysCalls = true;
                        }
                    }
                    for (uint i = 0; i < 8; i++)
                    {
                        uint index = address + i;
                        string countString = "0x" + ln.Substring(i*4 + 2, 2) + ln.Substring(i*4, 2);
                        uint count;
                        if (UInt.TryParse(countString, ref count)) 
                        {   
                            if (count > 0)
                            {
                                string name;
                                if (sysCalls)
                                {
                                    name = SysCalls.GetSysCallName(byte(index));
                                }
                                else
                                {
                                    name = Instructions.ToString(Instruction(index));
                                }
                                profileFile.Append(name + char(0x09) + count.ToString() + char(0x0A));
                            }
                        }
                    }
                }
                ln = "";
            }
            else if (c == ' ')
            {
                // skip
            }
            else
            {
                Build(ref ln, c);
            }
        } // for
        profileFile.Flush();
    }
    
    uint TypeAddressFromValueAddress(uint voffset)
    {
        uint toffset;
        bool stack8 = ZeroPageContains("BP8");
        if (stack8)
        {
            toffset = uint(voffset - 0x0100);
        }
        else
        {
            uint delta = uint(voffset - 0x0600);
            toffset = 0x0500 + (delta / 2);
        }
        return toffset;
    }
    string GenerateMethodString(uint methodIndex, uint bp)
    {
        <string,variant> methodSymbols = Code.GetMethodSymbols(methodIndex);
        string methodName = methodSymbols["name"];
        string content = methodName + "(";
        if (methodSymbols.Contains("arguments"))
        {
            <string, <string> > argumentInfo = methodSymbols["arguments"];
            bool first = true;
            foreach (var kv in argumentInfo)
            {
                if (!first)
                {
                    content = content + ", ";
                }
                <string> argumentList = kv.value;
                content = content + argumentList[2] + "=";
                int delta;
                if (Int.TryParse(kv.key, ref delta))
                {
                }
                uint voffset = uint(int(bp) +  delta);
                uint toffset = TypeAddressFromValueAddress(voffset);
                uint value = GetPageWord(voffset);
                string vtype = argumentList[1];
                // TODO : validate against pageData[toffset];
                bool isReference = (argumentList[0] == "true");
                content = content + char(2) + TypeToString(value, vtype, isReference, 255) + char(3);
                first = false;
            }
        }
        content = content + ")";
        return content;
    }    
    PrintColors(string colorContent)
    {
        string contentBuffer;
        foreach (var ch in colorContent)
        {
            if (ch == char(2))
            {
                Print(contentBuffer);
                contentBuffer = "";   
            }
            else if (ch == char(3))
            {
                Print(contentBuffer, LightestGray, Black);
                contentBuffer = "";
            }
            else
            {
                contentBuffer = contentBuffer + ch;
            }
        }
        Print(contentBuffer);
    }
    OutputMethodLine(uint address, uint methodIndex, uint bp, bool sourceLevel, bool symbolsLoaded)
    {
        if (!sourceLevel)
        {
            Print("  0x" + address.ToHexString(4), LightestGray, Black);
            if (!symbolsLoaded)
            {
                PrintLn();
                return;
            }
        }
        <string,variant> methodSymbols = Code.GetMethodSymbols(methodIndex);
        string methodName = methodSymbols["name"];
        string methodSource = methodSymbols["source"];
        string methodLine   = methodSymbols["line"];
                            
        Print("  ");
        string sLine = Code.GetSourceIndex(address, methodIndex);
        uint iColon;
        if ((sLine != "") && sLine.IndexOf(':', ref iColon))
        {
            methodLine = sLine.Substring(iColon+1);
        }
        else
        {
            Print(address.ToHexString(4) + "?");
        }
        
        string methodString = GenerateMethodString(methodIndex, bp);
        PrintColors(methodString);
        
        Screen.SetCursor(Screen.Columns - 40, Screen.CursorY);
        uint lSlash;
        if (methodSource.LastIndexOf('/', ref lSlash))
        {
            methodSource = methodSource.Substring(lSlash+1);
        }
        Print(" // " + methodSource + ":" + methodLine, Comment, Black);
        PrintLn();
        if (false && methodSymbols.Contains("debug"))
        {
            <string,string> debugInfo = methodSymbols["debug"];
            foreach (var kv in debugInfo)
            {
                Print(kv.key + " ");
            }
            PrintLn();
        }
    }
    
    ShowCallStack(bool sourceLevel, bool symbolsLoaded)
    {
        ClearPageData();
        Pages.LoadZeroPage(false); // for CSP and PC
        //Pages.LoadPageData(0x04);
        //Pages.LoadPageData(0x05);
        //Pages.LoadPageData(0x06);
        bool stack8 = ZeroPageContains("BP8");
        if (!stack8)
        {
            //Pages.LoadPageData(0x07);
        }
        
        if (   ZeroPageContains("PC") && ZeroPageContains("CSP") && ZeroPageContains("CODESTART")
            //&& IsPageLoaded(0x04)
           )
        {
            //DumpMap();
            
            uint csp = GetZeroPage("CSP");
            if (csp > 0)
            {
                uint bp;
                uint tsp;
                uint address;
                uint methodIndex;
                
                PrintLn();            
                uint icsp = 2;
                while (icsp < csp)
                {
                    address = GetPageWord(0x0400+icsp);
                    bp      = GetPageWord(0x0400+icsp+2);
                    if (stack8)
                    {
                        bp  = 0x600 + bp;
                    }
                    address = address - (GetZeroPage("CODESTART") << 8);
                    methodIndex = LocationToIndex(address);
                    OutputMethodLine(address - 3, methodIndex, bp, sourceLevel, symbolsLoaded);
                    icsp = icsp + 4;
                }
                
                // current method
                uint pc = GetZeroPage("PC") - (GetZeroPage("CODESTART") << 8);
                methodIndex = LocationToIndex(pc);
                if (stack8)
                {
                    bp  = 0x600 + GetZeroPage("BP8");
                }
                else
                {
                    bp  = GetZeroPage("BP");
                }
                OutputMethodLine(pc, methodIndex, bp, sourceLevel, symbolsLoaded);
                if (symbolsLoaded)
                {
                    <uint, <string> > usedGlobals = Source.GetGlobals(methodIndex, 0);
                    foreach (var kv in usedGlobals)
                    {
                        uint goffset = kv.key;
                        <string> globalList = kv.value;
                        uint gaddress = goffset + 0x0600;
                        uint toffset = TypeAddressFromValueAddress(gaddress);
                        uint gvalue = GetPageWord(gaddress);
                        
                        string gtype = globalList[0];
                        // TODO : validate against pageData[toffset];
                        
                        string gcontent = char(2) + Source.TypeToString(gvalue, gtype, false, 255) + char(3);
                        
                        PrintLn();
                        PrintColors("    " + globalList[1] + "=" + gcontent);
                    }
                }
            }
        }
        else
        {
            Print("Failure in ShowCallStack(..)");
        }
    }
    
    ShowZeroPage()
    {
        Pages.LoadZeroPage(true);
        <string,uint> zeroPageEntries = Pages.GetZeroPageEntries();
        foreach (var kv in zeroPageEntries)
        {
            uint value = kv.value;
            string info = kv.key + ": ";
            info = info.Pad(' ', 11);
            byte digits = 2;
            if (value > 255)
            {
                digits = 4;
            }
            info = info + value.ToHexString(digits);
            
            PrintLn();
            Print(info, Color.LightestGray, Color.Black);
        }
    }
    ShowDisassembly(uint address, uint instructions)
    {
        if (!ZeroPageContains("CODESTART"))
        {
            Pages.LoadZeroPage(false);
        }
        if (ZeroPageContains("CODESTART"))
        {
            string content = address.ToHexString(4); // fallback content
            address = address - (GetZeroPage("CODESTART") << 8);
            bool first = true;
            loop
            {
                if ((address > 0) && (address < Source.GetCodeLength()))
                {
                    string sourceIndex = Code.GetSourceIndex(address);
                    if (sourceIndex.Length > 0)
                    {
                        string sourceLine = Code.GetSourceLine(sourceIndex);
                        if (sourceLine.Length > 0)
                        {
                            sourceLine = "      " + sourceLine.Trim();
                            sourceLine = sourceLine.Pad(' ', 60);
                            PrintLn();
                            Print(sourceLine, White, Black);    
                            Print("// " + sourceIndex, Color.Comment, Color.Black);
                        }
                    }
                    Instruction instruction = Instruction(Source.GetCode(address));
                    bool wasReturn = Instructions.IsRET(instruction);
                    content = Source.Disassemble(ref address);
                    PrintLn();
                    if (first)
                    {
                        Print("PC -> ", Color.MatrixRed, Color.Black);
                    }
                    else
                    {
                        Print("      ");
                    }
                    uint iComment;
                    string comment;
                    if (content.IndexOf("//", ref iComment))
                    {
                        comment = content.Substring(iComment);
                        content = content.Substring(0, iComment);        
                        content = content.Pad(' ', 54);
                    }
                    Print(content, Color.MatrixBlue, Color.Black);
                    Print(comment, Color.MatrixGreen, Color.Black);
                    if (wasReturn)
                    {
                        break;
                    }
                }
                else
                {
                    break;
                }
                instructions--;
                if (instructions == 0)
                {
                    break;
                }
                address++;
                first = false;
            } //loop
        }
    }
    
    ShowCurrentInstruction(uint instructions)
    {
        Monitor.Command("P", true, true);
        string serialOutput = Monitor.GetSerialOutput();
        serialOutput = "0x" + serialOutput.Substring(1);
        uint pc;
        if (UInt.TryParse(serialOutput, ref pc))
        {
            ShowDisassembly(pc, instructions);
        }
    }
    
    HopperLinePrinter(string ln, uint backColor)
    {
        ln = ln.Pad(' ', Screen.Columns);
        <uint> colours = Highlighter.Hopper(ln, backColor);
        uint length = ln.Length;
        for (uint i=0; i < length; i++)
        {
            uint colour = colours[i];
            char c = ln[i];
            Print(c, colour, backColor);
        }
    }
    ShowCurrentSource(uint lines, uint address)
    {
        Screen.Suspend();
        Screen.Clear();
        string sourceIndex = Code.GetSourceIndex(address);
        if (sourceIndex.Length > 0)
        {
            string sourceLine = Code.GetSourceLine(sourceIndex);
            if (sourceLine.Length > 0)
            {
                <string> parts = sourceIndex.Split(':');
                string lNum = parts[1];
                uint iLine;
                if (UInt.TryParse(lNum, ref iLine))
                {
                    Screen.SetCursor(0,1);
                    uint iCurrent = iLine;
                    uint delta = lines / 2;
                    while ((delta > 0) && (iCurrent > 1))
                    {
                        delta--;
                        iCurrent--;
                    }
                    loop
                    {
                        if (lines == 0)
                        {
                            break;
                        }
                        lines--;
                        sourceLine = Code.GetSourceLine(iCurrent);
                        uint backColor = Color.LightestGray;
                        if (iCurrent == iLine)
                        {
                            backColor = Color.LightGray;
                        }
                        HopperLinePrinter(sourceLine, backColor);  
                        if (false && (iCurrent == iLine))
                        {
                            Screen.SetCursor(Screen.Columns - 40, Screen.CursorY);
                            uint lSlash;
                            if (sourceIndex.LastIndexOf('/', ref lSlash))
                            {
                                sourceIndex = sourceIndex.Substring(lSlash+1);
                            }
                            Print(" // " + sourceIndex, Comment, backColor);
                        }
                        iCurrent++;
                    }
                }
                
            }
        }
        Screen.Resume(true);
    }
    
    bool ValidateHexPage(ref string hexpage)
    {
        bool valid = false;
        hexpage = hexpage.ToUpper();
    
        uint returnValue = 0;
        if (UInt.TryParse("0x" + hexpage, ref returnValue))
        {
            if ((returnValue >= 0x00) && (returnValue <= 0xFF))
            {
                valid = true;
                if (hexpage.Length == 1)
                {
                    hexpage = "0" + hexpage;
                }
            }
        }
        
        return valid;
    }
    PrintPad(string ln, uint padding)
    {
        while (padding > 0)
        {
            String.BuildFront(ref ln, ' ');
            padding--;
        }
        PrintLn(ln);
    }
    Welcome()
    {
        PrintLn();
        PrintLn("HopperMon");
        string info = Monitor.GetHopperInfo();
        PrintPad(info, 2);
    }
    
    Help()
    {
        PrintLn();
        PrintPad("Commands:", 2);
        PrintPad("?        - this", 4);
        PrintPad("Q        - exit, also <alt><F4>", 4);
        PrintLn();
        PrintPad("L <name> - load Hopper program (IHex file)", 4);
        PrintPad("D        - debug Hopper program, also <F5>", 4);
        PrintPad("X        - execute Hopper program, also <ctrl><F5>", 4);
        PrintPad("W        - warm restart of loaded Hopper program", 4);
        PrintPad("O        - step over, also <F10>", 4);
        PrintPad("I        - step into, also <F11>", 4);
        PrintPad("B X      - clear all breakpoints", 4);
        PrintPad("B x xxxx - set breakpoint 1..F", 4);
        PrintLn();
        PrintPad("C        - emit Hopper call stack", 4);
        PrintPad("V        - emit Hopper value stack", 4);
        PrintPad("R        - emit Hopper registers", 4);
        PrintPad("P        - emit Hopper PC", 4);
        PrintPad("H        - emit current Hopper heap objects", 4);
        PrintPad("M <page> - emit a 256 byte page of memory", 4);
        PrintPad("U        - profile: opCode and sysCall usage data, generates .csv", 4);
    }
    
    Interactive()
    {
        Screen.Clear();
        
        // if "Debug.options" exists, see it has a comPort set by Port.hexe:
        uint comPort;
        optionsPath = Path.MakeOptions("Debug.options");
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
        
        // drain garbage from serial and header rubbish (like from the Seeed XAIO ESP32 C3)
        //WaitForDeviceReady();
        
        // send a <ctrl><C> in case there is a program running
        Serial.WriteChar(char(0x03));
        
        Welcome();
        
        bool sourceLevel = false; // Hopper source code level debugging
        bool symbolsLoaded = false; // running auto.hexe or was L used?
        
        char currentCommand = ' ';
        string commandLine = "";
        bool refresh = true;
        loop
        {
            if (refresh)
            {
                SetCursor(0, Screen.CursorY);
                string ln = ">" + commandLine;
                uint cursorX = ln.Length;
                ln = ln.Pad(' ', Screen.Columns-1);
                Print(ln);
                SetCursor(cursorX, Screen.CursorY);
                refresh = false;
            }
            
            Key key;
            if (keyboardBuffer.Length > 0)
            {
                key = keyboardBuffer[0];
                keyboardBuffer.Remove(0);
            }
            else
            {
                key  = ReadKey();
            }
            char ch = key.ToChar();
            ch = ch.ToUpper();
            uint clength = commandLine.Length;
            
            // shortcut keys
            bool doShortcut = false;
            if (key == (Key.Alt | Key.F4))
            {
                commandLine = "Q";
                doShortcut = true;
            }
            else if (key == Key.F5)
            {
                commandLine = "D";
                doShortcut = true;
            }
            else if (key == (Key.Control | Key.F5))
            {
                commandLine = "X";
                doShortcut = true;
            }
            else if (key == Key.F11)
            {
                commandLine = "I";
                doShortcut = true;
            }
            else if (key == Key.F10)
            {
                commandLine = "O";
                doShortcut = true;
            }
            if (doShortcut)
            {
                currentCommand = commandLine[0];
                Print(commandLine);
                key = Key.Enter;
            }
            if (key == Key.Enter)
            {
                // execute commandLine
                if (currentCommand == 'Q') // exit monitor UI
                {
                    PrintLn();
                    break; 
                }
                else if (currentCommand == '?') // help
                {
                    Welcome();
                    Help();
                    refresh = true;
                }
                else if (currentCommand == 'Z') // zero page variables
                {
                    ShowZeroPage();
                    refresh = true;
                }
                else if (currentCommand == 'C') // show call stack
                {
                    ShowCallStack(sourceLevel, symbolsLoaded);
                    refresh = true;
                }
                else if (currentCommand == 'L') // ihex load
                {
                    string ihexPath = commandLine.Substring(2);
                    if (ValidateHexPath(ref ihexPath))
                    {
                        UploadHex(ihexPath);
                        refresh = true;
                        symbolsLoaded = true;
                    }
                } // case 'L'
                
                else if (currentCommand == 'M') // memory dump
                {
                    string hexpage = "";
                    if (commandLine.Length > 2)
                    {
                        hexpage = commandLine.Substring(2, commandLine.Length-2);
                        if (ValidateHexPage(ref hexpage))
                        {
                            Monitor.Command(commandLine.Substring(0,1) + hexpage, false, true);
                            refresh = true;
                        }
                    }
                } // case 'M'
                
                else if (currentCommand == 'F') // memory dump
                {
                    string hexpage = "";
                    if (commandLine.Length > 2)
                    {
                        hexpage = commandLine.Substring(2, commandLine.Length-2);
                        if (ValidateHexPage(ref hexpage))
                        {
                            Monitor.Command(commandLine.Substring(0,1) + hexpage, false, true);
                            refresh = true;
                        }
                    }
                } // case 'F'
                
                else if (currentCommand == 'B') // breakpoints
                {
                    if (commandLine == "B X")
                    {
                        Monitor.Command("BX", false, false);
                        refresh = true;
                    }
                    else if (commandLine.Length > 4)
                    {
                        string hex = "0x" + commandLine.Substring(2,1);
                        uint breakpoint;
                        if (UInt.TryParse(hex, ref breakpoint) && (breakpoint > 0))
                        {
                            hex = "0x" + commandLine.Substring(4);
                            uint address;
                            if (UInt.TryParse(hex, ref address) && (address > 0) && (address < 0x8000))
                            {
                                commandLine = "B" + breakpoint.ToHexString(1) + address.ToHexString(4);
                                Monitor.Command(commandLine, false, false);
                                refresh = true;
                            }
                        }
                    }
                } // case 'B'
                
                else if (currentCommand == 'U') // gather usage data
                {
                    PrintLn();
                    string lastHexPath = Monitor.GetCurrentHexPath();
                    if (lastHexPath.Length == 0)
                    {
                        Print("Nothing loaded yet to profile.");
                    }
                    else
                    {
                        string pages = "89AB";
                        <string> commands;
                        foreach (var page in pages)
                        {
                            commands.Append("M0" + page);
                        }
                        Monitor.Command(commands, true, true);
                        string profilePath = Path.GetFileName(lastHexPath);
                        profilePath = profilePath.ToLower();
                        profilePath = profilePath.Replace(".hex", ".csv");
                        profilePath = Path.Combine("/Debug", profilePath);
                        Profile(GetSerialOutput(), profilePath);
                        Print("Profile data saved to '" + profilePath  + "'");
                    }
                    refresh = true;
                } // case 'U'
                else if (currentCommand == 'X') // Execute (run with Warp)
                {
                    Monitor.RunCommand(commandLine);
                    refresh = true;
                }
                else if (   (currentCommand == 'D') // Debug (run with !Warp)
                         || (currentCommand == 'I') // Step (single / into / F11)
                         || (currentCommand == 'O') // Step (next / over / F10)
                        )
                {
                    Source.LoadSymbols();
                    Monitor.RunCommand(commandLine);
                    if (sourceLevel)
                    {
                        uint pc = Monitor.ReturnToDebugger(currentCommand);
                        if (pc != 0)
                        {
                            ShowCurrentSource(Screen.Rows / 2, pc);
                        }
                    }
                    else
                    {
                        ShowCurrentInstruction(3);
                    }
                    refresh = true;
                }
                else if (currentCommand == 'S') // Source
                {
                    Source.LoadSymbols();
                    ShowCurrentInstruction(15);
                    refresh = true;
                }
                else if (currentCommand == 'W') // Warm Restart (keep program, reset data)
                {
                    Monitor.Command(commandLine, false, false);
                    refresh = true;
                }
                else if (currentCommand == 'R') // Registers
                {
                    Monitor.Command(commandLine, false, true);
                    refresh = true;
                }
                else if (currentCommand == 'P') // raw PC (mostly used internally)
                {
                    Monitor.Command(commandLine, false, true);
                    refresh = true;
                }
                else if (currentCommand == 'V') // Value Stack
                {
                    Monitor.Command(commandLine, false, true);
                    refresh = true;
                }
                else if (currentCommand == 'H') // Heap
                {
                    Monitor.Command(commandLine, false, true);
                    refresh = true;
                }
                if (refresh)
                {
                    commandLine = "";
                    currentCommand = ' ';
                    PrintLn();
                }
            } // if (key == Key.Enter)
            else if (key == Key.Escape)
            {
                // cancel commandline
                commandLine = "";
                refresh = true;
            }
            else if (key == Key.ControlC)
            {
                // cancel commandline
                commandLine = "";
                Monitor.EmptyCommand();
                PrintLn("<ctrl><C>");
                refresh = true;
            }
            else if (key == Key.Backspace)
            {
                // back up one
                if (commandLine.Length > 0)
                {
                    commandLine = commandLine.Substring(0, commandLine.Length-1);
                    SetCursor(0, Screen.CursorY);
                    refresh = true;
                }
            }
            else
            { 
                // alphanumeric
                if (clength < Screen.Columns-1)
                {
                    if (clength == 0)
                    {
                        // first character must be command key
                        if (String.Contains("?BCDFHILMOPQRSUVWXZ", ch))
                        {
                            currentCommand = ch;
                        }
                        else
                        {
                            continue;
                        }
                    } // clength == 0
                    else if (clength == 1)
                    {
                        if (ch != ' ') // 2nd character must be ' '
                        {
                            continue;
                        }
                        if (currentCommand == 'L')
                        {
                            // has arguments
                        }
                        else if (currentCommand == 'M')
                        {
                            // has arguments
                        }
                        else if (currentCommand == 'F')
                        {
                            // has arguments
                        }
                        else if (currentCommand == 'B')
                        {
                            // has arguments
                        }
                        else
                        {
                            continue; // no arguments
                        }
                    } // clength == 1
                    else
                    {   // clength > 1
                        // arguments
                        if (currentCommand == 'L')
                        {
                            // L <ihex path>
                        }
                        else if (currentCommand == 'M')
                        {
                            // M n or nn (MSB hex for page)
                        }
                        else if (currentCommand == 'F')
                        {
                            // F n or nn (MSB hex for page)
                        }
                        else if (currentCommand == 'B')
                        {
                            // B X or B n nnnn
                        }
                        else
                        {
                            continue; // should never get here
                        }
                    } // clength > 1
                    
                    if (ch != char(0))
                    {
                        commandLine = commandLine + ch;
                        refresh = true;
                    }
                }  // if (commandLine.Length < Screen.Columns-1)
            } // alphanumeric
        } // loop
        Serial.Close();
    }
    
    bool ValidateHexPath(ref string ihexPath)
    {
        bool uploadHex = false; 
        loop
        {
            string extension = Path.GetExtension(ihexPath);
            extension = extension.ToLower();
            if (extension == ".")
            {
                ihexPath = ihexPath + ".hex";
            }
            else if (extension != ".hex")
            {
                break;
            }
            if (!File.Exists(ihexPath))
            {
                string fullPath = Path.Combine(System.CurrentDirectory, ihexPath);
                if (!File.Exists(fullPath))
                {
                    fullPath = Path.Combine("/Bin", ihexPath);   
                    if (!File.Exists(fullPath))
                    {
                        break;
                    }
                    else
                    {
                        ihexPath = fullPath;
                    }    
                }
                else
                {
                    ihexPath = fullPath;
                }
            }
            uploadHex = true; 
            break;
        }
        return uploadHex;
    }
    
    {
#ifdef CAPTURESERIAL
        Monitor.InitializeCapture();
#endif        
        Source.ClearSymbols();
        Output.SetPassThrough();
        
        <string> rawArgs = System.Arguments;
        bool invalidArguments = false;
        string ihexPath;
        bool uploadHex = false;
        bool executeAndExit = false;
        bool debugAndExit = false;
        loop // option block
        {
            for (uint i = 0; i < rawArgs.Length; i++)
            {
			             string arg = rawArgs[i];
         			    if ((arg.Length == 2) && arg.StartsWith('-'))
            				{
          				      arg = arg.ToLower();
                    if (arg == "-x")
               					{
                       executeAndExit = true;
                    }
                				else if (arg == "-d")
               					{
                       debugAndExit = true;
                    }
                				else if (arg == "-l")
               					{
					                   i++;
						                  if (i == rawArgs.Length)
						                  {
						                      invalidArguments = true;
                      				  break;
                  						}
                  						ihexPath = rawArgs[i];
                        uploadHex = ValidateHexPath(ref ihexPath);
                        if (!uploadHex)
                        {
                            string extension = Path.GetExtension(ihexPath);
                            if (extension != ".hex")
                            {
                                PrintLn("IHex file should have .hex extension.");
                                invalidArguments = true;
                        						  break;
                            }
                        }
					               }
                				else
                				{
                				    invalidArguments = true;
                						  break;
                				}
                }
            				else
            				{
            				    invalidArguments = true;
                    break;
            				}
			         } // for each argument
         			break;
        } // option block
        if (debugAndExit && executeAndExit)
        {
            invalidArguments = true;
        }
        loop // execution block
        {
            if (invalidArguments)
        		  {
        			     PrintLn("Invalid arguments for HopperMonitor:");
        			     PrintLn("  -l <name> : load IHex image to 6502 machine");
        			     PrintLn("  -x        : execute without debugging and exit (<ctrl><F5>)");
        			     PrintLn("  -d        : execute with debugging and exit (<F5>)");
        			     break;
        		  }
            if (uploadHex)
            {
                string fileName = Path.GetFileName(ihexPath);
                fileName = fileName.ToUpper();
                fileName = fileName.Replace(".HEX", "");
                Print("'" + fileName + "'");
                InjectText("L " + fileName);
                InjectKey(Key.Enter);
            }
            if (debugAndExit)
            {
                InjectText("D");
                InjectKey(Key.Enter);
                InjectText("Q");
                InjectKey(Key.Enter);
            }
            if (executeAndExit)
            {
                InjectText("X");
                InjectKey(Key.Enter);
                InjectText("Q");
                InjectKey(Key.Enter);
            }
            Interactive();
            break;
        } // execution block
    }
}
