unit CodeStream
{
    uses "/Source/Compiler/CodeGen/Instructions"
    uses "/Source/Compiler/CodeGen/Block"
    uses "/Source/Compiler/Symbols"
    uses "/Source/Compiler/CodeGen/Peephole"
    
    
    <string,string> debugInfo;
    <string,bool> debugInfoLineUsed;
    <byte> currentStream;
    <byte> constantStream;
    
    bool checkedBuild;
    bool shortCallsDefined;
    bool portableDefined;
    bool h6053Defined;
    
    bool CheckedBuild 
    { 
        get { return checkedBuild; }
        set { checkedBuild = value; }
    }
    bool IsShortCalls { get { return shortCallsDefined; } }
    bool IsPortable   { get { return portableDefined; } }
    bool Target6502   { get { return h6053Defined; } }
    
    InitializeSymbolShortcuts()
    {
        shortCallsDefined = DefineExists("SHORTCALLS");
        portableDefined = DefineExists("PORTABLE");
        h6053Defined = DefineExists("H6502");
    }
    bool InUse { get { return currentStream.Length > 0; } } 
    
    Instruction GetLastInstruction()
    { 
        Instruction last = Instruction.NOP;
        if (LastInstructionIndex < currentStream.Length)
        {
            byte instr = currentStream[LastInstructionIndex];
            last = Instruction(instr); 
        }
        return last;
    }
    
    uint NextAddress 
    { 
        get 
        { 
            return currentStream.Length;
        } 
    }
        
    AppendCode(<byte> code)
    {
        foreach (var b in code)
        {
            currentStream.Append(b);        
        }
        UpdatePeepholeBoundary(currentStream.Length);
    }
    
    byte IntToByte(int offset)
    {
        if ((offset < -128) || (offset > 127))
        {
            Die(0x0B);
        }
        if (offset < 0)
        {
            offset = 256 + offset; // -1 -> 255
        }
        byte result = byte(offset);
        return result;
    }
    
    New()
    {
        currentStream.Clear();
        Peephole.Initialize();
    }
    New(<byte> starterStream)
    {
        currentStream = starterStream;
        Peephole.Initialize();
    }
    GetCurrentStream(ref <byte> rCurrentStream)
    {
        rCurrentStream = currentStream;
    }
    <byte> CurrentStream { get { return currentStream; } }
    <string,string> DebugInfo { get { return debugInfo; } }
    ClearDebugInfo()
    {
        debugInfo.Clear();
        debugInfoLineUsed.Clear();
    }
     
    uint AppendConstant(<byte> data)
    {
        uint constantAddress;
        loop
        {
            uint length = constantStream.Length;
            uint candidateLength = data.Length;
            uint iStart = 0;
            bool found = false;
            loop
            {
                if (iStart + candidateLength > length)
                {
                    break;
                }
                bool match = true;   
                for (uint i = 0; i < candidateLength; i++)
                {
                    if (data[i] != constantStream[iStart+i])
                    {
                        match = false;
                        break;
                    }
                }
                if (match)
                {
                    found = true;
                    constantAddress = iStart;
                    break;    
                }
                iStart++;
            }
            if (found)
            {
                break;
            }
            // not found
            constantAddress = constantStream.Length;
            foreach (var b in data)
            {
                constantStream.Append(b);
            }
            break;
        }
        return constantAddress;
    }
    
    uint CreateFloatConstant(float value)
    {
        <byte> bytes = value.ToBytes();
        return AppendConstant(bytes);
    }
    uint CreateLongConstant(long value)
    {
        <byte> bytes = value.ToBytes();
        return AppendConstant(bytes);
    }
    uint CreateStringConstant(string value)
    {
        <byte> bytes;
        foreach (var c in value)
        {
            bytes.Append(byte(c));
        }
        return AppendConstant(bytes);
    }
    <byte> GetConstantStream()
    {
        return constantStream;
    }
    
    
    PopTail(uint pops)
    {
        loop
        {
            uint iLast = currentStream.Length - 1;
            currentStream.Remove(iLast);
            pops--;
            if (pops == 0)
            {
                break;
            }
        }
    }
    
    PatchJump(uint jumpAddress, uint jumpToAddress)
    {
        byte jumpInstr = currentStream[jumpAddress];
        Instruction jumpInstruction = Instruction(jumpInstr);
        bool isLong; 
        Instruction shortInstruction;
        switch (jumpInstruction)
        {
            case Instruction.JB:
            {
            }
            case Instruction.JZB:
            {
            }
            case Instruction.JNZB:
            {
            }
            case Instruction.J:
            {
                isLong = true;
                shortInstruction = Instruction.JB;
            }
            case Instruction.JZ:
            {
                isLong = true;
                shortInstruction = Instruction.JZB;
            }
            case Instruction.JNZ:
            {
                isLong = true;
                shortInstruction = Instruction.JNZB;
            }
            default:
            {
                uint inst = uint(jumpInstruction);
                PrintLn("jumpInstruction=" + inst.ToHexString(2));
                Die(0x0B); // what's this?
            }
        }
        
        int offset = int(jumpToAddress) - int(jumpAddress);
        if (isLong)
        {
            uint op = Types.IntToUInt(offset);
            uint lsb = op & 0xFF;
            uint msb = op >> 8;
            if ((shortInstruction == Instruction.JB) && (offset >= 0) && (offset <= 127) && !IsTinyHopper)
            {
                uint phb = PeepholeBoundary;
                if (jumpAddress > phb)
                {
                  UpdatePeepholeBoundary(currentStream.Length);
                }
                currentStream.SetItem(jumpAddress+0, byte(shortInstruction));
                currentStream.SetItem(jumpAddress+1, byte(lsb));
                currentStream.SetItem(jumpAddress+2, byte(Instruction.NOP));
            }
            else
            {
                currentStream.SetItem(jumpAddress+1, byte(lsb));
                currentStream.SetItem(jumpAddress+2, byte(msb));
            }
        }
        else
        {
            byte op = IntToByte(offset);
            currentStream.SetItem(jumpAddress+1, op);
        }
        
    }
    
    bool TryUserSysCall(string name)
    {
        bool userSupplied = false;
        // Are we targetting an 8 bit platform?
        // Is there a user supplied alternative to the SysCall with only one overload?
        //  (we're not checking arguments or return type : shooting from the hip ..)
        uint fIndex;
        if (CodeStream.Target6502 || CodeStream.IsPortable)
        {
            if (GetFunctionIndex(name, ref fIndex))
            {
                <uint> iOverloads = GetFunctionOverloads(fIndex);
                if (iOverloads.Length == 1)
                {
                    uint iOverload = iOverloads[0];
                    if (!IsSysCall(iOverload))
                    {
                        Symbols.OverloadToCompile(iOverload); // User supplied SysCall as Hopper source
                        if (CodeStream.IsShortCalls && (iOverload < 256))
                        {
                            CodeStream.AddInstruction(Instruction.CALLB, byte(iOverload));
                        }
                        else
                        {
                            CodeStream.AddInstruction(Instruction.CALL, iOverload);
                        }
                        userSupplied = true;
                    }
                }
            }
            //PrintLn();
        }
        return userSupplied;
    }
    
    AddInstructionPushLocal(byte offset)
    {
        if (IsTinyHopper)
        {
            uint uoffset = (offset & 0x80 != 0) ? (byte(offset) | 0xFF00) : offset; // sign extend if -ve
            AddInstruction(Instruction.PUSHLOCAL, uoffset);
        }
        else
        {
            AddInstruction(Instruction.PUSHLOCALB, offset);
        }
    }
    AddInstructionPopLocal(byte offset)
    {
        if (IsTinyHopper)
        {
            uint uoffset = (offset & 0x80 != 0) ? (byte(offset) | 0xFF00) : offset; // sign extend if -ve
            AddInstruction(Instruction.POPLOCAL, uoffset);
        }
        else
        {
            AddInstruction(Instruction.POPLOCALB, offset);
        }
    }
    
    AddInstructionIncLocal(byte offset, bool signed)
    {
        if (IsTinyHopper)
        {
            uint uoffset = (offset & 0x80 != 0) ? (byte(offset) | 0xFF00) : offset; // sign extend if -ve
            AddInstruction(Instruction.PUSHLOCAL, uoffset);
            AddInstructionPUSHI(1);
            AddInstruction(signed ? Instruction.ADDI : Instruction.ADD);
            AddInstruction(Instruction.POPLOCAL, uoffset);
        }
        else
        {
            AddInstruction(Instruction.INCLOCALB, offset);
        }
    }
    AddInstructionDecLocal(byte offset, bool signed)
    {
        if (IsTinyHopper)
        {
            uint uoffset = (offset & 0x80 != 0) ? (byte(offset) | 0xFF00) : offset; // sign extend if -ve
            AddInstruction(Instruction.PUSHLOCAL, uoffset);
            AddInstructionPUSHI(1);
            AddInstruction(signed ? Instruction.SUBI : Instruction.SUB);
            AddInstruction(Instruction.POPLOCAL, uoffset);
        }
        else
        {
            AddInstruction(Instruction.DECLOCALB, offset);
        }
    }
    AddInstructionSysCall(string sysCallUnit, string sysCallMethod, byte iSysOverload)
    {
        loop
        {
            byte iSysCall;
            string name = sysCallUnit + '.' + sysCallMethod;
            if (TryUserSysCall(name))
            {
                break;
            }
            if (!TryParseSysCall(name, ref iSysCall))
            {
                PrintLn("'" + name + "' not found");
                Die(0x03); // key not found
            }
            if (!IsTinyHopper && (iSysOverload == 0))
            {
                CodeStream.AddInstruction(Instruction.SYSCALL0, iSysCall);
            }
            else if (!IsTinyHopper && (iSysOverload == 1))
            {
                CodeStream.AddInstruction(Instruction.SYSCALL1, iSysCall);
            }
            else
            {
                CodeStream.AddInstructionPUSHI(iSysOverload);
                CodeStream.AddInstruction(Instruction.SYSCALL, iSysCall);
            }
            break;
        }
    }
    AddInstructionSysCall0(string sysCallUnit, string sysCallMethod)
    {
        AddInstructionSysCall(sysCallUnit, sysCallMethod, 0);
    }
    
    AddInstructionLibCall(string libCallUnit, string libCallMethod)
    {
        loop
        {
            byte iLibCall;
            string name = libCallUnit + '.' + libCallMethod;
            if (!TryParseLibCall(name, ref iLibCall))
            {
                PrintLn("'" + name + "' not found");
                Die(0x03); // key not found
            }
            CodeStream.AddInstruction(Instruction.LIBCALL, iLibCall);
            break;
        }
    }
    AddInstructionJump(Instruction jumpInstruction)
    {
        // before jump (since this placeholder patch location is locked in already)
        UpdatePeepholeBoundary(currentStream.Length);
        
        switch (jumpInstruction)
        {
            case Instruction.J:
            case Instruction.JZ:
            case Instruction.JNZ:
            {
                AddInstruction(jumpInstruction, uint(0)); // place holder
            }
            case Instruction.JB:
            case Instruction.JZB:
            case Instruction.JNZB:
            {
                AddInstruction(jumpInstruction, byte(0)); // place holder
            }
            default:
            {
                Die(0x0B); // what's this?
            }
        }
        
    }    
    AddInstructionJumpOffset(Instruction jumpInstruction, byte offset)
    {
        AddInstruction(jumpInstruction, offset);
        UpdatePeepholeBoundary(currentStream.Length);
    }
    AddInstructionJump(Instruction jumpInstruction, uint jumpToAddress)
    {
        if ((jumpInstruction == Instruction.JIX) || (jumpInstruction == Instruction.JIXB))
        {
            AddInstruction(jumpInstruction, jumpToAddress); // operand is not really an address, always a uint
        }
        else
        {
            uint jumpAddress = NextAddress;
            int offset = int(jumpToAddress) - int(jumpAddress);
            if ((offset >= -128) && (offset <= 127) && !IsTinyHopper)
            {
                byte op = IntToByte(offset);
                switch (jumpInstruction)
                {
                    case Instruction.J:
                    {
                        jumpInstruction = Instruction.JB;
                    }
                    case Instruction.JZ:
                    {
                        jumpInstruction = Instruction.JZB;
                    }
                    case Instruction.JNZ:
                    {
                        jumpInstruction = Instruction.JNZB;
                    }
                }
                AddInstruction(jumpInstruction, op);
            }
            else
            {
                uint op = Types.IntToUInt(offset);
                switch (jumpInstruction)
                {
                    case Instruction.JB:
                    {
                        jumpInstruction = Instruction.J;
                    }
                    case Instruction.JZB:
                    {
                        jumpInstruction = Instruction.JZ;
                    }
                    case Instruction.JNZB:
                    {
                        jumpInstruction = Instruction.JNZ;
                    }
                }
                AddInstruction(jumpInstruction, op);
            }
        }
        UpdatePeepholeBoundary(currentStream.Length);
    }
    
    
    internalAddInstruction(Instruction instruction)
    {
        byte instr = byte(instruction);
        currentStream.Append(instr);
        LastInstructionIndex = currentStream.Length-1;
    }
    
    AddInstruction(Instruction instruction)
    {
        switch (instruction)
        {
            case Instruction.JB:
            case Instruction.JZB:
            case Instruction.JNZB:
            case Instruction.J:
            case Instruction.JZ:
            case Instruction.JNZ:
            case Instruction.JIXB:
            case Instruction.JIX:
            {
                Die(0x0B); // illegal to not use th Jump-specific AddInstructions (to update peephole boundary)
            }
        }
        internalAddInstruction(instruction);
        PeepholeOptimize(ref currentStream);
    }
    AddInstruction(Instruction instruction, byte operand)
    {
        internalAddInstruction(instruction);
        currentStream.Append(operand);
        PeepholeOptimize(ref currentStream);
    }
    AddInstruction(Instruction instruction, uint operand)
    {
        internalAddInstruction(instruction);
        uint lsb = operand & 0xFF;
        currentStream.Append(byte(lsb));
        uint msb = operand >> 8;
        currentStream.Append(byte(msb));
        PeepholeOptimize(ref currentStream);
    }
    AddInstructionPUSHI(uint operand)
    {
        if ((operand < 256) && !IsTinyHopper)
        {
            if (operand == 0)
            {
                CodeStream.AddInstruction(Instruction.PUSHI0);
            }
            else if (operand == 1)
            {
                CodeStream.AddInstruction(Instruction.PUSHI1);
            }
            else
            {
                CodeStream.AddInstruction(Instruction.PUSHIB, byte(operand));    
            }
        }
        else
        {
            CodeStream.AddInstruction(Instruction.PUSHI, operand);    
        }
    }
    
    AddInstructionPushVariable(string variableName)
    {
        string fullName;
        string variableType = Types.GetTypeString(variableName, true, ref fullName);
        if (Symbols.GlobalMemberExists(fullName))
        {
            uint globalAddress = Symbols.GetGlobalAddress(fullName);
            if ((globalAddress < 256) && !IsTinyHopper)
            {
                CodeStream.AddInstruction(Instruction.PUSHGLOBALB, byte(globalAddress));
            }
            else
            {
                CodeStream.AddInstruction(Instruction.PUSHGLOBAL, globalAddress);
            }       
        }
        else
        {
            bool isRef;
            int offset = Block.GetOffset(variableName, ref isRef);
            if ((offset > -129) && (offset < 128) && !IsTinyHopper)
            {
                byte operand =  CodeStream.IntToByte(offset);
                if (isRef)
                {
                    CodeStream.AddInstruction(Instruction.PUSHRELB, operand);
                }
                else
                {
                    CodeStream.AddInstruction(Instruction.PUSHLOCALB, operand);
                }
            }
            else
            {
                uint operand = Types.IntToUInt(offset);
                if (isRef)
                {
                    CodeStream.AddInstruction(Instruction.PUSHREL, operand);
                }
                else
                {
                    CodeStream.AddInstruction(Instruction.PUSHLOCAL, operand);
                }
            }
        }
    }
    AddInstructionPopVariable(string variableType, string variableName)
    {
        if (!IsValueType(variableType))
        {
            // what follows is a pop of a reference into a variable - should we make a copy?
            CodeStream.internalAddInstruction(Instruction.COPYNEXTPOP);
            PeepholeOptimize(ref currentStream);
        }
        string fullName;
        string variableType2 = Types.GetTypeString(variableName, true, ref fullName);
        
        if (Symbols.GlobalMemberExists(fullName))
        {
            uint globalAddress = Symbols.GetGlobalAddress(fullName);
            if ((globalAddress < 256) && !IsTinyHopper)
            {
                CodeStream.AddInstruction(Instruction.POPGLOBALB, byte(globalAddress));
            }
            else
            {
                CodeStream.AddInstruction(Instruction.POPGLOBAL, globalAddress);
            }       
        }
        else
        {
            bool isRef;
            int offset = Block.GetOffset(variableName, ref isRef);
            if ((offset > -129) && (offset < 128) && !IsTinyHopper)
            {
                byte operand =  CodeStream.IntToByte(offset);
                if (isRef)
                {
                    CodeStream.AddInstruction(Instruction.POPRELB, operand);
                }
                else
                {
                    CodeStream.AddInstruction(Instruction.POPLOCALB, operand);
                }
            }
            else
            {
                uint operand = Types.IntToUInt(offset);
                if (isRef)
                {
                    CodeStream.AddInstruction(Instruction.POPREL, operand);
                }
                else
                {
                    CodeStream.AddInstruction(Instruction.POPLOCAL, operand);
                }
            }
        }
    }
    AddString(string value)
    {
        if (value.Length == 0)
        {
            CodeStream.AddInstructionSysCall("String", "New", 0);
        }
        else if (value.Length == 1)
        {
            CodeStream.AddInstructionPUSHI(byte(value[0]));
            CodeStream.AddInstructionSysCall("String", "NewFromConstant", 1);
        }
        else if (value.Length == 2)
        {
            CodeStream.AddInstructionPUSHI(byte(value[0]) + (byte(value[1]) << 8));
            CodeStream.AddInstructionSysCall("String", "NewFromConstant", 1);
        }
        else
        {
            uint constantAddress = CodeStream.CreateStringConstant(value);
            CodeStream.AddInstructionPUSHI(constantAddress);
            CodeStream.AddInstructionPUSHI(value.Length);
            CodeStream.AddInstructionSysCall("String", "NewFromConstant", 0);
        }
    }
    
    InsertDebugInfo(bool usePreviousToken)
    {
        <string,string> token;
        if (!usePreviousToken)
        {
            token = CurrentToken;    
        }
        else
        {
            token = PreviousToken;
        }
        uint na = NextAddress;
        string nextAddress = na.ToString();
        string ln = token["line"];
        if (!debugInfoLineUsed.Contains(ln)) // keep the one with the earliest address
        {
            debugInfo[nextAddress] = ln;       
            debugInfoLineUsed[ln] = true;
        }
    }
}
