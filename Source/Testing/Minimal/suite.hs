unit Suite
{
    assertArrayEquals(int[] a, int[] b, string message)
    {
        if (a.Count != b.Count)
        {
            PrintFailed(message + " - Failed: Arrays differ in length.");
            return;
        }
        for (uint i = 0; i < a.Count; i++)
        {
            if (a[i] != b[i])
            {
                PrintFailed(message + " - Failed: Elements at index " + i.ToString() + " do not match.");
                return;
            }
        }
    }
    TestArray()
    {
        WriteLn("Array");
        int[5] intArray;
        intArray[0] = -3;
        intArray[1] = 20000;
        intArray[2] = 1;
        
        if (intArray.Count != 5)
        {
            PrintFailed("Array Int: Length failed");
        }
        
        if (intArray[2] != 1)
        {
            PrintFailed("Array Int: [2] = failed");
        }
        if (intArray[0] != -3)
        {
            PrintFailed("Array Int: [0] = failed");
        }
        if (intArray[1] != 20000)
        {
            PrintFailed("Array Int: [1] = failed");
        }

        if (intArray[3] != 0)
        {
            PrintFailed("Array Int: zero initialization failed");
        }
        int count = 0;
        
        foreach (var a in intArray)
        {
            count++;
        }
        if (count != 5)
        {
            PrintFailed("Array Int: foreach failed");
        }
        count = 0;
        
        uint[5] uintArray;
        uintArray[0] = 3;
        uintArray[1] = 40000;
        uintArray[2] = 1;
        if (uintArray.Count != 5)
        {
            PrintFailed("Array UInt: Length failed");
        }
        
        if (uintArray[2] != 1)
        {
            PrintFailed("Array UInt: [2] = failed");
        }
        
        if (uintArray[0] != 3)
        {
            PrintFailed("Array UInt: [0] = failed");
        }
        if (uintArray[1] != 40000)
        {
            PrintFailed("Array UInt: [1] = failed");
        }
        if (uintArray[3] != 0)
        {
            PrintFailed("Array UInt: zero initialization failed");
        }
        count = 0;
        
        foreach (var a in uintArray)
        {
            count++;
        }
        if (count != 5)
        {
            PrintFailed("Array UInt: foreach failed");
        }
        count = 0;
        
        char[5] charArray;
        charArray[0] = char(0);
        charArray[1] = 'a';
        charArray[2] = 'b';
        if (charArray.Count != 5)
        {
            PrintFailed("Array Char: Length failed");
        }
        
        if (charArray[2] != 'b')
        {
            PrintFailed("Array Char: [2] = failed");
        }
        
        if (charArray[0] != char(0))
        {
            PrintFailed("Array Char: [0] = failed");
        }
        if (charArray[1] != 'a')
        {
            PrintFailed("Array Char: [1] = failed");
        }
        if (charArray[3] != char(0))
        {
            PrintFailed("Array Char: zero initialization failed");
        }
        count = 0;
        
        foreach (var a in charArray)
        {
            count++;
        }
        if (count != 5)
        {
            PrintFailed("Array Char: foreach failed");
        }
        count = 0;
        
        bool[10] boolArray;
        boolArray[0] = true;
        boolArray[1] = false;
        boolArray[2] = true;
        boolArray[4] = false;
        boolArray[5] = true;
        boolArray[6] = true;
        boolArray[7] = false;
        boolArray[8] = true;
        boolArray[9] = true;
        if (boolArray.Count != 10)
        {
            PrintFailed("Array Bool: Length failed");
        }
        
        if (boolArray[2] != true)
        {
            PrintFailed("Array Bool: [2] = failed");
        }
        
        if (boolArray[0] != true)
        {
            PrintFailed("Array Bool: [0] = failed");
        }
        if (boolArray[1] != false)
        {
            PrintFailed("Array Bool: [1] = failed");
        }
        if (boolArray[3] != false)
        {
            PrintFailed("Array Bool: zero initialization failed");
        }
        if (boolArray[4] != false)
        {
            PrintFailed("Array Bool: [4] = failed");
        }
        if (boolArray[5] != true)
        {
            PrintFailed("Array Bool: [5] = failed");
        }
        if (boolArray[6] != true)
        {
            PrintFailed("Array Bool: [6] = failed");
        }
        if (boolArray[7] != false)
        {
            PrintFailed("Array Bool: [7] = failed");
        }
        if (boolArray[8] != true)
        {
            PrintFailed("Array Bool: [8] = failed");
        }
        if (boolArray[9] != true)
        {
            PrintFailed("Array Bool: [9] = failed");
        }
        count = 0;
        
        foreach (var a in boolArray)
        {
            if (a)
            {
                count++;
            }
        }
        if (count != 6)
        {
            PrintFailed("Array Bool: foreach failed");
        }
        count = 0;
        
        // Test cases for Array.Slice
        // Test 1: Slice from a specific start index to the end of the array
        int[5] originalArray;
        originalArray[0] = 1;
        originalArray[1] = 2;
        originalArray[2] = 3;
        originalArray[3] = 4;
        originalArray[4] = 5;
        int[3] expectedSlice;
        expectedSlice[0] = 3;
        expectedSlice[1] = 4;
        expectedSlice[2] = 5;
        int[] slicedToEnd = originalArray.Slice(2); // Expected to contain {3, 4, 5}
        assertArrayEquals(slicedToEnd, expectedSlice, "Slice from index 2 to end");
    
        // Test 2: Slice with specific start and length
        expectedSlice[0] = 2;
        expectedSlice[1] = 3;
        expectedSlice[2] = 4;
        
        int[] slicedWithLength = originalArray.Slice(1, 3); // Expected to contain {2, 3, 4}
        assertArrayEquals(slicedWithLength, expectedSlice, "Slice from index 1 with length 3");
    
        // Test 3: Slice with start index equal to array length (should return empty array)
        int[] emptySlice = originalArray.Slice(5); // Expected to be empty
        int[0] expectedEmpty;
        assertArrayEquals(emptySlice, expectedEmpty, "Slice with start index equal to array length");
    
        // Test 4: Slice with length zero (should return empty array regardless of start)
        int[] zeroLengthSlice = originalArray.Slice(3, 0); // Expected to be empty
        assertArrayEquals(zeroLengthSlice, expectedEmpty, "Slice with zero length");
    }
    
    TestDictionary()
    {
        WriteLn("Dictionary");
        
        <char,string> charDictionary;
        charDictionary.Set('a', "a value");
        charDictionary.Set('b', "b value");
        charDictionary.Set('c', "c value");
        if (charDictionary.Count != 3)
        {
            PrintFailed("Dictionary Char: Set failed");
        }
        if (!charDictionary.Contains('a'))
        {
            PrintFailed("Dictionary Char: Contains failed 1");
        }
        if (charDictionary.Contains('d'))
        {
            PrintFailed("Dictionary Char: Contains failed 2");
        }
        string result = charDictionary.Get('b');
        if (result != "b value")
        {
            PrintFailed("Dictionary Char: Get failed");
        }
        charDictionary.Set('c', "new c value");
        result = charDictionary.Get('c');
        if (result != "new c value")
        {
            PrintFailed("Dictionary Char: Set replace failed");
        }
        
        <uint,string> uintDictionary;
        uintDictionary.Set(0, "a value");
        uintDictionary.Set(1, "b value");
        uintDictionary.Set(2, "c value");
        if (uintDictionary.Count != 3)
        {
            PrintFailed("Dictionary UInt: Set failed");
        }
        if (!uintDictionary.Contains(0))
        {
            PrintFailed("Dictionary UInt: Contains failed 1");
        }
        if (uintDictionary.Contains(3))
        {
            PrintFailed("Dictionary UInt: Contains failed 2");
        }
        result = uintDictionary.Get(1);
        if (result != "b value")
        {
            PrintFailed("Dictionary UInt: Get failed");
        }
        uintDictionary.Set(2, "new c value");
        result = uintDictionary.Get(2);
        if (result != "new c value")
        {
            PrintFailed("Dictionary UInt: Set replace failed");
        }
        
        <string,string> stringDictionary;
        stringDictionary.Set("a", "a value");
        stringDictionary.Set("b", "b value");
        stringDictionary.Set("c", "c value");
        if (stringDictionary.Count != 3)
        {
            PrintFailed("Dictionary String: Set failed");
        }
        if (!stringDictionary.Contains("a"))
        {
            PrintFailed("Dictionary String: Contains failed 1");
        }
        if (stringDictionary.Contains("d"))
        {
            PrintFailed("Dictionary String: Contains failed 2");
        }
        result = stringDictionary.Get("b");
        if (result != "b value")
        {
            PrintFailed("Dictionary String: Get failed");
        }
        stringDictionary.Set("c", "new c value");
        result = stringDictionary.Get("c");
        if (result != "new c value")
        {
            PrintFailed("Dictionary String: Set replace failed");
        }
        
        stringDictionary["d"] = "d value";
        stringDictionary["e"] = "e value";
        stringDictionary["f"] = "f value";
        if (stringDictionary.Count != 6)
        {
            PrintFailed("Dictionary String: [] failed");
        }
        result = stringDictionary.Get("e");
        if (result != "e value")
        {
            PrintFailed("Dictionary String: [] failed");
        }
        
        int count = 0;
        foreach (var kv in stringDictionary)
        {
            count++;
        }
        if (count != 6)
        {
            PrintFailed("Dictionary String: foreach failed");
        }
        
        stringDictionary.Clear();
        if (stringDictionary.Count != 0)
        {
            PrintFailed("Dictionary String: Clear failed");
        }
      }
      TestValueDictionary()
      {
        WriteLn("Value Dict");  
        <uint, string> names;
        names[0] = "Zero";
        names[1] = "One";
        names[2] = "Two";
        names[3] = "Three";
        names[4] = "Four";
        uint length = 0;
        foreach (var nv in names)
        {
            uint key = nv.key;
            string name = nv.value;
            length = length + name.Length;
        }
        if (length != 19)
        {
            PrintFailed("Dictionary : <uint, string> foreach failed");
        }
        if (!names.Contains(4))
        {
            PrintFailed("Dictionary : <uint, string> !Contains failed");
        }
        if (names.Contains(5))
        {
            PrintFailed("Dictionary : <uint, string> Contains failed");
        }
        names.Set(2, "Twee");
        if (names[2] != "Twee")
        {
            PrintFailed("Dictionary : <uint, string> Set failed");
        }
    }
    TestDictionaryExpandVV()
    {
        WriteLn("Dict Expand: VV");
        <uint,uint> expandValueValue;
        for (uint i = 0; i < 65; i++)
        {
            expandValueValue[i] = i;
        }
        uint totalk = 0;
        uint totalv = 0;
        uint count = 0;
        foreach (var kv in expandValueValue)
        {
            totalk = totalk + kv.key;
            totalv = totalv + kv.value;
            count++;    
        }
        if (count != 65)
        {
            PrintFailed("expandValueValue failed 1");
        }
        if (totalk != 2080)
        {
            PrintFailed("expandValueValue failed 2");
        }
        if (totalv != 2080)
        {
            PrintFailed("expandValueValue failed 3");
        }
   	}
    TestDictionaryExpandRV()
    {
        WriteLn("Dict Expand: RV");
        uint totalk = 0;
        uint totalv = 0;
        uint count = 0;
        <string,uint> expandReferenceValue;
        for (uint i = 0; i < 65; i++)
        {
            expandReferenceValue[i.ToString()] = i;
        }
        foreach (var kv in expandReferenceValue)
        {
            uint k;
            if (UInt.TryParse(kv.key, ref k))
            {
                totalk = totalk + k;
            }
            totalv = totalv + kv.value;
            count++;    
        }
        if (count != 65)
        {
            PrintFailed("expandReferenceValue failed 1");
        }
        if (totalk != 2080)
        {
            PrintFailed("expandReferenceValue failed 2");
        }
        if (totalv != 2080)
        {
            PrintFailed("expandReferenceValue failed 3");
        }
    }   
   	TestDictionaryExpandVR()
   	{
        WriteLn("Dict Expand: VR");
        uint totalk = 0;
        uint totalv = 0;
        uint count = 0;
        <uint,string> expandValueReference;
        for (uint i = 0; i < 65; i++)
        {
            expandValueReference[i] = i.ToString();
        }
        foreach (var kv in expandValueReference)
        {
            totalk = totalk + kv.key;
            uint v;
            if (UInt.TryParse(kv.value, ref v))
            {
                totalv = totalv + v;
            }
            count++;    
        }
        if (count != 65)
        {
            PrintFailed("expandValueReference failed 1");
        }
        if (totalk != 2080)
        {
            PrintFailed("expandValueReference failed 2");
        }
        if (totalv != 2080)
        {
            PrintFailed("expandValueReference failed 3");
        }
    }
    TestDictionaryExpandRR()
   	{    
        WriteLn("Dict Expand: RR");
        uint totalk = 0;
        uint totalv = 0;
        uint count = 0;
        <string,string> expandReferenceReference;
        for (uint i = 0; i < 65; i++)
        {
            expandReferenceReference[i.ToString()] = i.ToString();
        }
        foreach (var kv in expandReferenceReference)
        {
            uint k;
            uint v;
            if (UInt.TryParse(kv.key, ref k))
            {
                totalk = totalk + k;
            }
            if (UInt.TryParse(kv.value, ref v))
            {
                totalv = totalv + v;
            }
            count++;    
        }
        if (count != 65)
        {
            PrintFailed("expandReferenceReference failed 1");
        }
        if (totalk != 2080)
        {
            PrintFailed("expandReferenceReference failed 2");
        }
        if (totalv != 2080)
        {
            PrintFailed("expandReferenceReference failed 3");
        }
    }
   	TestDictionaryOfLists()
   	{
    	   WriteLn("Dict of Lists");
        
        <string> list0;
        list0.Append("one");
        list0.Append("two");
        list0.Append("three");
        
        <string> list2;
        list2.Append("four");
        list2.Append("five");
        list2.Append("six");
       
        <string,<string> > dictionaryOfLists;
        
        dictionaryOfLists["key"] = list0;
        dictionaryOfLists["key2"] = list2;
        
        int count = 0;
        foreach (var kv in dictionaryOfLists)
        {
            string key = kv.key;
            foreach (var s in kv.value)
            {
                count++;
            }
        }
        if (dictionaryOfLists.Contains("key"))
        {
            <string> value = dictionaryOfLists.Get("key");
            foreach (var s in value)
            {
                count++;
            }
        }
        if (count != 9)
        {
            PrintFailed("Dictionary : <string, <string>> failed");
        }
		
		      count = 0;
        < string, <string> > dictionaryOfLists2;
        dictionaryOfLists2["one"] = list0;
        dictionaryOfLists2["two"] = list2;
         
        foreach (var kv4 in dictionaryOfLists2)
        {
            string k = kv4.key;
            foreach (var v2 in kv4.value)
            {
                count = count + 1;
            }
        }
        if (count != 6)
        {
            PrintFailed("Dictionary : <string, <string> > foreach failed");
        }
        if (!dictionaryOfLists2.Contains("two"))
        {
            PrintFailed("Dictionary : <string, <string> > !Contains failed");
        }
        if (dictionaryOfLists2.Contains("three"))
        {
            PrintFailed("Dictionary : <string, <string> > Contains failed");
        }
    }
    TestDictionaryOfDictionaries()
   	{
    	WriteLn("Dict of Dict");
        
        <string,int> dictionary0;
        dictionary0["One"] = 1;
        dictionary0["Two"] = 2;
        dictionary0["Three" ] = 3;
        
        <string,int> dictionary2;
        dictionary2["Four"] = 4;
        dictionary2["Five"] = 5;
        dictionary2["Six"] = 6;
		dictionary2["Seven"] = 7;
       
        < string, <string,int> > dictionaryOfDictionaries;
        dictionaryOfDictionaries["dict1"] = dictionary0;
        dictionaryOfDictionaries["dict2"] = dictionary2;
        
        int count = 0;
        <string,int> dictionary3 = dictionaryOfDictionaries.Get("dict1");
        foreach (var kv in dictionary3)
        {
            count = count +  kv.value;
        }
        if (count != 6)
        {
            PrintFailed("Dictionary : <string, <string, int> > failed 1");
        }
        
        count = 0;
        < string, <string,int> > dictionaryOfDictionaries2;
        dictionaryOfDictionaries2["one"] = dictionary0;
        dictionaryOfDictionaries2["two"] = dictionary2;
         
        foreach (var kv in dictionaryOfDictionaries2)
        {
            string k = kv.key;
            foreach (var kv2 in kv.value)
            {
                string k2 = kv2.key;
                int v2 = kv2.value;
                count = count + v2;
            }
        }
        if (count != 28)
        {
            PrintFailed("Dictionary : <string, <string, int> > failed 2");
        }
        
        
    }
    
    TestList32()
    {
        WriteLn("List 32");
        <float> floatList;
        floatList.Append(0);
        floatList.Append(20);     // byte
        floatList.Append(-10);    // int
        floatList.Append(40000);  // uint
        floatList.Append(100000); // long
        floatList.Append(1.5);
        floatList.Append(2.5);
        floatList.Append(3.5);
        floatList.Append(4.5);
        
        float total;
        foreach (var f in floatList)
        {
            total += f;
        }
        
        if (total != 140022.0)
        {
            PrintFailed("List 32: float failed");
        }
        
        <long> longList;
        longList.Append(0);
        longList.Append(20);     // byte
        longList.Append(-10);    // int
        longList.Append(40000); // uint
        longList.Append(100000);
        longList.Append(-40000);
        longList.Append(80000);
        longList.Append(-80000);
        
        long ltotal;
        foreach (var l in longList)
        {
            ltotal += l;
        }
        if (ltotal != 100010)
        {
            PrintFailed("List 32: long failed");
        }
    }
    TestDictionary32()
    {
        WriteLn("Dictionary 32");
        <byte,float> floatDictionary;
        floatDictionary[0] = 0;
        floatDictionary[1] = 20;
        floatDictionary[2] = -10; // int
        floatDictionary[3] = 40000; // int
        floatDictionary[4] = 100000; // long
        floatDictionary[5] = 1.5;
        floatDictionary[6] = 2.5;
        floatDictionary[7] = 3.5;
        floatDictionary[8] = 4.5;
        
        float total;
        foreach (var f in floatDictionary)
        {
            total += f.value;
        }
        
        if (total != 140022.0)
        {
            PrintFailed("Dictionary 32: float failed");
        }
        
        <byte,long> longDictionary;
        longDictionary[0] = 0;
        longDictionary[1] = 20;  // byte
        longDictionary[2] = -10; // int
        longDictionary[3] = 100000;
        longDictionary[4] = 40000; // uint
        longDictionary[5] = -40000;
        longDictionary[6] = 80000;
        longDictionary[7] = -80000;
        
        long ltotal;
        foreach (var l in longDictionary)
        {
            ltotal += l.value;
        }
        if (ltotal != 100010)
        {
            PrintFailed("Dictionary 32: long failed");
        }
    }

    TestList()
    {
        WriteLn("List");
        <string> stringList;
        stringList.Append("item 1");
        stringList.Append("item 2");
        stringList.Append("item 3");
        
        if (stringList.Count != 3)
        {
            PrintFailed("List String: Length failed");
        }
        int i = 0;
        foreach (var item in stringList)
        {
            i++;
        }
        if (i != 3)
        {
            PrintFailed("List String: foreach failed");
        }
        string result = stringList.GetItem(1);
        if (result != "item 2")
        {
            PrintFailed("List String: GetItem failed");
        }
        stringList.SetItem(1, "new item");
        result = stringList.GetItem(1);
        if (result != "new item")
        {
            PrintFailed("List String: SetItem failed");
        }
        
        stringList.Clear();
        if (stringList.Count != 0)
        {
            PrintFailed("List String: Clear failed");
        }
        
        <bool> boolList;
        boolList.Append(true);
        boolList.Append(false);
        boolList.Append(false);
        
        if (boolList.Count != 3)
        {
            PrintFailed("List Boolean: Length failed");
        }
        i = 0;
        foreach (var item in boolList)
        {
            i++;
        }
        if (i != 3)
        {
            PrintFailed("List Boolean: foreach failed");
        }
        
        bool bresult = boolList.GetItem(0);
        if (bresult != true)
        {
            PrintFailed("List Boolean: GetItem failed");
        }
        bresult = boolList.GetItem(1);
        if (bresult != false)
        {
            PrintFailed("List Boolean: GetItem failed");
        }
        bresult = boolList.GetItem(2);
        if (bresult != false)
        {
            PrintFailed("List Boolean: GetItem failed");
        }
        boolList.SetItem(1, true);
        bresult = boolList.GetItem(1);
        if (bresult != true)
        {
            PrintFailed("List Boolean: SetItem failed");
        }
        
        boolList.Clear();
        if (boolList.Count != 0)
        {
            PrintFailed("List Boolean: Clear failed");
        }
        
        <string> plainlist;
        plainlist.Append("one");
        plainlist.Append("two");
        plainlist.Append("three");
        
        < <string> > listOfLists;
        < < <string> > > listOfListsOfLists;

        listOfLists.Append(plainlist);
        
        listOfListsOfLists.Append(listOfLists);
        
        <string> item = listOfLists.GetItem(0);
        string value = item.GetItem(1);
        if (value != "two")
        {
            PrintFailed("List : < < string > > GetItem failed");
        }
        uint count = listOfLists.Count;
        if (count != 1)
        {
            PrintFailed("List : < < string > > Length failed");
        }
        
        < <string> > lOL = listOfListsOfLists.GetItem(0);
        <string> lOS = lOL.GetItem(0);
        value = lOS.GetItem(0);
        if (value != "one")
        {
            PrintFailed("List : < < < string > > > GetItem failed");
        }
                
        listOfLists.Clear();
        count = listOfLists.Count;
        if (count != 0)
        {
            PrintFailed("List : < < string > > Clear failed");
        }


        
        plainlist.Remove(1);
        if (plainlist.Count != 2)
        {
            PrintFailed("List : Remove failed 1");
        }
        
        plainlist.Remove(0);
        if (plainlist.Count != 1)
        {
            PrintFailed("List : Remove failed 2");
        }

        plainlist.Remove(0);
        if (plainlist.Count != 0)
        {
            PrintFailed("List : Remove failed 3");
        }
        plainlist.Insert(0, "aaa");
        if (plainlist[0] != "aaa")
        {
            PrintFailed("List : Insert failed 1");
        }
        plainlist.Insert(1, "end");
        if (plainlist[1] != "end")
        {
            PrintFailed("List : Insert failed 2");
        }
        plainlist.Insert(1, "bbb");
        if (plainlist[1] != "bbb")
        {
            PrintFailed("List : Insert failed 3");
        }
        long key = 0xAABBCCDD;
        <byte> bytes;
        bytes.Append(key.GetByte(0));
        bytes.Append(key.GetByte(1));
        bytes.Append(key.GetByte(2));
        bytes.Append(key.GetByte(3));
        string bstr;
        foreach (var b in bytes)
        {
            string bs = b.ToHexString(2);
            bstr = bstr + bs;
        }
        if (bstr != "DDCCBBAA")
        {
            PrintFailed("List : long.GetByte failed");
        }
    }
  	 TestListOfDictionaries()
	   {
	       WriteLn("List of Dict");

        <string> plainlist;
        plainlist.Append("one");
        plainlist.Append("two");
        plainlist.Append("three");
        
        <string,int> dictionary0;
        dictionary0["one"] = 1;
        dictionary0["two"] = 2;
        dictionary0["three" ] =3;
        
        <string,int> dictionary2;
        dictionary2["four"] = 4;
        dictionary2["five"] = 5;
        dictionary2["six"] = 6;
       
        < <string,int> > listOfDictionaries;
        listOfDictionaries.Append(dictionary0);
        listOfDictionaries.Append(dictionary2);
        
        int total = 0;
        foreach (var dict in listOfDictionaries)
        {
            foreach (var kv in dict)
            {
                total = total + kv.value;
            }
        }
        if (total != 21)
        {
            PrintFailed("List : < <string, int> > failed 3");
        }
        
        uint count = 0;
        < <string> > listOfLists2;
        listOfLists2.Append(plainlist);
        listOfLists2.Append(plainlist);
        foreach (var list2 in listOfLists2)
        {
            foreach (var v3 in list2)
            {
                string vs = v3;
                count = count + 1;
            }
        }
        if (count != 6)
        {
            PrintFailed("List : < <string> > failed");
        }
        
        total = 0;
        <string, int> dictionary4;
        dictionary4["one"] = 1;
        dictionary4["two"] = 2;
        dictionary4["three"] = 3;
        < <string,int> > listOfDictionaries2;
        listOfDictionaries2.Append(dictionary4);
        listOfDictionaries2.Append(dictionary4);
        foreach (var v5 in listOfDictionaries2)
        {
            foreach (var kv5 in v5)
            {
                string k = kv5.key;
                int v6 = kv5.value;
                total = total + v6;
            }
        }
        if (total != 12)
        {
            PrintFailed("List : < <string, int> > failed 4");
        }
   	}

    bool TrueCounter(ref int count)
    {
        count = count + 1;
        return true;
    }
    bool FalseCounter(ref int count)
    {
        count = count + 1;
        return false;
    }
    
    TestBooleanShortCircuit()
    {
        WriteLn("Short circuit");
        
        int trueCount = 0;
        int falseCount = 0;
        if (!(FalseCounter(ref falseCount) || TrueCounter(ref trueCount)))
        {
            PrintFailed("'false || true' failed 1");
        }
        if (trueCount != 1)
        {
            PrintFailed("'false || true' failed 2");
        }
        if (falseCount != 1)
        {
            PrintFailed("'false || true' failed 3");
        }
                
        trueCount = 0;
        falseCount = 0;
        if (!(TrueCounter(ref trueCount) || FalseCounter(ref falseCount)))
        {
            PrintFailed("'true || false' failed");
        }
        if (trueCount != 1)
        {
            PrintFailed("'true || false' failed");
        }
        if (falseCount != 0)
        {
            PrintFailed("'true || false' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (!(TrueCounter(ref trueCount) || TrueCounter(ref trueCount) || TrueCounter(ref trueCount)))
        {
            PrintFailed("'true || true || true' failed");
        }
        if (trueCount != 1)
        {
            PrintFailed("'true || true || true' failed");
        }
        
        falseCount = 0;
        if (FalseCounter(ref falseCount) || FalseCounter(ref falseCount))
        {
            PrintFailed("'false || false' failed");
        }
        if (falseCount != 2)
        {
            PrintFailed("'false || false' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (!(FalseCounter(ref falseCount) || FalseCounter(ref falseCount) || TrueCounter(ref trueCount)))
        {
            PrintFailed("'false || false || true' failed");
        }
        if (trueCount != 1)
        {
            PrintFailed("'false || false || true' failed");
        }
        if (falseCount != 2)
        {
            PrintFailed("'false || false || true' failed");
        }
        
        
        trueCount = 0;
        falseCount = 0;
        if (FalseCounter(ref falseCount) && TrueCounter(ref trueCount))
        {
            PrintFailed("'false && true' failed");
        }
        if (trueCount != 0)
        {
            PrintFailed("'false && true' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'false && true' failed");
        }
                
        trueCount = 0;
        falseCount = 0;
        if (TrueCounter(ref trueCount) && FalseCounter(ref falseCount))
        {
            PrintFailed("'true && false' failed");
        }
        if (trueCount != 1)
        {
            PrintFailed("'true && false' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'true && false' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (!(TrueCounter(ref trueCount) && TrueCounter(ref trueCount) && TrueCounter(ref trueCount)))
        {
            PrintFailed("'true && true && true' failed");
        }
        if (trueCount != 3)
        {
            PrintFailed("'true && true && true' failed");
        }
        
        falseCount = 0;
        if (FalseCounter(ref falseCount) && FalseCounter(ref falseCount))
        {
            PrintFailed("'false && false' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'false && false' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (FalseCounter(ref falseCount) && FalseCounter(ref falseCount) && TrueCounter(ref trueCount))
        {
            PrintFailed("'false && false && true' failed");
        }
        if (trueCount != 0)
        {
            PrintFailed("'false && false && true' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'false && false && true' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (TrueCounter(ref trueCount) && FalseCounter(ref falseCount) && FalseCounter(ref falseCount))
        {
            PrintFailed("'true && false && false' failed");
        }
        if (trueCount != 1)
        {
            PrintFailed("'true && false && false' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'true && false && false' failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        if (TrueCounter(ref trueCount) && TrueCounter(ref trueCount) && FalseCounter(ref falseCount))
        {
            PrintFailed("'true && true && false' failed");
        }
        if (trueCount != 2)
        {
            PrintFailed("'true && true && false' failed");
        }
        if (falseCount != 1)
        {
            PrintFailed("'true && true && false' failed");
        }
    }

    uint gindex = 0;
    TestRef()
    {
        WriteLn("'ref' arguments");
        string test = "Test String";
        
        if (!test.IndexOf("String", 4, ref gindex))
        {
            PrintFailed("IndexOf ref of ref of global failed A");
        }
        if (gindex != 5)
        {
            PrintFailed("IndexOf ref of ref of global failed B");
        }
        
        uint hex = 0;
        string word = "0x002A";
        if (UInt.TryParse(word, ref hex))
        {
        }
        if (hex != 42)
        {
            PrintFailed("TryParse ref failed (hex value type)");
        }
        long l = 0;
        word = "100000";
        if (Long.TryParse(word, ref l))
        {
        }
        if (l != 100000)
        {
            PrintFailed("Long.TryParse ref failed (reference type)");
        }
        
        
        uint index = 0;
        if (!test.IndexOf("String", 4, ref index))
        {
            PrintFailed("IndexOf ref of ref of local failed");
        }
        if (index != 5)
        {
            PrintFailed("IndexOf ref of ref of local failed");
        }
        
        
    }
    
    TestSwitch()
    {
        WriteLn("'switch'");
        
        int count = 0;
        char check = 'A';
        switch (check)
        {
            case 'A':
            {
                int inc = 1;
                count = count + inc;
            }
            case 'B':
            {
                int inc = 2;
                count = count + inc;
            }
            default:
            {
                int inc = 4;
                count = count + inc;
            }
        }
        if (count != 1)
        {
            PrintFailed("'switch' 1 failed");
        }
        count = 0;
        check = 'B';
        switch (check)
        {
            case 'A':
            {
                int inc = 1;
                count = count + inc;
            }
            case 'B':
            {
                int inc = 2;
                count = count + inc;
            }
            default:
            {
                int inc = 4;
                count = count + inc;
            }
        }
        if (count != 2)
        {
            PrintFailed("'switch' 2 failed");
        }
        count = 0;
        check = 'C';
        switch (check)
        {
            case 'A':
            {
                int inc = 1;
                count = count + inc;
            }
            case 'B':
            {
                int inc = 2;
                count = count + inc;
            }
            default:
            {
                int inc = 4;
                count = count + inc;
            }
        }
        if (count != 4)
        {
            PrintFailed("'switch' 3 failed");
        }
        loop
        {
            count = 0;
            check = 'B';
            switch (check)
            {
                case 'A':
                {
                    int inc = 1;
                    count = count + inc;
                }
                case 'B':
                {
                    int inc = 2;
                    break;
                    count = count + inc;
                }
                default:
                {
                    int inc = 4;
                    count = count + inc;
                }
            }
        }
        if (count != 0)
        {
            PrintFailed("'switch' 4 failed");
        }
    }
    TestWhile()
    {
        WriteLn("'while'");
        
        int trueCount = 0;
        int falseCount = 0;
        int count = 0;
        while ((falseCount < 10) && !(FalseCounter(ref falseCount)))
        {
            count++;
        }
        if ((falseCount != 11) && (count != 10))
        {
            PrintFailed("'while' 1 failed");
        }
        count = 0;
        while ((trueCount < 10) && TrueCounter(ref trueCount))
        {
            count++;
        }
        if ((trueCount != 11) && (count != 10))
        {
            PrintFailed("'while' 2 failed");
        }
        
        trueCount = 0;
        falseCount = 0;
        uint total = 0;
        while (TrueCounter(ref trueCount) && (trueCount <= 10))
        {
            falseCount = 0;
            while (!(FalseCounter(ref falseCount)) && (falseCount <= 10))
            {
                total++;
            }
        }
        if ((trueCount != 11) || (falseCount != 11)  || (total != 100))
        {
            PrintFailed("'while' 3 failed");
        }
    } // TestWhile
    
    TestVariantDictionary()
    {
        WriteLn("<string,variant>");    
        
        <string, variant> dict;
        
        string ss = "string";
        dict["string"] = "string";
        dict["true"] = true;
        dict["false"] = false;
        dict["uint"] = uint(10);
        long ll = 42424242;
        dict["long"] = ll;
        float fl = 3.141;
        dict["float"] = fl;
        
        <string> slist;
        slist.Append("string");
        dict["slist"] = slist;
        
        uint count = 0;
        foreach (var kv in dict)
        {
            switch (kv.key)
            {
                case "string":
                {
                    string s = kv.value;
                    if (s == "string")
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 1");
                    }
                }
                case "slist":
                {
                    <string> sl = kv.value;
                    string v = sl[0];
                    if (v == "string")
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 2");
                    }
                }
                case "long":
                {
                    long l = long(kv.value);
                    if (l == 42424242)
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 3");
                    }
                }
                case "uint":
                {
                    uint u = uint(kv.value);
                    if (u == 10)
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 4");
                    }
                }
                case "true":
                {
                    bool b = bool(kv.value);
                    if (b)
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 5");
                    }
                }
                case "false":
                {
                    bool b = bool(kv.value);
                    if (!b)
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 6");
                    }
                }
                case "float":
                {
                    float l = float(kv.value);
                    if (l == 3.141)
                    {
                        count++;
                    }
                    else
                    {
                        PrintFailed("<string,variant> 8");
                    }
                }
                default:
                {
                    PrintFailed("<string,variant> 7");
                }
            }
        }
        if (count != 7)
        {
            PrintFailed("<string,variant> 9");
        }
        
    } // TestVariantDictionary
    
    TestForEach()
    {
        WriteLn("'foreach'");    
        
        <string> lst;
        lst.Append("one");
        lst.Append("two");
        lst.Append("three");
        lst.Append("four");
        lst.Append("five");
        
        uint count = 0;
        foreach (var s in lst)
        {
            if (s == "two")
            {
                continue;
            }
            count++;
            if (s == "four")
            {
                break;
            }
        }
        if (count != 3)
        {
            PrintFailed("'foreach' 1");
        }
        
        count = 0;
        string ss = "abcde";
        foreach (var s in ss)
        {
            if (s == 'b')
            {
                continue;
            }
            count++;
            if (s == 'd')
            {
                break;
            }
        }
        if (count != 3)
        {
            PrintFailed("'foreach' 2");
        }
        
        count = 0;
        char[5] arr;
        arr[0] = 'a';
        arr[1] = 'b';
        arr[2] = 'c';
        arr[3] = 'd';
        arr[4] = 'e';
        
        foreach (var s in arr)
        {
            if (s == 'b')
            {
                continue;
            }
            count++;
            if (s == 'd')
            {
                break;
            }
        }
        if (count != 3)
        {
            PrintFailed("'foreach' 3");
        }

#ifdef DICTIONARIES
        count = 0;
        <uint,char> dict;
        dict[0] = 'a';
        dict[1] = 'b';
        dict[2] = 'c';
        dict[3] = 'd';
        dict[4] = 'e';

        uint breaks = 0;        
        uint continues = 0;
        foreach (var s in dict)
        {
            if (s.value == 'b')
            {
                continues++;
                continue;
            }
            count++;
            if (s.value == 'd')
            {
                breaks++;
                break;
            }
        }
        if ((count == 0) || (count == 5) || (continues > 1) || (breaks != 1))
        {
            PrintFailed("'foreach' 4");
        }
        
        breaks = 0;        
        continues = 0;
        count = 0;
        foreach (var s in dict)
        {
            if (s.key == 0)
            {
                continues++;
                continue;
            }
            count++;
            if (s.key == 3)
            {
                breaks++;
                break;
            }
        }
        if ((count == 0) || (count == 5) || (continues > 1) || (breaks != 1))
        {
            PrintFailed("'foreach' 5");
        }
        
        <string,char> dict2;
        dict2["0"] = 'a';
        dict2["1"] = 'b';
        dict2["2"] = 'c';
        dict2["3"] = 'd';
        dict2["4"] = 'e';
        
        count = 0;
        breaks = 0;        
        continues = 0;
        foreach (var s in dict2)
        {
            if (s.value == 'b')
            {
                continues++;
                continue;
            }
            count++;
            if (s.value == 'd')
            {
                breaks++;
                break;
            }
        }
        if ((count == 0) || (count == 5) || (continues > 1) || (breaks != 1))
        {
            PrintFailed("'foreach' 6");
        }
        
        breaks = 0;        
        continues = 0;
        count = 0;
        foreach (var s in dict2)
        {
            if (s.key == "0")
            {
                continues++;
                continue;
            }
            count++;
            if (s.key == "3")
            {
                breaks++;
                break;
            }
        }
        if ((count == 0) || (count == 5) || (continues > 1) || (breaks != 1))
        {
            PrintFailed("'foreach' 7");
        }
#endif
    } //TestForEach()
    
    TestFor()
    {
        WriteLn("'for'"); 
        
        <string> lst;
        lst.Append("one");
        lst.Append("two");
        lst.Append("three");
        lst.Append("four");
        lst.Append("five");
        
        uint count = 0;
        for (uint i = 0; i < 5; i++)
        {
            if (lst[i] == "two")
            {
                continue;
            }
            count++;
            if (lst[i] == "four")
            {
                break;
            }
        }
        if (count != 3)
        {
            PrintFailed("'for' 1");
        }
        
        uint i2 = 0;
        count = 0;
        bool bob; // old compiler cannot deal with empty statement
        for ( bob = true ; i2 < 5; i2++)
        {
            if (lst[i2] == "two")
            {
                continue;
            }
            count++;
            if (lst[i2] == "four")
            {
                break;
            }
        }
        if (count != 3)
        {
            PrintFailed("'for' 2");
        }
        
    } // TestFor
    
    Tests()
    {
        WriteLn();
        TestArray();
        
        
        TestSwitch();
        
        TestRef();
        TestBooleanShortCircuit();
        TestWhile();
        
        TestList();
        
        TestList32();
        
        TestFor();
        
#ifdef DICTIONARIES
        TestDictionary32();
        TestVariantDictionary(); // Variant.Box
        TestDictionaryExpandRR();
        TestDictionaryExpandVV();
        TestDictionaryExpandRV();
        TestDictionaryExpandVR();
        TestValueDictionary();
        TestDictionary();       
        TestDictionaryOfLists();
        TestListOfDictionaries();
        TestDictionaryOfDictionaries();
#endif                   
        TestForEach();
                              
        WriteLn();
        WriteLn("    Arrays and Lists Passed");   
    }
}

