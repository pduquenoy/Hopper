unit MessageBox
{
    uses "/Source/System/Keyboard"
    uses "/Source/System/Screen"
    uses "/Source/System/System"
    uses "/Source/Editor/Panel"
    uses "/Source/Editor/Commands"
    uses "/Source/Editor/Editor"
    uses "/Source/System/Diagnostics"
    uses "/Source/Compiler/Tokens/Token"
    
    delegate bool ValidationDelegate(string content);
    
    // Panel 
    //   x0     : uint
    //   y0     : uint
    //   width  : uint
    //   height : uint
    //   background : uint   - colour
    
    <string, variant> New(string title, string message, <string> buttons)
    {
        <string, variant> instance = New(title, message, "", buttons);
        return instance;
    }
    <string, variant> New(string title, string message, string extra, <string> buttons)
    {
        <string, variant> instance = New(title, message, extra, buttons, 0, 0);
        return instance;
    }
    <string, variant> New(string title, string message, string extra, <string> buttons, uint editfields, uint editwidth)
    {
        uint height = 6;
        uint width = 1;
        
        foreach (var button in buttons)
        {
            uint buttonWidth = button.Length + 2;
            if (buttonWidth < 8)
            {
                buttonWidth = 8;
            }
            width = width + buttonWidth + 1;
        }
        
        if (message.Length + 2 > width)
        {
            width = message.Length + 2;
        }
        if (extra.Length + 2 > width)
        {
            width = extra.Length + 2;
        }
        if (extra.Length > 0)
        {
            height = height + 1;
        }
        height = height + editfields;
        if (editwidth + 2 > width)
        {
            width = editwidth + 2;
        }
        
        uint x = Screen.Columns / 2 - width / 2;
        uint y = Screen.Rows / 2 - height / 2;
        <string, variant> instance = Panel.New(byte(x), byte(y), byte(width), byte(height));
        
        Panel.SetBackground(instance, Color.LightGray);
        
        
        instance["title"] = title;
        instance["message"] = message;
        instance["extra"] = extra;
        instance["buttons"] = buttons;
        
        < <uint> > listOfAreas;
        instance["buttonareas"] = listOfAreas;
        <string,string> fieldvalues;
        for (uint i = 0; i < editfields; i++)
        {
            fieldvalues[i.ToString()] = "";
        }
        instance["fields"] = fieldvalues;
        instance["editwidth"] = editwidth.ToString();
        
        return instance;
    }
    
    DrawField(uint x, uint y, string value, uint editwidth)
    {
        Suspend();
        value = value.Pad(' ', editwidth);
        foreach (var c in value)
        {
            DrawChar(x, y, c, Color.Black, Color.LightestGray);
            x++;
        }
        Resume(true); // interactive
    }
    
    bool AnythingGoes(string content)
    {
        return true;
    }
    string Execute(<string, variant> this)
    {
        ValidationDelegate validation = AnythingGoes;
        return Execute(this, validation);
    }
    
    
    DrawOK(uint x, uint y, bool enabled)
    {
        Suspend();
        string buttonText = " OK ";
        while (buttonText.Length < 8)
        {
            buttonText = " " + buttonText;
            if (buttonText.Length < 8)
            {
                buttonText = buttonText + " ";
            }
        }
        uint forecolor = Color.Black;
        if (!enabled)
        {
            forecolor = Color.DarkGray;
        }
        foreach (var c in buttonText)
        {
            DrawChar(x, y, c, forecolor, Color.Button);
            x++;
        }
        Resume(true); // interactive
    }
      
    
    string Execute(<string, variant> this, ValidationDelegate validation)
    {
        string result;
        
        // draws the solid background
        MessageBox.Draw(this); 
        
        uint editwidth = 0;
        string editWidthText = this["editwidth"];
        string extra = this["extra"];
        if (Token.TryParseUInt(editWidthText, ref editwidth))
        {
        
        }
        bool hasEdit = false;
        uint currentField = 0; // will tab between them
        <string,string> fieldvalues = this["fields"];
        if (fieldvalues.Count > 0)
        {
            hasEdit = true;
        }
        
        uint x0 = Panel.GetX0(this);
        uint y0 = Panel.GetY0(this);
        uint w = Panel.GetWidth(this);
        
        byte oldX = Screen.CursorX;
        byte oldY = Screen.CursorY;
        
        uint xf = x0 + w - editwidth - 1;
        uint yf = y0 + 3;
        uint cursorX = xf;
        uint cursorY = yf;
        string allowed;
        string currentValue = "";
        uint xOK = 0;
        uint yOK = 0;
        if (hasEdit)
        {
            currentValue = fieldvalues[currentField.ToString()];
            string okx = this["ok-x"];
            if (Token.TryParseUInt(okx, ref xOK))
            {
            }
            string oky = this["ok-y"];
            if (Token.TryParseUInt(oky, ref yOK))
            {
            }
            cursorX = xf + currentValue.Length;
            cursorY = yf + currentField * 2;
            Screen.SetCursor(cursorX, cursorY);
            allowed = this["allowed"];
        }
        
        bool enabled = true;
        foreach (var fieldvalue in fieldvalues)
        {
            if (!validation(fieldvalue.value))
            {
                enabled = false;
                break;
            }
        }
        
        <string> buttons = this["buttons"];
        loop
        {
            Key key = ReadKey();
            uint k = uint(key);
            switch (key)
            {
                case Key.Click:
                {
                    uint x = ClickX;
                    uint y = ClickY;
                    if (ClickUp && !ClickDouble)
                    {
                        < <uint> > buttonAreas = this["buttonareas"];
                        uint nbuttons = buttons.Length;
                        bool winner = false;
                        for (uint i=0; i < nbuttons; i++)
                        {
                            string name = buttons[i];
                            <uint> area = buttonAreas[i];
                            uint xb = area[0];
                            uint yb = area[1];
                            uint wb = area[2];
                            uint hb = area[3];
                            if ((x >= xb) && (x <= xb + wb))
                            {
                                if ((y >= yb) && (y < yb + hb))
                                {
                                    if ((name != "OK") || enabled)
                                    {
                                        result = name;
                                        winner = true;
                                        if (name == "OK")
                                        {
                                            fieldvalues[currentField.ToString()] = currentValue;
                                            this["fields"] = fieldvalues;
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                        if (winner)
                        {
                            break;
                        }
                    }
                }
                case Key.Escape:
                {
                    if (buttons.Contains("Cancel"))
                    {
                        result = "Cancel";
                        break;
                    }
                }
                case Key.Enter:
                {
                    if (buttons.Contains("OK"))
                    {   
                        if (enabled)
                        {
                            fieldvalues[currentField.ToString()] = currentValue;
                            this["fields"] = fieldvalues;
                            result = "OK";
                            break;
                        }
                    }
                }
                case Key.Tab:
                {
                    if (fieldvalues.Count > 1)
                    {
                        fieldvalues[currentField.ToString()] = currentValue;
                        currentField++;
                        if (currentField == fieldvalues.Count)
                        {
                            currentField = 0;
                        }
                        currentValue = fieldvalues[currentField.ToString()];
                        cursorX = xf + currentValue.Length;
                        cursorY = yf + currentField * 2;
                        Screen.SetCursor(cursorX, cursorY);
                        DrawField(xf, cursorY, currentValue, editwidth);
                    }
                }
                case Key.Home:
                {
                    if (fieldvalues.Count > 0)
                    {
                        if (cursorX > xf)
                        {
                            cursorX = xf;
                            Screen.SetCursor(cursorX, cursorY);
                            DrawField(xf, cursorY, currentValue, editwidth);
                        }
                    }
                }
                case Key.End:
                {
                    if (fieldvalues.Count > 0)
                    {
                        cursorX = xf + currentValue.Length;
                        Screen.SetCursor(cursorX, cursorY);
                        DrawField(xf, cursorY, currentValue, editwidth);
                    }
                }
                case Key.Left:
                {
                    if (fieldvalues.Count > 0)
                    {
                        if (cursorX > xf)
                        {
                            cursorX--;
                            Screen.SetCursor(cursorX, cursorY);
                            DrawField(xf, cursorY, currentValue, editwidth);
                        }
                    }
                }
                case Key.Right:
                {
                    if (fieldvalues.Count > 0)
                    {
                        if (cursorX < xf + currentValue.Length)
                        {
                            cursorX++; 
                            Screen.SetCursor(cursorX, cursorY);
                            DrawField(xf, cursorY, currentValue, editwidth);
                        }
                    }
                }
                case Key.Delete:
                {
                    if (fieldvalues.Count > 0)
                    {
                        if (cursorX < xf + currentValue.Length)
                        {
                            uint fIndex = cursorX-xf+1;
                            if (fIndex == 0) // at the left end
                            {
                                currentValue = currentValue.Substring(1);
                            }
                            else
                            {
                                currentValue = currentValue.Substring(0, fIndex-1) + currentValue.Substring(fIndex);
                            }
                            enabled = validation(currentValue);
                            DrawOK(xOK, yOK, enabled);
                            DrawField(xf, cursorY, currentValue, editwidth);
                            Screen.SetCursor(cursorX, cursorY);
                        }
                    }
                }
                case Key.Backspace:
                {
                    if (fieldvalues.Count > 0)
                    {
                        if (cursorX > xf)
                        {
                            uint fIndex = cursorX-xf;
                            if (fIndex == currentValue.Length) // at the right end
                            {
                                currentValue = currentValue.Substring(0, fIndex-1);
                            }
                            else
                            {
                                currentValue = currentValue.Substring(0, fIndex-1) + currentValue.Substring(fIndex);
                            }
                            enabled = validation(currentValue);
                            DrawOK(xOK, yOK, enabled);
                            cursorX--;
                            DrawField(xf, cursorY, currentValue, editwidth);
                            Screen.SetCursor(cursorX, cursorY);
                        }
                    }
                }
                default:
                {
                    char c = key.ToChar();
                    
                    if (hasEdit)
                    {
                        switch (key)
                        {
                            case Key.ControlV:
                            {
                                // Paste from Clipboard
                                if (HasClipboardText())
                                {
                                    string ctext = GetClipboardText();
                                    bool ok = true;
                                    foreach (var cc in ctext)
                                    {
                                        if (allowed.Length > 0)
                                        {
                                            ok = allowed.Contains(cc);
                                        }
                                        else
                                        {
                                            uint kk = uint(cc);
                                            ok = ((kk > 31) && (kk < 128));
                                        }
                                        if (!ok)
                                        {
                                            break;
                                        }
                                    } // foreach
                                    if (ok)
                                    {
                                        uint index = cursorX - xf;
                                        string before = currentValue.Substring(0, index);
                                        string after  = currentValue.Substring(index);
                                        currentValue = before + ctext + after;
                                        currentValue = currentValue.Substring(0, editwidth);
                                        enabled = validation(currentValue);
                                        DrawOK(xOK, yOK, enabled);
                                        DrawField(xf, cursorY, currentValue, editwidth);
                                        cursorX = cursorX + ctext.Length;
                                        if (cursorX > xf + editwidth)
                                        {
                                            cursorX = xf + editwidth;
                                        }
                                        Screen.SetCursor(cursorX, cursorY);
                                    } // if (ok)
                                } // if (HasClipboardText())
                            } // case Key.ControlV
                            default:
                            {
                                bool isAllowed = allowed.Contains(c);
                                if (allowed.Length == 0)
                                {
                                    uint uk = uint(key);
                                    isAllowed = ((uk > 31) && (uk < 128)); // printable ASCII
                                }
                                if (isAllowed)
                                {
                                    if (currentValue.Length < editwidth)
                                    {
                                        currentValue = currentValue.InsertChar(cursorX - xf, c);
                                        enabled = validation(currentValue);
                                        DrawOK(xOK, yOK, enabled);
                                        DrawField(xf, cursorY, currentValue, editwidth);
                                        cursorX++;
                                        Screen.SetCursor(cursorX, cursorY);
                                    }
                                }
                            } // default
                        } // switch (key)
                    }
                    else // !hasEdit
                    {
                        c = c.ToUpper();
                        switch (c)
                        {
                            case 'Y':
                            {
                                if (buttons.Contains("Yes"))
                                {   
                                    result = "Yes";
                                    break;
                                }
                            } // case 'Y'

                            case 'N':
                            {
                                if (buttons.Contains("No"))
                                {   
                                    result = "No";
                                    break;
                                }
                            } // case 'N'
                        } // switch (c)
                    }
                }
            }
        }
        Editor.Draw(Panel.GetHeight(this));
        
        if (hasEdit)
        {
            Screen.SetCursor(oldX, oldY);
        }
        return result;
    }
    
    bool OnKey(<string, variant> this, Key key)
    {
        return Panel.OnKey(this, key);
    }
    
    Draw(<string, variant> this)
    {
        Suspend();
        Panel.Draw(this);
        
        uint backcolor = Panel.GetBackground(this);
        
        uint x0 = Panel.GetX0(this);
        uint y0 = Panel.GetY0(this);
        uint w = Panel.GetWidth(this);
        uint x = 0;
        uint y = y0;
        for (x = x0; x < x0+w; x++)
        {
            DrawChar(x, y0, ' ', Color.MenuBlue, Color.MenuBlue);
        }
        x = x0+1;
        string message = this["message"];
        string extra = this["extra"];
        string title = this["title"];
        uint editwidth = 0;
        string editWidthText = this["editwidth"];
        if (Token.TryParseUInt(editWidthText, ref editwidth))
        {
        
        }
        <string> buttons = this["buttons"];
        
        
        foreach (var c in title)
        {
            DrawChar(x, y0, c, Color.White, Color.MenuBlue);
            x++;
        }
        x = x0 + 1;
        y = y0 + 2;
        foreach (var c in message)
        {
            DrawChar(x, y, c, Color.Black, backcolor);
            x++;
        }
        <string,string> fieldvalues = this["fields"];
        
        if ((extra.Length > 0) && (fieldvalues.Count == 0))
        {
            y++;
            x = x0 + w - extra.Length - 1;
            foreach (var c in extra)
            {
                DrawChar(x, y, c, Color.Black, backcolor);
                x++;
            }
        }
        bool firstField = true;
        foreach (var field in fieldvalues)
        {
            y++;
            string value = field.value;
            x = x0 + w - editwidth - 1;
            
            // field background area
            for (uint xb = 0; xb < editwidth; xb++)
            {
                DrawChar(x+xb, y, ' ', Color.LightestGray, Color.LightestGray); 
            }
            
            // field value
            DrawField(x, y, value, editwidth);
            if (firstField && (extra.Length > 0))
            {
                y++;
                x = x0 + 1;
                foreach (var c in extra)
                {
                    DrawChar(x, y, c, Color.Black, backcolor);
                    x++;
                }
            }
            firstField = false;
        }
        
        uint bwidth = 0;
        foreach (var button in buttons)
        {
            uint bw = button.Length + 2;
            if (bw < 8)
            {
                bw = 8;
            }
            bwidth = bwidth + bw + 1;
        }
        x = x0 + w - bwidth - 1;
        y = y + 2;
        
        < <uint> > listOfAreas;
        foreach (var button in buttons)
        {
            <uint> area;
            area.Append(x);
            area.Append(y);
            area.Append(uint(8)); // hardcoded button width below
            area.Append(uint(1));
            listOfAreas.Append(area);
            x++;
            if (button == "OK")
            {
                this["ok-x"] = x.ToString();
                this["ok-y"] = y.ToString();
            }
            string buttonText = " " + button + " ";
            while (buttonText.Length < 8)
            {
                buttonText = " " + buttonText;
                if (buttonText.Length < 8)
                {
                    buttonText = buttonText + " ";
                }
            }
            foreach (var c in buttonText)
            {
                DrawChar(x, y, c, Color.Black, Color.Button);
                x++;
            }
        }
        this["buttonareas"] = listOfAreas;
        Resume(true); // interactive
    }
}
