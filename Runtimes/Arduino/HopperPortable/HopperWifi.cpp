#include "HopperWifi.h"


#ifdef USEWIFISTUBS
Bool External_WiFiConnect(UInt hrssid, UInt hrpassword)
{
    return false;
}
void External_WiFiDisconnect()
{
}
Bool External_WebClientGetRequest_R(UInt hrurl, UInt& hrcontent)
{
    return false;
}
UInt External_WiFiIP()
{
    return HRString_New();    
}
UInt External_WiFiStatus()
{
    return 255; // WL_NO_SHIELD;
}
#endif

#ifdef USEWIFI
String ssid;
String password;
bool wifiConnected = false;

Bool IsWiFiConnected() { return wifiConnected; }

WiFiClient wifiClient;

UInt External_WiFiStatus()
{
    Byte status = WiFi.status();
    switch (status)
    {
      case WL_NO_SHIELD:
          status = 255;
          break;
      case WL_IDLE_STATUS:
          status = 0;
          break;
      case WL_CONNECTED:
          status = 1;
          break;
      case WL_CONNECT_FAILED:
          status = 2;
          break;
      case WL_CONNECTION_LOST:
          status = 3;
          break;
      case WL_DISCONNECTED:
          status = 4;
          break;
      case WL_AP_LISTENING:
          status = 5;
          break;
      case WL_AP_CONNECTED:
          status = 6;
          break;
      case WL_AP_FAILED:
          status = 7;
          break;
    }
    return status;
}

void External_WiFiDisconnect()
{
    if (wifiConnected)
    {
        WiFi.disconnect();
        wifiConnected = false;
    }
}


#if defined(RP2040PICOW) || defined(RP2350PICO2W)
bool WifiConnect()
{
    bool success = false;

    int status = WL_IDLE_STATUS;
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), password.c_str());
    for (int count = 0; count < 5; count++)
    {
        status = WiFi.status();
        if (status == WL_CONNECTED)
        {
#ifdef DIAGNOSTICS
            Serial.println();
            Serial.println("WiFi connected");
#endif
            success = true;
            break;
        }
        Serial.print("x");
        delay(1500);
    }
    return success;
}

#endif

#ifdef ARDUINONANO_RP2040
bool WifiConnect()
{
    bool success = false;

    int status = WL_IDLE_STATUS;
    for (int count = 0; count < 5; count++)
    {
        status = WiFi.begin(ssid.c_str(), password.c_str());
        if (status == WL_CONNECTED)
        {
#ifdef DIAGNOSTICS
            Serial.println();
            Serial.println("WiFi connected");
#endif
            success = true;
            break;
        }
        Serial.print("x");
        delay(500);
    } 
    return success;
}
#endif // ARDUINONANO_RP2040

#ifdef USESWIFIESPAT
bool WifiConnect()
{
    bool success = false;

    for (;;)
    {
        ESP_SERIAL_PORT.begin(115200);
        if (!Challenger2040WiFi.reset())
        {
            Serial.println(F("Could not reset WiFi chip !"));
            break;
        }
        
        //WiFi.init(Serial2);
        WiFi.init(ESP_SERIAL_PORT);
        

        if (WiFi.status() == WL_NO_MODULE) 
        {
            Serial.println("Communication with WiFi module failed!");
            break;
        }

        WiFi.begin(ssid.c_str(), password.c_str());

        int status = WL_IDLE_STATUS;
        for (int count = 0; count < 10; count++)
        {
            status = WiFi.status();
            if (status == WL_CONNECTED)
            {
#ifdef DIAGNOSTICS
                Serial.println();
                Serial.println("WiFi connected");
#endif
                success = true;
                break;
            }
            Serial.print("x");
            delay(1000);
        } 
        break;
    }
    return success;
}
#endif // CHALLENGER_RP2040_WIFI



bool WebClient_GetRequest(UInt hrurl, UInt& hrcontent)
{
    UInt length = HRString_GetLength(hrurl);
    String host;
    String url;
    bool dotSeen = false;
    UInt i;
    for (i=0; i < length; i++)
    {
        Char ch = HRString_GetChar(hrurl, i);
        if (dotSeen && (ch == '/')) // first '/' after '.' seen
        {
            break;
        }
        host += (char)ch;
        if (ch == '.')
        {
           dotSeen = true;
        }
    }
    for (; i < length; i++)
    {
        url += (char)HRString_GetChar(hrurl, i);
    }
    if (url.length() == 0)
    {
        url = "/";
    }

    if (wifiClient.connect(host.c_str(), 80))
    {
#ifdef DIAGNOSTICS      
        Serial.println("wifiClient: connected");
#endif
        wifiClient.print("GET " + url + " HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n");
        
        unsigned long timeout = millis();
        while (wifiClient.available() == 0) 
        {
          if (millis() - timeout > 10000)
          { 
#ifdef DIAGNOSTICS                  
            Serial.println(">>> " + host + " timeout !");
#endif
            wifiClient.stop(); 
            return false; 
          } 
        } 
        if (0 != hrcontent)
        {
            GC_Release(hrcontent);
        }
        hrcontent = HRString_New();
        while (wifiClient.available()) 
        {
            char c = wifiClient.read();
            UInt length = HRString_GetLength(hrcontent);
            HRString_BuildChar_R(hrcontent, c);
        }
    }
    else
    {
#ifdef DIAGNOSTICS
        Serial.println("wifiClient: failed to connect");
        Serial.print("Host: "); Serial.println(host);
        Serial.print("URL: "); Serial.println(url);
#endif
        return false; 
    }
    return true;
}

Bool External_WebClientGetRequest_R(UInt hrurl, UInt& hrcontent)
{
    return WebClient_GetRequest(hrurl, hrcontent);
}

Bool External_WiFiConnect(UInt hrssid, UInt hrpassword)
{
    if (!wifiConnected)
    {
        UInt length = HRString_GetLength(hrssid);
        ssid = "";
        for (UInt i=0; i < length; i++)
        {
            ssid += (char)HRString_GetChar(hrssid, i);
        }
        length = HRString_GetLength(hrpassword);
        password = "";
        for (UInt i=0; i < length; i++)
        {
            password += (char)HRString_GetChar(hrpassword, i);
        }
        wifiConnected =  WifiConnect();
    }
    External_WebServerRelease(); // reconnected to WiFi so we can probably clear handlers
    return wifiConnected;
}

UInt External_WiFiIP()
{
    UInt hrip = HRString_New();
    if (wifiConnected)
    {
        HRString_FromString(hrip, WiFi.localIP().toString());
    }
    return hrip;
}

#endif // USEWIFI