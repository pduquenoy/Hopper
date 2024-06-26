unit Block
{
    
    uses "../Tokens/Parser"
    uses "../Tokens/Token"
    uses "../Tokens/Scanner"
    uses "CodeStream"
    
    // "arguments" [BP-offset]
    // "locals"    [BP+offset]
    // isLoop? (how break and continue behave)
    //   - 'break' jumps to patch
    //   - 'continue' jumps to patch
    
    < <string,variant> > blockList;
    bool definingLocals;
    bool DefiningLocals { get { return definingLocals; } }
    
    uint BlockDepth() { return blockList.Count; }
    
    <string,variant> Top()
    {
        uint iLast = blockList.Count;
        iLast--;
        <string,variant> blockContext = blockList[iLast];
        return blockContext;
    }
    <string,variant> GetMethodBlock()
    {
        <string,variant> methodBlock;
        uint iBlock = blockList.Count;
        loop
        {   
            if (iBlock == 0)
            {
                break;
            }
            iBlock--;
            <string,variant> blockContext = blockList[iBlock];
            if (blockContext.Contains("arguments"))
            {
                methodBlock = blockContext;
                break;
            }
        }
        return methodBlock;
    }
    
    AddLocal(string variableType, string identifier)
    {
        <string,variant> top = Top();
        < <string> > locals = top["locals"];
        <string> local;
        local.Append(variableType);
        local.Append(identifier);
        uint fromAddress = LastInstructionIndex;
        local.Append(fromAddress.ToString());
        locals.Append(local);
        top["locals"] = locals;
        ReplaceTop(top);
    }
    
    ReplaceTop(<string,variant> blockContext)
    {
        definingLocals = true;
        uint iLast = blockList.Count;
        iLast--;
        blockList.SetItem(iLast, blockContext);
    }
    
    bool AddBreakPatch(uint address)
    {
        bool success = false;
        uint iLoop = blockList.Count;
        loop
        {
            if (iLoop == 0)
            {
                break;
            }
            iLoop--;
            <string,variant> blockContext = blockList[iLoop];
            if (blockContext.Contains("breaks"))
            {
                <uint> breakPatches = blockContext["breaks"];
                breakPatches.Append(address);
                blockContext["breaks"] = breakPatches;
                blockList.SetItem(iLoop, blockContext);
                success = true;
                break;
            }
        }
        return success;    
    }
    
    bool AddContinuePatch(uint address)
    {
        bool success = false;
        uint iLoop = blockList.Count;
        loop
        {
            if (iLoop == 0)
            {
                break;
            }
            iLoop--;
            <string,variant> blockContext = blockList[iLoop];
            if (blockContext.Contains("continues"))
            {
                <uint> continuePatches = blockContext["continues"];
                continuePatches.Append(address);
                blockContext["continues"] = continuePatches;
                blockList.SetItem(iLoop, blockContext);
                success = true;
                break;
            }
        }
        return success;    
    }
    
    PushBlock(bool isLoopBlock)
    {
        definingLocals = false;
        <string,variant> blockContext;
        if (isLoopBlock)
        {
            <uint> breakPatches;
            blockContext["breaks"] = breakPatches;
            <uint> continuePatches;
            blockContext["continues"] = continuePatches;
        }
        < <string> > locals;
        blockContext["locals"] = locals;
        if (blockList.Count == 0)
        {
            < <string> > globals;
            blockContext["globals"] = globals;
        }
        blockList.Append(blockContext);
        <string,string> currToken = CurrentToken;
    }    
    
        
    PopBlock()
    {
        PopBlock(0, 0);
    }
    PopBlock(uint continueTarget, uint breakTarget)
    {
        uint iLast = blockList.Count;
        iLast--;
        Export(iLast);
        
        
#ifdef ASSEMBLER
        bool isUse = Asm6502.InUse;
#else
        bool isUse = CodeStream.InUse;
#endif
        if (isUse)
        {
#ifdef TRANSLATE
            Parser.ErrorAt(Parser.PreviousToken, "translate should not be generating code!!");
            Die(0x0B);
#endif
            uint slotsToPop = GetBytesToPop();
            if (slotsToPop > 0)
            {
#ifdef ASSEMBLER
                if (iLast == 0) 
                {
                    // Hopper exit
                }
                else if (Asm6502.LastInstructionIsRET(iLast == 0))
                {
                    // Return logic already dealt with
                }
                else
                {
                    Die(0x0A); // locals and arguments not supported yet
                }
#endif
                Instruction previousInstruction = CodeStream.GetLastInstruction();
                if ((previousInstruction != Instruction.RETB) 
                 && (previousInstruction != Instruction.RET)
                 && (previousInstruction != Instruction.RETRESB) 
                 && (previousInstruction != Instruction.RETRES)
                 && (previousInstruction != Instruction.RET0)
                   )
                {
                    <string,string> previousToken = Parser.PreviousToken;
                    HopperToken tokenType = Token.GetType(previousToken);
                    if (tokenType != HopperToken.RBrace)
                    {
                        if (!Parser.HadError)
                        {
                            Parser.ErrorAt(previousToken, "'}' expected in PopBlock(..)!!");
                            Die(0x0B);
                        }
                    }               
                    CodeStream.InsertDebugInfo(true); // PreviousToken is '}'
                    
                    if (slotsToPop > 255)
                    {
                        Die(0x0B); // need multiple calls to DECSP (see untested code below)
                    }
                    
                    CodeStream.AddInstruction(Instruction.DECSP, byte(slotsToPop));
                    if (breakTarget != 0)
                    {
                        breakTarget = breakTarget + 2; // break past the above DECSP
                    }
                    /*
                    uint breakOffset = 0;
                    while (slotsToPop > 0)
                    {
                        if (slotsToPop > 254)
                        {
                            CodeStream.AddInstruction(Instruction.DECSP, 254);
                            slotsToPop = slotsToPop - 254;
                        }
                        else
                        {
                            CodeStream.AddInstruction(Instruction.DECSP, byte(slotsToPop));
                            slotsToPop = 0;
                        }
                        breakOffset = breakOffset + 2;
                    }
                    if (breakTarget != 0)
                    {
                        breakTarget = breakTarget + breakOffset; // break past the above DECSP's
                    }
                    */
                }
            } // (slotsToPop > 0)

            <string,variant> blockContext = blockList[iLast];   
            if (blockContext.Contains("breaks"))
            {
                if ((continueTarget == 0) && (breakTarget == 0))
                {
                    if (!Parser.HadError)
                    {
                        Die(0x0B);
                    }
                }
                <uint> breakPatches = blockContext["breaks"];
                foreach (var breakJump in breakPatches)
                {
#ifdef ASSEMBLER
                    Asm6502.PatchJump(breakJump, breakTarget);
#else
                    CodeStream.PatchJump(breakJump, breakTarget);
#endif
                }
            }
            if (blockContext.Contains("continues"))
            {
                if ((continueTarget == 0) && (breakTarget == 0))
                {
                    if (!Parser.HadError)
                    {
                        Die(0x0B);
                    }
                }
                <uint> continuePatches = blockContext["continues"];
                foreach (var continueJump in continuePatches)
                {
#ifdef ASSEMBLER
                    Asm6502.PatchJump(continueJump, continueTarget);
#else
                    CodeStream.PatchJump(continueJump, continueTarget);
#endif
                }
            }
        }
        blockList.Remove(iLast);
        definingLocals = (blockList.Count <= 2);
    }
    
    uint GetBytesToPop()
    {
        return GetBytesToPop(false, false);
    }
    uint GetBytesToPop(bool toLoop, bool isContinue)
    {
        uint slotsToPop = 0;
        uint iLast = blockList.Count;
        loop
        {
            if (iLast == 0)
            {
                break;
            }
            iLast--;
            <string,variant> blockContext = blockList[iLast];
            uint popMore;
            if (!IsCDecl && blockContext.Contains("arguments"))
            {
                < < string > > arguments = blockContext["arguments"];
                popMore = popMore + arguments.Count; // slots for arguments
            }
            if (blockContext.Contains("locals"))
            {
                < < string > > locals = blockContext["locals"];
                popMore = popMore + locals.Count; // slots for locals
            }
            if (blockContext.Contains("globals"))
            {
                < < string > > globals = blockContext["globals"];
                popMore = popMore + globals.Count; // slots for globals
            }
            slotsToPop = slotsToPop + popMore;
            if (!toLoop)
            {
                break;
            }
            if (blockContext.Contains("breaks")) // loop block
            {
                if (isContinue)
                {
                    slotsToPop = slotsToPop - popMore;
                }
                break;
            }
        }
        return slotsToPop;
    }
    
    uint GetLocalsToPop(bool andArguments, bool andGlobals)
    {
        uint localsToPop = 0;
        uint iLast = blockList.Count;
        loop
        {
            if (iLast == 0)
            {
                break;
            }
            iLast--;
            <string,variant> blockContext = blockList[iLast];
            if (blockContext.Contains("locals"))
            {
                < < string > > locals = blockContext["locals"];
                localsToPop = localsToPop + locals.Count; // slots for locals
            }
            if (!IsCDecl && andArguments && blockContext.Contains("arguments"))
            {
                < < string > > arguments = blockContext["arguments"];
                localsToPop = localsToPop + arguments.Count; // slots for arguments
            }
            if (andGlobals && blockContext.Contains("globals"))
            {
                < < string > > globals = blockContext["globals"];
                localsToPop = localsToPop + globals.Count; // slots for globals
            }
        }
        return localsToPop;
    }
    
    int GetOffset(string identifier, ref bool isRef)
    {
        int offset;
        bool found;
        uint iCurrent = blockList.Count;
        < < string > > members;
        isRef = false;
        loop
        {
            if (iCurrent == 0)
            {
                break;
            }
            iCurrent--;
            <string,variant> blockContext = blockList[iCurrent];
            if (blockContext.Contains("locals"))
            {
                members = blockContext["locals"];        
                uint nlocals = members.Count;   
                for (uint i=0; i < nlocals; i++)
                {
                    <string> local = members[i];
                    string name = local[1];
                    if (name == identifier)
                    {
                        offset = int(i);
                        found = true;
                        break;
                    }
                }
            }
            if (blockContext.Contains("arguments"))
            {
                members = blockContext["arguments"];
                uint narguments = members.Count;
                for (uint i=0; i < narguments; i++)
                {
                    <string> argument = members[i];
                    string reference = argument[0];
                    string name = argument[2];
                    if (name == identifier)
                    {
                        if (found)
                        {
                            if (!Parser.HadError)
                            {
                                // This implies we have a local at the top scope with the same name as an argument
                                Die(0x0B); // Compiler should have caught this!
                            }
                        }
                        offset = (int(narguments) - int(i));
                        offset = 0 - offset;
                        if (reference.Length != 0)
                        {
                            isRef = true; // content of the stack slot is an absolute stack address
                        }
                        found = true;
                        break;
                    }
                }
            }
            if (found)
            {
                break;
            }
        } // loop
        
        if (found && (iCurrent != 0))
        {
            // must have been a local found in a nested block
            loop
            {
                // add the local size of all the surrounding blocks
                if (iCurrent == 0)
                {
                    break;
                }
                iCurrent--;
                <string,variant> blockContext = blockList[iCurrent];
                if (blockContext.Contains("locals"))
                {
                    members = blockContext["locals"];
                    uint nlocals = members.Count;
                    offset = offset + int(nlocals);
                }
            }
        }
        if (!found)
        {
            if (!Parser.HadError)
            {
                Parser.Error("offset not found for '" + identifier + "'");
                Die(0x0B); // Compiler should have caught this!
            }
        }
        
        return offset;
    } 
    
    string GetType(string identifier)
    {
        bool isLocal;
        return GetType(identifier, ref isLocal);
    }
    string GetType(string identifier, ref bool isLocal)
    {
        isLocal = false;
        string name;
        <string,variant> blockContext;
        < <string> > members;
        uint iCurrent = blockList.Count;
        loop
        {
            if (iCurrent == 0)
            {
                break;
            }
            iCurrent--;
            
            blockContext = blockList[iCurrent];
            if (blockContext.Contains("locals"))
            {
                // locals: < <type,name> >
                members = blockContext["locals"];
                foreach (var local in members)
                {
                    name = local[1];
                    if (name == identifier)
                    {
                        isLocal = true;
                        return local[0]; // typeString
                    }            
                }   
            }       
            if (blockContext.Contains("arguments"))
            {
                // arguments: < <ref,type,name> >
                members = blockContext["arguments"];
                foreach (var argument in members)
                {
                    name = argument[2];
                    if (name == identifier)
                    {
                        isLocal = true;
                        return argument[1]; // typeString
                    }        
                }
            }       
            if (blockContext.Contains("globals"))
            {
                // globals: < <type,name> >
                members = blockContext["globals"];
                foreach (var global in members)
                {
                    name = global[1];
                    if (name == identifier)
                    {
                        return global[0]; // typeString
                    }            
                }
            }       
        }
        return "";
    }
    
    bool LocalExists(string identifier)
    {
        bool localExists;
        string name;
        <string,variant> blockContext;
        < <string> > members;
        uint iCurrent = blockList.Count;
        loop
        {
            if (iCurrent == 0)
            {
                break;
            }
            iCurrent--;
            blockContext = blockList[iCurrent];
            if (blockContext.Contains("arguments"))
            {
                // arguments: < <ref,type,name> >
                members = blockContext["arguments"];
                foreach (var argument in members)
                {
                    name = argument[2];
                    if (name == identifier)
                    {
                        localExists = true;
                        break;
                    }        
                }
            }       
            if (blockContext.Contains("locals"))
            {
                // locals: < <type,name> >
                members = blockContext["locals"];
                foreach (var local in members)
                {
                    name = local[1];
                    if (name == identifier)
                    {
                        localExists = true;
                        break;
                    }            
                }   
            }   
        } // loop    
        return localExists;
    }
    /*
    bool LocalExists(string identifier)
    {
        bool exists;
        <string,variant> top = Top();
        < <string> > locals = top["locals"];
        uint nlocals = locals.Count;   
        for (uint i=0; i < nlocals; i++)
        {
            <string> local = locals[i]; // <type, name>
            string name = local[1];
            if (name == identifier)
            {
                return true;
            }
        }
        if (top.Contains("arguments"))
        {
            < <string> > arguments = top["arguments"];
            uint narguments = arguments.Count;   
            for (uint i=0; i < narguments; i++)
            {
                <string> argument = arguments[i]; // <ref, type, name>
                string name = argument[2];
                if (name == identifier)
                {
                    return true;
                }
            }
        }        
        return false;
    }
    */
    Export(uint iBlock)
    {
        <string,variant> blockContext = blockList[iBlock]; 
        < <string> > locals;
        if (blockContext.Contains("locals"))
        {
            locals = blockContext["locals"];
        }
        if (locals.Count != 0)
        {
            < <string> > localNamesAndTypes;
            
            uint toAddress = LastInstructionIndex;
            foreach (var local in locals)
            {
                <string> lstring = local;
                string ltype    = lstring[0];
                string lname    = lstring[1];
                string laddress = lstring[2];
                bool isRef;
                int loffset = GetOffset(lname, ref isRef); // always positive for locals (BP+offset)
                
                uint fromAddress;
                if (UInt.TryParse(laddress, ref fromAddress))
                {
                }
                <string> localNameAndType;
                // address range is unique because location of definition is unique
                localNameAndType.Append("0x" + fromAddress.ToHexString(4) + "-0x" + toAddress.ToHexString(4)); 
                localNameAndType.Append(lname);
                localNameAndType.Append(ltype);
                localNameAndType.Append(loffset.ToString()); // in theory, could be -ve (but never)
                
                localNamesAndTypes.Append(localNameAndType);
            }
            uint iOverload = Types.GetCurrentMethod();
            Symbols.AppendLocalNamesAndTypes(iOverload, localNamesAndTypes);
        }
    }
}
