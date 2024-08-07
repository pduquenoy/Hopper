unit TCScanner
{
    uses "TCToken"
    uses "/Source/System/File"
    
    // Scanner state
    string currentSourcePath;
    file sourceFile;
    uint currentLine;
    uint lineIndex;
    string currentLineContent;
    
    Token currentToken;
    Token peekedToken;
    bool peeked;
    
    Advance()
    {
        if (peeked)
        {
            currentToken = peekedToken;
            peeked = false;
        }
        else
        {
            advanceToken();
        }
    }
    
    Token Peek()
    {
        if (!peeked)
        {
            Token stored = currentToken;
            advanceToken();
            peekedToken = currentToken;
            peeked = true;
            currentToken = stored;
        }
        return peekedToken;
    }
    
    Token Current()
    {
        return currentToken;
    }
    
    Restart(string sourcePath)
    {
        currentSourcePath = sourcePath;
        currentLine = 0;
        lineIndex = 0;
        currentLineContent = "";
        
        currentToken.Type = TokenType.EOF;
        currentToken.Lexeme = "";
        currentToken.Line = 0;
        currentToken.SourcePath = sourcePath;
        
        sourceFile = File.Open(sourcePath);
        if (!sourceFile.IsValid())
        {
            Error(sourcePath, 0, "failed to open '" + sourcePath + "'");
            return;
        }
        advanceLine();
        advanceToken();
    }
    
       
    advanceLine()
    {
        string line = sourceFile.ReadLine();
        if (sourceFile.IsValid()) // after ReadLine implies that we got good content
        {
            if (line.Length == 0) 
            {
                currentLineContent = "";
                return;
            }
            
            uint firstColon;
            uint secondColon;
            if (!line.IndexOf(':', ref firstColon) || !line.IndexOf(Char.Tab, firstColon + 1, ref secondColon)) 
            {
                Error(currentSourcePath, currentLine, "invalid preprocessed line format");
                return;
            }
            
            currentSourcePath = line.Substring(0, firstColon);
            _ = UInt.TryParse(line.Substring(firstColon + 1, secondColon - firstColon - 1), ref currentLine);
            currentLineContent = (line.Substring(secondColon + 1)).Trim();
            lineIndex = 0;
        }
        else
        {
            currentLineContent = "";
        }
    }
    
    advanceToken()
    {
        skipWhitespace();
        if (lineIndex >= currentLineContent.Length)
        {
            if (!sourceFile.IsValid())
            {
                currentToken.Type = TokenType.EOF;
                currentToken.Lexeme = "";
                currentToken.Line = currentLine;
                currentToken.SourcePath = currentSourcePath;
                return;
            }
            advanceLine();
            skipWhitespace();
        }
        
        if (lineIndex >= currentLineContent.Length)
        {
            currentToken.Type = TokenType.EOF;
            currentToken.Lexeme = "";
            currentToken.Line = currentLine;
            currentToken.SourcePath = currentSourcePath;
            return;
        }
        
        char c = currentLineContent[lineIndex];
        
        if (Char.IsLetter(c) || (c == '_'))
        {
            currentToken = tokenizeIdentifier();
        }
        else if (Char.IsDigit(c))
        {
            currentToken = tokenizeNumber();
        }
        else if (c == '"')
        {
            currentToken = tokenizeString();
        }
        else if (c == '\'')
        {
            currentToken = tokenizeChar();
        }
        else
        {
            currentToken = tokenizeSymbol();
        }
    }
    
    Token tokenizeIdentifier()
    {
        uint start = lineIndex;
        while ((lineIndex < currentLineContent.Length) && (Char.IsLetterOrDigit(currentLineContent[lineIndex]) || (currentLineContent[lineIndex] == '_')))
        {
            lineIndex++;
        }
        
        string lexeme = currentLineContent.Substring(start, lineIndex - start);
        TokenType tp;
        if (TCToken.IsKeyword(lexeme, ref tp))
        {
            return createToken(tp, lexeme);
        }
        else
        {
            return createToken(TokenType.IDENTIFIER, lexeme);
        }
    }
    
    Token tokenizeNumber()
    {
        uint start = lineIndex;
        bool isHex = false;
        bool isBinary = false;

        if ((currentLineContent[start] == '0') && (start + 1 < currentLineContent.Length))
        {
            char nextChar = currentLineContent[start + 1];
            if ((nextChar == 'x') || (nextChar == 'X'))
            {
                isHex = true;
                lineIndex += 2; // Skip '0x'
            }
            else if ((nextChar == 'b') || (nextChar == 'B'))
            {
                isBinary = true;
                lineIndex += 2; // Skip '0b'
            }
        }

        if (isHex)
        {
            while ((lineIndex < currentLineContent.Length) && Char.IsHexDigit(currentLineContent[lineIndex]))
            {
                lineIndex++;
            }
        }
        else if (isBinary)
        {
            while ((lineIndex < currentLineContent.Length) && ((currentLineContent[lineIndex] == '0') || (currentLineContent[lineIndex] == '1')))
            {
                lineIndex++;
            }
        }
        else
        {
            while ((lineIndex < currentLineContent.Length) && Char.IsDigit(currentLineContent[lineIndex]))
            {
                lineIndex++;
            }
        }
        
        string lexeme = currentLineContent.Substring(start, lineIndex - start);
        return createToken(TokenType.LIT_NUMBER, lexeme);
    }
    
    Token tokenizeString()
    {
        uint start = lineIndex;
        lineIndex++; // Skip opening quote
        string lexeme = "";
        while (lineIndex < currentLineContent.Length)
        {
            char c = currentLineContent[lineIndex];
            if (c == '"')
            {
                lineIndex++; // Skip closing quote
                return createToken(TokenType.LIT_STRING, lexeme);
            }
            else if (c == '\\')
            {
                lineIndex++; // Skip backslash
                if (lineIndex >= currentLineContent.Length)
                {
                    break;
                }
                c = currentLineContent[lineIndex];
                switch (c)
                {
                    case '"':  { lexeme += '"'; }
                    case '\\': { lexeme += '\\'; }
                    case 'n':  { lexeme += Char.EOL; }
                    case 't':  { lexeme += Char.Tab; }
                    case 'r':  { lexeme += char(0x0D); }
                    default:   { lexeme += '\\' + c; } // Keep unrecognized escape sequences as is
                }
            }
            else
            {
                lexeme += c;
            }
            lineIndex++;
        }
        
        Error(currentSourcePath, currentLine, "unterminated string literal");
        return createToken(TokenType.EOF, "");
    }
    
    
    Token tokenizeChar()
    {
        uint start = lineIndex;
        lineIndex++; // Skip opening quote
        string lexeme = "";
    
        if (lineIndex >= currentLineContent.Length)
        {
            Error(currentSourcePath, currentLine, "unterminated char literal");
            return createToken(TokenType.EOF, "");
        }
    
        char c = currentLineContent[lineIndex];
        if (c == '\\')
        {
            lineIndex++; // Skip backslash
            if (lineIndex >= currentLineContent.Length)
            {
                Error(currentSourcePath, currentLine, "unterminated char literal");
                return createToken(TokenType.EOF, "");
            }
            c = currentLineContent[lineIndex];
            switch (c)
            {
                case '\'': { lexeme += '\'';  }
                case '\\': { lexeme += '\\';  }
                case 'n':  { lexeme += Char.EOL;  }
                case 't':  { lexeme += Char.Tab;  }
                case 'v':  { lexeme += char(0x0B);  }
                case 'f':  { lexeme += char(0x0C);  }
                case 'r':  { lexeme += char(0x0D);  }
                case '0':  { lexeme += char(0x00);  }
                default:   
                { 
                    Error(currentSourcePath, currentLine, "unrecognized escape sequence '\\" + c + "'");
                    return createToken(TokenType.EOF, "");
                } 
            }
        }
        else
        {
            lexeme += c;
        }
    
        lineIndex++; // Move past the character or escape sequence
    
        if ((lineIndex >= currentLineContent.Length) || (currentLineContent[lineIndex] != '\''))
        {
            Error(currentSourcePath, currentLine, "unterminated char literal");
            return createToken(TokenType.EOF, "");
        }
    
        lineIndex++; // Skip closing quote
        return createToken(TokenType.LIT_CHAR, lexeme);
    }
    
    
    Token tokenizeSymbol()
    {
        char c = currentLineContent[lineIndex];
        lineIndex++;
        
        switch (c)
        {
            case '(': { return createToken(TokenType.SYM_LPAREN, "(");}
            case ')': { return createToken(TokenType.SYM_RPAREN, ")");}
            case '{': { return createToken(TokenType.SYM_LBRACE, "{");}
            case '}': { return createToken(TokenType.SYM_RBRACE, "}");}
            case ']': { return createToken(TokenType.SYM_RBRACKET, "]");}
            case ';': { return createToken(TokenType.SYM_SEMICOLON, ";");}
            case ':': { return createToken(TokenType.SYM_COLON, ":");}
            case ',': { return createToken(TokenType.SYM_COMMA, ","); }
            case '.': { return createToken(TokenType.SYM_DOT, ".");}
            case '#': { return createToken(TokenType.SYM_HASH, "#");}
            case '[': 
            { 
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '['))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_LLBRACKET, "[[");
                }
                return createToken(TokenType.SYM_LBRACKET, "[");
            }
            case '+':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '+'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_PLUSPLUS, "++");
                }
                else if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_PLUSEQ, "+=");
                }
                return createToken(TokenType.SYM_PLUS, "+");
            }
            case '-':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '-'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_MINUSMINUS, "--");
                }
                else if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_MINUSEQ, "-=");
                }
                return createToken(TokenType.SYM_MINUS, "-");
            }
            case '*':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_STAREQ, "*=");
                }
                return createToken(TokenType.SYM_STAR, "*");
            }
            case '/':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_SLASHEQ, "/=");
                }
                return createToken(TokenType.SYM_SLASH, "/");
            }
            case '%':
            {
                return createToken(TokenType.SYM_PERCENT, "%");
            }
            case '&':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '&'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_AMPAMP, "&&");
                }
                return createToken(TokenType.SYM_AMP, "&");
            }
            case '|':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '|'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_PIPEPIPE, "||");
                }
                return createToken(TokenType.SYM_PIPE, "|");
            }
            case '^':
            {
                return createToken(TokenType.SYM_CARET, "^");
            }
            case '~':
            {
                return createToken(TokenType.SYM_TILDE, "~");
            }
            case '!':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_NEQ, "!="); Print("HERE");
                }
                return createToken(TokenType.SYM_BANG, "!");
            }
            case '?':
            {
                return createToken(TokenType.SYM_QUESTION, "?");
            }
            case '=':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_EQEQ, "==");
                }
                return createToken(TokenType.SYM_EQ, "=");
            }
            case '<':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_LTE, "<=");
                }
                else if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '<'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_LSHIFT, "<<");
                }
                return createToken(TokenType.SYM_LT, "<");
            }
            case '>':
            {
                if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '='))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_GTE, ">=");
                }
                else if ((lineIndex < currentLineContent.Length) && (currentLineContent[lineIndex] == '>'))
                {
                    lineIndex++;
                    return createToken(TokenType.SYM_RSHIFT, ">>");
                }
                return createToken(TokenType.SYM_GT, ">");
            }
        }
        Error(currentSourcePath, currentLine, "unsupported token '" + c + "'");
        return createToken(TokenType.EOF, "");
    }
    
    Token createToken(TokenType tp, string lexeme)
    {
        Token token;
        token.Type = tp;
        token.Lexeme = lexeme;
        token.Line = currentLine;
        token.SourcePath = currentSourcePath;
        return token;
    }
    
    skipWhitespace()
    {
        while ((lineIndex < currentLineContent.Length) && Char.IsWhitespace(currentLineContent[lineIndex]))
        {
            lineIndex++;
        }
    }
}

