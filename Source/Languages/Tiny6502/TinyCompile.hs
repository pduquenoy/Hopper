unit TinyCompile
{
    uses "TinyToken"
    uses "TinyScanner"
    uses "TinyCode"
    
    bool Compile()
    {
        bool success;
        success = parseProgram();
        return success;
    }
    
    bool parseProgram()
    {
        bool success;
        Token token;
        
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.EOF)
            {
                break;
            }
            
            switch (token.Type)
            {
                case TokenType.KW_CONST: { success = parseConst(); }
                case TokenType.KW_BYTE:
                case TokenType.KW_WORD:
                case TokenType.KW_CHAR:
                case TokenType.KW_BOOL:
                case TokenType.KW_INT:
                case TokenType.KW_UINT:
                {
                    success = parseGlobalVar();
                }
                case TokenType.KW_FUNC: { success = parseFunction(); }
                default:
                {
                    Error(token.SourcePath, token.Line, "unexpected token: " + TinyToken.ToString(token.Type));
                    success = false;
                    break;
                }
            }
            
            if (!success)
            {
                break;
            }
        }
        
        return success;
    }
    
    bool parseConst()
    {
        TinyScanner.Advance(); // Skip 'const'
        Token token = TinyScanner.Current();
        
        if ((token.Type != TokenType.KW_BYTE) && (token.Type != TokenType.KW_WORD) && (token.Type != TokenType.KW_CHAR) && (token.Type != TokenType.KW_BOOL) && (token.Type != TokenType.KW_INT) && (token.Type != TokenType.KW_UINT))
        {
            Error(token.SourcePath, token.Line, "expected type after 'const'");
            return false;
        }
        
        string tp = token.Lexeme;
        TinyScanner.Advance(); // Skip type
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.IDENTIFIER)
        {
            Error(token.SourcePath, token.Line, "expected identifier after type");
            return false;
        }
        
        string name = token.Lexeme;
        TinyScanner.Advance(); // Skip identifier
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_EQ)
        {
            Error(token.SourcePath, token.Line, "expected '=' after identifier");
            return false;
        }
        
        TinyScanner.Advance(); // Skip '='
        
        token = TinyScanner.Current();
        if ((token.Type != TokenType.LIT_NUMBER) && (token.Type != TokenType.LIT_CHAR))
        {
            Error(token.SourcePath, token.Line, "expected literal value after '='");
            return false;
        }
        
        string value = token.Lexeme;
        TinyScanner.Advance(); // Skip value
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after constant declaration");
            return false;
        }
        
        TinyScanner.Advance(); // Skip ';'
        
        //TinyCode.DefineConst(tp, name, value);
        return true;
    }
    
    bool parseGlobalVar()
    {
        Token token = TinyScanner.Current();
        string tp = token.Lexeme;
        TinyScanner.Advance(); // Skip type
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.IDENTIFIER)
        {
            Error(token.SourcePath, token.Line, "expected identifier after type");
            return false;
        }
        
        string name = token.Lexeme;
        TinyScanner.Advance(); // Skip identifier
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_EQ)
        {
            Error(token.SourcePath, token.Line, "expected '=' after identifier");
            return false;
        }
        
        TinyScanner.Advance(); // Skip '='
        
        token = TinyScanner.Current();
        if ((token.Type != TokenType.LIT_NUMBER) && (token.Type != TokenType.LIT_CHAR))
        {
            Error(token.SourcePath, token.Line, "expected literal value after '='");
            return false;
        }
        
        string value = token.Lexeme;
        TinyScanner.Advance(); // Skip value
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after variable declaration");
            return false;
        }
        
        TinyScanner.Advance(); // Skip ';'
        
        TinyCode.DefineGlobalVar(tp, name, value);
        return true;
    }
    
    bool parseFunction()
    {
        TinyScanner.Advance(); // Skip 'func'
        Token token = TinyScanner.Current();
        
        if (token.Type != TokenType.IDENTIFIER)
        {
            Error(token.SourcePath, token.Line, "expected identifier after 'func'");
            return false;
        }
        
        string name = token.Lexeme;
        TinyScanner.Advance(); // Skip identifier
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_LPAREN)
        {
            Error(token.SourcePath, token.Line, "expected '(' after function name");
            return false;
        }
        
        TinyScanner.Advance(); // Skip '('
        parseParameterList();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_RPAREN)
        {
            Error(token.SourcePath, token.Line, "expected ')' after parameter list");
            return false;
        }
        
        TinyScanner.Advance(); // Skip ')'
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_LBRACE)
        {
            Error(token.SourcePath, token.Line, "expected '{' to start function body");
            return false;
        }
        
        TinyScanner.Advance(); // Skip '{'
        parseFunctionBody();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_RBRACE)
        {
            Error(token.SourcePath, token.Line, "expected '}' to end function body");
            return false;
        }
        
        TinyScanner.Advance(); // Skip '}'
        
        TinyCode.DefineFunction(name);
        return true;
    }
    
    parseParameterList()
    {
        Token token;
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_RPAREN)
            {
                break;
            }
            
            if ((token.Type != TokenType.KW_BYTE) && (token.Type != TokenType.KW_WORD) && (token.Type != TokenType.KW_CHAR) && (token.Type != TokenType.KW_BOOL) && (token.Type != TokenType.KW_INT) && (token.Type != TokenType.KW_UINT))
            {
                Error(token.SourcePath, token.Line, "expected parameter type");
                break;
            }
            
            string tp = token.Lexeme;
            TinyScanner.Advance(); // Skip type
            
            token = TinyScanner.Current();
            if (token.Type != TokenType.IDENTIFIER)
            {
                Error(token.SourcePath, token.Line, "expected parameter name");
                break;
            }
            
            string name = token.Lexeme;
            TinyScanner.Advance(); // Skip name
            
            //TinyCode.DefineParameter(tp, name); // TODO
            
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_COMMA)
            {
                TinyScanner.Advance(); // Skip ','
            }
            else if (token.Type != TokenType.SYM_RPAREN)
            {
                Error(token.SourcePath, token.Line, "expected ',' or ')' after parameter");
                break;
            }
        }
    }
    
    parseFunctionBody()
    {
        Token token;
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_RBRACE)
            {
                break;
            }
            
            // Parse statements
            parseStatement();
        }
    }
    
    parseStatement()
    {
        Token token = TinyScanner.Current();
        switch (token.Type)
        {
            case TokenType.KW_IF: { parseIfStatement(); }
            case TokenType.KW_WHILE: { parseWhileStatement(); }
            case TokenType.KW_FOR: { parseForStatement(); }
            case TokenType.KW_RETURN: { parseReturnStatement(); }
            case TokenType.IDENTIFIER: { parseExpressionStatement(); }
            default:
            {
                Error(token.SourcePath, token.Line, "unexpected token in statement: " + TinyToken.ToString(token.Type));
            }
        }
    }
    
    parseIfStatement()
    {
        TinyScanner.Advance(); // Skip 'if'
        Token token = TinyScanner.Current();
        
        if (token.Type != TokenType.SYM_LPAREN)
        {
            Error(token.SourcePath, token.Line, "expected '(' after 'if'");
            return;
        }
        
        TinyScanner.Advance(); // Skip '('
        parseExpression();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_RPAREN)
        {
            Error(token.SourcePath, token.Line, "expected ')' after condition");
            return;
        }
        
        TinyScanner.Advance(); // Skip ')'
        parseBlock();
    }
    
    parseWhileStatement()
    {
        TinyScanner.Advance(); // Skip 'while'
        Token token = TinyScanner.Current();
        
        if (token.Type != TokenType.SYM_LPAREN)
        {
            Error(token.SourcePath, token.Line, "expected '(' after 'while'");
            return;
        }
        
        TinyScanner.Advance(); // Skip '('
        parseExpression();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_RPAREN)
        {
            Error(token.SourcePath, token.Line, "expected ')' after condition");
            return;
        }
        
        TinyScanner.Advance(); // Skip ')'
        parseBlock();
    }
    
    parseForStatement()
    {
        TinyScanner.Advance(); // Skip 'for'
        Token token = TinyScanner.Current();
        
        if (token.Type != TokenType.SYM_LPAREN)
        {
            Error(token.SourcePath, token.Line, "expected '(' after 'for'");
            return;
        }
        
        TinyScanner.Advance(); // Skip '('
        parseExpressionStatement();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after initialization");
            return;
        }
        
        TinyScanner.Advance(); // Skip ';'
        parseExpression();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after condition");
            return;
        }
        
        TinyScanner.Advance(); // Skip ';'
        parseExpression();
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_RPAREN)
        {
            Error(token.SourcePath, token.Line, "expected ')' after increment");
            return;
        }
        
        TinyScanner.Advance(); // Skip ')'
        parseBlock();
    }
    
    parseReturnStatement()
    {
        TinyScanner.Advance(); // Skip 'return'
        parseExpression();
        
        Token token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after return statement");
            return;
        }
        
        TinyScanner.Advance(); // Skip ';'
    }
    
    parseExpressionStatement()
    {
        parseExpression();
        
        Token token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after expression");
            return;
        }
        
        TinyScanner.Advance(); // Skip ';'
    }
    
    parseBlock()
    {
        Token token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_LBRACE)
        {
            Error(token.SourcePath, token.Line, "expected '{' to start block");
            return;
        }
        
        TinyScanner.Advance(); // Skip '{'
        
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_RBRACE)
            {
                break;
            }
            
            parseStatement();
        }
        
        TinyScanner.Advance(); // Skip '}'
    }
    
    parseExpression()
    {
        // Placeholder for parsing expressions
        TinyScanner.Advance();
    }
}
