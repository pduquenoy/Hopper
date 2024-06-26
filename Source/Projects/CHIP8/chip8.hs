program CHIP8
{
    // https://github.com/mattmikolay/chip-8/wiki/CHIP%E2%80%908-Technical-Reference
    
    // Quirks:
    // https://chip-8.github.io/database/#options
    
    // https://johnearnest.github.io/chip8Archive/
    // https://github.com/JohnEarnest/chip8Archive
    
    uses "/Source/Library/Devices/WSPicoLCD144"
    uses "/Source/Library/Fonts/Hitachi5x7"
    
    //uses "/Source/System/System"
    //uses "/Source/System/Screen"
    //uses "/Source/System/Keyboard"
    
    // Constants for the LCG
    const uint A = 75;      // Multiplier
    const uint C = 74;      // Increment
    const uint M = 65535;   // Modulus (2^16 - 1)
    uint seed;
    long lastTime; // Last recorded time in millis / 17
    
    const byte[] fontSet = {
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80  // F
    };
    
    // Memory and registers
    byte[4096] memory;
    byte[16] v;
    uint i;
    uint pc;
    uint[16] stack;
    byte sp;
    uint delayTimer;
    uint soundTimer;
    
    byte[8] rplFlags; // Define RPL user flags
    
    bool running;
 
    bool extendedScreenMode; // Flag for extended screen mode
    bool[128 * 64] display; // Each element is either false (off) or true (on) 
    byte pWidth;
    byte pHeight;   
    uint xOffset;
    uint yOffset;
    
    bool[16] keyState;
    
    disableExtendedScreen()
    {
        extendedScreenMode = false;
        // Additional code to handle switching back to standard screen mode
        // For example, clearing the screen or adjusting the display array
        CHIP8.Clear();
        xOffset = 32;
        yOffset = 16;
        pWidth  = 64;
        pHeight = 32;
    }
    enableExtendedScreen()
    {
        extendedScreenMode = true;
        // Additional code to handle switching to extended screen mode
        // For example, clearing the screen or adjusting the display array
        CHIP8.Clear();
        xOffset = 0;
        yOffset = 0;
        pWidth  = 128;
        pHeight = 64;
    }
    
    bool GetPixel(byte x, byte y)
    {
        x = x % pWidth;
        y = y % pHeight;
        
        uint index = x + y * 128;
        return display[index];
    }
    SetPixel(byte x, byte y, bool value)
    {
        x = x % pWidth;
        y = y % pHeight;
    
        uint index = x + y * 128;
        display[index] = value;
        //Display.SetPixel(int(xOffset + x), int(yOffset + y), value ? Colour.White : Colour.Black);
        
        x *= 2;
        y *= 2;
        
        Display.SetPixel(x,   y,   value ? Colour.White : Colour.Black);
        Display.SetPixel(x+1, y,   value ? Colour.White : Colour.Black);
        Display.SetPixel(x,   y+1, value ? Colour.White : Colour.Black);
        Display.SetPixel(x+1, y+1, value ? Colour.White : Colour.Black);
        
    }
    
    Clear()
    {
        for (uint j = 0; j < 128 * 64; j++) { display[j] = false; }        
        Display.Clear();
    }
    
    // CHIP-8 Keypad Layout:
    //
    // Keypad              Indices
    //
    // 1 2 3 C             1 2 3 C
    // 4 5 6 D             4 5 6 D
    // 7 8 9 E             7 8 9 E
    // A 0 B F             A 0 B F
    //
    
    
    UpdateKeyStates()
    {
        //keyState[0x4] = Button0;
        //keyState[0x5] = Button1;
        //keyState[0x6] = Button2;
        //keyState[0xD] = Button3;
        
        // Invaders:
        keyState[0x4] = Button0; // <--
        keyState[0x5] = Button1; // shoot
        keyState[0x5] = Button2; // shoot
        keyState[0x6] = Button3; // -->
        
        // bottom row
        //keyState[0xA] = Button0;
        //keyState[0x0] = Button1;
        //keyState[0xB] = Button2;
        //keyState[0xF] = Button3;
        
        // for quirks test:
        //keyState[0xA] = Button0; // select
        //keyState[0xF] = Button2; // down
        //keyState[0xE] = Button3; // up
        
        //keyState[0x1] = Button0; // 1
        //keyState[0x2] = Button2; // 2
        //keyState[0x3] = Button3; // 3
    }
    
    ResetKeyStates()
    {
        for (byte i = 0; i < 16; i++)
        {
            keyState[i] = false;
        }
    }
    
    
    
    
    Initialize()
    {
        // Initialize registers and memory
        pc = 0x200;  // Program counter starts at 0x200
        i = 0;
        sp = 0;
        
        uint j;
        // Clear display, stack, registers, memory
        for (j = 0; j < 4096; j++) { memory[j] = 0; }
        for (j = 0; j < 16; j++) { v[j] = 0; }
        for (j = 0; j < 16; j++) { stack[j] = 0; }
        
        for (j = 0; j < 7; j++)  { rplFlags[j] = 0; }
        
        long now = Time.Millis;
        seed = UInt.FromBytes(now.GetByte(0), now.GetByte(1));
        lastTime = Time.Seconds; // Initialize lastTime
        // Load font set into memory
        j = 0;
        foreach (var f in fontSet)
        {
            memory[0x50 + j] = f;
            j++;
        }
        disableExtendedScreen();
    }
    
    byte random(byte n, byte m)
    {
        seed = (A * seed + C) % M;
        return byte(n + seed % (m - n));
    }
    
    scrollRight()
    {
        for (uint y = 0; y < 64; y++)
        {
            for (uint x = 127; x >= 4; x--)
            {
                display[x + y * 128] = display[(x - 4) + y * 128];
            }
            for (uint x = 0; x < 4; x++)
            {
                display[x + y * 128] = false; // Clear the left 4 columns
            }
        }
    }
    scrollLeft()
    {
        for (uint y = 0; y < 64; y++)
        {
            for (uint x = 0; x < 124; x++)
            {
                display[x + y * 128] = display[(x + 4) + y * 128];
            }
            for (uint x = 124; x < 128; x++)
            {
                display[x + y * 128] = false; // Clear the right 4 columns
            }
        }
    }
    scrollDown(byte n)
    {
        for (uint y = 63; y >= n; y--)
        {
            for (uint x = 0; x < 128; x++)
            {
                display[x + y * 128] = display[x + (y - n) * 128];
            }
        }
        for (uint y = 0; y < n; y++)
        {
            for (uint x = 0; x < 128; x++)
            {
                display[x + y * 128] = false; // Clear the top n rows
            }
        }
    }
    exitProgram()
    {
        // In a real environment, you might set a flag or call an exit function
        // Since this is an interpreter, you can stop the main loop or return
        // For this example, let's assume we set a running flag to false
        running = false;
    }
        
    EmulateCycle()
    {
        // Fetch
        uint opcode = (memory[pc] << 8) | memory[pc + 1];
        byte opCodeMSN = byte(opcode >> 12);
    
        // Decode and execute using switch on an 8-byte value
        switch (opCodeMSN)
        {
            case 0x0:
            {
                switch (opcode)
                {
                    case 0x00E0:
                    {
                        // 00E0: Clears the screen
                        CHIP8.Clear();
                        pc += 2;
                    }
                    case 0x00EE:
                    {
                        // 00EE: Returns from a subroutine
                        sp -= 1;
                        pc = stack[sp];
                        pc += 2;
                    }
                    case 0x00FB:
                    {
                        // 00FB: Scroll display 4 pixels right
                        scrollRight();
                        pc += 2;
                    }
                    case 0x00FC:
                    {
                        // 00FC: Scroll display 4 pixels left
                        scrollLeft();
                        pc += 2;
                    }
                    case 0x00FD:
                    {
                        // 00FD: Exit CHIP-48 program
                        exitProgram();
                        pc += 2;
                    }
                    case 0x00FE:
                    {
                        // 00FE: Disable extended screen mode
                        disableExtendedScreen();
                        pc += 2;
                    }
                    case 0x00FF:
                    {
                        // 00FF: Enable extended screen mode for full-screen graphics
                        enableExtendedScreen();
                        pc += 2;
                    }
                    case 0x00C0:
                    {
                        // 00Cn: Scroll display n pixels down (CHIP-48 only)
                        byte n = byte(opcode & 0x000F);
                        scrollDown(n);
                        pc += 2;
                    }
                    default:
                    {
                        Die(0x0A); // not implemented?
                    }
                }
            }
            case 0x1:
            {
                // 1NNN: Jumps to address NNN
                pc = opcode & 0x0FFF;
            }
            case 0x2:
            {
                // 2NNN: Calls subroutine at NNN
                stack[sp] = pc;
                sp += 1;
                pc = opcode & 0x0FFF;
            }
            case 0x3:
            {
                // 3XNN: Skips the next instruction if VX equals NN
                uint x = (opcode & 0x0F00) >> 8;
                byte nn = byte(opcode & 0x00FF);
                if (v[x] == nn)
                {
                    pc += 4;
                }
                else
                {
                    pc += 2;
                }
            }
            case 0x4:
            {
                // 4XNN: Skips the next instruction if VX does not equal NN
                uint x = (opcode & 0x0F00) >> 8;
                byte nn = byte(opcode & 0x00FF);
                if (v[x] != nn)
                {
                    pc += 4;
                }
                else
                {
                    pc += 2;
                }
            }
            case 0x5:
            {
                // 5XY0: Skips the next instruction if VX equals VY
                uint x = (opcode & 0x0F00) >> 8;
                uint y = (opcode & 0x00F0) >> 4;
                if (v[x] == v[y])
                {
                    pc += 4;
                }
                else
                {
                    pc += 2;
                }
            }
            case 0x6:
            {
                // 6XNN: Set VX to NN
                uint x = (opcode & 0x0F00) >> 8;
                byte nn = byte(opcode & 0x00FF);
                v[x] = nn;
                pc += 2;
            }
            case 0x7:
            {
                // 7XNN: Adds NN to VX (Carry flag is not changed)
                uint x = (opcode & 0x0F00) >> 8;
                byte nn = byte(opcode & 0x00FF);
                v[x] = v[x] + nn;
                pc += 2;
            }
            case 0x8:
            {
                uint x = (opcode & 0x0F00) >> 8;
                uint y = (opcode & 0x00F0) >> 4;
                uint opCodeLSN = byte(opcode & 0x000F);
                byte flag;
                switch (opCodeLSN)
                {
                    case 0x0:
                    {
                        // 8XY0: Set VX to the value of VY
                        v[x] = v[y];
                        pc += 2;
                    }
                    case 0x1:
                    {
                        // 8XY1: Set VX to VX OR VY
                        v[x] = v[x] | v[y];
                        v[0xF] = 0;
                        pc += 2;
                    }
                    case 0x2:
                    {
                        // 8XY2: Set VX to VX AND VY
                        v[x] = v[x] & v[y];
                        v[0xF] = 0;
                        pc += 2;
                    }
                    case 0x3:
                    {
                        // 8XY3: Set VX to VX XOR VY
                        v[x] = v[x] ^ v[y];
                        v[0xF] = 0;
                        pc += 2;
                    }
                    case 0x4:
                    {
                        // 8XY4: Add VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't
                        if (v[y] > (0xFF - v[x]))
                        {
                            flag = 1; // Carry
                        }
                        else
                        {
                            flag = 0;
                        }
                        v[x] = v[x] + v[y];
                        v[0xF] = flag;
                        pc += 2;
                    }
                    case 0x5:
                    {
                        // 8XY5: VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't
                        if (v[x] >= v[y])
                        {
                            flag = 1;
                        }
                        else
                        {
                            flag = 0;
                        }
                        v[x] = v[x] - v[y];
                        v[0xF] = flag;
                        pc += 2;
                    }
                    case 0x6:
                    {
                        // 8XY6: Store the least significant bit of VX in VF and then shifts VX to the right by 1
                        flag = v[x] & 0x1;
                        v[x] = v[x] >> 1;
                        v[0xF] = flag;
                        pc += 2;
                    }
                    case 0x7:
                    {
                        // 8XY7: Set VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't
                        if (v[y] >= v[x])
                        {
                            flag = 1;
                        }
                        else
                        {
                            flag = 0;
                        }
                        v[x] = v[y] - v[x];
                        v[0xF] = flag;
                        pc += 2;
                    }
                    case 0xE:
                    {
                        // 8XYE: Store the most significant bit of VX in VF and then shifts VX to the left by 1
                        flag = (v[x] >> 7) & 0x1;
                        v[x] = v[x] << 1;
                        v[0xF] = flag;
                        pc += 2;
                    }
                    default:
                    {
                        Die(0x0A); // not implemented?
                    }
                }
            }
            case 0x9:
            {
                // 9XY0: Skip next instruction if VX not equal to VY
                uint x = (opcode & 0x0F00) >> 8;
                uint y = (opcode & 0x00F0) >> 4;
                if (v[x] != v[y])
                {
                    pc += 4;
                }
                else
                {
                    pc += 2;
                }
            }
            case 0xA:
            {
                // ANNN: Set I to the address NNN
                i = opcode & 0x0FFF;
                pc += 2;
            }
            case 0xB:
            {
                // BNNN: Jump to the address NNN plus V0
                pc = (opcode & 0x0FFF) + v[0];
            }
            case 0xC:
            {
                // CXNN: Set VX to a random number and NN
                uint x = (opcode & 0x0F00) >> 8;
                byte nn = byte(opcode & 0x00FF);
                v[x] = random(0, nn);
                pc += 2;
            }
            case 0xD:
            {
                // DXYN: Draw a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels.
                // Each row of 8 pixels is read as bit-coded starting from memory location I; 
                // I value doesnt change after the execution of this instruction.
                // VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, 
                // and to 0 if that doesnt happen
                uint x = (opcode & 0x0F00) >> 8;
                uint y = (opcode & 0x00F0) >> 4;
                byte height = byte(opcode & 0x000F);
                uint pixel;
            
                v[0xF] = 0;
                for (byte yline = 0; yline < height; yline++)
                {
                    pixel = memory[i + yline];
                    for (byte xline = 0; xline < 8; xline++)
                    {
                        if ((pixel & (0x80 >> xline)) != 0)
                        {
                            byte xCoord = (v[x] + xline);
                            byte yCoord = (v[y] + yline);
                            bool currentPixel = CHIP8.GetPixel(xCoord, yCoord);
                            if (currentPixel)
                            {
                                v[0xF] = 1; // Collision detection
                            }
                            CHIP8.SetPixel(xCoord, yCoord, !currentPixel);
                        }
                    }
                }
                pc += 2;
            }
            case 0xE:
            {
                uint opCodeLSN = byte(opcode & 0x000F);
                switch (opCodeLSN)
                {
                    case 0xE:
                    {
                        // EX9E: Skips the next instruction if the key stored in VX is pressed
                        uint x = (opcode & 0x0F00) >> 8;
                        if (keyState[v[x]])
                        {
                            pc += 4;
                        }
                        else
                        {
                            pc += 2;
                        }
                    }
                    case 0x1:
                    {
                        // EXA1: Skips the next instruction if the key stored in VX is not pressed
                        uint x = (opcode & 0x0F00) >> 8;
                        if (!keyState[v[x]])
                        {
                            pc += 4;
                        }
                        else
                        {
                            pc += 2;
                        }
                    }
                    default:
                    {
                        Die(0x0A); // not implemented?
                    }
                }
            }
            case 0xF:
            {
                uint opCodeLSB = byte(opcode & 0x00FF);
                switch (opCodeLSB)
                {
                    case 0x07:
                    {
                        // FX07: Set VX to the value of the delay timer
                        uint x = (opcode & 0x0F00) >> 8;
                        v[x] = byte(delayTimer & 0xFF);
                        pc += 2;
                    }
                    case 0x0A:
                    {
                        // FX0A: A key press is awaited, and then stored in VX (blocking operation, all instruction halted until next key event)
                        uint x = (opcode & 0x0F00) >> 8;
                        bool keyPress = false;
                        loop
                        {
                            // Continuously check for key presses until one is detected
                            UpdateKeyStates();
                            for (byte i = 0; i < 16; i++)
                            {
                                if (keyState[i])
                                {
                                    v[x] = i;
                                    keyPress = true;
                                    break;
                                }
                            }
                            if (keyPress) { break; }
                        }
                        pc += 2;
                    }
                    case 0x15:
                    {
                        // FX15: Set delay timer = VX
                        uint x = (opcode & 0x0F00) >> 8;
                        delayTimer = v[x];
                        pc += 2;
                    }
                    case 0x18:
                    {
                        // FX18: Set sound timer = VX
                        uint x = (opcode & 0x0F00) >> 8;
                        soundTimer = v[x];
                        pc += 2;
                    }
                    case 0x1E:
                    {
                        // FX1E: Set I = I + VX
                        uint x = (opcode & 0x0F00) >> 8;
                        i = i + v[x];
                        pc += 2;
                    }
                    case 0x29:
                    {
                        // FX29: Set I = location of sprite for digit VX
                        uint x = (opcode & 0x0F00) >> 8;
                        i = v[x] * 0x5;
                        pc += 2;
                    }
                    case 0x30:
                    {
                        // FX30: Set I = location of extended sprite for digit VX (10 bytes per digit)
                        uint x = (opcode & 0x0F00) >> 8;
                        i = v[x] * 0xA;
                        pc += 2;
                    }
                    case 0x33:
                    {
                        // FX33: Store BCD representation of VX in memory locations I, I+1, and I+2
                        uint x = (opcode & 0x0F00) >> 8;
                        memory[i] = v[x] / 100;
                        memory[i + 1] = (v[x] / 10) % 10;
                        memory[i + 2] = (v[x] % 100) % 10;
                        pc += 2;
                    }
                    case 0x55:
                    {
                        // FX55: Store registers V0 through VX in memory starting at location I
                        uint x = (opcode & 0x0F00) >> 8;
                        for (uint idx = 0; idx <= x; idx++)
                        {
                            memory[i + idx] = v[idx];
                        }
                        i = i + x + 1; // Increment I
                        pc += 2;
                    }
                    case 0x65:
                    {
                        // FX65: Read registers V0 through VX from memory starting at location I
                        uint x = (opcode & 0x0F00) >> 8;
                        for (uint idx = 0; idx <= x; idx++)
                        {
                            v[idx] = memory[i + idx];
                        }
                        i = i + x + 1; // Increment I
                        pc += 2;
                    }
                    case 0x75:
                    {
                        // FX75: Store V0 through VX in RPL user flags (X <= 7)
                        uint x = (opcode & 0x0F00) >> 8;
                        for (uint idx = 0; idx <= x; idx++)
                        {
                            rplFlags[idx] = v[idx];
                        }
                        pc += 2;
                    }
                    case 0x85:
                    {
                        // FX85: Read V0 through VX from RPL user flags (X <= 7)
                        uint x = (opcode & 0x0F00) >> 8;
                        for (uint idx = 0; idx <= x; idx++)
                        {
                            v[idx] = rplFlags[idx];
                        }
                        pc += 2;
                    }
                    default:
                    {
                        Die(0x0A); // not implemented?
                    }
                }
            }
            default:
            {
                Die(0x0A); // not implemented?
            }
        }
    }
    
    UpdateTimers()
    {
        long currentTime = Time.Millis / 17;
        if (currentTime > lastTime)
        {
            long elapsedTicks = currentTime - lastTime;
            if (elapsedTicks > 0)
            {
                if (delayTimer > 0)
                {
                    if (delayTimer > uint(elapsedTicks))
                    {
                        delayTimer -= uint(elapsedTicks);
                    }
                    else
                    {
                        delayTimer = 0;
                    }
                }
                if (soundTimer > 0)
                {
                    if (soundTimer > uint(elapsedTicks))
                    {
                        soundTimer -= uint(elapsedTicks);
                    }
                    else
                    {
                        soundTimer = 0;
                        // TODO: stop the sound here
                    }
                }
                lastTime = currentTime;
            }
        }
    }
        
    bool LoadGame()
    {
        bool success;
        loop
        {
            // https://github.com/Timendus/chip8-test-suite/blob/main/README.md
            // https://github.com/loktar00/chip8/tree/master
            // https://github.com/kripod/chip8-roms/tree/master/games
            
            //string filePath = "/Tests/5.ch8";
            //string filePath = "/Games/invaders.ch8";
            string filePath = "/Games/blinky.ch8";
        
        
            // Ensure the file exists
            if (!File.Exists(filePath))
            {
                // Handle the error, for example:
                WriteLn("File not found: " + filePath);
                break;
            }
        
            // Open the file
            file gameFile = File.Open(filePath);
            if (!gameFile.IsValid())
            {
                // Handle the error, for example:
                WriteLn("Failed to open file: " + filePath);
                break;
            }
        
            // Load the game into memory starting at address 0x200
            uint loadAddress = 0x200;
            loop
            {
                byte data = gameFile.Read();
                if (!gameFile.IsValid()) { break; }
        
                memory[loadAddress] = data;
                loadAddress++;
            }
            success = true;
            break;
        }
        return success;
    }
    
    
    
    Hopper()
    {
        if (!DeviceDriver.Begin())
        {
            IO.WriteLn("Failed to initialize Waveshare Pico-LCD-1.44");
            return;
        }
        
        Initialize();
        if (LoadGame())
        {
            long cycles;
            long start = Millis;
            
            running = true;
            // Main emulation loop
            while (running)
            {
                ResetKeyStates();  // Reset key states for the new frame
                UpdateKeyStates(); // Update the key states
            
                EmulateCycle();
                cycles++;
                
                UpdateTimers(); // Update the delay and sound timers
                if (soundTimer > 0)
                {
                    // TODO : start sound here
                }
                Time.Delay(1);
                if (cycles % 1000 == 0)
                {
                    long elapsed = Millis - start;
                    float seconds = elapsed / 1000.0;
                    float speed = 1.0 * cycles / seconds;
                    WriteLn(cycles.ToString() + " cycles, " + seconds.ToString() + " s, " + speed.ToString() + " cycles/s");
                }
            }
        }
    }
}

