unit HopperVM
{
    uses "Emulation/Minimal"
    uses "Emulation/Memory"
    
    uses "Platform/OpCodes"
    uses "Platform/Types"
    uses "Platform/SysCalls"
    
    uses "Platform/GC"
    uses "Platform/Array"
    uses "Platform/Dictionary"
    uses "Platform/Directory"
    uses "Platform/File"
    uses "Platform/Float"
    uses "Platform/Int"
    uses "Platform/List"
    uses "Platform/Long"
    uses "Platform/Pair"
    uses "Platform/String"
    uses "Platform/UInt"
    uses "Platform/Variant"
    
    uses "Platform/External"
    uses "Platform/Instructions"
    uses "Platform/Library"
    
#ifdef LOCALDEBUGGER
    uses "Platform/Desktop"
#endif    
    
    
    const uint stackSize     = 512; // size of value stack in byte (each stack slot is 2 bytes)
    const uint callStackSize = 512; // size of callstack in bytes (4 bytes per call)
    
    const uint dataMemoryStart = 0x0000; // data memory magically exists from 0x0000 to 0xFFFF
    
#ifdef RUNTIME    
    const uint keyboardBufferSize = 256;
#endif

#ifndef LOCALDEBUGGER
    const uint jumpTableSize   = 512; // 4 byte function pointer slots on Pi Pico
#else    
    const uint jumpTableSize   = 256; // 2 byte delegate slots, highest OpCode is currently 0x6A (256 will do until 0x7F)
#endif
    
    uint binaryAddress;
    uint programSize;
    
    uint constAddress;
    uint methodTable;
    uint programOffset;
    
#ifdef RUNTIME        
    uint keyboardBuffer;
#endif
    
    uint valueStack; // 2 byte slots
    uint typeStack;  // 2 byte slots (but we only use the LSB, just to be able to use the same 'sp' as valueStack)
    uint callStack;  // 2 byte slots (either return address PC or BP for stack from)
    
    uint dataMemory; // start of free memory (changes if a new program is loaded)
    
    uint breakpoints;
    bool breakpointExists;
    
    uint currentDirectory;
    uint currentArguments;
    
    uint pc;
    uint gp; // floor for globals (matters for child processes)
    uint sp;
    uint bp;
    uint csp;
    uint cspStart;
    bool cnp;
#ifdef CHECKED
    uint messagePC;
#endif    
    bool inDebugger;
    
    uint PC  { get { return pc; }  set { pc = value; } }
    uint SP  { get { return sp; }  set { sp = value; } }
    uint GP  { get { return gp; }  set { gp = value; } }
    uint CSP { get { return csp; } set { csp = value; } }
    uint CSPStart { get { return cspStart; } set { cspStart = value; } }
    bool CNP { get { return cnp; } set { cnp = value; } }
    uint BP  { get { return bp; }  set { bp = value; } }
    
    OpCode opCode;
    OpCode CurrentOpCode { get { return opCode; } }
    
    uint ValueStack { get { return valueStack; } }
    uint TypeStack  { get { return typeStack; } }
    uint CallStack  { get { return callStack; } }
    
    bool BreakpointExists { get { return breakpointExists; } }
    
    uint jumpTable; // 2 byte delegate slots for Instruction jumps
    
    
    ClearBreakpoints(bool includingZero)
    {
        for (byte i=2; i < 32; i = i + 2)
        {
            WriteWord(breakpoints + i, 0);
        }
        if (includingZero)
        {
            WriteWord(breakpoints, 0);
            breakpointExists = false;
        }
        else
        {
            breakpointExists = ReadWord(breakpoints) != 0; // single step breakpoint set?
        }
    }
    uint GetBreakpoint(byte n)
    {
        return ReadWord(breakpoints + n * 2);
    }
    
    SetBreakpoint(byte n, uint address)
    {
        WriteWord(breakpoints + n * 2,  address);
        if (address != 0)
        {
            breakpointExists = true;
        }
        else
        {
            breakpointExists = false;
            for (byte i=0; i < 32; i = i + 2)
            {
                if (ReadWord(breakpoints+i) != 0)
                {
                    breakpointExists = true;
                    break;
                }
            }
        }
    }
    
    Initialize(uint loadedAddress, uint loadedSize)
    {
        binaryAddress      = loadedAddress;
        programSize        = loadedSize;
        constAddress       = ReadCodeWord(binaryAddress + 0x0002);
        methodTable        = binaryAddress + 0x0006;
    }
    
    DataMemoryReset()
    {
        HRArray.Release();  // in case we were already called
#ifndef LOCALDEBUGGER
        External.WebServerRelease();
#endif
        
        uint nextAddress   = dataMemoryStart;
        callStack          = nextAddress;
        nextAddress        = nextAddress + callStackSize;
        
        valueStack         = nextAddress;
        nextAddress        = nextAddress + stackSize;
        
        typeStack          = nextAddress;
        nextAddress        = nextAddress + stackSize;
        
        jumpTable          = nextAddress;
        nextAddress        = nextAddress + jumpTableSize;
        
#ifdef RUNTIME        
        keyboardBuffer     = nextAddress;
        nextAddress        = nextAddress + keyboardBufferSize;
        IO.AssignKeyboardBuffer(keyboardBuffer);
#endif        
        
        Instructions.PopulateJumpTable(jumpTable);
        
        dataMemory         = nextAddress;
        
        if (dataMemory < 0x0800)
        {
            dataMemory = 0x0800; // after our 'fake' stack pages
        }
        
        // currently we have 64K on the Pi Pico (actually only 0xFF00 for various reasons)
        // to avoid any boundary condition issues in the heap allocator)
        // For Wemos D1 Mini, 32K segments so 0x8000
        Memory.Initialize(dataMemory, (External.GetSegmentPages() << 8) - dataMemory);

        breakpoints   = Memory.Allocate(32);
        ClearBreakpoints(true);
        HRArray.Initialize();
        currentDirectory = 0;
        currentArguments = 0;
    }
    Release()
    {
        HRArray.Release();
#ifndef LOCALDEBUGGER
        External.WebServerRelease();
#endif
        
        Memory.Free(breakpoints);
        breakpoints = 0;
        if (currentDirectory != 0)
        {
            GC.Release(currentDirectory);
            currentDirectory = 0;
        }
        if (currentArguments != 0)
        {
            GC.Release(currentArguments);
            currentArguments = 0;
        }
#ifdef MEMORYLEAKS
        TestMemory(0);
#endif
    }

    uint GetAppName(bool crc)
    {
        uint path = HRString.New();
        HRString.BuildChar(ref path, char('/'));
        HRString.BuildChar(ref path, char('B'));
        HRString.BuildChar(ref path, char('i'));
        HRString.BuildChar(ref path, char('n'));
        HRString.BuildChar(ref path, char('/'));
        HRString.BuildChar(ref path, char('A'));
        HRString.BuildChar(ref path, char('u'));
        HRString.BuildChar(ref path, char('t'));
        HRString.BuildChar(ref path, char('o'));
        HRString.BuildChar(ref path, char('.'));
        if (crc)
        {
            HRString.BuildChar(ref path, char('c'));
            HRString.BuildChar(ref path, char('r'));
            HRString.BuildChar(ref path, char('c'));
        }
        else
        {    
            HRString.BuildChar(ref path, char('h'));
            HRString.BuildChar(ref path, char('e'));
            HRString.BuildChar(ref path, char('x'));
            HRString.BuildChar(ref path, char('e'));
        }
        return path;
    }
    DiskSetup()
    {
        uint path = HRString.New();
        HRString.BuildChar(ref path, char('/'));
        HRString.BuildChar(ref path, char('B'));
        HRString.BuildChar(ref path, char('i'));
        HRString.BuildChar(ref path, char('n'));
        if (!HRDirectory.Exists(path))
        {
            HRDirectory.Create(path);
        }
        HRString.BuildClear(ref path);
        HRString.BuildChar(ref path, char('/'));
        HRString.BuildChar(ref path, char('T'));
        HRString.BuildChar(ref path, char('e'));
        HRString.BuildChar(ref path, char('m'));
        HRString.BuildChar(ref path, char('p'));
        if (!HRDirectory.Exists(path))
        {
            HRDirectory.Create(path);
        }
        GC.Release(path);
    }
    FlashProgram(uint codeLocation, uint codeLength, uint crc)
    {
        uint path = GetAppName(false);
        uint appFile = HRFile.CreateFromCode(path, codeLocation, codeLength);
        HRFile.Flush(appFile);
        GC.Release(appFile);
        GC.Release(path);   
        path = GetAppName(true); 
        uint crcFile = HRFile.Create(path);
        HRFile.Append(crcFile, byte(crc & 0xFF));
        HRFile.Append(crcFile, byte(crc >> 8));
        HRFile.Flush(crcFile);
        GC.Release(crcFile);
        GC.Release(path);   
    }
    Restart()
    {
        External.MCUClockSpeedSet(133); // RP2040 default
        DataMemoryReset();
        DiskSetup();
#ifndef LOCALDEBUGGER
        External.TimerInitialize(); // TODO : implement Timer on Windows
#endif        
        sp = 0;
        gp = 0;
        bp = 0;
        csp = 0;
        cspStart = csp;
        Error = 0;
        cnp = false;
        
        uint version = ReadCodeWord(binaryAddress + 0x0000);
        uint entryPoint = ReadCodeWord(binaryAddress + 0x0004);
        if (version > 0)
        {
            pc = 0;
            programOffset = entryPoint;
        }
        else
        {
            pc = entryPoint;
            programOffset = 0;
        }
        External.SetProgramOffset(programOffset);
    }
    
    uint RuntimeExecute(uint hrpath, uint hrargs)
    {
        uint result;
        
        
        // store
        uint previousArguments = currentArguments;
        currentArguments = hrargs;
        
        uint pcBefore = pc;
        uint spBefore = sp;
        uint bpBefore = bp;
        uint gpBefore = gp;
        uint cspBefore = csp;
        uint cspStartBefore = cspStart;
        
        // modified by Initialize(..)
        uint binaryAddressBefore = binaryAddress;
        uint programSizeBefore   = programSize;
        uint constAddressBefore  = constAddress;
        uint methodTableBefore   = methodTable;
        uint programOffsetBefore = programOffset;
        
        uint loadedAddress;
        uint codeLength;
        uint startAddress = binaryAddress + programSize;
        if (LoadHexe(hrpath, startAddress, ref loadedAddress, ref codeLength, false))
        {
            binaryAddress = loadedAddress;
            programSize   = codeLength;
            constAddress  = ReadCodeWord(binaryAddress + 0x0002) + startAddress;
            programOffset = ReadCodeWord(binaryAddress + 0x0004) + startAddress;
            External.SetProgramOffset(programOffset);
            methodTable   = binaryAddress + 0x0006;
            
            Error = 0;
            cnp = false;
            gp = sp;
            cspStart = csp;
            pc = 0;
            
            bool restart = HopperVM.InlinedExecuteWarp(false);
        }
        else if (Error == 0)
        {
            Error = 0x0E;
        }
        
        result = Error;
        
        // restore
        binaryAddress = binaryAddressBefore;
        programSize   = programSizeBefore;
        constAddress  = constAddressBefore;
        methodTable   = methodTableBefore;
        programOffset = programOffsetBefore;
        External.SetProgramOffset(programOffset);
        pc = pcBefore;
        gp = gpBefore;
        cspStart = cspStartBefore;
            
        if (result != 0) 
        {
            // Die happened, otherwise they should already be correct
            csp = cspBefore;
            sp  = spBefore;
            bp  = bpBefore;
            Error = 0;
        }
        
        currentArguments = previousArguments;
        return result;
    }
    
    
    uint LookupMethod(uint methodIndex)
    {
        methodIndex = (methodIndex & 0x3FFF);
        uint address = methodTable;
        loop
        {
            uint entry = ReadCodeWord(address);
            if (entry == methodIndex)
            {
                address = ReadCodeWord(address+2);
                break;
            }
            address = address + 4;
        } // loop
        return address;
    }
#ifdef CHECKED
    AssertChar(Type htype, uint value)
    {
        switch (htype)
        {
            case Type.Byte:
            case Type.UInt:
            case Type.Int:
            case Type.Char:
            {
                if (value > 255)
                {
                    ErrorDump(38);
                    Error = 0x0B; // system failure (internal error)
                }
            }
            default:
            {
                ErrorDump(37);
                Error= 0x0B; // system failure (internal error)
            }
        }
    }
    AssertByte(Type htype, uint value)
    {
        if (htype != Type.Byte)
        {
            AssertUInt(htype, value);
        }
        if (value > 255)
        {
            ErrorDump(129);
            Error = 0x0B; // system failure (internal error)
        }
    }
    AssertBool(Type htype, uint value)
    {
        if (htype != Type.Bool)
        {
            AssertUInt(htype, value);
        }
        if (value > 1)
        {
            ErrorDump(36);
            Error = 0x0B; // system failure (internal error)
        }
    }
    AssertLong(Type htype)
    {
        if (htype != Type.Long)
        {
            ErrorDump(74);
            Error = 0x0B; // system failure (internal error)
        }
    }
    AssertFloat(Type htype)
    {
        if (htype != Type.Float)
        {
            ErrorDump(99);
            Error = 0x0B; // system failure (internal error)
        }
    }
    AssertUInt(Type htype, uint value)
    {
        switch (htype)
        {
            case Type.Byte:
            case Type.Char:
            case Type.Bool:
            case Type.UInt:
            case Type.Type:
            {
            }
            case Type.Int:
            {
                if (value > 0x7FFF) // +int is ok, -int is not
                {
                    ErrorDump(35);
                    Error = 0x0D; // numeric type out of range / overflow
                }
            }
            default:
            {
                Write(' ');WriteHex(byte(htype)); Write(' ');ErrorDump(34);
                Error= 0x0B; // system failure (internal error)
            }
        }
    }
    AssertInt(Type htype)
    {
        AssertInt(htype, 0);
    }
    AssertInt(Type htype, uint value)
    {
        switch (htype)
        {
            case Type.Byte:
            case Type.Char:
            case Type.Bool:
            case Type.UInt:
            {
                if (value > 0x7FFF) // won't fit
                {
                    ErrorDump(61);
                    Error = 0x0D; // numeric type out of range / overflow
                }
            }
            case Type.Int:
            {
                
            }
            default:
            {
                WriteHex(byte(htype)); Write(' '); ErrorDump(33);
                Error= 0x0B; // system failure (internal error)
            }
        }
    }
    AssertReference(Type htype, uint value)
    {
        switch (htype)
        {
            case Type.Byte:
            case Type.UInt:
            case Type.Reference:
            {
            }
            default:
            {
                ErrorDump(32);
                Error= 0x0B; // system failure (internal error)
            }
        }
    }
#endif    
    bool ExecuteSysCall(byte iSysCall, uint iOverload)
    {
        bool doNext = true;
        switch (SysCalls(iSysCall))
        {
            case SysCalls.DiagnosticsDie:
            {
                doNext = Instructions.Die();
            }
            case SysCalls.RuntimeInline:
            {
                if (!RunInline())
                {
                    ErrorDump(165); Error= 0x0B; // nested call to inline code?
                    doNext = false;
                }
            }
            case SysCalls.RuntimeExecute:
            {
                Type ltype;
                uint args = Pop(ref ltype);
                Type stype;
                uint path = Pop(ref stype);
#ifdef CHECKED
                if (ltype != Type.List)
                {
                    ErrorDump(101);
                    Error = 0x0B; // system failure (internal error)
                }
                if (stype != Type.String)
                {
                    ErrorDump(101);
                    Error = 0x0B; // system failure (internal error)
                }
#endif     
                uint result = RuntimeExecute(path, args);
                GC.Release(args);
                GC.Release(path);
                Push(result, Type.UInt);
                doNext = false;
            }
            case SysCalls.RuntimeUserCodeGet:
            {
                Push(programSize, Type.UInt);
            }
            case SysCalls.RuntimeInDebuggerGet:
            {
                Push(inDebugger ? 1 : 0, Type.Bool);
            }
            case SysCalls.RuntimeDateTimeGet:
            {
                uint dateTime = RuntimeDateTime();
                Push(dateTime, Type.String);
            }
            
            case SysCalls.MemoryAvailable:
            {
                uint size = Memory.Available();
                Push(size, Type.UInt);
            }
            case SysCalls.MemoryMaximum:
            {
                uint size = Memory.Maximum();
                Push(size, Type.UInt);
            }
            case SysCalls.MemoryAllocate:
            {
                Type atype;
                uint size = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, size);
#endif       
                uint address = Memory.Allocate(size);
                Push(address, Type.UInt);
            }
            case SysCalls.MemoryFree:
            {
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, address);
#endif       
                Memory.Free(address);
            }
            case SysCalls.MemoryReadBit:
            {
                Type itype;
                uint index = Pop(ref itype);
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(itype, index);
                AssertUInt(atype, address);
#endif       
                address = address + (index >> 3);
                byte mask = (1 << (index & 0x07));
                byte value = Memory.ReadByte(address) & mask;
                Push((value != 0) ? 1 : 0, Type.Byte);
            }
            case SysCalls.MemoryWriteBit:
            {
                Type btype;
                uint data = Pop(ref btype);
                Type itype;
                uint index = Pop(ref itype);
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertByte(btype, data);
                AssertUInt(itype, index);
                AssertUInt(atype, address);
#endif       
                address = address + (index >> 3);
                byte mask = (1 << (index & 0x07));
                byte current = Memory.ReadByte(address);
                if (data == 0)
                {
                    Memory.WriteByte(address, byte(current & ~mask));
                }
                else
                {
                    Memory.WriteByte(address, byte(current | mask));
                }
            }
            
            case SysCalls.MemoryReadByte:
            {
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, address);
#endif       
                byte b = Memory.ReadByte(address);
                Push(b, Type.Byte);
            }
            case SysCalls.MemoryWriteByte:
            {
                Type btype;
                uint b = Pop(ref btype);
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertByte(btype, b);
                AssertUInt(atype, address);
#endif       
                Memory.WriteByte(address, byte(b));
            }
            case SysCalls.MemoryReadWord:
            {
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, address);
#endif       
                uint w = Memory.ReadWord(address);
                Push(w, Type.UInt);
            }
            case SysCalls.MemoryWriteWord:
            {
                Type btype;
                uint w = Pop(ref btype);
                Type atype;
                uint address = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(btype, w);
                AssertUInt(atype, address);
#endif       
                Memory.WriteWord(address, w);
            }
            case SysCalls.SystemArgumentsGet:
            {
                if (0 == currentArguments)
                {
                    currentArguments = HRList.New(Type.String);
                }
                Push(GC.Clone(currentArguments), Type.String);
            }
            case SysCalls.SystemCurrentDirectoryGet:
            {
                if (0 == currentDirectory)
                {
                    currentDirectory = HRString.NewFromConstant1(uint('/'));
                }
                Push(GC.Clone(currentDirectory), Type.String);
            }
            case SysCalls.SystemCurrentDirectorySet:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(101);
                    Error = 0x0B; // system failure (internal error)
                }
#endif     
                if (0 != currentDirectory)
                {
                    GC.Release(currentDirectory);
                }
                currentDirectory = GC.Clone(str);
                GC.Release(str);
            }
            case SysCalls.FileNew:
            {
                uint result = HRFile.New();
                Push(result, Type.File);        
            }
            case SysCalls.FileExists:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(102);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                bool result = HRFile.Exists(str);
                Push(result ? 1 : 0, Type.Bool);
                GC.Release(str);         
            }
            case SysCalls.FileIsValid:
            {
                Type stype;
                uint hrfile = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.File)
                {
                    ErrorDump(103);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                bool result = HRFile.IsValid(hrfile);
                Push(result ? 1 : 0, Type.Bool);        
                GC.Release(hrfile);         
            }
            case SysCalls.FileFlush:
            {
                Type stype;
                uint hrfile = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.File)
                {
                    ErrorDump(104);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                HRFile.Flush(hrfile);
                GC.Release(hrfile);         
            }
            
            case SysCalls.FileReadLine:
            {
                Type stype;
                uint hrfile = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.File)
                {
                    ErrorDump(105);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint str = HRFile.ReadLine(hrfile);
                GC.Release(hrfile);       
                Push(str, Type.String);  
            }
            case SysCalls.FileRead:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type stype;
                        uint hrfile = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.File)
                        {
                            ErrorDump(106);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint b = HRFile.Read(hrfile);
                        GC.Release(hrfile);       
                        Push(b, Type.Byte);  
                    }
                    case 1:
                    {
                        Type ltype;
                        uint hrlong = Pop(ref ltype);
                        Type stype;
                        uint hrfile = Pop(ref stype);
#ifdef CHECKED
                        if (ltype != Type.Long)
                        {
                            ErrorDump(107);
                            Error = 0x0B; // system failure (internal error)
                        }
                        if (stype != Type.File)
                        {
                            ErrorDump(108);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint b = HRFile.Read(hrfile, hrlong);
                        GC.Release(hrfile);       
                        GC.Release(hrlong);       
                        Push(b, Type.Byte);  
                    }
                    case 2:
                    {
                        Type ltype;
                        uint bufferSize = Pop(ref ltype);
                        Type atype;
                        uint hrarray = Pop(ref atype);
                        Type stype;
                        uint hrfile = Pop(ref stype);
#ifdef CHECKED
                        AssertUInt(ltype, bufferSize);
                        if (atype != Type.Array)
                        {
                            ErrorDump(108);
                            Error = 0x0B; // system failure (internal error)
                        }
                        if (stype != Type.File)
                        {
                            ErrorDump(108);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint bytesRead = HRFile.Read(hrfile, hrarray, bufferSize);
                        GC.Release(hrfile);       
                        GC.Release(hrarray);       
                        Push(bytesRead, Type.UInt);  
                    }
                }
            }
            case SysCalls.FileAppend:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        uint top = Pop();
                        Type stype;
                        uint hrfile = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.File)
                        {
                            ErrorDump(109);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        HRFile.Append(hrfile, byte(top));
                        GC.Release(hrfile);
                    }
                    case 1:
                    {
                        Type stype;
                        uint str = Pop(ref stype);
                        Type ftype;
                        uint hrfile = Pop(ref ftype);
#ifdef CHECKED
                        if (stype != Type.String)
                        {
                            ErrorDump(110);
                            Error = 0x0B; // system failure (internal error)
                        }
                        if (ftype != Type.File)
                        {
                            ErrorDump(111);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        HRFile.Append(hrfile, str);
                        GC.Release(str);
                        GC.Release(hrfile);
                    }
                }
            }
            
            case SysCalls.FileCreate:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(112);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.Create(str);
                Push(result, Type.File);        
                GC.Release(str);         
            }
            case SysCalls.FileOpen:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(113);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.Open(str);
                Push(result, Type.File);        
                GC.Release(str);         
            }
            case SysCalls.FileDelete:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(114);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                HRFile.Delete(str);
                GC.Release(str);         
            }
            case SysCalls.FileGetTimeStamp:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(115);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.GetTimeStamp(str);
                Push(result, Type.Long);        
                GC.Release(str);         
            }
            
            case SysCalls.FileGetTime:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(115);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.GetTime(str);
                Push(result, Type.String);        
                GC.Release(str);         
            }
            case SysCalls.FileGetDate:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(115);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.GetDate(str);
                Push(result, Type.String);        
                GC.Release(str);         
            }
            case SysCalls.DirectoryGetTime:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(115);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRDirectory.GetTime(str);
                Push(result, Type.String);        
                GC.Release(str);         
            }
            case SysCalls.DirectoryGetDate:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(115);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRDirectory.GetDate(str);
                Push(result, Type.String);        
                GC.Release(str);         
            }
            
            case SysCalls.FileGetSize:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(116);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRFile.GetSize(str);
                Push(result, Type.Long);        
                GC.Release(str);         
            }
            
            case SysCalls.DirectoryNew:
            {
                uint result = HRDirectory.New();
                Push(result, Type.Directory);        
            }
            case SysCalls.DirectoryExists:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(117);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                bool result = HRDirectory.Exists(str);
                Push(result ? 1 : 0, Type.Bool);        
                GC.Release(str);         
            }
            case SysCalls.DirectoryOpen:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(118);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRDirectory.Open(str);
                Push(result, Type.Directory);        
                GC.Release(str);         
            }
            case SysCalls.DirectoryIsValid:
            {
                Type stype;
                uint hrdir = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.Directory)
                {
                    ErrorDump(119);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                bool result = HRDirectory.IsValid(hrdir);
                Push(result ? 1 : 0, Type.Bool);        
                GC.Release(hrdir);         
            }
            case SysCalls.DirectoryGetFileCount:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type stype;
                        uint hrdir = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.Directory)
                        {
                            ErrorDump(120);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint result = HRDirectory.GetFileCount(hrdir);
                        Push(result, Type.UInt);        
                        GC.Release(hrdir);         
                    }
                    case 1:
                    {
                        Type utype;
                        uint address = Pop(ref utype);
                        uint skipped = Get(address, ref utype);
                        
                        Type stype;
                        uint hrdir = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.Directory)
                        {
                            ErrorDump(120);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint result = HRDirectory.GetFileCount(hrdir, ref skipped);
                        Push(result, Type.UInt);       
                        Put(address, skipped, Type.UInt); 
                        GC.Release(hrdir);         
                    }
                }
            }
            case SysCalls.DirectoryGetDirectoryCount:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type stype;
                        uint hrdir = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.Directory)
                        {
                            ErrorDump(121);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint result = HRDirectory.GetDirectoryCount(hrdir);
                        Push(result, Type.UInt);        
                        GC.Release(hrdir);         
                    }
                    case 1:
                    {
                        Type utype;
                        uint address = Pop(ref utype);
                        uint skipped = Get(address, ref utype);
                        
                        Type stype;
                        uint hrdir = Pop(ref stype);
#ifdef CHECKED
                        if (stype != Type.Directory)
                        {
                            ErrorDump(121);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif       
                        uint result = HRDirectory.GetDirectoryCount(hrdir, ref skipped);
                        Push(result, Type.UInt);    
                        Put(address, skipped, Type.UInt);     
                        GC.Release(hrdir);         
                    }
                }
            }
            case SysCalls.DirectoryGetFile:
            {
                Type itype;
                uint index = Pop(ref itype);
                Type stype;
                uint hrdir = Pop(ref stype);
#ifdef CHECKED
                AssertUInt(itype, index);
                if (stype != Type.Directory)
                {
                    ErrorDump(122);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRDirectory.GetFile(hrdir, index);
                Push(result, Type.String);        
                GC.Release(hrdir);         
            }
            case SysCalls.DirectoryGetDirectory:
            {
                Type itype;
                uint index = Pop(ref itype);
                Type stype;
                uint hrdir = Pop(ref stype);
#ifdef CHECKED
                AssertUInt(itype, index);
                if (stype != Type.Directory)
                {
                    ErrorDump(123);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                uint result = HRDirectory.GetDirectory(hrdir, index);
                Push(result, Type.String);        
                GC.Release(hrdir);         
            }
            case SysCalls.DirectoryDelete:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(124);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                HRDirectory.Delete(str);
                GC.Release(str);         
            }
            case SysCalls.DirectoryCreate:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(125);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                HRDirectory.Create(str);
                GC.Release(str);         
            }
            case SysCalls.SerialIsAvailableGet:
            {
                bool avail = Serial.IsAvailable;
                Push(uint(avail), Type.Bool);
            }
            case SysCalls.SerialReadChar:
            {
                char ch = Serial.ReadChar();
                Push(uint(ch), Type.Char);
            }
            case SysCalls.SerialWriteChar:
            {
                Type atype;
                uint ch = Pop(ref atype);
#ifdef CHECKED
                AssertChar(atype, ch);
#endif
                Serial.WriteChar(char(ch));
            }
            case SysCalls.SerialWriteString:
            {
                Type stype;
                uint str = Pop(ref stype);
#ifdef CHECKED
                if (stype != Type.String)
                {
                    ErrorDump(211);
                    Error = 0x0B; // system failure (internal error)
                }
#endif       
                External.SerialWriteString(str);
            }
            
            case SysCalls.LongNewFromConstant:
            {
                Type atype;
                uint location = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, location);
#endif
                uint address = HRLong.NewFromConstant(constAddress + location);
                Push(address, Type.Long);
            }
            
            case SysCalls.FloatNewFromConstant:
            {
                Type atype;
                uint location = Pop(ref atype);
#ifdef CHECKED
                AssertUInt(atype, location);
#endif
                uint address = HRFloat.NewFromConstant(constAddress + location);
                Push(address, Type.Float);
            }
            case SysCalls.StringNewFromConstant:
            {
                switch(iOverload)
                {
                    case 0:
                    {
                        Type ltype;
                        uint length  = Pop(ref ltype);
                        Type atype;
                        uint location = Pop(ref atype);
#ifdef CHECKED
                        AssertUInt(ltype, length);
                        AssertUInt(atype, location);
#endif
                        uint address = HRString.NewFromConstant0(constAddress + location, length);
                        Push(address, Type.String);
                    }
                    case 1:
                    {
                        Type utype;
                        uint doubleChar = Pop(ref utype);
#ifdef CHECKED
                        AssertUInt(utype, doubleChar);
#endif
                        uint address = HRString.NewFromConstant1(doubleChar);
                        Push(address, Type.String);
                    }
                    default:
                    {
                        ErrorDump(5);
                        Error = 0x0A; // iOverload
                    }
                }
            }
            case SysCalls.StringPushImmediate:
            {
                uint address = HRString.New();
                loop
                {
                    Type utype;
                    uint content = Pop(ref utype);
#ifdef CHECKED
                    AssertUInt(utype, content);
#endif
                    byte lsb = byte(content & 0xFF);
                    byte msb = byte(content >> 8);
                    if (lsb == 0)
                    {
                        break;
                    }
                    HRString.BuildChar(ref address, char(lsb));
                    if (msb == 0)
                    {
                        break;
                    }
                    HRString.BuildChar(ref address, char(msb));
                }
                Push(address, Type.String);
            }
        
            case SysCalls.StringNew:
            {
                uint address = HRString.New();
                Push(address, Type.String);
            }
            case SysCalls.StringLengthGet:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.String)
                {
                    WriteLn(); WriteHex(byte(ttype)); ErrorDump(30);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                uint length = HRString.GetLength(this);
                GC.Release(this);
                Push(length, Type.UInt);
            }
            case SysCalls.StringGetChar:
            {
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.String)
                {
                    ErrorDump(29);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                char ch = HRString.GetChar(this, index);
                GC.Release(this);
                Push(uint(ch), Type.Char);
            }
            case SysCalls.StringInsertChar:
            {
                Type atype;
                uint ch = Pop(ref atype);
                Type itype;
                uint index  = Pop(ref itype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertChar(atype, ch);
                AssertUInt(itype, index);
                if (ttype != Type.String)
                {
                    ErrorDump(28);
                    Error = 0x0B; // system failure (internal error)
                }
#endif             
                uint result = HRString.InsertChar(this, index, char(ch));
                GC.Release(this);
                Push(result, Type.String);                
            }
            case SysCalls.StringToUpper:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        // string ToUpper(string this)
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.ToUpper(this);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        // ToUpper(ref string build) system;
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(19);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.ToUpper(ref str);
                        Put(address, str, Type.String);
                    }
                }
            }
            case SysCalls.StringToLower:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        // string ToLower(string this)
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.ToLower(this);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        // ToUpper(ref string build) system;
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(19);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.ToLower(ref str);
                        Put(address, str, Type.String);
                    }
                }
            }
            case SysCalls.StringStartsWith:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertChar(atype, with);
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.StartsWith(this, char(with));
                        GC.Release(this);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    case 1:
                    {
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if ((atype != Type.String) || (ttype != Type.String))
                        {
                            ErrorDump(26);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.StartsWith(this, with);
                        GC.Release(this);
                        GC.Release(with);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    default:
                    {
                        ErrorDump(225);
                        Error = 0x0B; // system failure (internal error)
                    }
                } 
            }
            
            case SysCalls.StringContains:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertChar(atype, with);
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.Contains(this, char(with));
                        GC.Release(this);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    default:
                    {
                        ErrorDump(223);
                        Error = 0x0B; // system failure (internal error)
                    }
                } 
            }
            case SysCalls.StringIndexOf:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type htype;
                        uint address = Pop(ref htype);
                        uint index = Get(address, ref htype);
                        
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertUInt(htype, index);
                        AssertChar(atype, with);
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.IndexOf(this, char(with), ref index);
                        if (result)
                        {
                            Put(address, index, Type.UInt);
                        }
                        GC.Release(this);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    case 1:
                    {
                        Type htype;
                        uint address = Pop(ref htype);
                        uint index = Get(address, ref htype);
                        
                        Type itype;
                        uint searchIndex = Pop(ref itype);
                        
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertUInt(htype, index);
                        AssertUInt(itype, searchIndex);
                        AssertChar(atype, with);
                        if (ttype != Type.String)
                        {
                            ErrorDump(26);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.IndexOf(this, char(with), searchIndex, ref index);
                        if (result)
                        {
                            Put(address, index, Type.UInt);
                        }
                        GC.Release(this);
                        GC.Release(with);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    default:
                    {
                        ErrorDump(224);
                        Error = 0x0B; // system failure (internal error)
                    }
                } 
            }
            
            case SysCalls.StringEndsWith:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertChar(atype, with);
                        if (ttype != Type.String)
                        {
                            ErrorDump(27);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.EndsWith(this, char(with));
                        GC.Release(this);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    case 1:
                    {
                        Type atype;
                        uint with = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if ((atype != Type.String) || (ttype != Type.String))
                        {
                            ErrorDump(26);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        bool result = HRString.EndsWith(this, with);
                        GC.Release(this);
                        GC.Release(with);
                        Push(result ? 1 : 0, Type.Bool);
                    }
                    
                }  
            }
            case SysCalls.StringCompare:
            {
                Type atype;
                uint right = Pop(ref atype);
                Type btype;
                uint left  = Pop(ref btype);
#ifdef CHECKED
                if ((atype != Type.String) || (btype != Type.String))
                {
                    WriteLn(); WriteHex(byte(btype)); Write('='); WriteHex(byte(atype)); ErrorDump(77);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                int result = HRString.Compare(left, right);
                GC.Release(right);
                GC.Release(left);
                PushI(result);
            }
            case SysCalls.StringReplace:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint to     = Pop(ref atype);
                        Type btype;
                        uint from   = Pop(ref btype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if ((atype != Type.String) || (btype != Type.String) || (ttype != Type.String))
                        {
                            ErrorDump(25);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Replace(this, from, to);
                        GC.Release(this);
                        GC.Release(to);
                        GC.Release(from);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        Type atype;
                        uint to   = Pop(ref atype);
                        Type btype;
                        uint from   = Pop(ref btype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertChar(atype, to);
                        AssertChar(btype, from);
                        if (ttype != Type.String)
                        {
                            ErrorDump(24);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Replace(this, char(from), char(to));
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                }    
            }
            case SysCalls.StringAppend:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint append = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        if ((atype != Type.String) || (ttype != Type.String))
                        {
                            ErrorDump(23);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Append(this, append);
                        GC.Release(this);
                        GC.Release(append);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        Type atype;
                        uint append = Pop(ref atype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertChar(atype, append);
                        if (ttype != Type.String)
                        {
                            ErrorDump(22);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Append(this, char(append));
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                }   
            }
            case SysCalls.StringSubstring:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type stype;
                        uint start = Pop(ref stype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertUInt(stype, start);
                        if (ttype != Type.String)
                        {
                            ErrorDump(21);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Substring(this, start);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        Type ltype;
                        uint limit = Pop(ref ltype);
                        Type stype;
                        uint start = Pop(ref stype);
                        Type ttype;
                        uint this = Pop(ref ttype);
#ifdef CHECKED
                        AssertUInt(ltype, limit);
                        AssertUInt(stype, start);
                        if (ttype != Type.String)
                        {
                            ErrorDump(20);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Substring(this, start, limit);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 2:
                    {
                        Type stype;
                        uint start = Pop(ref stype);
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        AssertUInt(stype, start);
                        if (htype != Type.String)
                        {
                            ErrorDump(19);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.Substring(ref str, start);
                        Put(address, str, Type.String);
                    }
                    default:
                    {
                        ErrorDump(18);
                        Error = 0x0B;
                    }
                }   
            }
            case SysCalls.StringBuild:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type atype;
                        uint append = Pop(ref atype);
#ifdef CHECKED
                        if (atype != Type.String)
                        {
                            ErrorDump(43);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(17);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.BuildString(ref str, append);
                        Put(address, str, Type.String);
                        GC.Release(append);
                    }
                    case 1:
                    {
                        Type htype;
                        char ch = char(Pop(ref htype));
#ifdef CHECKED
                        AssertChar(htype, byte(ch));
#endif                
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(17);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.BuildChar(ref str, ch);
                        Put(address, str, Type.String);
                    }
                    case 2:
                    {
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(17);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.BuildClear(ref str);
                        Put(address, str, Type.String);                        
                    }
                    default:
                    {
                        ErrorDump(42);
                        Error = 0x0B;
                    }
                }
            }
            case SysCalls.StringBuildFront:
            {
                Type htype;
                char ch = char(Pop(ref htype));
#ifdef CHECKED
                AssertChar(htype, byte(ch));
#endif                
                uint address = Pop(ref htype);
                uint str = Get(address, ref htype);
#ifdef CHECKED
                if (htype != Type.String)
                {
                    ErrorDump(16);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                HRString.BuildFront(ref str, ch);
                Put(address, str, Type.String);
            }
            case SysCalls.StringTrim:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type htype;
                        uint this = Pop(ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(14);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.Trim(this);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(15);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.TrimRight(ref str);
                        HRString.TrimLeft(ref str);
                        Put(address, str, Type.String);
                    }
                    default:
                    {
                        ErrorDump(4);
                        Error = 0x0A; // iOverload
                    }
                }
            }
            case SysCalls.StringTrimLeft:
            {
                switch (iOverload)
                {
                    case 0:
                    {
                        Type htype;
                        uint this = Pop(ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(14);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        uint result = HRString.TrimLeft(this);
                        GC.Release(this);
                        Push(result, Type.String);
                    }
                    case 1:
                    {
                        Type htype;
                        uint address = Pop(ref htype);
                        uint str = Get(address, ref htype);
#ifdef CHECKED
                        if (htype != Type.String)
                        {
                            ErrorDump(14);
                            Error = 0x0B; // system failure (internal error)
                        }
#endif        
                        HRString.TrimLeft(ref str);
                        Put(address, str, Type.String);
                    }
                    default:
                    {
                        ErrorDump(3);
                        Error = 0x0A; // iOverload
                    }
                }
            }
            case SysCalls.StringTrimRight:
            {
                Type htype;
                uint address = Pop(ref htype);
                uint str = Get(address, ref htype);
#ifdef CHECKED
                if (htype != Type.String)
                {
                    ErrorDump(68);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                HRString.TrimRight(ref str);
                Put(address, str, Type.String);
            }
            
            case SysCalls.WiFiConnect:
            {
                Type ptype;    
                uint password = Pop(ref ptype);
                Type stype;    
                uint ssid = Pop(ref stype);
#ifdef CHECKED
                if ((stype != Type.String) || (ptype != Type.String))
                {
                    ErrorDump(16);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                bool success = External.WiFiConnect(ssid, password);
                GC.Release(ssid);
                GC.Release(password);
                Push(success ? 1 : 0, Type.Bool);                
            }
            case SysCalls.WiFiIPGet:
            {
                uint ip = External.WiFiIP();
                Push(ip, Type.String);                
            }
            case SysCalls.WiFiStatusGet:
            {
                uint status = External.WiFiStatus();
                Push(status, Type.UInt);                
            }
            case SysCalls.WiFiDisconnect:
            {
                External.WiFiDisconnect();
            }
            
            case SysCalls.ArrayNew:
            {   
                Type stype;
                Type htype = Type(Pop(ref stype));
#ifdef CHECKED
                if (IsReferenceType(htype))
                {
                    ErrorDump(12);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint count = Pop(ref stype);
#ifdef CHECKED
                AssertUInt(htype, count);
#endif
                uint address = HRArray.New(htype, count);
                Push(address, Type.Array);
            }
            case SysCalls.ArrayNewFromConstant:
            {   
                Type stype;
                Type ltype;
                Type htype = Type(Pop(ref stype));
#ifdef CHECKED
                if (IsReferenceType(htype))
                {
                    ErrorDump(12);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint length = Pop(ref stype);
                uint location = Pop(ref stype);
#ifdef CHECKED
                AssertUInt(stype, length);
                AssertUInt(ltype, location);
#endif
                uint address = HRArray.NewFromConstant(constAddress + location, htype, length);
                Push(address, Type.Array);
            }
            
            case SysCalls.ArrayGetItem:
            {
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.Array)
                {
                    ErrorDump(11);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                Type etype;
                uint item = HRArray.GetItem(this, index, ref etype);
                GC.Release(this);
                Push(item, etype);
            }
            case SysCalls.ArraySetItem:
            {
                Type itype;
                uint item = Pop(ref itype);
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if ((ttype != Type.Array) || IsReferenceType(itype))
                {
                    WriteHex(this); Write(' '); WriteHex(byte(ttype)); Write(' '); WriteHex(byte(itype)); Write(' '); ErrorDump(164);
                    Error = 0x0B; // system failure (internal error)
                }
#endif        
                HRArray.SetItem(this, index, item);
                GC.Release(this);
            }
            case SysCalls.ArrayCountGet:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Array)
                {
                    ErrorDump(53);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                uint length = HRArray.GetCount(this);
                GC.Release(this);
                Push(length, Type.UInt);
            }
          
            
            case SysCalls.ListNew:
            {   
                Type stype;
                Type htype = Type(Pop(ref stype));
                uint address = HRList.New(htype);
                Push(address, Type.List);
            }
            case SysCalls.ListCountGet:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.List)
                {
                    ErrorDump(53);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                uint count = HRList.GetCount(this);
                GC.Release(this);
                Push(count, Type.UInt);
            }
            case SysCalls.ListAppend:
            {
                Type itype;
                uint item = Pop(ref itype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.List)
                {
                    ErrorDump(54);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                HRList.Append(this, item, itype);
                if (IsReferenceType(itype))
                {
                    GC.Release(item);    
                }
                GC.Release(this);
            }
            case SysCalls.ListSetItem:
            {
                Type itype;
                uint item  = Pop(ref itype);
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.List)
                {
                    ErrorDump(57);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                    
                HRList.SetItem(this, index, item, itype);
                if (IsReferenceType(itype))
                {
                    GC.Release(item);
                }
                GC.Release(this);
            }
            case SysCalls.ListInsert:
            {
                Type itype;
                uint item  = Pop(ref itype);
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.List)
                {
                    ErrorDump(55);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                    
                HRList.Insert(this, index, item, itype);
                if (IsReferenceType(itype))
                {
                    GC.Release(item);
                }
                GC.Release(this);
            }
            case SysCalls.ListGetItem:
            {
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.List)
                {
                    ErrorDump(56);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                Type itype;
                uint item = HRList.GetItem(this, index, ref itype);
                GC.Release(this);
                Push(item, itype);
            }
            case SysCalls.ListGetItemAsVariant:
            {
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.List)
                {
                    ErrorDump(127);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                Type itype;
                uint item = HRList.GetItem(this, index, ref itype);
                if (!IsReferenceType(itype))
                {
                    item = HRVariant.CreateValueVariant(item, itype);
                    itype = Type.Variant;
                }
                //PrintLn(item.ToHexString(4) + " " + (ReadWord(item)).ToHexString(4) + " ");
                GC.Release(this);
                Push(item, itype);
            }
            
            case SysCalls.ListClear:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.List)
                {
                    ErrorDump(58);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                    
                HRList.Clear(this);
                GC.Release(this);
            }
            case SysCalls.ListRemove:
            {
                Type atype;
                uint index = Pop(ref atype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(atype, index);
                if (ttype != Type.List)
                {
                    ErrorDump(72);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                HRList.Remove(this, index);
                GC.Release(this);
            }
            case SysCalls.ListContains:
            {
                Type itype;
                uint item = Pop(ref itype);
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.List)
                {
                    ErrorDump(60);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                bool contains = HRList.Contains(this, item, itype);
                if (IsReferenceType(itype))
                {
                    GC.Release(item);    
                }
                GC.Release(this);
                Push(contains ? 1 : 0, Type.Bool);
            }
            
            case SysCalls.PairNew:
            {
                Type vtype;
                uint value = Pop(ref vtype);
                Type ktype;
                uint key = Pop(ref ktype);
#ifdef CHECKED
                if (IsReferenceType(ktype) && (ktype != Type.String))
                {
                    ErrorDump(85);
                    Error = 0x0B; // system failure (internal error) - only reference type allowed for key is String
                }
#endif
                uint address = HRPair.New(ktype, key, vtype, value);
                Push(address, Type.Pair);
            }
            
            case SysCalls.VariantBox:
            {
                Type vvtype;
                Type vtype = Type(Pop(ref vvtype));
                Type vttype;
                uint value = Pop(ref vttype);
                uint address = HRVariant.New(value, vtype);
                Push(address, Type.Variant);
            }
            case SysCalls.VariantUnBox:
            {
                Type vType;
                uint this = Pop(ref vType);
#ifdef CHECKED
                if (vType != Type.Variant)
                {
                    ErrorDump(81);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                Type mType;
                uint member = HRVariant.UnBox(this, ref mType);
                Push(member, mType);
                GC.Release(this);
            }
            
            case SysCalls.PairValue:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Pair)
                {
                    ErrorDump(81);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                Type vtype;
                uint value = HRPair.GetValue(this, ref vtype);
                GC.Release(this);
                Push(value, vtype);
            }
            case SysCalls.PairKey:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Pair)
                {
                    ErrorDump(81);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                Type ktype;
                uint key = HRPair.GetKey(this, ref ktype);
                GC.Release(this);
                Push(key, ktype);
            }
            
            case SysCalls.TypesTypeOf:
            {
                Type ttype;
                uint this = Pop(ref ttype);
                if (IsReferenceType(ttype))
                {
                    GC.Release(this);
                }
                Push(byte(ttype), Type.Type);
            }
            case SysCalls.TypesBoxTypeOf:
            {
                Type ttype;
                uint this = Pop(ref ttype);
                if (IsReferenceType(ttype))
                {
                    ttype = Type(ReadByte(this));
                    if (ttype == Type.Variant)
                    {
                        ttype = Type(ReadByte(this+2));
                    }
                    GC.Release(this);
                }
                Push(byte(ttype), Type.Type);
            }
            case SysCalls.TypesVerifyValueTypes:
            {
                Type ttype;
                Type memberType = Type(Pop(ref ttype));
                uint this = Pop(ref ttype);
                bool success = true;
                switch (ttype)
                {
                    case Type.List:
                    {
                        // verify that all members of the list are of type valueType
                        uint count = HRList.GetCount(this);
                        for (uint i = 0; i < count; i++)
                        {
                            Type itype;
                            uint item = HRList.GetItem(this, i, ref itype);
                            if (IsReferenceType(itype))
                            {
                                GC.Release(item);
                            }
                            if (itype != memberType)
                            {
                                success = false;
                                break;
                            }
                        }
                    }
                    case Type.Dictionary:
                    {
                        // verify that all members of the dictionary are of type valueType
                        uint iterator;
                        uint hrpair;
                        while(HRDictionary.Next(this, ref iterator, ref hrpair))
                        {
                            Type vtype = HRPair.GetValueType(hrpair);
                            GC.Release(hrpair);
                            if (vtype != memberType)
                            {
                                success = false;
                                break;
                            }
                        }
                    }
                    default:
                    {
                        ErrorDump(12);
                        Error = 0x0B;
                    }
                }
                Push(success ? 1 : 0, Type.Bool);
                GC.Release(this);
            }
            
            
            case SysCalls.TypesKeyTypeOf:
            {
                Type vtype;
                uint this = Pop(ref vtype);
                switch (vtype)
                {
                    case Type.Dictionary:
                    {
                        Push(uint(HRDictionary.GetKeyType(this)), Type.Type);
                    }
                    case Type.Pair:
                    {
                        Push(uint(HRPair.GetKeyType(this)), Type.Type);
                    }
                    default:
                    {
                        ErrorDump(11);
                        Error = 0x0B; // system failure (internal error)
                    }
                } // switch
                if (IsReferenceType(vtype))
                {
                    GC.Release(this);
                }
            }
            case SysCalls.TypesValueTypeOf:
            {
                Type vtype;
                uint this = Pop(ref vtype);
                switch (vtype)
                {
                    case Type.Dictionary:
                    {
                        Push(uint(HRDictionary.GetValueType(this)), Type.Type);
                    }
                    case Type.Pair:
                    {
                        Push(uint(HRPair.GetValueType(this)), Type.Type);
                    }
                    case Type.List:
                    {
                        Push(uint(HRList.GetValueType(this)), Type.Type);
                    }
                    case Type.Array:
                    {
                        Push(uint(HRArray.GetValueType(this)), Type.Type);
                    }
                    default:
                    {
                        if (!IsReferenceType(vtype))
                        {
                            // box variant
                            Push(uint(HRVariant.GetValueType(this)), Type.Type);
                        }
                        else
                        {
                            ErrorDump(10);
                            Error = 0x0B; // system failure (internal error)
                        }
                    }
                } // switch
                if (IsReferenceType(vtype))
                {
                    GC.Release(this);
                }
            }
            
            case SysCalls.DictionaryNew:
            {   
                Type stype;
                Type vtype = Type(Pop(ref stype));
                Type ktype = Type(Pop(ref stype));
#ifdef CHECKED
                if (IsReferenceType(ktype) && (ktype != Type.String))
                {
                    ErrorDump(9);
                    Error = 0x0B; // system failure (internal error) - only reference type allowed for key is String
                }
#endif
                uint address = HRDictionary.New(ktype, vtype);
                Push(address, Type.Dictionary);
            }
            
            case SysCalls.DictionaryCountGet:
            {
                Type ttype;
                uint this = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(81);
                    Error = 0x0B; // system failure (internal error)
                }
#endif    
                uint count = HRDictionary.GetCount(this);
                GC.Release(this);
                Push(count, Type.UInt);
            }
            
            case SysCalls.DictionarySet:
            {
                Type vtype;
                uint value  = Pop(ref vtype);
                Type ktype;
                uint key = Pop(ref ktype);
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(82);
                    Error = 0x0B; // system failure (internal error)
                    return false;
                }
#endif                    
                HRDictionary.Set(this, key, ktype, value, vtype);
                if (IsReferenceType(ktype))
                {
                    GC.Release(key);
                }
                if (IsReferenceType(vtype))
                {
                    GC.Release(value);
                }
                GC.Release(this);
            }
            
            case SysCalls.DictionaryNext:
            {
                Type htype;
                uint iterator = Pop(ref htype);
                
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                AssertUInt(htype, iterator);
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(89);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                  
                uint hrpair;
                uint found = HRDictionary.Next(this, ref iterator, ref hrpair) ? 1 : 0;
                
                GC.Release(this);
                Push(found, Type.Bool);
                Push(hrpair, Type.Pair);    
                Push(iterator, Type.UInt);    
            }
            
            case SysCalls.DictionaryContains:
            {
                Type ktype;
                uint key = Pop(ref ktype);
                
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                if (ktype != Type.String)
                {
                    AssertUInt(ktype, key);
                }
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(87);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                  
                uint found = HRDictionary.Contains(this, key) ? 1 : 0;
                if (ktype == Type.String)
                {
                    GC.Release(key);
                }
                GC.Release(this);
                Push(found, Type.Bool);
            }
            
            case SysCalls.DictionaryGet:
            {
                Type ktype;
                uint key = Pop(ref ktype);
                
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                if (ktype != Type.String)
                {
                    AssertUInt(ktype, key);
                }
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(88);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                  
                Type vtype;
                uint result = HRDictionary.Get(this, key, ref vtype);
                if (ktype == Type.String)
                {
                    GC.Release(key);
                }
                GC.Release(this);
                Push(result, vtype);
            }
            case SysCalls.DictionaryClear:
            {
                Type ttype;
                uint this  = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Dictionary)
                {
                    ErrorDump(90);
                    Error = 0x0B; // system failure (internal error)
                }
#endif                  
                HRDictionary.Clear(this);
                GC.Release(this);
            }
            
            case SysCalls.CharToString:
            {
                Type utype;
                uint singleChar = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, singleChar);
#endif
                uint address = HRString.NewFromConstant1(singleChar);
                Push(address, Type.String);
            }
            case SysCalls.CharToUpper:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.ToUpper(char(ch))), Type.Char);
            }
            case SysCalls.CharToLower:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.ToLower(char(ch))), Type.Char);
            }
            case SysCalls.CharIsUpper:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.IsUpper(char(ch))), Type.Bool);
            }
            case SysCalls.CharIsLower:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.IsLower(char(ch))), Type.Bool);
            }
            case SysCalls.CharIsDigit:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.IsDigit(char(ch))), Type.Bool);
            }
            case SysCalls.CharIsLetterOrDigit:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.IsLetterOrDigit(char(ch))), Type.Bool);
            }
            case SysCalls.CharIsHexDigit:
            {
                Type utype;
                uint ch = Pop(ref utype);
#ifdef CHECKED
                AssertChar(utype, ch);
#endif
                Push(byte(HRChar.IsHexDigit(char(ch))), Type.Bool);
            }
            
            case SysCalls.ByteToDigit:
            {
                Type htype;
                uint b = byte(Pop(ref htype));
#ifdef CHECKED
                if (b > 9) // 0..9 ok
                {
                    ErrorDump(8);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                Push(byte(HRByte.ToDigit(byte(b))), Type.Char);
            }
            case SysCalls.ByteToHex:
            {
                Type htype;
                uint b = byte(Pop(ref htype));
#ifdef CHECKED
                if (b > 0x0F) // 0..F ok
                {
                    ErrorDump(8);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                Push(byte(HRByte.ToHex(byte(b))), Type.Char);
            }
            
            case SysCalls.UIntToLong:
            {
                Type htype;
                uint value = Pop(ref htype);
#ifdef CHECKED
                AssertUInt(htype, value);
#endif
                uint lng = HRUInt.ToLong(value);
                Push(lng, Type.Long);
            }
            
            
            case SysCalls.UIntToInt:
            {
                Type htype;
                uint value = Pop(ref htype);
#ifdef CHECKED
                AssertUInt(htype, value);
                if (value > 32767)
                {
                    ErrorDump(131);
                    Error = 0x0D; // system failure (internal error)
                }
#endif        
                PushI(int(value));             
            }
            
            case SysCalls.IntToLong:
            {
                Type htype;
                uint ichunk = Pop(ref htype);
#ifdef CHECKED
                AssertInt(htype, ichunk);
#endif
                uint lng = HRInt.ToLong(ichunk);
                Push(lng, Type.Long);
            }
            case SysCalls.IntToFloat:
            {
                Type htype;
                int ichunk = PopI(ref htype);
                uint f = External.IntToFloat(ichunk);
                Push(f, Type.Float);
            }
            case SysCalls.UIntToFloat:
            {
                Type htype;
                uint ichunk = Pop(ref htype);
#ifdef CHECKED
                AssertUInt(htype, ichunk);
#endif
                uint f = External.UIntToFloat(ichunk);
                Push(f, Type.Float);
            }
            case SysCalls.IntToBytes:
            {
                Type htype;
                uint ichunk = Pop(ref htype);
#ifdef CHECKED
                AssertInt(htype, ichunk);
#endif
                uint lst = HRInt.ToBytes(ichunk);
                Push(lst, Type.List);
            }
            case SysCalls.LongToBytes:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertLong(htype);
#endif
                uint lst = HRLong.ToBytes(this);
                Push(lst, Type.List);  
                GC.Release(this);
            }
            
            case SysCalls.FloatToLong:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertFloat(htype);
#endif
                uint lng = External.FloatToLong(this);
                Push(lng, Type.Long);
                GC.Release(this);
            }
            case SysCalls.FloatToUInt:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertFloat(htype);
#endif
                uint ui = External.FloatToUInt(this);
                Push(ui, Type.UInt);
                GC.Release(this);
            }
            
            case SysCalls.LongGetByte:
            {
                uint index = Pop();
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertLong(htype);
#endif
                byte b = HRLong.GetByte(this, index);
                Push(b, Type.Byte);  
                GC.Release(this);              
            }
            case SysCalls.LongFromBytes:
            {
                byte b3 = byte(Pop());
                byte b2 = byte(Pop());
                byte b1 = byte(Pop());
                byte b0 = byte(Pop());
                
                uint l = HRLong.FromBytes(b0, b1, b2, b3);
                Push(l, Type.Long);                
            }
            case SysCalls.IntGetByte:
            {
                uint index = Pop();
                Type htype;
                uint i = Pop();
                byte b = HRInt.GetByte(i, index);
                Push(b, Type.Byte);                
            }
            case SysCalls.IntFromBytes:
            {
                byte b1 = byte(Pop());
                byte b0 = byte(Pop());
                
                uint i = HRInt.FromBytes(b0, b1);
                Push(i, Type.Int);  
            }
            
            case SysCalls.FloatToBytes:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertFloat(htype);
#endif
                uint lst = HRFloat.ToBytes(this);
                Push(lst, Type.List); 
                GC.Release(this);
            }
            case SysCalls.FloatToString:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertFloat(htype);
#endif
                uint str = External.FloatToString(this);
                Push(str, Type.String);
                GC.Release(this);
            }
            case SysCalls.LongToString:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertLong(htype);
#endif
                uint str = External.LongToString(this);
                Push(str, Type.String); 
                GC.Release(this);
            }
            case SysCalls.FloatGetByte:
            {
                uint index = Pop();
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                AssertFloat(htype);
#endif
                byte b = HRFloat.GetByte(this, index);
                Push(b, Type.Byte); 
                GC.Release(this);               
            }
            case SysCalls.FloatFromBytes:
            {
                byte b3 = byte(Pop());
                byte b2 = byte(Pop());
                byte b1 = byte(Pop());
                byte b0 = byte(Pop());
                
                uint f = HRFloat.FromBytes(b0, b1, b2, b3);
                Push(f, Type.Float);                
            }
            case SysCalls.LongToUInt:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                if (htype != Type.Long)
                {
                    ErrorDump(7);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint ui = HRLong.ToUInt(this);
                Push(ui, Type.UInt);
                GC.Release(this);
            }
            case SysCalls.LongToInt:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                if (htype != Type.Long)
                {
                    ErrorDump(7);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                int i = External.LongToInt(this);
                PushI(i);
                GC.Release(this);
            }
            case SysCalls.LongToFloat:
            {
                Type htype;
                uint this = Pop(ref htype);
#ifdef CHECKED
                if (htype != Type.Long)
                {
                    ErrorDump(7);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint f = External.LongToFloat(this);
                Push(f, Type.Float);
                GC.Release(this);
            }
            
            case SysCalls.LongNegate:
            {
                Type ttype;
                uint top = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Long)
                {
                    ErrorDump(64);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Long;
                result = HRLong.LongNegate(top);
                Push(result, rtype);        
                GC.Release(top);
            }
            
            
            case SysCalls.LongAdd:
            case SysCalls.LongSub:
            case SysCalls.LongDiv:
            case SysCalls.LongMul:
            case SysCalls.LongMod:
            case SysCalls.LongEQ:
            case SysCalls.LongLT:
            case SysCalls.LongLE:
            case SysCalls.LongGT:
            case SysCalls.LongGE:
            {
                Type ttype;
                uint top = Pop(ref ttype);
                Type ntype;
                uint next = Pop(ref ntype);
#ifdef CHECKED
                if ((ttype != Type.Long) || (ntype != Type.Long))
                {
                    ErrorDump(6);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Long;
                switch (SysCalls(iSysCall))
                {
                    case SysCalls.LongAdd:
                    {
                        result = External.LongAdd(next, top);
                    }
                    case SysCalls.LongSub:
                    {
                        result = External.LongSub(next, top);
                    }
                    case SysCalls.LongDiv:
                    {
                        result = External.LongDiv(next, top);
                    }
                    case SysCalls.LongMul:
                    {
                        result = External.LongMul(next, top);
                    }
                    case SysCalls.LongMod:
                    {
                        result = External.LongMod(next, top);
                    }   
                    case SysCalls.LongEQ:
                    {
                        result = External.LongEQ(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.LongLT:
                    {
                        result = External.LongLT(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.LongLE:
                    {
                        result = External.LongLE(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.LongGT:
                    {
                        result = External.LongGT(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.LongGE:
                    {
                        result = External.LongGE(next, top);
                        rtype = Type.Bool;
                    }   
                    
                }
                Push(result, rtype);        
                GC.Release(top);
                GC.Release(next);
            }
            case SysCalls.LongAddB:
            {
                Type ttype;
                uint top  = Pop(ref ttype);
                Type ntype;
                uint next = Pop(ref ntype);
#ifdef CHECKED
                if (ntype != Type.Long)
                {
                    ErrorDump(6);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Long;
                
                result = HRLong.LongAddB(next, top);
                Push(result, rtype);        
                GC.Release(next);
            }
            case SysCalls.LongSubB:
            {
                Type ttype;
                uint top  = Pop(ref ttype);
                Type ntype;
                uint next = Pop(ref ntype);
#ifdef CHECKED
                if (ntype != Type.Long)
                {
                    ErrorDump(6);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Long;
                
                result = HRLong.LongSubB(next, top);
                Push(result, rtype);        
                GC.Release(next);
            }
            
            case SysCalls.FloatAdd:
            case SysCalls.FloatSub:
            case SysCalls.FloatDiv:
            case SysCalls.FloatMul:
            case SysCalls.FloatATan2:
            case SysCalls.FloatEQ:
            case SysCalls.FloatLT:
            case SysCalls.FloatLE:
            case SysCalls.FloatGT:
            case SysCalls.FloatGE:
            {
                Type ttype;
                uint top = Pop(ref ttype);
                Type ntype;
                uint next = Pop(ref ntype);
#ifdef CHECKED
                if ((ttype != Type.Float) || (ntype != Type.Float))
                {
                    ErrorDump(6);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Float;
                switch (SysCalls(iSysCall))
                {
                    case SysCalls.FloatAdd:
                    {
                        result = External.FloatAdd(next, top);
                    }
                    case SysCalls.FloatSub:
                    {
                        result = External.FloatSub(next, top);
                    }
                    case SysCalls.FloatDiv:
                    {
                        result = External.FloatDiv(next, top);
                    }
                    case SysCalls.FloatMul:
                    {
                        result = External.FloatMul(next, top);
                    }
                    case SysCalls.FloatATan2:
                    {
                        result = External.FloatATan2(next, top);
                    }
                    case SysCalls.FloatEQ:
                    {
                        result = External.FloatEQ(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.FloatLT:
                    {
                        result = External.FloatLT(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.FloatLE:
                    {
                        result = External.FloatLE(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.FloatGT:
                    {
                        result = External.FloatGT(next, top);
                        rtype = Type.Bool;
                    }   
                    case SysCalls.FloatGE:
                    {
                        result = External.FloatGE(next, top);
                        rtype = Type.Bool;
                    }   
                    
                }
                Push(result, rtype);        
                GC.Release(top);
                GC.Release(next);
            }
            case SysCalls.FloatSin:
            case SysCalls.FloatCos:
            case SysCalls.FloatSqrt:
            {
                Type ttype;
                uint top = Pop(ref ttype);
#ifdef CHECKED
                if (ttype != Type.Float)
                {
                    ErrorDump(6);
                    Error = 0x0B; // system failure (internal error)
                }
#endif
                uint result;
                Type rtype = Type.Float;
                switch (SysCalls(iSysCall))
                {
                    case SysCalls.FloatSin:
                    {
                        result = External.FloatSin(top);
                    } 
                    case SysCalls.FloatCos:
                    {
                        result = External.FloatCos(top);
                    }
                    case SysCalls.FloatSqrt:
                    {
                        result = External.FloatSqrt(top);
                    }
                }
                Push(result, rtype);        
                GC.Release(top);
            }
            case SysCalls.LongNew:
            {
                uint address = HRLong.New();
                Push(address, Type.Long);
            }
            case SysCalls.FloatNew:
            {
                uint address = HRFloat.New();
                Push(address, Type.Float);
            }
            
            
            case SysCalls.TimeMillis:
            {
                uint address = External.GetMillis();
                Push(address, Type.Long);
            }
            case SysCalls.TimeDelay:
            {
                External.Delay(Pop());
                doNext = false;
            }
            
            
            case SysCalls.ScreenPrint:
            {
#ifdef LOCALDEBUGGER
                switch (iOverload)
                {
                    case 0:
                    {
                        //Print(char c,     uint foreColour, uint backColour) system;
                        Type btype;
                        uint backColour = Pop(ref btype);
                        Type ftype;
                        uint foreColour = Pop(ref ftype);
                        Type atype;
                        uint ch = Pop(ref atype);
#ifdef CHECKED
                        AssertChar(atype, ch);
                        AssertUInt(ftype, foreColour);
                        AssertUInt(btype, backColour);
#endif
                        Desktop.Print(ch, foreColour, backColour);
                    }
                    case 1:
                    {
                        //Print(string s,   uint foreColour, uint backColour) system;
                        Type btype;
                        uint backColour = Pop(ref btype);
                        Type ftype;
                        uint foreColour = Pop(ref ftype);
                        Type atype;
                        uint str = Pop(ref atype);
#ifdef CHECKED
                        if (atype != Type.String)
                        {
                            ErrorDump(226);
                            Error = 0x0B; // system failure (internal error)
                        }
                        AssertUInt(ftype, foreColour);
                        AssertUInt(btype, backColour);
#endif
                        Desktop.Print(str, foreColour, backColour);
                    }
                    default:
                    {
                        ErrorDump(203); Error = 0x0B;
                    }
                }   
#else
                ErrorDump(204); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenPrintLn:
            {
#ifdef LOCALDEBUGGER
                // PrintLn() system;
                Desktop.PrintLn();
#else
                ErrorDump(206); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenClear:
            {
#ifdef LOCALDEBUGGER
                // Clear() system;
                Desktop.Clear();
#else
                ErrorDump(208); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenSetCursor:
            {
#ifdef LOCALDEBUGGER
                // SetCursor(uint col, uint row) system;
                Type rtype;
                uint row = Pop(ref rtype);
                Type ctype;
                uint col = Pop(ref ctype);
#ifdef CHECKED
                AssertUInt(ctype, col);
                AssertUInt(rtype, row);
#endif
                Desktop.SetCursor(col, row);
                
#else
                ErrorDump(210); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenColumnsGet:
            {
#ifdef LOCALDEBUGGER
                // byte Columns { get system; }
                Push(Desktop.GetColumns(), Type.Byte);
#else
                ErrorDump(212); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenRowsGet:
            {
#ifdef LOCALDEBUGGER
                // byte Rows { get system; }
                Push(Desktop.GetRows(), Type.Byte);
#else
                ErrorDump(214); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenCursorXGet:
            {
#ifdef LOCALDEBUGGER
                // byte CursorX { get system; }
                Push(Desktop.GetCursorX(), Type.Byte);
#else
                ErrorDump(216); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenCursorYGet:
            {
#ifdef LOCALDEBUGGER
                // byte CursorY { get system; }
                Push(Desktop.GetCursorY(), Type.Byte);
#else
                ErrorDump(218); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenSuspend:
            {
#ifdef LOCALDEBUGGER
                // Suspend() system;
                Desktop.Suspend();
#else
                ErrorDump(220); Error = 0x0B;
#endif
            }
            case SysCalls.ScreenResume:
            {
#ifdef LOCALDEBUGGER
                // Resume() system;
                Type ctype;
                uint isInteractive = Pop(ref ctype);
#ifdef CHECKED
                AssertBool(ctype, col);
#endif                
                Desktop.Resume(isInteractive != 0);
#else
                ErrorDump(222); Error = 0x0B;
#endif
            }
            
            case SysCalls.KeyboardReadKey:
            {
#ifdef LOCALDEBUGGER
                // Key  ReadKey() system;
                Push(Desktop.ReadKey(), Type.UInt);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            case SysCalls.KeyboardIsAvailableGet:
            {
#ifdef LOCALDEBUGGER
                // bool IsAvailable { get system; }
                Push(Desktop.IsAvailable() ? 1 : 0, Type.Bool);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            
            case SysCalls.KeyboardClickXGet:
            {
#ifdef LOCALDEBUGGER
                // uint ClickX      { get system; } // x position of last read click event
                Push(Desktop.ClickX(), Type.UInt);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            case SysCalls.KeyboardClickYGet:
            {
#ifdef LOCALDEBUGGER
                // uint ClickY      { get system; } // y position of last read click event
                Push(Desktop.ClickY(), Type.UInt);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            case SysCalls.KeyboardClickUpGet:
            {
#ifdef LOCALDEBUGGER
                // bool ClickUp     { get system; } // was last read click event Up or Down?
                Push(Desktop.ClickUp() ? 1 : 0, Type.Bool);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            case SysCalls.KeyboardClickDoubleGet:
            {
#ifdef LOCALDEBUGGER
                // bool ClickDouble { get system; } // was last read click event a double click?
                Push(Desktop.ClickDouble() ? 1 : 0, Type.Bool);
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            case SysCalls.KeyboardScrollDeltaGet:
            {
#ifdef LOCALDEBUGGER
                // int  ScrollDelta { get system; } // delta for last scroll wheel event
                PushI(Desktop.ScrollDelta());
#else
                ErrorDump(227); Error = 0x0B;
#endif
            }
            
                     
            default:
            {
                IO.WriteHex(PC); IO.Write(':'); IO.Write('S'); IO.WriteHex(iSysCall); IO.Write('-'); IO.WriteHex(iOverload);  
                IO.Write(' '); ErrorDump(2);
                Error = 0x0A; // not implemented
            }
        }
        return doNext && (Error == 0);
    }
    
    Put(uint address, uint value, Type htype)
    {
        WriteWord(valueStack + address, value);
        WriteWord(typeStack  + address, byte(htype));
    }
    uint Get(uint address, ref Type htype)
    {
        uint value  = ReadWord(valueStack + address);
        htype  = Type(ReadWord(typeStack + address));
        return value;
    }
    uint Get(uint address)
    {
        return ReadWord(valueStack + address);
    }
    
    PushI(int ivalue)
    {
        uint value = External.IntToUInt(ivalue);
#ifdef CHECKED        
        if (sp == stackSize)
        {
            ErrorDump(7); ErrorDump(1); Error = 0x07; // stack overflow
            return;
        }
#endif
        WriteWord(valueStack + sp, value);
        WriteWord(typeStack + sp, byte(Type.Int));
        sp = sp + 2;
    }
    PutI(uint address, int ivalue, Type htype)
    {
        uint value = External.IntToUInt(ivalue);
        WriteWord(valueStack + address, value);
        WriteWord(typeStack  + address, byte(htype));
    }
    PutI(uint address, int ivalue)
    {
        uint value = External.IntToUInt(ivalue);
        WriteWord(valueStack + address, value);
        WriteWord(typeStack  + address, byte(Type.Int));
    }
    
    int PopI(ref Type htype)
    {
#ifdef CHECKED
        if (sp == 0)
        {
            ErrorDump(2); Error = 0x07; // stack underflow
            return 0;
        }
#endif
        sp = sp - 2;
        uint value  = ReadWord(valueStack + sp);
        htype  = Type(ReadWord(typeStack + sp));
        return External.UIntToInt(value);
    }
    int PopI()
    {
#ifdef CHECKED
        if (sp == 0)
        {
            ErrorDump(3); Error = 0x07; // stack underflow
            return 0;
        }
#endif
        sp = sp - 2;
        return External.UIntToInt(ReadWord(valueStack + sp));
    }
    int GetI(uint address, ref Type htype)
    {
        uint value  = ReadWord(valueStack + address);
        htype  = Type(ReadWord(typeStack + address));
        return External.UIntToInt(value);
    }
    int GetI(uint address)
    {
        uint value  = ReadWord(valueStack + address);
        return External.UIntToInt(value);
    }
    
    
    Push(uint value, Type htype)
    {
#ifdef CHECKED        
        if (sp == stackSize)
        {
            ErrorDump(4); Error = 0x07; // stack overflow
            return;
        }
#endif
        WriteWord(valueStack + sp, value);
        WriteWord(typeStack + sp, byte(htype));
        sp = sp + 2;
    }
    uint Pop(ref Type htype)
    {
#ifdef CHECKED
        if (sp == 0)
        {
            ErrorDump(5); Error = 0x07; // stack underflow
            return 0;
        }
#endif
        sp = sp - 2;
        uint value  = ReadWord(valueStack + sp);
        htype  = Type(ReadWord(typeStack + sp));
        return value;
    }
    uint Pop()
    {
#ifdef CHECKED
        if (sp == 0)
        {
            ErrorDump(6); Error = 0x07; // stack underflow
            return 0;
        }
#endif
        sp = sp - 2;
        return ReadWord(valueStack + sp);
    }
    uint GetCS(uint address)
    {
        return ReadWord(callStack + address);
    }
    PushCS(uint value)
    {
#ifdef CHECKED
        if (csp == callStackSize)
        {
            ErrorDump(8); Error = 0x06; // call stack overflow
            return;
        }
#endif
        WriteWord(callStack + csp, value);
        csp = csp + 2;
    }
    uint PopCS()
    {
#ifdef CHECKED
        if (csp == 0)
        {
            ErrorDump(9); Error = 0x06; // call stack underflow
            return 0;
        }
#endif
        csp = csp - 2;
        return ReadWord(callStack + csp);
    }
    
    
    uint ReadWordOperand()
    {
        uint operand = ReadProgramWord(pc); 
        pc++; pc++;
        return operand;
    }
    byte ReadByteOperand()
    {
        byte operand = ReadProgramByte(pc); 
        pc++;
        return operand;
    }
    int ReadByteOffsetOperand()
    {
        int offset = int(ReadProgramByte(pc)); 
        pc++;
        if (offset > 127)
        {
            offset = offset - 256; // 0xFF -> -1
        }
        return offset;
    }
    int ReadWordOffsetOperand()
    {
        int offset = External.UIntToInt(ReadProgramWord(pc)); 
        pc++; pc++;
        return offset;
    }
    ShowCurrent()
    {
        IO.WriteHex(pc); IO.Write(' ');  IO.WriteHex(ReadProgramByte(pc)); IO.Write(' ');
        IO.WriteLn();
    }
    WriteBREAK()
    {
        IO.WriteLn();IO.Write('B');IO.Write('R');IO.Write('E');IO.Write('A');IO.Write('K');IO.WriteLn();
    }
    WriteERROR()
    {
        IO.WriteLn();
#ifdef CHECKED                
        IO.WriteHex(messagePC);
#else
        IO.WriteHex(PC);
#endif
        IO.Write(' '); IO.Write('E'); IO.Write('r'); IO.Write('r'); IO.Write('o'); IO.Write('r'); IO.Write(':'); 
        byte berror = Error;
        IO.WriteHex(berror);
        IO.WriteLn();
    }
    
    DumpHeap(bool display, uint accountedFor)
    {
        bool verboseDisplay = false;
        if (display)
        {
            verboseDisplay = true;
        }
        if (verboseDisplay)
        {
            IO.WriteLn();
            for (uint s = 0; s < sp; s = s + 2)
            {
                uint value  = ReadWord(valueStack + s);
                uint address = valueStack + s;
                byte htype  = byte(ReadWord(typeStack + s));
                if (IsReferenceType(Type(htype)))
                {
                    byte count  = byte(ReadByte(value + 1));
                    IO.WriteHex(value); IO.Write(':'); IO.WriteHex(htype);IO.Write(' ');IO.WriteHex(count); IO.Write(' '); 
                    GC.Dump(value, 0);
                    IO.WriteLn();
                }
            }
        }
        
        
        
        if (display)
        {
            IO.WriteLn();
            IO.Write('P');IO.Write('C');IO.Write(':');IO.WriteHex(PC);
            IO.WriteLn();
            IO.Write('F');IO.Write(':');
        }
        
        uint pCurrent = Memory.FreeList;
        uint freeSize = 0;
        uint allocatedSize = 0;
        loop
        {
            if (0 == pCurrent)
            {
                break;
            }
            uint size  = ReadWord(pCurrent);    
            uint pNext = ReadWord(pCurrent+2);    
            uint pPrev = ReadWord(pCurrent+4);   
            if (verboseDisplay) // free list items
            { 
                IO.WriteLn();
                IO.WriteHex(pCurrent);IO.Write(' ');
                IO.WriteHex(size); IO.Write(' ');
                IO.WriteHex(pNext);IO.Write('>');IO.Write(' ');IO.Write('<');IO.WriteHex(pPrev);
            }
            pCurrent = pNext;
            freeSize = freeSize + size;
        }
        if (display)
        {
            IO.WriteLn();
            IO.Write('H');IO.Write(':');
            uint h = HeapStart+HeapSize;
            IO.WriteHex(h);IO.Write('-');
            IO.WriteHex(HeapStart);IO.Write('=');IO.WriteHex(HeapSize);
        }
        pCurrent = HeapStart;
        uint pLimit   = HeapStart + HeapSize;
        uint count = 0;
        loop
        {
            count ++;
            if (pCurrent >= pLimit)
            {
                break;
            }
            uint size  = ReadWord(pCurrent);    
            if (count > 50)
            {
                break;
            }
                
            if (!IsOnFreeList(pCurrent))
            {
                if (verboseDisplay) // heap items
                {
                    IO.WriteLn();
                    IO.WriteHex(pCurrent); Write(' ');
                    IO.WriteHex(size); Write(' ');
                    byte tp = ReadByte(pCurrent+2);
                    byte rf = ReadByte(pCurrent+3);
                    IO.WriteHex(tp); Write(' ');IO.WriteHex(rf);
                }
                allocatedSize = allocatedSize + size;
            }
            else if (verboseDisplay)
            {
                // free list items
                IO.WriteLn();
                IO.WriteHex(pCurrent); Write(' ');
                IO.WriteHex(size); Write(' ');
            }
            if (size == 0)
            {
                break;
            }
            pCurrent = pCurrent + size; // this is why we limit ourselves to 0xFF00 (not 0x10000, actual 64K)
        }
        bool reportAndStop = (HeapSize != (allocatedSize + freeSize));
        if (!reportAndStop && (accountedFor > 0))
        {
            reportAndStop = (accountedFor != allocatedSize);    
        }
        if (reportAndStop)
        {
            if (!display)
            {
                DumpHeap(true, accountedFor);
                ErrorDump(91); Error = 0x0B;
            }
            else
            {
                IO.WriteLn();
                Write('A');IO.WriteHex(allocatedSize);Write(':');IO.WriteHex(accountedFor);Write(' ');Write('F');IO.WriteHex(freeSize);
                uint fl = HeapSize - (allocatedSize + freeSize);
                Write(' ');Write('L');IO.WriteHex(fl);
            }
        }
    }
    bool IsOnFreeList(uint pCandidate)
    {
        uint pCurrent = Memory.FreeList;
        loop
        {
            if (0 == pCurrent)
            {
                break;
            }
            if (pCurrent == pCandidate)
            {
                return true;
            }
            pCurrent = ReadWord(pCurrent+2);  
        }
        return false;
    }
    
    DumpStack(uint limit)
    {
        IO.WriteLn();
        limit = limit * 2;
        for (uint s = 0; s < sp; s = s + 2)
        {
            if (sp - s > limit) { continue; }
            if (s == bp)
            {
                IO.Write('B'); IO.Write('P');
            }
            else
            {
                IO.Write(' '); IO.Write(' ');
            }
            IO.Write(' '); IO.Write(' ');
            uint value  = ReadWord(valueStack + s);
            uint address = valueStack + s;
            byte htype  = byte(ReadWord(typeStack + s));
            IO.WriteHex(s); IO.Write(' '); IO.WriteHex(address); IO.Write(' ');
            IO.WriteHex(value); IO.Write(':'); IO.WriteHex(htype);
            if (IsReferenceType(Type(htype)))
            {
                byte count  = byte(ReadByte(value + 1));
                IO.Write(' '); IO.WriteHex(count); IO.Write(' '); 
                GC.Dump(value);
            }
            else
            {
                switch (Type(htype))
                {
                    case Type.Byte:
                    case Type.UInt:
                    {
                        IO.Write(' ');
                        IO.WriteUInt(value);
                    }
                    case Type.Bool:
                    {
                        IO.Write(' ');
                        IO.Write(((value != 0) ? 't' : 'f'));
                    }
                    case Type.Char:
                    {
                        IO.Write(char(0x27)); // single quote
                        IO.Write(char(value));
                        IO.Write(char(0x27)); // single quote
                    }
                    case Type.Int:
                    {
                        IO.Write(' ');
                        int iv = External.UIntToInt(value);
                        IO.WriteInt(iv);
                    }
                } 
            }
            IO.WriteLn();
        }
    }  
    
    bool ExecuteStepTo()
    {
        bool restart;
        inDebugger = true;
#ifdef CHECKED
        messagePC = pc;
#endif
        bool doNext = ExecuteOpCode();
        if (Error != 0)
        {
            WriteERROR();
        }
        else if (pc == 0) // returned from "main"
        {
            restart = true; // this restart causes the Profiler to hang for MSU (since 0 is legit start address)
        }
        inDebugger = false;
        return restart;
    }
    
    
    bool Execute()
    {
        bool restart;
        inDebugger = true;
        loop
        {
#ifdef CHECKED
            messagePC = pc;
#endif
            bool doNext = ExecuteOpCode();
            if (Error != 0)
            {
                WriteERROR();
                break;
            }
            if (pc == 0) // returned from "main"
            {
                restart = true; // this restart causes the Profiler to hang for MSU (since 0 is legit start address)
                break;          // clean exit of "main"
            }
            if (IsBreak())
            {
                WriteBREAK();
                break;
            }
            if (BreakpointExists)
            {
                // pc is never zero here (see above)
                byte iBreak;
                bool atBreakpoint;
                for (iBreak = 0; iBreak<16; iBreak++)
                {
                    if (GetBreakpoint(iBreak) == pc)
                    {
                        if (iBreak == 0)
                        {
                            SetBreakpoint(0, 0); // clear single step breakpoint
                        }
                        inDebugger = false;
                        return restart; // return control to Monitor
                    }
                }
            }
            WatchDog();
        } // loop
        inDebugger = false;
        return restart;
    }
    
    bool ExecuteOpCode()
    {
        ServiceInterrupts();
        
        opCode = OpCode(ReadProgramByte(pc));
        pc++;

#ifdef LOCALDEBUGGER                
        uint jump = ReadWord(jumpTable + (byte(opCode) << 1));
#ifdef CHECKED
        if (0 == jump)
        {
            _ = Instructions.Undefined();
            return false;
        }
#endif
        InstructionDelegate instructionDelegate = InstructionDelegate(jump);
        return instructionDelegate();
#else
        // on MCU
        return External.FunctionCall(jumpTable, byte(opCode));
#endif
    }
    
    bool InlinedExecuteWarp(bool logging)
    {
        bool restart;
        uint watchDog = 2500;
        loop
        {
            if (ISRExists) { ServiceInterrupts(); }
#ifdef CHECKED
            messagePC = PC;
#endif
            byte bopCode = ReadProgramByte(pc);
#ifdef LOCALDEBUGGER
            uint jump = ReadWord(jumpTable + (bopCode << 1));
#endif
            pc++;
#ifdef LOCALDEBUGGER            
#ifdef CHECKED
            if (0 == jump)
            {
                opCode = OpCode(bopCode); // for error reporting of undefined opcodes
                _ = Instructions.Undefined();
                return restart;
            }
#endif
#endif
            watchDog--;
            if (watchDog == 0)
            {
                WatchDog(); // yield() on devices like Wemos D1 Mini so WDT is not tripped
                watchDog = 2500;
                if (IsBreak()) // adding this check slowed down the FiboUInt benchmark from 1094ms to 1220ms (~10%)
                {
                    WriteBREAK();
                    break;
                }
            }
            
#ifndef LOCALDEBUGGER // on MCU
            if (External.FunctionCall(jumpTable, bopCode)) { continue; }
#else
            InstructionDelegate instructionDelegate = InstructionDelegate(jump);
            if (instructionDelegate()) { continue; }
#endif
            
            if (Error != 0)
            {
                WriteERROR();
                break;
            }
            if (PC == 0) // returned from "main"
            {
                restart = true; // this restart causes the Profiler to hang for MSU (since 0 is legit start address)
                break;     // clean exit of "main"
            }
            if (IsBreak())
            {
                WriteBREAK();
                break;
            }
        } // loop
        return restart;
    }
    uint RuntimeDateTime()
    {
        Serial.WriteChar(char(0x07)); // Bell
        Serial.WriteChar('D'); // DateTime
        while (!Serial.IsAvailable)
        {
            External.Delay(10);    
        }   
        uint hrstring = HRString.New();
        loop
        {
            char ch = Serial.ReadChar();
            if (ch == char(0x0D))
            {
                break;
            }
            HRString.BuildChar(ref hrstring, ch);
        }
        return hrstring;
    }
    
    uint pcStore;
    bool RunInline()
    {
        Type stype;
        uint startIndex = Pop(ref stype);
        Type ttype;
        uint inlineCodeArray = Pop(ref ttype);
#ifdef CHECKED
        AssertUInt(stype, startIndex);
        if (ttype != Type.Array)
        {
            ErrorDump(167); Error = 0x0B;
        }
#endif       
        
        pcStore  = pc;
        uint inlineLocation = binaryAddress + programSize;
        pc = inlineLocation + startIndex - programOffset;
        
        uint length = HRArray.GetCount(inlineCodeArray);
        for (uint i = 0; i < length; i++)
        {
            Type itype;
            byte c = byte(HRArray.GetItem(inlineCodeArray, i, ref itype));
            WriteCodeByte(inlineLocation, c);
            inlineLocation++;
        }
        GC.Release(inlineCodeArray);
        
        return true; // success
    }
    bool ExitInline()
    {
        pc = pcStore;
        Push(0, Type.UInt); // strictly speaking, this is the result from Runtime.Inline(..)
        return true;
    }
}
