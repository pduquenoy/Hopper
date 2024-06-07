program TestLexer
{
    #define EXPERIMENTAL
    #define MCU

    uses "TinyToken"
    uses "Lexer"
    uses "Parser"
    uses "AST"
    uses "/Source/System/System"
    uses "/Source/System/IO"

    string Clean(string value)
    {
        string clean;
        clean = value.Replace("\\", "/");
        return clean;
    }

    Hopper()
    {
        Initialize();
        //<string> arguments = Arguments;
        string sourcePath = "/data/test.tc"; // Path.GetFullPath(arguments[0]);
        //string sourcePath = "/data/testsuite.tc"; // Path.GetFullPath(arguments[0]);
        WriteLn(sourcePath);
        string source;
        if (!File.TryReadAllText(sourcePath, ref source))
        {
            IO.WriteLn("Failed to read source file.");
            Diagnostics.Die(1);
        }

        Lexer lexer = Lexer(source);
        <Token> tokens;
        Token token;
        LexerError error;
        loop
        {
            error = ScanToken(ref lexer, ref token);
            if (error != LexerError.NONE)
            {
                IO.WriteLn("Lexer error: " + Lexer.ToString(error));
                break;
            }

            tokens.Append(token);
            //IO.WriteLn(">> " + TinyToken.ToString(token.Type) + " '" + Clean(token.Lexeme) + "'");
            if (token.Type == TokenType.EOF)
            {
                break;
            }
        }

        Parser parser = Parser(tokens);
        Program prog;
        ParserError parserError = ParseProgram(ref parser, ref prog);

        if (parserError != ParserError.NONE)
        {
            IO.WriteLn("Parser error: " + Parser.ToString(parserError));
            Diagnostics.Die(1);
        }

        // Print or process the AST
        // For example, IO.WriteLn(program.ToString());
    }
}

