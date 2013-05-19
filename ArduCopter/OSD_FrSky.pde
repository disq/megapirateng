#if OSD_PROTOCOL == OSD_PROTOCOL_FRSKY

// ****************************************************************
// FrSky telemetry protocol
// You must connect FrSky RX pin via TTL invertor to Serial1 TX (TX1)
// Code ported from MultiWii project by Sir Alex
// ****************************************************************

  // user defines
  //#define FAS_100  //if commment out, MultiWii vBat voltage will be send instead of FrSky FAS 100 voltage
#define FRSKY_SEND_FILLER_DATA // send 13.37 as filler data in heading and gps speed

  // Serial config datas
  #define TELEMETRY_FRSKY_SERIAL 1
  #define TELEMETRY_FRSKY_BAUD 9600

  // Timing
  #define Time_telemetry_send 125000
  static uint8_t cycleCounter = 0;
  static uint32_t FrSkyTime  = 0;

  // Frame protocol
  #define Protocol_Header   0x5E
  #define Protocol_Tail      0x5E

  // Data Ids  (bp = before point; af = after point)
  // Official data IDs
  #define ID_GPS_altitude_bp    0x01
  #define ID_GPS_altitude_ap    0x09
  #define ID_Temperature1        0x02
  #define ID_RPM                0x03
  #define ID_Fuel_level         0x04
  #define ID_Temperature2        0x05
  #define ID_Volt               0x06
  #define ID_Altitude_bp        0x10
  #define ID_Altitude_ap        0x21 // Not supported ?
  #define ID_GPS_speed_bp       0x11
  #define ID_GPS_speed_ap       0x19
  #define ID_Longitude_bp       0x12
  #define ID_Longitude_ap       0x1A
  #define ID_E_W                0x22
  #define ID_Latitude_bp        0x13
  #define ID_Latitude_ap        0x1B
  #define ID_N_S                0x23
  #define ID_Course_bp          0x14
  #define ID_Course_ap          0x1C
  #define ID_Date_Month         0x15
  #define ID_Year               0x16
  #define ID_Hour_Minute        0x17
  #define ID_Second             0x18
  #define ID_Acc_X              0x24
  #define ID_Acc_Y              0x25
  #define ID_Acc_Z              0x26
  #define ID_Voltage_Amp_bp     0x3A
  #define ID_Voltage_Amp_ap     0x3B
  #define ID_Current            0x28
  // User defined data IDs
  #define ID_Gyro_X             0x40
  #define ID_Gyro_Y             0x41
  #define ID_Gyro_Z             0x42

   // Main function FrSky telemetry
    void telemetry_frsky()
   {
			uint32_t currentTime 			= micros();
      if (currentTime > FrSkyTime ) //
      {
         FrSkyTime = currentTime + Time_telemetry_send;
         cycleCounter++;
         // Datas sent every 125 ms
//            send_Altitude();
//            send_Accel();
//            sendDataTail();

         if ((cycleCounter % 4) == 0)
         {
            // Datas sent every 500ms
            send_Altitude();
            send_Course();
            send_GPS_speed();
         }
         if ((cycleCounter % 8) == 0)
         {
            // Datas sent every 1s
            send_Time();
            send_GPS_position();
            send_GPS_altitude();
            send_Voltage_ampere();
            send_Temperature2(); // num of Sats
            send_Fuel(); // num of Sats as Fuel
         }
         if (cycleCounter == 40)
         {
            // Datas sent every 5s
            send_Temperature1();
            send_RPM();
            cycleCounter = 0;
         }
         if ((cycleCounter % 4) == 0) // cycleCounter%4==0 is true for 4, 8 and 40 (runs on all 3 instances)
         {
            sendDataTail();
         }
      }
   }

   void write_FrSky8_internal(uint8_t Data)
   {
      Serial1.write(Data);
   }

   void write_FrSky8(uint8_t Data)
   {
			check_FrSky_stuffing(Data);
   }

   void write_FrSky16(uint16_t Data)
   {
      uint8_t Data_send;
      Data_send = Data;
      check_FrSky_stuffing(Data_send);
      Data_send = Data >> 8 & 0xff;
      check_FrSky_stuffing(Data_send);
   }

   void check_FrSky_stuffing(uint8_t Data) //byte stuffing
   {
      if (Data == 0x5E)
      {
         write_FrSky8_internal(0x5D);
         write_FrSky8_internal(0x3E);
      }
      else if (Data == 0x5D)
      {
         write_FrSky8_internal(0x5D);
         write_FrSky8_internal(0x3D);
      }
      else
      {
         write_FrSky8_internal(Data);
      }
   }

   static void sendDataHead(uint8_t Data_id)
   {
      write_FrSky8_internal(Protocol_Header);
      write_FrSky8_internal(Data_id);
   }

   static void sendDataTail(void)
   {
      write_FrSky8_internal(Protocol_Tail);
   }

   static void sendTwoPart(uint8_t bpId, uint8_t apId, float value)
   {
         int16_t bpVal;
         uint16_t apVal;

         bpVal = floor(value); // value before the decimal point ("bp" is "before point")
         apVal = (value - int(value)) * 100; // value after the decimal point

         sendDataHead(bpId);
         write_FrSky16(bpVal);
         sendDataHead(apId);
         write_FrSky16(apVal);
   }


   //*********************************************************************************
   //-----------------   Telemetrie Datas   ------------------------------------------
   //*********************************************************************************

   // GPS altitude
   void send_GPS_altitude(void)
   {
      if (g_gps->status() == GPS::GPS_OK && g_gps->num_sats>=4)
      {
         sendTwoPart(ID_GPS_altitude_bp, ID_GPS_altitude_ap, g_gps->altitude/100);
      }
   }

   // Temperature
   void send_Temperature1(void)
   {
      sendDataHead(ID_Temperature1);
      write_FrSky16(barometer.get_temperature()/10);
   }

   // RPM
   void send_RPM(void)
   {
      sendDataHead(ID_RPM);
      write_FrSky16(home_distance/100); // send home distance in meters
   }


   // Temperature 2
   void send_Temperature2(void)
   {
         sendDataHead(ID_Temperature2);
         switch (g_gps->status()) {
           case GPS::GPS_OK:
              write_FrSky16(100 + g_gps->num_sats); // GPS sat count (100+: 3D fix)
              break;
           case GPS::NO_FIX:
              write_FrSky16(g_gps->num_sats); // GPS sat count
              break;
           default: // GPS::NO_GPS
              write_FrSky16(-1);
         }
   }

   // Altitude
   void send_Altitude(void)
   {
         sendTwoPart(ID_Altitude_bp, ID_Altitude_ap, current_loc.alt/100);
   }

   // GPS speed
   void send_GPS_speed(void)
   {
      if (g_gps->status() == GPS::GPS_OK)
      {
         sendTwoPart(ID_GPS_speed_bp, ID_GPS_speed_ap, g_gps->ground_speed/100 * 1.94384449); // Knots
      }
#ifdef FRSKY_SEND_FILLER_DATA
      else
      {
         sendTwoPart(ID_GPS_speed_bp, ID_GPS_speed_ap, 13.37 * 1.94384449);
      }
#endif
   }

   // GPS position
   void send_GPS_position(void)
   {
         uint16_t Datas_Longitude_bp;
         uint16_t Datas_Longitude_ap;
         uint16_t Datas_E_W;
         uint16_t Datas_Latitude_bp;
         uint16_t Datas_Latitude_ap;
         uint16_t Datas_N_S;
         float lat = g_gps->latitude / 10000000.0f * 100;
         float lon = g_gps->longitude / 10000000.0f * 100;
         Datas_Longitude_bp = lon;
         Datas_Longitude_ap = (lon-int(lon))*10000;
         Datas_E_W = lon < 0 ? 'W' : 'E';
         Datas_Latitude_bp = lat;
         Datas_Latitude_ap = (lat-int(lat))*10000;
         Datas_N_S = lat < 0 ? 'S' : 'N';

         sendDataHead(ID_Longitude_bp);
         write_FrSky16(Datas_Longitude_bp);
         sendDataHead(ID_Longitude_ap);
         write_FrSky16(Datas_Longitude_ap);
         sendDataHead(ID_E_W);
         write_FrSky16(Datas_E_W);

         sendDataHead(ID_Latitude_bp);
         write_FrSky16(Datas_Latitude_bp);
         sendDataHead(ID_Latitude_ap);
         write_FrSky16(Datas_Latitude_ap);
         sendDataHead(ID_N_S);
         write_FrSky16(Datas_N_S);
   }

   // Course
   void send_Course(void)
   {
      if (g_gps->status() == GPS::GPS_OK)
      {
         sendTwoPart(ID_Course_bp, ID_Course_ap, g_gps->ground_course*100);
      }
#ifdef FRSKY_SEND_FILLER_DATA
      else
      {
         sendTwoPart(ID_Course_bp, ID_Course_ap, 13.37);
      }
#endif
   }

   // Time
   void send_Time(void)
   {
      uint32_t seconds_since_start = millis() / 1000;

      sendDataHead(ID_Hour_Minute);
      write_FrSky8(uint16_t(seconds_since_start / 3600));
      write_FrSky8(uint16_t((seconds_since_start / 60) % 60));
      sendDataHead(ID_Second);
      write_FrSky16(uint16_t(seconds_since_start % 60));
   }

   // ACC
/*   void send_Accel(void)
   {
      int16_t Datas_Acc_X;
      int16_t Datas_Acc_Y;
      int16_t Datas_Acc_Z;

      Datas_Acc_X = ((float)accSmooth[0] / acc_1G) * 1000;
      Datas_Acc_Y = ((float)accSmooth[1] / acc_1G) * 1000;
      Datas_Acc_Z = ((float)accSmooth[2] / acc_1G) * 1000;

      sendDataHead(ID_Acc_X);
      write_FrSky16(Datas_Acc_X);
      sendDataHead(ID_Acc_Y);
      write_FrSky16(Datas_Acc_Y);
      sendDataHead(ID_Acc_Z);
      write_FrSky16(Datas_Acc_Z);
   }*/

   // Voltage (Ampere Sensor)
   void send_Voltage_ampere(void)
   {
         uint16_t Datas_Current;

					float volts = battery_voltage1*2; //in 0.5v resolution
         sendTwoPart(ID_Voltage_Amp_bp, ID_Voltage_Amp_ap, volts);

         Datas_Current = current_amps1;
         sendDataHead(ID_Current);
         write_FrSky16(Datas_Current);

   }

void send_Fuel(void)
{
      uint16_t Data_Num_Sat;

         Data_Num_Sat = (g_gps->num_sats / 2) * 25;

      sendDataHead(ID_Fuel_level);
      write_FrSky16(Data_Num_Sat);
}

// OSD Initialization
void osd_init()
{
	Serial1.begin(9600);
}

void osd_heartbeat_50Hz()
{
	telemetry_frsky();
}

void osd_heartbeat_10Hz()
{
}

#endif