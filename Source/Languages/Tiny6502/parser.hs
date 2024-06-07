unit Parser
{
    uses "AST"
    uses "TinyToken"
    uses "Lexer"
    
    record ParserError
    {
        ParserErrorType Type;
        uint Line;
    }
    
    enum ParserErrorType
    {
        NONE,
        UNEXPECTED_TOKEN,
        EXPECTED_EXPRESSION,
        EXPECTED_CLOSING_PAREN
    }
    
    string ToString(ParserError error)
    {
        string result = "";
        switch (error.Type)
        {
            case ParserErrorType.NONE: { result = "No error"; }
            case ParserErrorType.UNEXPECTED_TOKEN: { result = "Unexpected token"; }
            case ParserErrorType.EXPECTED_EXPRESSION: { result = "Expected expression"; }
            case ParserErrorType.EXPECTED_CLOSING_PAREN: { result = "Expected closing parenthesis"; }
        }
        return result + " at line " + (error.Line).ToString();
    }
    
    record Parser
    {
        <Token> Tokens;
        uint Current;
    }
    
    Parser Parser(<Token> tokens)
    {
        Parser result;
        result.Tokens = tokens;
        result.Current = 0;
        return result;
    }
    
    bool isAtEnd(Parser parser)
    {
        Token current = (parser.Tokens).GetItem(parser.Current);
        return current.Type == TokenType.EOF;
    }
    
    Token advance(ref Parser parser)
    {
        if (!isAtEnd(parser)) { parser.Current++; }
        return previous(parser);
    }
    
    Token peek(Parser parser)
    {
        Token result = (parser.Tokens).GetItem(parser.Current);
        return result;
    }
    
    Token previous(Parser parser)
    {
        Token result = (parser.Tokens).GetItem(parser.Current - 1);
        return result;
    }
    
    bool match(ref Parser parser, TokenType tokenType)
    {
        if (isAtEnd(parser)) { return false; }
        if ((peek(parser)).Type != tokenType) { return false; }
        _ = advance(ref parser);
        return true;
    }
    
    ParserError parseExpression(ref Parser parser, ref Expr expr)
    {
        expr = parseEquality(ref parser);
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = expr.Line;
        return success;
    }
    
    Expr parseEquality(ref Parser parser)
    {
        Expr expr = parseComparison(ref parser);
        while (match(ref parser, TokenType.SYM_EQEQ) || match(ref parser, TokenType.SYM_NEQ))
        {
            string operator = (previous(parser)).Lexeme;
            Expr right = parseComparison(ref parser);
            expr = AST.ExprBinary(expr.Line, expr, operator, right);
        }
        return expr;
    }
    
    Expr parseComparison(ref Parser parser)
    {
        Expr expr = parseAddition(ref parser);
        while (match(ref parser, TokenType.SYM_LT) || match(ref parser, TokenType.SYM_LTE) ||
               match(ref parser, TokenType.SYM_GT) || match(ref parser, TokenType.SYM_GTE))
        {
            string operator = (previous(parser)).Lexeme;
            Expr right = parseAddition(ref parser);
            expr = AST.ExprBinary(expr.Line, expr, operator, right);
        }
        return expr;
    }
    
    Expr parseAddition(ref Parser parser)
    {
        Expr expr = parseMultiplication(ref parser);
        while (match(ref parser, TokenType.SYM_PLUS) || match(ref parser, TokenType.SYM_MINUS))
        {
            string operator = (previous(parser)).Lexeme;
            Expr right = parseMultiplication(ref parser);
            expr = AST.ExprBinary(expr.Line, expr, operator, right);
        }
        return expr;
    }
    
    Expr parseMultiplication(ref Parser parser)
    {
        Expr expr = parseUnary(ref parser);
        while (match(ref parser, TokenType.SYM_STAR) || match(ref parser, TokenType.SYM_SLASH))
        {
            string operator = (previous(parser)).Lexeme;
            Expr right = parseUnary(ref parser);
            expr = AST.ExprBinary(expr.Line, expr, operator, right);
        }
        return expr;
    }
    
    Expr parseUnary(ref Parser parser)
    {
        if (match(ref parser, TokenType.SYM_BANG) || match(ref parser, TokenType.SYM_MINUS))
        {
            string operator = (previous(parser)).Lexeme;
            Expr right = parseUnary(ref parser);
            return AST.ExprUnary(right.Line, operator, right);
        }
        return parsePrimary(ref parser);
    }
    
    Expr parsePrimary(ref Parser parser)
    {
        if (match(ref parser, TokenType.LIT_NUMBER))
        {
            return AST.ExprLiteral((previous(parser)).Line, (previous(parser)).Lexeme);
        }
        if (match(ref parser, TokenType.LIT_CHAR))
        {
            return AST.ExprLiteral((previous(parser)).Line, (previous(parser)).Lexeme);
        }
        if (match(ref parser, TokenType.IDENTIFIER))
        {
            return AST.ExprVariable((previous(parser)).Line, (previous(parser)).Lexeme);
        }
        if (match(ref parser, TokenType.SYM_LPAREN))
        {
            Expr expr;
            ParserError error = parseExpression(ref parser, ref expr);
            if (error.Type != ParserErrorType.NONE) 
            {
                return AST.ExprLiteral(0, "0");  // Using "0" as the default placeholder value
            }
            if (!match(ref parser, TokenType.SYM_RPAREN))
            {
                return AST.ExprLiteral(0, "0");  // Using "0" as the default placeholder value
            }
            return expr;
        }
        return AST.ExprLiteral(0, "0");  // Using "0" as the default placeholder value
    }
    
    ParserError parseDeclaration(ref Parser parser, ref Decl decl)
    {
        if (match(ref parser, TokenType.KW_FUNC))
        {
            return parseFunctionDeclaration(ref parser, ref decl);
        }
        else
        {
            return parseVariableDeclaration(ref parser, ref decl);
        }
    }
    
    ParserError parseVariableDeclaration(ref Parser parser, ref Decl decl)
    {
        StmtVar varStmt;
        if (!match(ref parser, TokenType.IDENTIFIER))
        {
            ParserError error;
            error.Type = ParserErrorType.UNEXPECTED_TOKEN;
            error.Line = (previous(parser)).Line;
            return error;
        }
        varStmt.Name = (previous(parser)).Lexeme;
        uint line = (previous(parser)).Line;
    
        Expr initializer;
        if (match(ref parser, TokenType.SYM_EQ))
        {
            ParserError error = parseExpression(ref parser, ref initializer);
            if (error.Type != ParserErrorType.NONE) 
            { 
                return error; 
            }
        }
        else
        {
            initializer = AST.ExprLiteral(line, "0"); // Using "0" as the default value
        }
        varStmt.Initializer = initializer;
    
        if (!match(ref parser, TokenType.SYM_SEMICOLON))
        {
            ParserError error;
            error.Type = ParserErrorType.UNEXPECTED_TOKEN;
            error.Line = (previous(parser)).Line;
            return error;
        }
    
        Decl result;
        result.Line = line;
        result.Type = DeclType.VAR_DECL;
        result.VarDecl = varStmt;
        decl = result;
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = line;
        return success;
    }
        
    ParserError parseFunctionDeclaration(ref Parser parser, ref Decl decl)
    {
        DeclFunc funcDecl;
        if (!match(ref parser, TokenType.IDENTIFIER))
        {
            ParserError error;
            error.Type = ParserErrorType.UNEXPECTED_TOKEN;
            error.Line = (previous(parser)).Line;
            return error;
        }
        funcDecl.Name = (previous(parser)).Lexeme;
        uint line = (previous(parser)).Line;
    
        if (!match(ref parser, TokenType.SYM_LPAREN))
        {
            ParserError error;
            error.Type = ParserErrorType.UNEXPECTED_TOKEN;
            error.Line = (previous(parser)).Line;
            return error;
        }
    
        <string> parameters;
        if (!match(ref parser, TokenType.SYM_RPAREN))
        {
            loop
            {
                if (!match(ref parser, TokenType.IDENTIFIER))
                {
                    ParserError error;
                    error.Type = ParserErrorType.UNEXPECTED_TOKEN;
                    error.Line = (previous(parser)).Line;
                    return error;
                }
                parameters.Append((previous(parser)).Lexeme);
                if (!match(ref parser, TokenType.SYM_COMMA))
                {
                    if (!match(ref parser, TokenType.SYM_RPAREN))
                    {
                        ParserError error;
                        error.Type = ParserErrorType.UNEXPECTED_TOKEN;
                        error.Line = (previous(parser)).Line;
                        return error;
                    }
                    break;
                }
            }
        }
    
        funcDecl.Params = parameters;
    
        <Stmt> body;
        if (!match(ref parser, TokenType.SYM_LBRACE))
        {
            ParserError error;
            error.Type = ParserErrorType.UNEXPECTED_TOKEN;
            error.Line = (previous(parser)).Line;
            return error;
        }
        while (!match(ref parser, TokenType.SYM_RBRACE) && !isAtEnd(parser))
        {
            Stmt statement;
            ParserError error = parseStatement(ref parser, ref statement);
            if (error.Type != ParserErrorType.NONE) 
            { 
                return error; 
            }
            body.Append(statement);
        }
    
        funcDecl.Body = body;
        Decl result;
        result.Line = line;
        result.Type = DeclType.FUNC_DECL;
        result.FuncDecl = funcDecl;
        decl = result;
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = line;
        return success;
    }
    
    
    ParserError ParseProgram(ref Parser parser, ref Program prog)
    {
        <Decl> declarations;
        ParserError error;
        loop
        {
            Decl decl;
            error = parseDeclaration(ref parser, ref decl);
            if (error.Type != ParserErrorType.NONE) 
            { 
                return error; 
            }
            declarations.Append(decl);
            if (isAtEnd(parser)) 
            { 
                break; 
            }
        }
        prog.Declarations = declarations;
    
        ParserError result;
        result.Type = ParserErrorType.NONE;
        result.Line = 0;
        return result;
    }
    
    
    ParserError parseStatement(ref Parser parser, ref Stmt stmt)
    {
        if (match(ref parser, TokenType.KW_IF)) 
        {
            return parseIfStatement(ref parser, ref stmt);
        } 
        else if (match(ref parser, TokenType.KW_WHILE)) 
        {
            return parseWhileStatement(ref parser, ref stmt);
        } 
        else if (match(ref parser, TokenType.KW_FOR)) 
        {
            return parseForStatement(ref parser, ref stmt);
        } 
        else if (match(ref parser, TokenType.KW_RETURN)) 
        {
            return parseReturnStatement(ref parser, ref stmt);
        } 
        else if (match(ref parser, TokenType.SYM_LBRACE)) 
        {
            return parseBlockStatement(ref parser, ref stmt);
        }
        else
        {
            return parseExpressionStatement(ref parser, ref stmt);
        }
    }
    
    ParserError parseIfStatement(ref Parser parser, ref Stmt stmt)
    {
        // Implement this function as needed
        Diagnostics.Die(0x0A);
        ParserError result;
        result.Type = ParserErrorType.NONE;
        result.Line = 0;
        return result;
    }
    
    ParserError parseWhileStatement(ref Parser parser, ref Stmt stmt)
    {
        // Implement this function as needed
        Diagnostics.Die(0x0A);
        ParserError result;
        result.Type = ParserErrorType.NONE;
        result.Line = 0;
        return result;
    }
    
    ParserError parseForStatement(ref Parser parser, ref Stmt stmt)
    {
        // Implement this function as needed
        Diagnostics.Die(0x0A);
        ParserError result;
        result.Type = ParserErrorType.NONE;
        result.Line = 0;
        return result;
    }
    
    ParserError parseReturnStatement(ref Parser parser, ref Stmt stmt)
    {
        uint line = (previous(parser)).Line;
    
        StmtReturn returnStmt;
        returnStmt.Expression = AST.ExprLiteral(line, ""); // Placeholder for return expression
    
        if (!match(ref parser, TokenType.SYM_SEMICOLON))
        {
            Expr expr;
            ParserError error = parseExpression(ref parser, ref expr);
            if (error.Type != ParserErrorType.NONE)
            {
                return error;
            }
            returnStmt.Expression = expr;
    
            if (!match(ref parser, TokenType.SYM_SEMICOLON))
            {
                ParserError result;
                result.Type = ParserErrorType.UNEXPECTED_TOKEN;
                result.Line = line;
                return result;
            }
        }
    
        Stmt resultStmt;
        resultStmt.Line = line;
        resultStmt.Type = StmtType.RETURN_STMT;
        resultStmt.ReturnStmt = returnStmt;
        stmt = resultStmt;
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = line;
        return success;
    }
    
    ParserError parseBlockStatement(ref Parser parser, ref Stmt stmt)
    {
        uint line = (previous(parser)).Line;
        <Stmt> statements;
    
        while (!match(ref parser, TokenType.SYM_RBRACE) && !isAtEnd(parser))
        {
            Stmt statement;
            ParserError error = parseStatement(ref parser, ref statement);
            if (error.Type != ParserErrorType.NONE) 
            {
                return error;
            }
            statements.Append(statement);
        }
    
        StmtBlock blockStmt;
        blockStmt.Statements = statements;
    
        Stmt resultStmt;
        resultStmt.Line = line;
        resultStmt.Type = StmtType.BLOCK_STMT;
        resultStmt.BlockStmt = blockStmt;
        stmt = resultStmt;
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = line;
        return success;
    }
    
    ParserError parseExpressionStatement(ref Parser parser, ref Stmt stmt)
    {
        Expr expression;
        ParserError error = parseExpression(ref parser, ref expression);
        if (error.Type != ParserErrorType.NONE) 
        {
            return error;
        }
    
        if (!match(ref parser, TokenType.SYM_SEMICOLON)) 
        {
            ParserError result;
            result.Type = ParserErrorType.UNEXPECTED_TOKEN;
            result.Line = expression.Line;
            return result;
        }
    
        StmtExpr exprStmt;
        exprStmt.Expression = expression;
    
        Stmt resultStmt;
        resultStmt.Line = expression.Line;
        resultStmt.Type = StmtType.EXPR_STMT;
        resultStmt.ExprStmt = exprStmt;
        stmt = resultStmt;
    
        ParserError success;
        success.Type = ParserErrorType.NONE;
        success.Line = expression.Line;
        return success;
    }

}
