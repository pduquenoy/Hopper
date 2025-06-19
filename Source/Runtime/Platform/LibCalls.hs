unit LibCalls
{
    enum LibCall
    {
        TimerStart,
        TimerStop,
        TimerAlarm,
        TimerCancel,
        
        WireBegin,
        WireBeginTx,
        WireEndTx,
        WireWrite,
        WireConfigure,
        WireRead,
        WireRequestFrom,
        
        MCUPinMode,
        MCUDigitalRead,
        MCUDigitalWrite,
        MCUAnalogRead,
        MCUAnalogWrite,
        MCUAnalogWriteResolution,
        MCUTone,
        MCUNoTone,
        MCUAttachToPin,
        MCUInterruptsEnabledGet,
        MCUInterruptsEnabledSet,
        MCUReboot,
        
        MCUHeapFree,
        MCUStackFree,
        MCUClockSpeedGet,
        MCUClockSpeedSet,
                
        SPISettings,
        SPIBegin,
        SPIBeginTransaction,
        SPIEndTransaction,
        SPIReadByte,
        SPIReadWord,
        SPIReadBuffer,
        SPIWriteByte,
        SPIWriteBytes,
        SPIWriteWord,
        SPIWriteWords,
        SPIWriteBuffer,
        SPISetCSPin,
        SPIGetCSPin,
        SPISetClkPin,
        SPISetTxPin,
        SPISetRxPin,
        
        SPICSPinGet,
        SPICSPinSet,
        SPIClkPinSet,
        SPITxPinSet,
        SPIRxPinSet,
        
        NeoPixelBegin,
        NeoPixelBrightnessSet,
        NeoPixelBrightnessGet,
        NeoPixelSetColor,
        NeoPixelShow,
        NeoPixelLengthGet,
        
        WebClientGetRequest,
        
        WiFiBeginAP,
        
        WebServerBegin,
        WebServerOn,
        WebServerOnNotFound,
        WebServerEvents,
        WebServerClose,
        WebServerSend,
        
        SDSPIControllerGet,
        SDSPIControllerSet,
        SDCSPinGet,
        SDCSPinSet,
        SDClkPinGet,
        SDClkPinSet,
        SDTxPinGet,
        SDTxPinSet,
        SDRxPinGet,
        SDRxPinSet,
        SDMount,
        SDEject, 
        
        // serial EEPROM on 6502
        StorageMediaInitialize,
        StorageMediaMount,
        StorageMediaUnmount,
        StorageMediaReadSector,
        StorageMediaWriteSector,
        
        UARTSetup,
        UARTIsAvailableGet,
        UARTReadChar,
        UARTWriteChar,
        
    }
}
