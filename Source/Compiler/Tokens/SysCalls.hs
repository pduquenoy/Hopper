unit SysCalls
{
    <string,byte> syscalls;

    addEntry(string unitName, string methodName)
    {
        syscalls[unitName + '.' + methodName] = byte(syscalls.Count);
    }
    
    New()
    {
        syscalls.Clear(); // in case called a 2nd time
        
        addEntry("String", "NewFromConstant");
        addEntry("Char",   "ToString");
        addEntry("String", "New");
        addEntry("String", "Append");
        addEntry("String", "InsertChar");
        addEntry("String", "Compare");
        addEntry("String", "Length_Get");
        addEntry("String", "EndsWith");
        addEntry("String", "Substring");
        addEntry("String", "Replace");
        addEntry("String", "GetChar");
        
        addEntry("Array", "New");
        addEntry("Array", "Count_Get");
        addEntry("Array", "GetItem");
        addEntry("Array", "SetItem");
        
        addEntry("List", "New");
        addEntry("List", "Count_Get");
        addEntry("List", "Append");
        addEntry("List", "Insert");
        addEntry("List", "GetItem");
        addEntry("List", "GetItemAsVariant");
        addEntry("List", "SetItem");
        addEntry("List", "Clear");
        addEntry("List", "Remove");
        addEntry("List", "Contains");
        
        addEntry("Dictionary", "New");
        addEntry("Dictionary", "Count_Get");
        addEntry("Dictionary", "Set");
        addEntry("Dictionary", "Contains");
        addEntry("Dictionary", "Get");
        addEntry("Dictionary", "Next");
        addEntry("Dictionary", "Clear");
        
        addEntry("Pair", "New");
        addEntry("Pair", "Set");
        addEntry("Pair", "Key");
        addEntry("Pair", "KeyType");
        addEntry("Pair", "Value");
        addEntry("Pair", "ValueType");
        
        addEntry("Variant", "Type");
        addEntry("Variant", "Box");
        addEntry("Variant", "UnBox");
        
        addEntry("Screen", "Print");
        addEntry("Screen", "PrintLn");
        addEntry("Screen", "Clear");
        addEntry("Screen", "SetCursor");
        addEntry("Screen", "Columns_Get");
        addEntry("Screen", "Rows_Get");
        addEntry("Screen", "CursorX_Get");
        addEntry("Screen", "CursorY_Get");
        addEntry("Screen", "Suspend");
        addEntry("Screen", "Resume");
        addEntry("Screen", "DrawChar");
        
        addEntry("Int", "ToFloat");
        addEntry("Int", "ToLong");
        
        addEntry("UInt", "ToLong");
        addEntry("UInt", "ToInt");
        
        addEntry("Long", "ToString");
        addEntry("Long", "ToBytes");
        addEntry("Long", "ToFloat");
        addEntry("Long", "ToInt");
        addEntry("Long", "ToUInt");
        addEntry("Long", "New");
        addEntry("Long", "NewFromConstant");
        addEntry("Long", "Add");
        addEntry("Long", "Sub");
        addEntry("Long", "Div");
        addEntry("Long", "Mul");
        addEntry("Long", "Mod");
        addEntry("Long", "EQ");
        addEntry("Long", "LT");
        addEntry("Long", "LE");
        addEntry("Long", "GT");
        addEntry("Long", "GE");
        addEntry("Long", "Negate");
        
        addEntry("Float", "ToString");
        addEntry("Float", "ToBytes");
        addEntry("Float", "New");
        addEntry("Float", "NewFromConstant");
        addEntry("Float", "Add");
        addEntry("Float", "Sub");
        addEntry("Float", "Div");
        addEntry("Float", "Mul");
        addEntry("Float", "EQ");
        addEntry("Float", "LT");
        addEntry("Float", "LE");
        addEntry("Float", "GT");
        addEntry("Float", "GE");
        
        addEntry("Time", "Millis_Get");
        addEntry("Time", "Micros_Get");
        
        addEntry("System", "Arguments_Get");
        addEntry("System", "CurrentDirectory_Get");
        addEntry("System", "CurrentDirectory_Set");
        addEntry("System", "Beep");
        addEntry("System", "Execute"); // unused
        addEntry("System", "RegisterObject");
        
        addEntry("File", "Exists");
        addEntry("File", "New");
        addEntry("File", "Open");
        addEntry("File", "Create");
        addEntry("File", "ReadLine");
        addEntry("File", "Read");
        addEntry("File", "IsValid");
        addEntry("File", "Append");
        addEntry("File", "Flush");
        addEntry("File", "Delete");
        addEntry("File", "GetSize");
        
        addEntry("Directory", "Exists");
        addEntry("Directory", "New");
        addEntry("Directory", "IsValid");
        addEntry("Directory", "Open");
        addEntry("Directory", "GetDirectoryCount");
        addEntry("Directory", "GetFileCount");
        addEntry("Directory", "GetFile");
        addEntry("Directory", "GetDirectory");
        
        addEntry("Keyboard", "ReadKey");
        addEntry("Keyboard", "IsAvailable_Get");
        addEntry("Keyboard", "ToKey");
        
        addEntry("Keyboard", "ClickX_Get");
        addEntry("Keyboard", "ClickY_Get");
        addEntry("Keyboard", "ClickUp_Get");
        addEntry("Keyboard", "ClickDouble_Get");
        addEntry("Keyboard", "ScrollDelta_Get");
        
        addEntry("Diagnostics", "OutputDebug");
        addEntry("Diagnostics", "Assert");
        addEntry("Diagnostics", "Die");
        addEntry("Diagnostics", "SetError");

        addEntry("Types", "TypeOf");      // gives 'true' type (for instance, "variant" and not the boxed contents of a variant)
        addEntry("Types", "ValueTypeOf"); // if the type is a list, dictionary, pair or array, then return its value type
        addEntry("Types", "KeyTypeOf");   // if the type is a dictionary then return its key type
        addEntry("Types", "BoxTypeOf");   // regular "TypeOf" except for boxed variants where the boxed value type is returned (used for "typeof")
        addEntry("Types", "VerifyValueTypes");
        
        addEntry("String", "Build");
        
        //legacy
        addEntry("_WebServer", "Method_Get");
        addEntry("_WebServer", "URL_Get");
        addEntry("_WebServer", "Arguments_Get");
        addEntry("_WebServer", "On");
        addEntry("_WebServer", "Send");
        addEntry("_WebServer", "ClearHandlers");
        addEntry("_HttpClient", "GetRequest");
        
        addEntry("Runtime", "PC_Get");
        addEntry("Runtime", "SP_Get");
        addEntry("Runtime", "BP_Get");
        addEntry("Runtime", "CSP_Get");
        addEntry("Runtime", "GetStackWord");
        addEntry("Runtime", "GetStackType");
        addEntry("Runtime", "GetCallStackWord");
        addEntry("Runtime", "Execute");
        addEntry("Runtime", "Inline");
        addEntry("Runtime", "UserCode_Get");
        
        // legacy:
        addEntry("_Runtime", "Load");             // used by the windows shell debugger
        addEntry("_Runtime", "BytesLoaded_Get");  // used by the windows shell debugger
        addEntry("_Runtime", "Run");              // used by the windows shell debugger
        addEntry("_Runtime", "SetVisibility");    // Windows shell debugger: debug child window visible?
        addEntry("_Runtime", "SetStepping");
        addEntry("_Runtime", "StepInto");
        addEntry("_Runtime", "StepOver");
        addEntry("_Runtime", "StepRun");
        addEntry("_Runtime", "Waiting_Get");
        addEntry("_Runtime", "ClearBreakpoints");
        addEntry("_Runtime", "ClearStatements");
        addEntry("_Runtime", "SetBreakpoint");
        addEntry("_Runtime", "SetStatement");
        
        addEntry("Serial", "Connect");
        addEntry("Serial", "Close");
        addEntry("Serial", "IsValid");
        addEntry("Serial", "IsAvailable_Get");
        addEntry("Serial", "ReadChar");
        addEntry("Serial", "WriteChar");
        
        addEntry("Hardware", "LED_Set");
        
        addEntry("Memory", "ReadByte");
        addEntry("Memory", "WriteByte");
        addEntry("Memory", "Available");
        addEntry("Memory", "Maximum");
        addEntry("Memory", "Allocate");
        addEntry("Memory", "Free");
        
        addEntry("System", "Trace_Set");
        addEntry("System", "Trace_Get");
        
        addEntry("Dictionary", "HashKey");
        
        addEntry("Clipboard", "HasText_Get");
        addEntry("Clipboard", "GetText");
        addEntry("Clipboard", "SetText");
        
        addEntry("String", "BuildFront");
        
        addEntry("Memory", "ReadBit");
        addEntry("Memory", "WriteBit");
        
        addEntry("Char", "ToUpper");
        addEntry("Char", "IsUpper");
        addEntry("Char", "IsDigit");
        addEntry("Char", "IsLetterOrDigit");
        addEntry("Char", "IsLower");
        addEntry("Byte", "ToDigit");
        addEntry("Byte", "ToHex");
        addEntry("Char", "IsHexDigit");
        addEntry("Char", "ToLower");
        
        addEntry("String", "StartsWith");
        addEntry("String", "Contains");
        addEntry("String", "IndexOf");
        
        addEntry("System", "Warp_Set");
        addEntry("System", "Warp_Get");
        
        addEntry("Time", "Delay");
        
        addEntry("Long", "Inc");
        addEntry("Long", "AddRef");
        addEntry("Long", "MulRef");
        
        addEntry("Array", "GetItemUInt");
        addEntry("Array", "SetItemUInt");
        
        addEntry("System", "Inline");  // unused
        addEntry("Int", "ToBytes");
        
        addEntry("File", "GetTime");
        addEntry("Directory", "GetTime");
        
        addEntry("String", "Trim");
        addEntry("String", "TrimLeft");
        addEntry("String", "TrimRight");
        addEntry("String", "PushImmediate");
        addEntry("String", "ToUpper");
        addEntry("String", "ToLower");
        
        addEntry("Clipboard", "GetChar");
        
        addEntry("Memory", "ReadWord");
        addEntry("Memory", "WriteWord");
        
        addEntry("Unused", "PinMode");
        addEntry("Unused", "DigitalRead");
        addEntry("Unused", "DigitalWrite");
        
        addEntry("Memory", "ReadCodeByte");
        addEntry("Memory", "WriteCodeByte");
        addEntry("Memory", "ReadCodeWord");
        addEntry("Memory", "WriteCodeWord");
        
        addEntry("Long",   "GetByte");
        addEntry("Int",    "GetByte");
        addEntry("Float",  "GetByte");
        addEntry("Long",   "FromBytes");
        addEntry("Int",    "FromBytes");
        addEntry("Float",  "FromBytes");
        addEntry("UInt",   "ToFloat");
        addEntry("Serial", "Ports_Get");
        
        addEntry("System", "HexeVersion_Get");
        
        addEntry("Directory", "Create");
        addEntry("Directory", "Delete");
        
        addEntry("WiFi", "Connect");
        
        addEntry("Float", "ToUInt");
        addEntry("Float", "ToLong");
        
        addEntry("Long", "AddB");
        addEntry("Long", "SubB");
        
        addEntry("Array", "NewFromConstant");
        
        addEntry("WiFi", "IP_Get");
        
        addEntry("List", "Length_Get");
        
    }
    
    bool TryParseSysCall(string name, ref byte index)
    {
        bool success = false;
        if (syscalls.Contains(name))
        {
            index = syscalls[name];
            success = true;
        }
        return success;
    }
    
    string GetSysCallName(byte iSysCall)
    {
        string name;
        foreach (var kv in syscalls)
        {
            if (kv.value == iSysCall)
            {
                name = kv.key;
                break;
            }
        }
        return name;
    }
    <string,byte> GetSysCalls()
    {
        return syscalls;
    }
    
}
