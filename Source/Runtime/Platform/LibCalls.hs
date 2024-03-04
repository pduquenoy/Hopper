unit LibCalls
{
    enum LibCall
    {
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
        MCUAttachToPin,
        MCUInterruptsEnabledGet,
        MCUInterruptsEnabledSet,
        MCUReboot,
        
        MCUHeapFree,
        MCUStackFree,
        MCUClockSpeedGet,
        MCUClockSpeedSet,
        
        TimerStart,
        TimerStop,
        TimerAlarm,
        TimerCancel,
        
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
    }
}
