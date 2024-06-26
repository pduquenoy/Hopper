**Note:**  - this is a work in progress between ChatGPT and me. It will improve as ChatGPT's knowledge of the language improves.

Sure, I'll adjust the section with your provided sample for the `program` and use examples from the `MCU` unit for the `unit` section.

---

## Programs and Units in Hopper

Hopper organizes code into two primary constructs: `program` and `unit`. These constructs help structure the code, making it modular and maintainable, similar to how Turbo Pascal separates program logic from reusable modules.

### Program
- **Purpose**: The `program` block is the main entry point of a Hopper application. It contains the core logic, including setup and loop functions.
- **Structure**: A `program` in Hopper is enclosed in a `program` block and typically includes an initialization method (`Setup`) and an entry point method (`Hopper`) which contains the main loop.
- **Example**:
  ```hopper
  program Blink
  {
      uses "/Source/Library/Boards/CytronMakerPiRP2040"
      
      // Initialize the built-in LED pin
      Setup()
      {
          MCU.PinMode(Board.BuiltInLED, MCU.PinModeOption.Output);
      }

      // Entry point
      Hopper()
      {
          Blink.Setup();
          loop
          {
              // Turn the LED on
              MCU.DigitalWrite(Board.BuiltInLED, true);
              Time.Delay(1000); // Delay for 1000 milliseconds (1 second)
              
              // Turn the LED off
              MCU.DigitalWrite(Board.BuiltInLED, false);
              Time.Delay(1000); // Delay for 1000 milliseconds (1 second)
          }
      }
  }
  ```

### Unit
- **Purpose**: A `unit` in Hopper defines reusable components or libraries. Units can include functions, constants, and other definitions that can be imported into programs or other units.
- **Structure**: A `unit` block is enclosed in a `unit` block and contains definitions and implementations pertinent to specific functionalities.
- **Example**:
  ```hopper
  unit MCU
  {
      uses "/Source/System/System"
      uses "/Source/System/Runtime"
      uses "/Source/System/IO"

      flags PinModeOption
      {
          Input         = 0x00,
          Output        = 0x01,
          InputPullup   = 0x02,
          InputPulldown = 0x03,
      }

      enum PinStatus
      {
          Low = 0,
          High = 1,
          Change = 2,
          Falling = 3,
          Rising = 4,
      }
      
      delegate PinISRDelegate(byte pin, PinStatus status);

      PinMode(byte pin, PinModeOption pinMode) library;
      bool DigitalRead(byte pin) library;
      DigitalWrite(byte pin, bool value) library;
      uint AnalogRead(byte pin) library;
      AnalogWrite(byte pin, uint value) library;
      AnalogWriteResolution(byte bits) library;

      bool AttachToPin(byte pin, PinISRDelegate gpioISR, PinStatus status) library;

      bool InterruptsEnabled { get library; set library; }
  }
  ```

### Comparison to Turbo Pascal
- **Separation**: Both Hopper and Turbo Pascal use the concept of `program` and `unit` to modularize code, but Hopper enforces a stricter separation by requiring them to be in separate files.
- **Structure**: Hopper has a more rigid structure, especially with the use of curly braces `{}` for blocks and requiring all code to be within well-defined sections.
- **Entry Point**: In both languages, the `program` block serves as the entry point, but Hopper uses `Hopper()` as the main entry method, while Turbo Pascal uses the `begin...end.` block.

This structure encourages modularity and reusability in Hopper, making it easier to manage and maintain complex applications.


## Loops in Hopper

Here's a summary of the loop constructs in Hopper, including the use of `break` and `continue`:

### `loop`:
- The `loop` construct in Hopper is a simple infinite loop that repeats until explicitly exited using `break`.
- It doesn't have any built-in conditions or initialization, making it suitable for cases where you need to repeatedly execute a block of code.
- Example:
  ```hopper
  loop
  {
      // Code to repeat indefinitely
      if (condition)
      {
          break; // Exit the loop based on a condition
      }
  }
  ```

### `for`:
- The `for` loop in Hopper is similar to traditional `for` loops in other languages, allowing you to iterate over a range of values.
- It consists of an initialization, a condition, and an iteration statement, separated by semicolons.
- Example:
  ```hopper
  for (uint i = 0; i < 10; i++)
  {
      // Code to repeat 10 times
  }
  ```

### `foreach`:
- The `foreach` loop in Hopper is used to iterate over elements of a collection, such as a list or dictionary.
- It automatically iterates over each element, assigning it to a variable for processing.
- Example:
  ```hopper
  foreach (var element in myList)
  {
      // Process each element of the list
  }
  ```

### `while`:
- The `while` loop in Hopper repeats a block of code as long as a specified condition is true.
- It evaluates the condition before each iteration, so it may not execute at all if the condition is false initially.
- Example:
  ```hopper
  uint i = 0;
  while (i < 10)
  {
      // Code to repeat as long as i is less than 10
      i++;
  }
  ```

### `break`:
- The `break` statement is used to exit a loop prematurely, regardless of the loop's condition.
- It can be used in `for`, `foreach`, `while`, and `loop` constructs to immediately exit the innermost loop.
- Example:
  ```hopper
  loop
  {
      // Some condition to exit the loop
      if (condition)
      {
          break; // Exit the loop
      }
  }
  ```

### `continue`:
- The `continue` statement is used to skip the rest of the current iteration and start the next iteration of the loop.
- It can be used in `for`, `foreach`, `while`, and `loop` constructs to jump to the next iteration without executing the remaining code in the loop's body.
- Example:
  ```hopper
  for (uint i = 0; i < 10; i++)
  {
      // Skip even numbers
      if (i % 2 == 0)
      {
          continue; // Skip the rest of the loop body for even numbers
      }
      // Code here will only be executed for odd numbers
  }
  ```


### Hopper Switch Statement

The switch statement in Hopper allows you to conditionally execute code based on the value of a variable. It has several unique features
compared to other languages like C, C++, and C#.

#### Basic Syntax
The basic syntax of the switch statement in Hopper is as follows:

```hopper
switch (variable)
{
    case value1:
    {
        // code to execute if variable equals value1
    }
    case value2:
    {
        // code to execute if variable equals value2
    }
    // more cases...
    default:
    {
        // code to execute if variable does not match any case
    }
}
```

#### No Need for Break
Unlike C and its derivatives, Hopper **does not allow** the use of `break` statements after each case.
The code execution will **never** fall through to the next case. `break` is reserved for loop constructs.

#### Streamlined Control Flow for Loop and Switch Integration

In Hopper, `break` and `continue` are dedicated solely to managing loop control and are not used within switch cases. This clear delineation enhances control flow management within nested structures and provides several key advantages:

1. **Clear Intent**: Using `break` or `continue` within a switch case that is nested inside a loop makes it unequivocally clear that the intention is to control the loop, not to exit a switch case. This clarity helps in maintaining the readability and straightforwardness of the code.

2. **Simplified Logic**: Developers are not required to implement additional mechanisms like boolean flags or complex conditional structures to exit loops from within switch cases. This straightforward approach avoids extra code overhead and potential errors from more complex control flow manipulations.

3. **Enhanced Maintainability**: Code that exhibits straightforward and predictable behavior is easier to maintain and debug. A `break` or `continue` statement in a loop behaves consistently, whether it's inside a switch statement or not, simplifying the troubleshooting and modification processes.

4. **Consistent Behavior Across Contexts**: By ensuring that `break` and `continue` have uniform functionality across all usage contexts, Hopper provides a consistent developer experience when writing and reading code, even in complex applications with nested loops and switch cases.

This design not only prevents common errors but also enhances the usability of control statements, making them effective tools for managing the program's flow, particularly in complex scenarios.


#### Supported Variable Types
In Hopper, switch cases can be of various types including bool, char, byte, uint, int, and string. 

```hopper
string fruit = "Apple";
switch (fruit.ToLower())
{
    case "apple":
    {
        Screen.PrintLn("It's an apple!");
    }
    case "banana":
    {
        Screen.PrintLn("It's a banana!");
    }
    case "orange":
    {
        Screen.PrintLn("It's an orange!");
    }
    default:
    {
        Screen.PrintLn("Unknown fruit!");
    }
}
```

It also allows for flexible matching if your switch case `variable` is of `variant` type.

```hopper
switch (variable)
{
    case 'A':
    {
        Print("Uppercase A");
    }
    case 'a':
    {
        Print("Lowercase a");
    }
    case true:
    {
        Print("Boolean true");
    }
    case 42:
    {
        Print("The answer");
    }
    case "hello":
    {
        Print("The greeting");
    }
    default:
    {
        Print("Default");
    }
}
```

#### Stacking Case Labels
Hopper allows you to stack multiple case labels, making it more convenient to execute the same code for multiple values.

```hopper
switch (variable)
{
    case '1':
    case '2':
    case '3':
    {
        Print("One, Two, or Three");
    }
    default:
    {
        Print("Default");
    }
}
```

#### Integer Range Syntax
You can use range syntax in cases to match a range of values when those values are byte or char type.

```hopper
switch (variable)
{
    case 'a'..'z', 'A'..'Z':
    {
        Print("Alphabetic character");
    }
    case '0'..'9':
    {
        Print("Numeric character");
    }
    default:
    {
        Print("Default");
    }
}
```

#### Conclusion
The switch statement in Hopper offers flexibility and readability with its unique features like no fall-through,
support for various variable types in cases, stacking case labels, and integer range syntax. Understanding these
features can help you write more expressive and concise code in Hopper.


## Using Delegates in Hopper

Delegates in Hopper are typed function pointers that allow you to assign and pass references to functions within your program. This feature is particularly useful for implementing callbacks and handling events, such as user interactions or timer expirations.

### Definition and Usage

A delegate in Hopper is defined by specifying the function signature it supports. Once defined, you can assign any function that matches this signature to a delegate variable and call the function through the delegate.

### Example: Setting Up a Button Event Handler

```hopper
// Define a delegate type for a button event handler
delegate void ButtonEventHandler(byte pin, PinStatus status);

// Define a function that matches the delegate signature
void ButtonPressedHandler(byte pin, PinStatus status)
{
    if (status == PinStatus.Pressed)
    {
        IO.WriteLn("Button on pin " + pin.ToString() + " was pressed.");
    }
}

Hopper()
{
    ButtonEventHandler buttonHandler = ButtonPressedHandler; // Assigning function to delegate

    // Setup button event with the delegate
    SetupButtonEvent(1, buttonHandler); // Assume SetupButtonEvent sets up the hardware event

    // Continue with other tasks or enter a sleep mode
}
```

### Benefits of Using Delegates

- **Type Safety**: Delegates provide type safety, ensuring that only functions with the correct signature can be assigned to a delegate type, reducing runtime errors.

- **Modularity**: Delegates enhance modularity and reusability by allowing functions to be passed as parameters or stored as variables, making your code more flexible and easier to manage.

- **Event Handling**: Delegates are ideal for handling events in a controlled and efficient manner, especially in embedded systems where resources are limited and reliability is critical.


## Language Comparison

This table summarizes the key differences in syntax and features between Hopper, C, C#, and Java.


| Feature            | Hopper                                | C                          | C#                              | Java                            |
|----------------------|--------------------------------------|----------------------------|---------------------------------|---------------------------------|
| Type System          | Value types: int, uint, char<br>Reference types: list, string, dictionary | Primitive types: int, char, etc.<br>Structs, enums, unions, pointers | Primitive types: int, char, etc.<br>Reference types: classes, interfaces, delegates | Primitive types: int, char, etc.<br>Reference types: classes, interfaces, enums |
| Method Definition    | Methods defined with a code block between curly braces, no 'system' keyword | Functions and methods defined with curly braces, no special keyword | Methods defined with a code block between curly braces, 'system' keyword for system methods | Methods defined with a code block between curly braces, no special keyword |
| Variable Declaration | Requires type name, `var` only for loop iterators | Requires type name, no `var` keyword | `var` keyword for implicit type inference | `var` keyword for implicit type inference |
| Loop Statements      | Requires curly braces even for single statements | Requires curly braces even for single statements | Requires curly braces even for single statements | Requires curly braces even for single statements |
| Conditional Statements | Uses `while` for loops | Uses `while` for loops | Uses `while` for loops | Uses `while` for loops |
| Passing Arguments    | Uses `ref` keyword for passing arguments as references | Uses pointers for passing arguments by reference | Uses `ref` keyword for passing arguments as references | Uses `ref` keyword for passing arguments as references |
| String Concatenation | Uses `Build` method for efficiency, can also use `+` | Uses `strcat` function or `+` operator | Uses `StringBuilder` class or `+` operator | Uses `StringBuilder` class or `+` operator |
| Switch Statements    | No fall-through, no `break` needed | Fall-through unless `break` used | No fall-through, `break` needed | Fall-through unless `break` used |
| Expression vs Statement | Cannot use expression where statement is expected | Can use expression where statement is expected | Can use expression where statement is expected | Can use expression where statement is expected |

