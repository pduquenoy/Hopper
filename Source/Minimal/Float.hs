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
    
    float Div(float a, float b)
    {
        if (isZero(b))
        {
            Die(0x04); // Division by zero
        }
        
        byte signA = getSign(a);
        byte exponentA = getExponent(a);
        long mantissaA = getMantissa(a);
        byte signB = getSign(b);
        byte exponentB = getExponent(b);
        long mantissaB = getMantissa(b);
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        
        long resultMantissa = Long.Div(Long.shiftLeft(mantissaA, 23), mantissaB); // Divide mantissas
        int resultExponent = int(exponentA) - int(exponentB) + 127; // Subtract exponents
        byte resultSign = signA ^ signB; // Determine the sign
        if (Long.GE(resultMantissa, Long.FromBytes(0, 0, 0, 0x01))) // 0x01000000 in 32-bit
        {
            resultMantissa = Long.shiftRight(resultMantissa, 1);
            resultExponent++;
        }
        else
        {
            normalize(ref resultMantissa, ref resultExponent);
        }
        return combineComponents(resultSign, byte(resultExponent), resultMantissa);
    }
    
    float Add(float a, float b)
    {
        byte signA     = getSign(a);
        int exponentA  = getExponent(a);  // Change to int for processing
        long mantissaA = getMantissa(a);
    
        byte signB     = getSign(b);
        int exponentB  = getExponent(b);  // Change to int for processing
        long mantissaB = getMantissa(b);
    
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    
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
    
        if (Long.GE(resultMantissa, Long.FromBytes(0, 0, 0, 0x01))) // 0x01000000 in 32-bit
        {
            resultMantissa = Long.shiftRight(resultMantissa, 1);
            exponentA++;
        }
        else
        {
            normalize(ref resultMantissa, ref exponentA); // Pass exponent as int for normalization
        }
    
        float result = combineComponents(signA, byte(exponentA), resultMantissa); // Convert exponent back to byte for combining
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
        // Extract the higher and lower parts of the mantissas
        long aHigh = Long.shiftRight(mantissaA, 12);
        long aLow = Long.and(mantissaA, Long.FromBytes(0xFF, 0x0F, 0x00, 0x00)); // Bottom 12 bits
        long bHigh = Long.shiftRight(mantissaB, 12);
        long bLow = Long.and(mantissaB, Long.FromBytes(0xFF, 0x0F, 0x00, 0x00)); // Bottom 12 bits
    
        // Perform the multiplications
        long highHigh = Long.Mul(aHigh, bHigh);
        long highLow = Long.Mul(aHigh, bLow);
        long lowHigh = Long.Mul(aLow, bHigh);
        long lowLow = Long.Mul(aLow, bLow);
    
        // Combine results to form the full 48-bit result
        long highResult = highHigh;
        long midResult1 = highLow;
        long midResult2 = lowHigh;
        long lowResult = Long.shiftRight(lowLow, 12);
    
        // Combine results into a final mantissa
        resultHigh = highResult;
        resultHigh = Long.Add(resultHigh, Long.shiftRight(midResult1, 12));
        resultHigh = Long.Add(resultHigh, Long.shiftRight(midResult2, 12));
    
        resultLow = lowResult;
    }
    byte countLeadingZeros(long resultHigh, long resultLow)
    {
        byte count = 0;
        long one = Long.FromBytes(1, 0, 0, 0); // 0x00000001 as a long
    
        // Check the higher 32 bits first
        for (int i = 31; i >= 0; i--)
        {
            if (!Long.EQ(Long.and(resultHigh, Long.shiftLeft(one, i)), Long.FromBytes(0, 0, 0, 0)))
            {
                return count;
            }
            count++;
        }
    
        // If resultHigh is zero, check the lower 32 bits
        for (int i = 31; i >= 0; i--)
        {
            if (!Long.EQ(Long.and(resultLow, Long.shiftLeft(one, i)), Long.FromBytes(0, 0, 0, 0)))
            {
                return count;
            }
            count++;
        }
    
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
        byte signA = getSign(a);
        int exponentA = getExponent(a);
        long mantissaA = getMantissa(a);
        byte signB = getSign(b);
        int exponentB = getExponent(b);
        long mantissaB = getMantissa(b);
    
        
    
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0));
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0));
    
        // Perform the multiplication
        long resultHigh;
        long resultLow;
        mantissaMultiply(mantissaA, mantissaB, ref resultHigh, ref resultLow);
        
        byte leadingZeros = countLeadingZeros(resultHigh, resultLow);
        if (leadingZeros < 40)
        {
            shiftRight64Bit(ref resultHigh, ref resultLow, 40 - leadingZeros);
        }
        else
        {
            resultLow = Long.shiftLeft(resultLow, leadingZeros - 40);
        }
        
        // Now the mantissa of interest is in lowResult
        long resultMantissa = Long.and(resultLow, Long.FromBytes(0xFF, 0xFF, 0x7F, 0));  // remove the implicit leading 1
        int resultExponent = exponentA + exponentB - 127;   
        byte resultSign = signA ^ signB;
        
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
    
        float result = combineComponents(resultSign, byte(resultExponent), resultMantissa );
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
    
    
    normalize(ref long mantissa, ref int exponent)
    {
        long implicitLeadingBit = Long.FromBytes(0, 0, 0x80, 0); // 0x00800000 in 32-bit
        long mask = Long.FromBytes(0xFF, 0xFF, 0x7F, 0x00); // 0x007FFFFF in 32-bit
        long zero = Long.FromBytes(0, 0, 0, 0);
    
        if (Long.EQ(mantissa, zero))
        {
            // If mantissa is zero, set exponent to zero as well
            exponent = 0;
        }
        else
        {
            while (Long.EQ(Long.and(mantissa, implicitLeadingBit), zero))
            {
                mantissa = Long.shiftLeft(mantissa, 1);
                exponent--;
            }
        }
        // No need to mask the mantissa as it is already normalized correctly
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
}

