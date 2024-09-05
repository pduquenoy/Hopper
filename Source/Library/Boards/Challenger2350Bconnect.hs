unit Board // Challenger 2350 Bconnect
{
    #define CHALLENGER_2350_BCONNECT

    #define MCU_BOARD_DEFINED
    #define MCU_BOARD_RP

    // Note: see Attribution.md (in the same folder as this file)

    #define BOARD_HAS_NEOPIXEL
    #define BOARD_HAS_LED
    #define BOARD_HAS_I2C
    #define BOARD_HAS_NO_SPI1
    #define BOARD_HAS_SPI
    #define BOARD_HAS_A0
    #define BOARD_HAS_A1
    #define BOARD_HAS_A2
    #define BOARD_HAS_A3
    #define BOARD_HAS_A4
    #define BOARD_HAS_A5

    const byte BuiltInLED = 7;
    const byte BuiltInNeoPixel = 22;
    const byte BuiltInNeoPixelLength = 1;

    const byte A0 = 29;
    const byte A1 = 28;
    const byte A2 = 27;
    const byte A3 = 26;
    const byte A4 = 1;
    const byte A5 = 17;
    const byte ADCResolution = 12;

    const byte I2CSDA0 = 20;
    const byte I2CSCL0 = 21;
    const byte I2CSDA1 = 10;
    const byte I2CSCL1 = 11;

    const byte SPI0Tx = 19;
    const byte SPI0Rx = 16;
    const byte SPI0SCK = 18;
    const byte SPI0SS = 17;

    const byte UART1Tx = 12;
    const byte UART1Rx = 13;

    const byte GP0 = 13;
    const byte GP1 = 12;  // A4
    const byte GP5 = 23;
    const byte GP6 = 24;
    const byte GP9 = 25;
    const byte GP10 = 2;  // I2CSDA1
    const byte GP11 = 3;  // I2CSCL1
    const byte GP12 = 6;  // UART1Tx
    const byte GP13 = 7;  // UART1Rx

    uses "/Source/Library/MCU"

    string BoardName { get { return "Challenger 2350 Bconnect"; } }

}