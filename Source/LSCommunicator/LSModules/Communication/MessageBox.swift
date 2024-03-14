//
//  MessageBox.swift
//  
//
//  Created by Guru on 14/03/24.
//

import UIKit

public enum MessageType: Int {
    /// Read = 1
    case READ = 1
    /// Write = 2
    case WRITE = 2
}

public enum MessageBox: Int, CaseIterable {
    
    case NOTREGISTERED = 0
    case REG_ASYNC_EVENTS = 3
    case DREG_ASYNC_EVENTS = 4
    case FwVersion_Info = 5
    case HostVersion_Info = 6
    case GCastVersion_Info = 7
    case IsHostPresent = 9
    case PlayBackSource = 10
    case IsHostALLowed = 11
    case AirPlay_SOurceSwitch = 12
    case ACPShare_cmd = 14
    case ACPShare_response = 15
    case DeepSleep_start = 20
    case DeepSleep_end = 21
    case Standby_start = 22
    case Standby_end = 23
    case PowerSave_status = 24
    case DevDetachment_status = 36
    case Graceful_shutdown = 37
    case DevAttachment_status = 38
    case PLAYCNTRL = 40
    case BROWSE_CNTRL = 41
    //    case REMOTE = 41
    case PLAYJSON = 42 //GETUI
    case TRACK_INFO = 44
    case GetUI_play = 45
    case CoverArt_Transfer = 46
    case GETPLAYDURATION = 49 // currentTime
    case CURRSOURCE = 50
    case PLAY_STATE  = 51
    case PlayList_CntrlCmd = 52
    case PLAYERRORMB = 54 //isplaystatus
    case Reboot = 55
    case Mute_Unmute = 63
    case VOLUME = 64
    case FWUpgrade_request = 65
    case FWUpgrade_progress = 66
    case HostImg_Present = 68
    case RequestFW_Upgrade = 69
    case FAVORITES = 70 //App control
    case SDCard_Status = 71
    case WIFI_Scan = 72
    case Scan_Results = 73
    case Spotify_Discovery = 76
    case PlayAudio_Index = 80
    case I2C_Client_access = 81
    case Dev_Name = 90
    case DevMACID = 91
    case DevInfo = 92
    case MBID_STARTAUX = 95 //AUXinput start
    case MBID_STOPAUX = 96 //AUXinput stop
    case External_Playback = 97
    case MRATrigger = 100
    case StandAlone_Mode = 101
    case SearchLSModule = 102
    case DEVICESTATE = 103 //QueryMRA
    case setZoneID = 104
    case DDMS_SSID = 105
    case SPEAKER_TYPE = 106
    case SCENENAME = 107
    case SetupStereo_Pair = 108
    case ClientsInMRA = 110
    case IPTunneling_Start = 111
    case Tunnel_Data = 112
    case MIRACast_control = 113
    case Reboot_Request = 114
    case Reboot_cmd = 115
    case Master_To_Slave = 117
    case Slave_To_Master = 118
    case GVA_Status = 120
    case Custom_GVA_Action = 121
    case NWConnection_Status = 124
    case ConfigureNetwork = 125
    case WIFI_Settings_Sharing = 126
    case Link_Status = 134
    case WPS_Config_Status = 140
    case NW_Config = 142
    case NW_Config_Status = 143
    case Stop_WAC = 144
    case Factory_Reset = 150
    case RSSI_Indicator = 151
    case AVS_Login_Status = 205
    case Region = 206
    
    case LED = 207 //IOT Control
    case GetENV = 208 //NV Read/Write
    case MBID_BT = 209 //Bluetooth Control Command)
    case DMR_Start = 210
    case Start_FW_Upgrade = 211
    case SDDP_NOTIFIER = 212
    case USERNAME = 213
    case Enable_ShareMode = 214
    case Enable_Pair_Mode = 215
    case SlaveInfo = 216
    case ZONEVOLUME = 219 //ZoneVolumeControl
    case PairStatus = 221
    case GCast = 222 //Cast_OTA_Update
    case FW_Upgrade_Internet = 223
    case Cast_Enabled = 224
    case MBID_GoogleTOS = 226 //Google Cast Settings Info
    case DMR_Stop = 227
    case Get_NTP_Time = 229
    case AudioOutput_FS = 230
    case GCast_Sl_No = 231
    case AC_Powered = 232
    case ALEXA_MIC = 233
    case ALEXA_VOICE_SERVICE = 234 //AVS_APP_SERVICE)
    case Cloud_Tunneling_request = 236
    case Cloud_Tunneling_response = 237
    case Forced_Upgrade = 238
    case Low_Latency = 239
    case AVS_Client_Status = 240
    case MIC_Power_Measurement = 245
    case ALEXA_UI = 246
    case Host_MCU_PSM = 251
    case Notify_Airplay_Password = 252
    case Device_Band = 253
    case EXtSourceStatus = 301
    case CAST_SETUP_STARTED = 494
    case MIC_Dump_Debug = 497
    case Sound_Clasification = 502
    case Host_Facoty_Test = 503
    
    case AppleHomeInclusionCheck = 561
    
    case Cast_ToS_CrashReport_Send = 571
    case Cast_ToS_CrashReport_Read = 572
    
    case MB_TimeZone = 573
    
    case MB_Trigger_Device_Log = 651
}
