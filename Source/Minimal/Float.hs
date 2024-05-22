unit Float
{
    uses "Diagnostics" // for Die
    uses "Int"         // for Int.ToString
    uses "Long"        // so we can use Long for the 23 bit mantissa
    
    friend UInt;       // so UInt.ToFloat can access Float.normalize and Float.combineComponents
    friend  Int;       // so Int.ToFloat  can access Float.normalize and Float.combineComponents
    friend Long;       // so Long.ToFloat can access Float.normalize and Float.combineComponents
    
    byte GetByte(float this, byte index) system;
    float FromBytes(byte b0, byte b1, byte b2, byte b3) system;
    const float Pi = 3.1415926535;
    
    mantissaDivide(long dividend, long divisor, ref long quotient, ref long remainder)
    {
        long zero = Long.FromBytes(0, 0, 0, 0); // 0x00000000 in 32-bit
        long one  = Long.FromBytes(1, 0, 0, 0);  // 0x00000001 in 32-bit
        
        quotient  = zero;
        remainder = zero;
    
        // Split the dividend into high and low parts for extended precision
        long extendedDividendHigh = Long.shiftRight(dividend, 8); // upper 24 bits of dividend
        long extendedDividendLow  = Long.shiftLeft(dividend, 24); // lower 8 bits of dividend
    
        for (int i = 47; i >= 0; i--)
        {
            // Shift remainder left by 1 and combine with the next bit from extendedDividendHigh or extendedDividendLow
            remainder = Long.shiftLeft(remainder, 1);
            if (i >= 24)
            {
                remainder = Long.or(remainder, Long.and(Long.shiftRight(extendedDividendHigh, i - 24), one));
            }
            else
            {
                remainder = Long.or(remainder, Long.and(Long.shiftRight(extendedDividendLow, i), one));
            }
    
            // If the remainder is greater than or equal to the divisor, subtract the divisor from the remainder
            if (Long.GE(remainder, divisor))
            {
                remainder = Long.Sub(remainder, divisor);
                quotient = Long.or(quotient, Long.shiftLeft(one, i));
            }
        }
    }
       
    float Div(float a, float b)
    {
        if (isZero(a))
        {
            return a;
        }
        if (isZero(b))
        {
            Die(0x04); // Division by zero
        }
        //IO.WriteLn();
        //IO.WriteLn("Test case 'a=" + a.ToString() + " / " + b.ToString() + "' :");
        
        byte signA = getSign(a);
        byte exponentA = getExponent(a);
        long mantissaA = getMantissa(a);
        byte signB = getSign(b);
        byte exponentB = getExponent(b);
        long mantissaB = getMantissa(b);
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    
        //IO.WriteLn("mantissaA with implicit bit: " + Long.ToHexString(mantissaA, 8));
        //IO.WriteLn("mantissaB with implicit bit: " + Long.ToHexString(mantissaB, 8));
        
        long quotient;
        long remainder;
        mantissaDivide(mantissaA, mantissaB, ref quotient, ref remainder); // Divide mantissas
    
        //IO.WriteLn("quotient: " + Long.ToHexString(quotient, 8));
        //IO.WriteLn("remainder: " + Long.ToHexString(remainder, 8));
        
        int resultExponent = int(exponentA) - int(exponentB) + 127; // Subtract exponents
        byte resultSign = signA ^ signB; // Determine the sign
    
        long resultMantissaHigh = Long.FromBytes(0, 0, 0, 0);
        long resultMantissaLow = quotient;
    
        // Normalize the result
        byte leadingZeros = countLeadingZeros(resultMantissaHigh, resultMantissaLow);
        if (leadingZeros < 40)
        {
            shiftRight64Bit(ref resultMantissaHigh, ref resultMantissaLow, 40 - leadingZeros);
        }
        else
        {
            resultMantissaLow = Long.shiftLeft(resultMantissaLow, leadingZeros - 40);
        }
    
        // Now the mantissa of interest is in lowResult
        long resultMantissa = Long.and(resultMantissaLow, Long.FromBytes(0xFF, 0xFF, 0x7F, 0)); // remove the implicit leading 1
    
        //IO.WriteLn("resultMantissa after normalization: " + Long.ToHexString(resultMantissa, 8));
        //IO.WriteLn("resultExponent after normalization: " + Int.ToHexString(resultExponent, 2));
        
        // Handle exponent overflow/underflow
        if (resultExponent <= 0) 
        {
            // Underflow: result is too small to be represented
            resultExponent = 0;
            resultMantissa  = 0;
        }
        else if (resultExponent >= 255) 
        {
            // Overflow: result is too large to be represented
            resultExponent = 255;
            resultMantissa  = 0;
        }
    
        float result = combineComponents(resultSign, byte(resultExponent), resultMantissa);
        //IO.WriteLn("result after combineComponents: " + Float.ToString(result));
        //_ = Serial.ReadChar();
        return result;
    }
            
    float Add(float a, float b)
    {
        if (isZero(a))
        {
            return b;
        }
        if (isZero(b))
        {
            return a;
        }
    
        //IO.WriteLn();
        //IO.WriteLn("Test case 'a=" + Float.ToString(a) + " + " + Float.ToString(b) + "' :"); // DANGER : circular
    
        byte signA     = getSign(a);
        int exponentA  = getExponent(a);  // Change to int for processing
        long mantissaA = getMantissa(a);
        
        byte signB     = getSign(b);
        int exponentB  = getExponent(b);  // Change to int for processing
        long mantissaB = getMantissa(b);
        
        //IO.WriteLn("Initial values:");
        //IO.WriteLn("signA: " + Int.ToHexString(signA, 2));
        //IO.WriteLn("exponentA: " + Int.ToHexString(exponentA, 4));
        //IO.WriteLn("mantissaA: " + Long.ToHexString(mantissaA, 8));
        //IO.WriteLn("signB: " + Int.ToHexString(signB, 2));
        //IO.WriteLn("exponentB: " + Int.ToHexString(exponentB, 4));
        //IO.WriteLn("mantissaB: " + Long.ToHexString(mantissaB, 8));
    
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    
        //IO.WriteLn("After adding implicit leading bit:");
        //IO.WriteLn("mantissaA: " + Long.ToHexString(mantissaA, 8));
        //IO.WriteLn("mantissaB: " + Long.ToHexString(mantissaB, 8));
        
        // Align exponents
        if (exponentA > exponentB)
        {
            int shift = exponentA - exponentB;
            mantissaB = Long.shiftRight(mantissaB, shift);
            exponentB = exponentA;
        }
        else if (exponentA < exponentB)
        {
            int shift = exponentB - exponentA;
            mantissaA = Long.shiftRight(mantissaA, shift);
            exponentA = exponentB;
        }
    
        //IO.WriteLn("After aligning exponents:");
        //IO.WriteLn("exponentA: " + Int.ToHexString(exponentA, 4));
        //IO.WriteLn("mantissaA: " + Long.ToHexString(mantissaA, 8));
        //IO.WriteLn("mantissaB: " + Long.ToHexString(mantissaB, 8));
    
        long resultMantissa;
        if (signA == signB)
        {
            resultMantissa = Long.Add(mantissaA, mantissaB); // Same sign: addition
        }
        else
        {
            if (Long.GE(mantissaA, mantissaB))
            {
                resultMantissa = Long.Sub(mantissaA, mantissaB); // Different signs: subtraction
            }
            else
            {
                resultMantissa = Long.Sub(mantissaB, mantissaA);
                signA = signB;
            }
        }
    
        //IO.WriteLn("After addition/subtraction:");
        //IO.WriteLn("resultMantissa: " + Long.ToHexString(resultMantissa, 8));
        
        // Normalize the result
        byte leadingZeros = countLeadingZeros(resultMantissa);
        if (leadingZeros < 8)
        {
            resultMantissa = Long.shiftRight(resultMantissa, 8 - leadingZeros);
            exponentA += (8 - leadingZeros);
        }
        else
        {
            resultMantissa = Long.shiftLeft(resultMantissa, leadingZeros - 8);
            exponentA -= (leadingZeros - 8);
        }
    
        //IO.WriteLn("After normalizing:");
        //IO.WriteLn("leadingZeros: " + Int.ToString(leadingZeros));
        //IO.WriteLn("resultMantissa: " + Long.ToHexString(resultMantissa, 8));
        //IO.WriteLn("exponentA: " + Int.ToHexString(exponentA, 4));
        
        // Handle exponent overflow/underflow
        if (exponentA <= 0) 
        {
            // Underflow: result is too small to be represented
            exponentA = 0;
            resultMantissa  = 0;
        }
        else if (exponentA >= 255) 
        {
            // Overflow: result is too large to be represented
            exponentA = 255;
            resultMantissa  = 0;
        }
    
        // Remove the implicit leading bit
        resultMantissa = Long.and(resultMantissa, Long.FromBytes(0xFF, 0xFF, 0x7F, 0));
    
        //IO.WriteLn("Final result values:");
        //IO.WriteLn("resultMantissa: " + Long.ToHexString(resultMantissa, 8));
        //IO.WriteLn("exponentA: " + Int.ToHexString(exponentA, 4));
        //IO.WriteLn("signA: " + Int.ToHexString(signA, 2));
    
        float result = combineComponents(signA, byte(exponentA), resultMantissa); // Convert exponent back to byte for combining
        //IO.WriteLn("result after combineComponents: " + Float.ToString(result));
        return result;
    }
        
    
    float Sub(float a, float b)
    {
        byte signB = getSign(b);
        signB = signB ^ 1; // Flip the sign of b
        float negativeB = combineComponents(signB, getExponent(b), getMantissa(b));
        return Add(a, negativeB);
    }
    
    mantissaMultiply(long mantissaA, long mantissaB, ref long resultHigh, ref long resultLow)
    {
        IO.WriteLn("mantissaA: " + Long.ToHexString(mantissaA, 8));
        IO.WriteLn("mantissaB: " + Long.ToHexString(mantissaB, 8));
    
        // Extract the higher and lower parts of the mantissas
        long aHigh = Long.shiftRight(mantissaA, 12);
        long aLow = Long.and(mantissaA, Long.FromBytes(0xFF, 0x0F, 0x00, 0x00)); // Bottom 12 bits
        long bHigh = Long.shiftRight(mantissaB, 12);
        long bLow = Long.and(mantissaB, Long.FromBytes(0xFF, 0x0F, 0x00, 0x00)); // Bottom 12 bits
    
        IO.WriteLn("aHigh: " + Long.ToHexString(aHigh, 8));
        IO.WriteLn("aLow: " + Long.ToHexString(aLow, 8));
        IO.WriteLn("bHigh: " + Long.ToHexString(bHigh, 8));
        IO.WriteLn("bLow: " + Long.ToHexString(bLow, 8));
    
        // Perform the multiplications
        long highHigh = Long.Mul(aHigh, bHigh);  // Bits 24-47
        long highLow  = Long.Mul(aHigh, bLow);   // Bits 12-35
        long lowHigh  = Long.Mul(aLow, bHigh);   // Bits 12-35
        long lowLow   = Long.Mul(aLow, bLow);    // Bits 0-23
    
        IO.WriteLn("highHigh: " + Long.ToHexString(highHigh, 8));
        IO.WriteLn("highLow: " + Long.ToHexString(highLow, 8));
        IO.WriteLn("lowHigh: " + Long.ToHexString(lowHigh, 8));
        IO.WriteLn("lowLow: " + Long.ToHexString(lowLow, 8));
    
        // Initialize lowerLong with the lower 16 bits of lowLow
        long lowerLong = Long.and(lowLow, Long.FromBytes(0xFF, 0xFF, 0, 0));
        IO.WriteLn("initial lowerLong: " + Long.ToHexString(lowerLong, 8));
    
        // Add the overlapping bits from highLow and lowHigh
        long highLowOverlap = Long.and(highLow, Long.FromBytes(0x0F, 0x00, 0, 0)); // Extract bits 12..15 (0x0000000F)
        long lowHighOverlap = Long.and(lowHigh, Long.FromBytes(0x0F, 0x00, 0, 0)); // Extract bits 12..15 (0x0000000F)
        
        // Shift these overlaps to the right position and add them to lowerLong
        lowerLong = Long.Add(lowerLong, Long.shiftLeft(highLowOverlap, 12));
        lowerLong = Long.Add(lowerLong, Long.shiftLeft(lowHighOverlap, 12));
        IO.WriteLn("lowerLong after overlap: " + Long.ToHexString(lowerLong, 8));
    
        // Check for carry to middleLong
        long middleLong = Long.shiftRight(lowerLong, 16);
        
        // Mask lowerLong to 16 bits after adding
        lowerLong = Long.and(lowerLong, Long.FromBytes(0xFF, 0xFF, 0, 0));
        IO.WriteLn("final lowerLong: " + Long.ToHexString(lowerLong, 8));
        IO.WriteLn("initial middleLong (carry from lowerLong): " + Long.ToHexString(middleLong, 8));
    
        // Accumulate the 16..31 bits
        middleLong = Long.Add(middleLong, Long.shiftRight(lowLow, 16)); // Add bits 16..31 of lowLow
        
        // Add the overlapping bits from highLow and lowHigh
        highLowOverlap  = Long.and(highLow, Long.FromBytes(0xF0, 0xFF, 0x0F, 0)); // Extract bits 16..31 from 12..35 (0x000FFFF0)
        lowHighOverlap  = Long.and(lowHigh, Long.FromBytes(0xF0, 0xFF, 0x0F, 0)); // Extract bits 16..31 from 12..35 (0x000FFFF0)
        long highHighOverlap = Long.and(highHigh, Long.FromBytes(0xFF, 0, 0, 0)); // Extract bits 24..31 from 24..47 (0x000000FF)
    
        middleLong = Long.Add(middleLong, Long.shiftRight(highLowOverlap, 4));  // Add bits 16..31 of highLow
        middleLong = Long.Add(middleLong, Long.shiftRight(lowHighOverlap, 4));  // Add bits 16..31 of lowHigh
        middleLong = Long.Add(middleLong, Long.shiftLeft (highHighOverlap, 8)); // Add bits 24..31 of highHigh
        IO.WriteLn("middleLong after accumulation: " + Long.ToHexString(middleLong, 8));
    
        // Check for carry to upperLong
        long upperLong = Long.shiftRight(middleLong, 16);
    
        // Mask middleLong to 16 bits after adding
        middleLong = Long.and(middleLong, Long.FromBytes(0xFF, 0xFF, 0, 0));
        IO.WriteLn("final middleLong: " + Long.ToHexString(middleLong, 8));
        IO.WriteLn("initial upperLong (carry from middleLong): " + Long.ToHexString(upperLong, 8));
    
        // Accumulate the 32..47 bits
        highLowOverlap = Long.and(Long.shiftRight(highLow, 20), Long.FromBytes(0x0F, 0x00, 0, 0)); // Extract bits 32..35 (0x0000000F)
        lowHighOverlap = Long.and(Long.shiftRight(lowHigh, 20), Long.FromBytes(0x0F, 0x00, 0, 0)); // Extract bits 32..35 (0x0000000F)
        highHighOverlap = Long.shiftRight(highHigh, 8);                                            // Extract bits 32..47
        
        upperLong = Long.Add(upperLong, highLowOverlap);  // Add bits 32..47 of highLow
        upperLong = Long.Add(upperLong, lowHighOverlap);  // Add bits 32..47 of lowHigh
        upperLong = Long.Add(upperLong, highHighOverlap); // Add bits 32..47 of highHigh
        IO.WriteLn("upperLong after accumulation: " + Long.ToHexString(upperLong, 8));
    
        // Mask upperLong to 16 bits after adding
        upperLong = Long.and(upperLong, Long.FromBytes(0xFF, 0xFF, 0, 0));
        IO.WriteLn("final upperLong: " + Long.ToHexString(upperLong, 8));
    
        // Combine results into final mantissa
        resultLow = Long.or(lowerLong, Long.shiftLeft(middleLong, 16));
        resultHigh = upperLong;
    
        IO.WriteLn("resultLow: " + Long.ToHexString(resultLow, 8));
        IO.WriteLn("resultHigh: " + Long.ToHexString(resultHigh, 8));
    }
    
    
    byte countLeadingZeros(long result)
    {
        byte count = 0;
        long one = Long.FromBytes(1, 0, 0, 0); // 0x00000001 as a long
    
        for (int i = 31; i >= 0; i--)
        {
            if (!Long.EQ(Long.and(result, Long.shiftLeft(one, i)), Long.FromBytes(0, 0, 0, 0)))
            {
                return count;
            }
            count++;
        }
        return count; // all zero, return 32
    }
    byte countLeadingZeros(long resultHigh, long resultLow)
    {
        byte count = countLeadingZeros(resultHigh);
        if (count != 32)
        {
            return count;
        }
        count += countLeadingZeros(resultLow);
        return count; // If both resultHigh and resultLow are zero, return 64
    }
    shiftRight64Bit(ref long resultHigh, ref long resultLow, byte shift)
    {
        if (shift >= 32)
        {
            resultLow = Long.shiftRight(resultHigh, shift - 32);
            resultHigh = 0;
        }
        else
        {
            resultLow  = Long.shiftRight(resultLow, shift);
            resultLow  = Long.or(resultLow, Long.shiftLeft(resultHigh, 32 - shift));
            resultHigh = Long.shiftRight(resultHigh, shift);
        }
    }
    
    float Mul(float a, float b)
{
    if (isZero(a)) 
    {
        return a;
    }
    if (isZero(b)) 
    {
        return b;
    }
    IO.WriteLn();
    IO.WriteLn("Test case 'a=" + ToHexString(a) + " * " + ToHexString(b) + "' :");
    
    if (ToHexString(a) == "3D23D70A")
    {
        int wtf = 0;
    }
    
    byte signA = getSign(a);
    int exponentA = getExponent(a);
    long mantissaA = getMantissa(a);
    byte signB = getSign(b);
    int exponentB = getExponent(b);
    long mantissaB = getMantissa(b);
    
    IO.WriteLn("Initial values:");
    IO.WriteLn("signA: " + Int.ToHexString(signA, 2));
    IO.WriteLn("exponentA: " + Int.ToHexString(exponentA, 2));
    IO.WriteLn("mantissaA: " + Long.ToHexString(mantissaA, 8));
    IO.WriteLn("signB: " + Int.ToHexString(signB, 2));
    IO.WriteLn("exponentB: " + Int.ToHexString(exponentB, 2));
    IO.WriteLn("mantissaB: " + Long.ToHexString(mantissaB, 8));
    
    // Add the implicit leading bit
    mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    IO.WriteLn("After adding implicit leading bit:");
    IO.WriteLn("mantissaA with implicit bit: " + Long.ToHexString(mantissaA, 8));
    IO.WriteLn("mantissaB with implicit bit: " + Long.ToHexString(mantissaB, 8));
    
    // Perform the multiplication
    long resultHigh;
    long resultLow;
    mantissaMultiply(mantissaA, mantissaB, ref resultHigh, ref resultLow);
    IO.WriteLn("resultHigh: " + Long.ToHexString(resultHigh, 8));
    IO.WriteLn("resultLow: " + Long.ToHexString(resultLow, 8));
    
    // Normalize the result
    byte leadingZeros = countLeadingZeros(resultHigh, resultLow);
    IO.WriteLn("leadingZeros: " + Int.ToHexString(leadingZeros, 2));
    if (leadingZeros < 40)
    {
        shiftRight64Bit(ref resultHigh, ref resultLow, 40 - leadingZeros);
    }
    else
    {
        resultLow = Long.shiftLeft(resultLow, leadingZeros - 40);
    }
    IO.WriteLn("resultHigh after shift: " + Long.ToHexString(resultHigh, 8));
    IO.WriteLn("resultLow after shift: " + Long.ToHexString(resultLow, 8));
    
    // Now the mantissa of interest is in resultLow
    long resultMantissa = Long.and(resultLow, Long.FromBytes(0xFF, 0xFF, 0x7F, 0));  // remove the implicit leading 1
    int resultExponent = exponentA + exponentB - 127;   
    byte resultSign = signA ^ signB;
    
    IO.WriteLn("resultMantissa before normalization: " + Long.ToHexString(resultMantissa, 8));
    IO.WriteLn("resultExponent before normalization: " + Int.ToHexString(resultExponent, 2));

    // Adjust the exponent based on the leading zeros found
    //resultExponent -= leadingZeros - 24; // Adjust the exponent to account for the leading zero shift
    //IO.WriteLn("resultExponent after adjustment: " + Int.ToHexString(resultExponent, 2));

    // Handle exponent overflow/underflow
    if (resultExponent <= 0) 
    {
        // Underflow: result is too small to be represented
        resultExponent = 0;
        resultMantissa = 0;
    }
    else if (resultExponent >= 255) 
    {
        // Overflow: result is too large to be represented
        resultExponent = 255;
        resultMantissa = 0;
    }

    IO.WriteLn("resultMantissa after normalization: " + Long.ToHexString(resultMantissa, 8));
    IO.WriteLn("resultExponent after normalization: " + Int.ToHexString(resultExponent, 2));
    
    float result = combineComponents(resultSign, byte(resultExponent), resultMantissa);
    IO.WriteLn("result after combineComponents: " + ToHexString(result));
    return result;
}

       
    bool EQ(float a, float b)
    {
        if (isZero(a) && isZero(b))
        {
            return true;
        }
        return (GetByte(a, 0) == GetByte(b, 0)) &&
               (GetByte(a, 1) == GetByte(b, 1)) &&
               (GetByte(a, 2) == GetByte(b, 2)) &&
               (GetByte(a, 3) == GetByte(b, 3));
    }
    
    bool LT(float a, float b)
    {
        byte signA = getSign(a);
        byte signB = getSign(b);
        if (signA != signB)
        {
            return signA > signB;
        }
        byte exponentA = getExponent(a);
        byte exponentB = getExponent(b);
        if (exponentA != exponentB)
        {
            return (signA == 0) ? (exponentA < exponentB) : (exponentA > exponentB);
        }
        long mantissaA = getMantissa(a);
        long mantissaB = getMantissa(b);
        return (signA == 0) ? (mantissaA < mantissaB) : (mantissaA > mantissaB);
    }
    
    bool GT(float a, float b)
    {
        return !LE(a, b);
    }
    
    bool LE(float a, float b)
    {
        return LT(a, b) || EQ(a, b);
    }
    
    bool GE(float a, float b)
    {
        return GT(a, b) || EQ(a, b);
    }
    
    string ToString(float value)
    {
        if (isZero(value))
        {
            return "0";
        }
        bool isNegative = getSign(value) == 1;
        if (isNegative)
        {
            value = negate(value);
        }
        long integerPart = Float.ToLong(value);
        float fractionalPart = Float.Sub(value, Long.ToFloat(integerPart));
        string integerPartStr = integerPart.ToString();
        string fractionalPartStr = fractionToString(fractionalPart);
        string result = integerPartStr + "." + fractionalPartStr;
        if (isNegative)
        {
            String.BuildFront(ref result, '-');
        }
        return result;
    }
    
    long ToLong(float f)
    {
        byte sign = getSign(f);
        int exponent = getExponent(f) - 127; // Bias adjustment
        long mantissa = getMantissa(f);
        mantissa = Long.or(mantissa, Long.FromBytes(0, 0, 0x80, 0)); // Add the implicit leading bit
    
        long result;
        if (exponent > 23)
        {
            result = Long.shiftLeft(mantissa, exponent - 23);
        }
        else if (exponent < 23)
        {
            result = Long.shiftRight(mantissa, 23 - exponent);
        }
        else
        {
            result = mantissa;
        }
    
        return sign == 1 ? Long.Negate(result) : result;
    }
    
    int ToInt(float f)
    {
        long longValue = f.ToLong();
        if ((longValue < -32768) || (longValue > 32767))
        {
            Die(0x0D); // Overflow
        }
        return int(longValue);
    }
    
    uint ToUInt(float f)
    {
        int intValue = f.ToInt();
        if (intValue < 0)
        {
            Die(0x0D); // Overflow
        }
        return uint(intValue);
    }
    
    
    byte getSign(float f)
    {
        return (GetByte(f, 3) >> 7) & 1;
    }
    
    byte getExponent(float f)
    {
        return (GetByte(f, 3) & 0x7F) << 1 | (GetByte(f, 2) >> 7);
    }
    
    long getMantissa(float f)
    {
        return Long.FromBytes(GetByte(f, 0), GetByte(f, 1), GetByte(f, 2) & 0x7F, 0);
    }
    
    float combineComponents(byte sign, byte exponent, long mantissa)
    {
        // Extract bytes from mantissa
        byte b0 = Long.GetByte(mantissa, 0);
        byte b1 = Long.GetByte(mantissa, 1);
        byte b2 = Long.GetByte(mantissa, 2) & 0x7F; // Only take the 7 least significant bits
        b2 |= byte((exponent & 1) << 7); // Set the least significant bit of the exponent in b2
    
        byte b3 = byte((exponent >> 1) & 0x7F); // Take the next 7 bits of the exponent
        b3 |= byte(sign << 7); // Set the sign bit in b3
    
        return FromBytes(b0, b1, b2, b3);
    }
    
    bool isZero(float this)
    {
        return (GetByte(this, 0) == 0) && (GetByte(this, 1) == 0) && (GetByte(this, 2) == 0) &&
               ((GetByte(this, 3) == 0) || (GetByte(this, 3) == 0x80));
    }
       
    string fractionToString(float fractionalPart)
    {
        string result = "";
        int precision = 6; // Number of digits after the decimal point
        while (precision > 0)
        {
            fractionalPart = Mul(fractionalPart, Int.ToFloat(10));
            int digit = fractionalPart.ToInt();
            result += char(byte('0') + digit);
            fractionalPart = Sub(fractionalPart, Int.ToFloat(digit));
            precision--;
        }
        return result;
    }
    
    float negate(float value)
    {
        byte sign = getSign(value) ^ 1;
        byte exponent = getExponent(value);
        long mantissa = getMantissa(value);
        return combineComponents(sign, exponent, mantissa);
    }
    
    string ToHexString(float f)
    {
        string result;
        result += Byte.ToHexString(Float.GetByte(f, 3), 2);
        result += Byte.ToHexString(Float.GetByte(f, 2), 2);
        result += Byte.ToHexString(Float.GetByte(f, 1), 2);
        result += Byte.ToHexString(Float.GetByte(f, 0), 2);
        return result;
    }
    
}

