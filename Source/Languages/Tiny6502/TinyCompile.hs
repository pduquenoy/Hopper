unit TinyCompile
{
    friend TinyStatement, TinyExpression;
    
    uses "TinyToken"
    uses "TinyScanner"
    uses "TinyCode"
    uses "TinyStatement"
    uses "TinyExpression"
    uses "TinyConstant"
    uses "TinyType"
    uses "TinySymbols"
    
    bool Compile()
    {
        bool success;
        loop
        {
            // global scope
            TinyConstant.EnterBlock();
            TinySymbols.EnterBlock();
            
            if (!parseProgram())
            {
                break;
            }
        
            // global scope
            TinySymbols.LeaveBlock("program");
            TinyConstant.LeaveBlock();
            
            Token token = TinyScanner.Current();
            string returnType;
            if (!GetFunction("main", ref returnType))
            {
                Error(token.SourcePath, token.Line, "'main()' entrypoint missing");
                break;
            }
            if (returnType != "")
            {
                Error(token.SourcePath, token.Line, "'main()' entrypoint should not have return type");
                break;
            }
            success = true;
            break;
        }
        
        return success;
    }
    
    bool parseProgram()
    {
        bool success = true;
        Token token;
        
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.EOF)
            {
                break; // exit the loop when reaching EOF
            }
            
            switch (token.Type)
            {
                case TokenType.KW_CONST:
                {
                    success = parseConst();
                }
                case TokenType.KW_BYTE:
                case TokenType.KW_WORD:
                case TokenType.KW_CHAR:
                case TokenType.KW_BOOL:
                case TokenType.KW_INT:
                case TokenType.KW_UINT:
                {
                    success = parseGlobalVar();
                }
                case TokenType.KW_FUNC:
                {
                    success = parseFunction();
                }
                case TokenType.SYM_HASH:
                {
                    success = parseSymbol();
                }
                default:
                {
                    Error(token.SourcePath, token.Line, "unexpected token: " + TinyToken.ToString(token.Type) + "('" + token.Lexeme + "')");
                    success = false;
                }
            }
            
            if (!success)
            {
                break; // exit the loop on error
            }
        }
        
        return success;
    }
    
    bool parseConst()
    {
        TinyScanner.Advance(); // Skip 'const'
        Token token = TinyScanner.Current();
        
        string constantType;
        if (!parseType(ref constantType))
        {
            return false;
        }
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
        
        constantType = "const " + constantType;
        
        string expressionType;
        string value;
        if (!TinyConstant.parseConstantExpression(ref value, ref expressionType))
        {
            return false;
        }
        if (!IsAutomaticCast(constantType, expressionType))
        {
            TypeError(constantType, expressionType);
        }
        
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after constant declaration, ('" + token.Lexeme + "')");
            return false;
        }
        
        TinyScanner.Advance(); // Skip ';'
        
        return TinyConstant.DefineConst(constantType, name, value);
    }
    
    bool parseSymbol()
    {
        TinyScanner.Advance(); // Skip #
        
        Token token = TinyScanner.Current();
        if ((token.Type != TokenType.IDENTIFIER) || (token.Lexeme != "define"))
        {
            Error(token.SourcePath, token.Line, "'#define' expected");
            return false;
        }
        
        TinyScanner.Advance(); // Skip 'define'
        
        token = TinyScanner.Current();
        if (token.Type != TokenType.IDENTIFIER)
        {
            Error(token.SourcePath, token.Line, "preprocessor symbol identifier expected");
            return false;
        }
        DefineSymbol(token.Lexeme);
        
        TinyScanner.Advance(); // Skip symbol
        return true;
    }
    
 
    bool parseGlobalVar()
    {
        string tp;
        if (!parseType(ref tp))
        {
            return false;
        }
    
        Token token = TinyScanner.Current();
        if (token.Type != TokenType.IDENTIFIER)
        {
            Error(token.SourcePath, token.Line, "expected identifier after type");
            return false;
        }
    
        string name = token.Lexeme;
        
        if (!DefineVariable(tp, name))
        {
            return false;
        }
        
        TinyScanner.Advance(); // Skip identifier
    
        token = TinyScanner.Current();
        if (token.Type == TokenType.SYM_EQ)
        {
            TinyScanner.Advance(); // Skip '='
    
            string exprType;
            if (!TinyExpression.parseExpression(ref exprType))
            {
                return false;
            }
        }
    
        token = TinyScanner.Current();
        if (token.Type != TokenType.SYM_SEMICOLON)
        {
            Error(token.SourcePath, token.Line, "expected ';' after variable declaration, (" + token.Lexeme + "')");
            return false;
        }
    
        TinyScanner.Advance(); // Skip ';'
    
        return true;
    }
    
    bool parseFunction()
    {
        bool success;
        
        loop
        {
            TinyScanner.Advance(); // Skip 'func'
            Token token = TinyScanner.Current();
        
            // Optional return type
            string returnType = "";
            if (token.Type != TokenType.IDENTIFIER)
            {
                if (!parseType(ref returnType))
                {
                    break;
                }
                token = TinyScanner.Current();
            }
        
            if (token.Type != TokenType.IDENTIFIER)
            {
                Error(token.SourcePath, token.Line, "expected identifier after 'func', (" + token.Lexeme + "')");
                break;
            }
        
            string functionName = token.Lexeme;
            TinyScanner.Advance(); // Skip identifier
            
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_EQ)
            {
                // Handle function pointer assignment
                TinyScanner.Advance(); // Skip '='
                
                string exprType;
                if (!TinyExpression.parseExpression(ref exprType))
                {
                    break;
                }
        
                token = TinyScanner.Current();
                if (token.Type != TokenType.SYM_SEMICOLON)
                {
                    Error(token.SourcePath, token.Line, "expected ';' after function pointer assignment, (" + token.Lexeme + "')");
                    break;
                }
        
                TinyScanner.Advance(); // Skip ';'
                //TinyCode.DefineFunctionPointer(name); // TODO: Implement in TinyCode
                success = true;
                break;
            }
            
            TinyCode.Function(functionName);
            TinyConstant.EnterBlock();
            TinySymbols.EnterBlock(); // for arguments
            if (!DefineFunction(returnType, functionName))
            {
                break;
            }
            
            if (token.Type != TokenType.SYM_LPAREN)
            {
                Error(token.SourcePath, token.Line, "expected '(' after function name, (" + token.Lexeme + "')");
                break;
            }
        
            TinyScanner.Advance(); // Skip '('
            if (!parseParameterList(functionName))
            {
                break;
            }
        
            token = TinyScanner.Current();
            if (token.Type != TokenType.SYM_RPAREN)
            {
                Error(token.SourcePath, token.Line, "expected ')' after parameter list, (" + token.Lexeme + "')");
                break;
            }
        
            TinyScanner.Advance(); // Skip ')'
        
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_SEMICOLON)
            {
                // This is a forward declaration
                TinyScanner.Advance(); // Skip ';'
                //TinyCode.DefineForwardFunction(name);
            }
            else if (token.Type == TokenType.SYM_LBRACE)
            {
                // This is an actual function definition
                if (!TinyStatement.parseBlock(false))
                {
                    break;
                }
            }
            else
            {
                Error(token.SourcePath, token.Line, "expected '{' to start function body or ';' for forward declaration");
                break;
            }
            
            TinySymbols.LeaveBlock(functionName); // for arguments
            TinyConstant.LeaveBlock();
            
            success = true;
            break;
        } // loop
        
        
        return success;
    }
    
    bool parseParameterList(string functionName)
    {
        Token token;
        loop
        {
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_RPAREN)
            {
                break; // exit the loop when reaching ')'
            }
            
            string variableType;
            if (!parseType(ref variableType))
            {
                return false;
            }
            
            token = TinyScanner.Current();
            if (token.Type != TokenType.IDENTIFIER)
            {
                Error(token.SourcePath, token.Line, "expected parameter name");
                return false;
            }
            
            string variableName = token.Lexeme;
            
            if (!DefineVariable(variableType, variableName))
            {
                return false;
            }
            if (!DefineArgument(functionName, variableType, variableName))
            {
                return false;
            }
            
            TinyScanner.Advance(); // Skip name
            
            token = TinyScanner.Current();
            if (token.Type == TokenType.SYM_COMMA)
            {
                TinyScanner.Advance(); // Skip ','
            }
            else if (token.Type != TokenType.SYM_RPAREN)
            {
                Error(token.SourcePath, token.Line, "expected ',' or ')' after parameter");
                return false;
            }
        }
        return true; // success
    }
    
    bool parseType(ref string tp)
    {
        Token token = TinyScanner.Current();
    
        if (token.Type == TokenType.KW_CONST)
        {
            tp = "const ";
            TinyScanner.Advance(); // Skip 'const'
            token = TinyScanner.Current();
        }
        else
        {
            tp = "";
        }
    
        if (!TinyToken.IsTypeKeyword(token.Type))
        {
            Error(token.SourcePath, token.Line, "expected type");
            return false;
        }
    
        tp += token.Lexeme;
        TinyScanner.Advance(); // Skip type
    
        token = TinyScanner.Current();
        if (token.Type == TokenType.SYM_LBRACKET)
        {
            TinyScanner.Advance(); // Skip '['
            token = TinyScanner.Current();
    
            // Check for number or identifier (constant)
            if (token.Type != TokenType.SYM_RBRACKET)
            {
                string value;
                string actualType;
                if (!TinyConstant.parseConstantExpression(ref value, ref actualType))
                {
                    return false;
                }
                tp += "[" + value + "]";
            }
            else
            {
                tp += "[]";
            }
    
            token = TinyScanner.Current();
            if (token.Type != TokenType.SYM_RBRACKET)
            {
                Error(token.SourcePath, token.Line, "expected ']', ('" + token.Lexeme + "')");
                return false;
            }
            TinyScanner.Advance(); // Skip ']'
        }
        return true;
    }
}
