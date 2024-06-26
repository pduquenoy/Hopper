### Hopper 6502 Assembly Syntax and Format

This document provides a comprehensive guide to the Hopper 6502 Assembly flavour. It is tailored to help future iterations of GPT understand and generate code that adheres to the Hopper 6502 Assembly conventions. The primary focus is on ensuring clarity, maintainability, and consistency in code generation.

#### General Formatting Rules

1. **Curly Braces:**
   - Opening curly braces `{` should typically be on their own line.
   - Example:
     ```assembly
     loop
     {
         // code block
     }
     ```

2. **Comments:**
   - Use `//` for comments, not `;`.
   - Example:
     ```assembly
     // This is a comment
     ```

3. **Indentation:**
   - Use consistent indentation for code blocks inside braces. Typically, a single level of indentation is two spaces.

4. **Line Breaks:**
   - Use line breaks to separate logical sections of code for better readability.

#### Instruction Format

1. **Labels and Functions:**
   - Define labels or function names followed by a colon `:`. However, labels within functions should be avoided in favour of structured control flow constructs like loops and conditionals.
   - Example:
     ```assembly
     MyFunction:
     ```

2. **Control Flow Constructs:**
   - Use structured control flow constructs (`if`, `loop`, `break`, `continue`) instead of jump instructions (`JMP`, `JZ`, etc.).

   - **If Statements:**
     ```assembly
     if (Z)
     {
         // code to execute if zero flag is set
     }
     ```

   - **Loop Statements:**
     ```assembly
     loop
     {
         // code block
         if (condition) { break; }
         if (condition) { continue; }
     }
     ```

#### Zero Page Variables

1. **Variable Declaration:**
   - Declare zero page variables at the beginning of the program using the `const` keyword.
   - Example:
     ```assembly
     const byte VAR1 = 0x00;
     const byte VAR2 = 0x01;
     ```

2. **Usage:**
   - Use zero page variables for frequently accessed data to optimize performance.
   - Example:
     ```assembly
     LDA VAR1
     STA VAR2
     ```

#### Memory and Stack Operations

1. **Load and Store:**
   - Use `LDA`, `STA`, `LDX`, `STX`, `LDY`, and `STY` for loading and storing data.
   - Example:
     ```assembly
     LDA #0x10
     STA VAR1
     ```

2. **Stack Operations:**
   - Use `PHA`, `PLA`, `PHP`, and `PLP` for pushing and pulling data to/from the stack.
   - Example:
     ```assembly
     PHA
     PLA
     ```

#### Function Calls and Returns

1. **Function Calls:**
   - Use `JSR` to call a subroutine. However, for clarity and maintainability, encapsulate function calls within meaningful method names.
   - Example:
     ```assembly
     Append();
     ```

2. **Function Returns:**
   - Use `RTS` to return from a subroutine. This is usually implied and not explicitly written in structured methods.

#### Encapsulation and Friend Classes

1. **Friend Classes:**
   - Use the `friend` keyword to allow specific units to access private methods of another unit.
   - Example:
     ```assembly
     unit List
     {
         friend GC;
     }
     ```

#### Sample Code Structure

Here is an example of a properly formatted Hopper 6502 Assembly code block:

```assembly
unit MyUnit
{
    // Declare zero page variables
    const byte VAR1 = 0x00;
    const byte VAR2 = 0x01;

    MyFunction()
    {
        // Load data into VAR1
        LDA #0x10
        STA VAR1

        // Conditional check
        if (Z)
        {
            // Code block
            LDA VAR1
            STA VAR2
        }

        // Loop example
        loop
        {
            LDA VAR1
            if (Z) { break; }

            INC VAR1
            if (C) { continue; }

            LDA VAR1
            STA VAR2
        }
    }
}
```

### Key Takeaways

- **Consistency**: Always follow the same style for braces, comments, and indentation.
- **Structure**: Use structured control flow constructs instead of labels and jumps for better readability and maintainability.
- **Encapsulation**: Use the `friend` keyword to manage access to private methods across units.
- **Optimization**: Utilize zero page variables and stack operations for efficient memory management.
- **Method Calls**: Use method calls rather than direct `JSR` instructions for better readability and maintainability.

This guide ensures that future iterations of GPT can generate and understand Hopper 6502 Assembly code that is clean, efficient, and maintainable.