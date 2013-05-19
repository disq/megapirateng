// Support for Remzibi OSD
// Based on file OSD_RemzibiV2.pde from WWW.DIYDRONES.COM
// tested with remzibi firmware ardum 1.73 from rcgroup
// coded by sir alex, 
// tested by fr3d on his desktop with flyduino v2 
// only connect TX1 wire to remzibi RX plug! no ground no 5v power ONLY one Wire !
// tested with the poor remzibi gps on  rx/tx2.
// write flight mode (acro, stabilize,etc..) on line 3 and column 1
// write voltage (an0) on line 14 column 1
// write alert voltage on line 13 column 6

//****************************************************************************************
// to run it configure APM_config.h adding thoses lines.
//#define OSD_PROTOCOL OSD_PROTOCOL_REMZIBI
//#define GPS_PROTOCOL GPS_PROTOCOL_NMEA            //for the poor remzibi nmea gps
//#define BATTERY_EVENT  ENABLED                    //enable for checking main voltage in an0 on flyduino
//#define LOW_VOLTAGE			9.9         //min voltage show alarm
//#define VOLT_DIV_RATIO			3.60// with 10k on (+) and 3k9 on(-)
// have fun fr3d
//**************************************************************************************** 

#if OSD_PROTOCOL == OSD_PROTOCOL_REMZIBI

#define SendSer		Serial1.print
#define SendSerln	Serial1.println

/*
byte oldOSDSwitchPosition = 1;

void read_osd_switch()
{
	byte osdSwitchPosition = readOSDSwitch();
	if (oldOSDSwitchPosition != osdSwitchPosition){
		
		switch(osdSwitchPosition)
		{
			case 1: // First position
			set_osd_mode(1);
			break;

			case 2:
			set_osd_mode(0);
			break;
		}

		oldOSDSwitchPosition = osdSwitchPosition;
	}
}

byte readOSDSwitch(void){
  	int osdPulseWidth = APM_RC.InputCh(OSD_MODE_CHANNEL - 1);
	if (osdPulseWidth >= 1450)  return 2;	// Off
	return 1;
}
*/
void osd_init(){
	Serial1.begin(38400);
	set_osd_mode(1);
}

void osd_heartbeat_10Hz(void)
{
        double nMult=0;
        int nMeters=0; //Change this to 1 for meters, 0 for feet

        if (nMeters==1) {
          nMult=1;
        } else {
          nMult=3.2808399;
        }

	SendSer("$A,");
	SendSer((float)current_loc.lat/10000000,5); //Latitude
	SendSer(",");
	SendSer((float)current_loc.lng/10000000,5); //Longitude
	SendSer(",");
	SendSer(g_gps->num_sats,DEC); //Satellite Count
	SendSer(",");
  SendSer((int)(wp_distance*nMult)); //Distance to Waypoint
	SendSer(",");
	SendSer(current_loc.alt*nMult/10,DEC); //Altitude
	SendSer(",");
	SendSer(g_gps->ground_speed/100,DEC); //Ground Speed
	SendSer(",");
  SendSer(get_bearing_cd(&current_loc,&home)/100,DEC);
	SendSer(",");
	SendSer(",");
	//SendSer(pitch_sensor/100,DEC); //Pitch
	//SendSer(",");
	//SendSer((roll_sensor/100) * -1,DEC); //Roll
	//SendSer(",");
	SendSer(g_gps->date,DEC); //Date
  //SendSer(""); //Date
	SendSer(",");
	SendSer(g_gps->time,DEC); //Time
	SendSerln();

# if BATTERY_EVENT == ENABLED
    if(battery_voltage < LOW_VOLTAGE)
    {
          SendSer("$M,6,13,215,215,");     //fr3d colonne 6 ligne 13 
          SendSer("LOW VOLTAGE ALERT");
          SendSerln();                  

          SendSer ("$M,1,14,215,00,");   //fr3d colonne 1 ligne 14 
          SendSer(battery_voltage,1); 
          SendSerln();

    }
    else
    {
//        SendSerln("$CLS");
//        SendSer("$M,1,4,0,0,");         //fr3d colonne 1 ligne 4 
//        SendSer("                 ");

        SendSer ("$M,1,14,213,00,");     //fr3d colonne 1 ligne 14
        SendSer(battery_voltage,1);
        SendSerln();         

    }
  #endif
        SendSer ("$M,1,4,0,0, "); //fr3d write flight mode column 1 ligne 3
	switch (control_mode){
		case STABILIZE:
			SendSer("STABILIZE       ");
                        break;
		case ACRO:
			SendSer("ACRO            ");
                        break;
		case ALT_HOLD:
			SendSer("ALT_HOLD        ");
                        break;
		case AUTO:
			SendSer("WP");
                        SendSer((int)(wp_distance*nMult));
                        SendSer("   ");
                        break;
		case GUIDED:
			SendSer("GUIDED          ");
                        break;
		case LOITER:
			SendSer("LOITER          ");
                        break;
		case RTL:
			SendSer("RTL:");
                        SendSer((int)(wp_distance*nMult));
                        SendSer("   ");
                        break;
		case CIRCLE:
			SendSer("CIRCLE          ");
                        break;
		case POSITION:
			SendSer("POSITION        ");
                        break;
	}
  SendSerln("");
}

void osd_heartbeat_50Hz(void)
{
	SendSer("$I,");
	SendSer(ahrs.roll_sensor/100,DEC); //Roll
	SendSer(",");
	SendSer(ahrs.pitch_sensor/100,DEC); //Pitch
	SendSer(",");
	SendSerln();
} 

void osd_init_home(void)
{
	SendSer("$SH");
	SendSerln();
	SendSer("$CLS");
	SendSerln(); 
}

void set_osd_mode(int mode){
		switch(mode)
		{
			case 1: // On
				SendSerln("$CLS");
        SendSerln("$L1");
			break;

			case 0: // Off
				SendSerln("$L0");
        SendSerln("$CLS");
			break;
		}
}

#endif
