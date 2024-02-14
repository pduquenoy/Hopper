unit Board // Adafruit Feather ThinkInk
{
    #define ADAFRUIT_FEATHER_THINKINK

    #define MCU_BOARD_DEFINED
    #define MCU_BOARD_RP2040
    #define FORMFACTOR_FEATHER

    #define BOARD_HAS_NEOPIXEL
    #define BOARD_HAS_NEOPIXEL_POWER
    #define BOARD_HAS_LED
    #define BOARD_HAS_I2C
    #define BOARD_HAS_NO_I2C0
    #define BOARD_HAS_SPI
    #define BOARD_HAS_A0
    #define BOARD_HAS_A1
    #define BOARD_HAS_A2
    #define BOARD_HAS_A3

    const byte BuiltInLED = 13;
    const byte BuiltInNeoPixel = 21;
    const byte BuiltInNeoPixelLength = 1;
    const byte BuiltInNeoPixelPower = 20;

    const byte BuiltInA0 = 26;
    const byte BuiltInA1 = 27;
    const byte BuiltInA2 = 28;
    const byte BuiltInA3 = 29;
    const byte ADCResolution = 12;

    const byte I2CSDA1 = 2;
    const byte I2CSCL1 = 3;

    const byte SPI0Tx = 15;
    const byte SPI0Rx = 8;
    const byte SPI0SCK = 14;
    const byte SPI0SS = 13;
    const byte SPI1Tx = 23;
    const byte SPI1Rx = 31;
    const byte SPI1SCK = 22;
    const byte SPI1SS = 19;

    const byte UART1Tx = 0;
    const byte UART1Rx = 1;


    uses "/Source/Library/MCU"
}
