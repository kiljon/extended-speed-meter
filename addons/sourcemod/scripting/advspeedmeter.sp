/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>
#include <mapchooser>
#include <colors>

/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Adv Speed Meter"
#define PLUGIN_TAG				"sm"
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"Show current player speed in HUD and saves it until mapchange."
#define PLUGIN_VERSION 			"2.8.16"
#define PLUGIN_URL				"https://forums.alliedmods.net/showthread.php?p=1355865 OR http://www.mannisfunhouse.eu/"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


P L U G I N   D E F I N E S


*****************************************************************/
#define MAX_UNIT_TYPES 4
#define MAX_UNITMESS_LENGTH 5

#define STEAMAUTH_LENGTH 32

/*****************************************************************


G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:g_cvarUnit = INVALID_HANDLE;
new Handle:g_cvarFloodTime = INVALID_HANDLE;
new Handle:g_cvarDisplayTick = INVALID_HANDLE;
new Handle:g_cvarShowSpeedToSpecs = INVALID_HANDLE;

//ConVars runtime saver:
new g_iPlugin_Unit = 0;
new Float:g_fPlugin_FloodTime = 0.0;
new Float:g_fPlugin_DisplayTick = 0.0;
new bool:g_bPlugin_ShowSpeedToSpecs = false;

//Game
new g_bIsHL2DM = false;

//Timer
new Handle:g_hTimer_Think = INVALID_HANDLE;

//Dynamic Arrays
new Handle:g_hClientSteamId = INVALID_HANDLE;
new Handle:g_hClientName = INVALID_HANDLE;
new Handle:g_hMaxClientSpeedRound = INVALID_HANDLE;
new Handle:g_hMaxClientSpeedGame = INVALID_HANDLE;

//Offsets
new g_off_MoveType = -1;

//Game Management
new bool:g_bRoundEnded = false;
new bool:g_bGameEnded = false;

//Misc
new bool:g_bClientSetZero[MAXPLAYERS+1];
new Float:g_fLastCommand = 0.0;

new String:g_szUnitMess_Name[MAX_UNIT_TYPES][MAX_UNITMESS_LENGTH] = {
	
	"km/h",
	"mph",
	"u/s",
	"m/s"
};

new Float:g_fUnitMess_Calc[MAX_UNIT_TYPES] = {
	
	0.04263157894736842105263157894737,
	0.05681807590283512505382617918945,
	1.0,
	0.254
	
};

/*****************************************************************


F O R W A R D   P U B L I C S


*****************************************************************/
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	MarkNativeAsOptional("IsVoteInProgress");
	return APLRes_Success;
}

public OnPluginStart() {
	
	//Translations
	LoadTranslations("plugin.advspeedmeter.phrases");
	
	//Init for smlib
	SMLib_OnPluginStart(PLUGIN_NAME,PLUGIN_TAG,PLUGIN_VERSION,PLUGIN_AUTHOR,PLUGIN_DESCRIPTION,PLUGIN_URL);
	
	g_cvarUnit = CreateConVarEx("unit", "0", "Unit of measurement of speed (0=kilometers per hour, 1=miles per hour, 2=units per second, 3=meters per second)", FCVAR_PLUGIN,true,0.0,true,3.0);
	g_cvarDisplayTick = CreateConVarEx("tick", "0.2", "This sets how often the display is redrawn (this is the display tick rate).",FCVAR_PLUGIN);
	g_cvarShowSpeedToSpecs = CreateConVarEx("showtospecs", "1.0", "Should spectators be able to see the speed of the one they spectating?",FCVAR_PLUGIN,true,0.0,true,1.0);
	//g_cvar_FloodTime will be found in OnConfigsExecuted!
	
	//Cvar Runtime optimizer
	g_iPlugin_Unit = GetConVarInt(g_cvarUnit);
	g_fPlugin_DisplayTick = GetConVarFloat(g_cvarDisplayTick);
	g_bPlugin_ShowSpeedToSpecs = GetConVarBool(g_cvarShowSpeedToSpecs);
	//g_cvar_FloodTime is set in OnConfigsExecuted!
	
	//Game
	new String:gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir,sizeof(gamedir));
	if(StrEqual(gamedir,"hl2mp",false)){
		
		g_bIsHL2DM = true;
	}
	else {
		
		g_bIsHL2DM = false;
	}
	
	g_hClientSteamId = CreateArray(MAX_STEAMAUTH_LENGTH);
	g_hClientName = CreateArray(MAX_NAME_LENGTH);
	g_hMaxClientSpeedRound = CreateArray(4);
	g_hMaxClientSpeedGame = CreateArray(4);
	
	//Offsets
	g_off_MoveType = FindSendPropOffs("CBaseEntity","movetype");
	
	//Cvar Hooks
	HookConVarChange(g_cvarUnit,ConVarChange_Unit);
	HookConVarChange(g_cvarDisplayTick,ConVarChange_DisplayTick);
	HookConVarChange(g_cvarShowSpeedToSpecs,ConVarChange_SpeedToSpecs);
	//g_cvar_FloodTime is hooked in OnConfigsExecuted!
	
	//Event Hooks
	HookEventEx("round_start",OnRoundStart);
	HookEventEx("round_end",OnRoundEnd);
	HookEvent("player_changename", Event_PlayerNameChange);
	
	//Console Commands
	RegConsoleCmd("topspeed",Command_TopSpeed,"Shows the fastest player on the map");
	
	//Admin commands
	RegAdminCmd("sm_listtopspeed",Command_ListTopSpeed,ADMFLAG_ROOT,"dumps all top speed players arrays in the console");
	
	//Auto Config (you should always use it)
	//Always with "plugin." prefix and the short name
	decl String:configName[MAX_PLUGIN_SHORTNAME_LENGTH+8];
	Format(configName,sizeof(configName),"plugin.%s",g_sPlugin_Short_Name);
	AutoExecConfig(true,configName);
}

public OnConfigsExecuted(){
	
	if(g_hTimer_Think == INVALID_HANDLE){
		g_hTimer_Think = CreateTimer(g_fPlugin_DisplayTick, Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
	}
	
	g_cvarFloodTime = FindConVar("sm_flood_time");
	g_fPlugin_FloodTime = GetConVarFloat(g_cvarFloodTime);
	HookConVarChange(g_cvarFloodTime,ConVarChange_FloodTime);
	
	//Late load init.
	ClientAll_Initialize();
}

public OnMapStart(){
	
	// hax against valvefail (thx psychonic for fix)
	if(GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(g_cvarVersion, PLUGIN_VERSION);
	}
	
	g_fLastCommand = GetGameTime();
	
	ClearArray(g_hClientSteamId);
	ClearArray(g_hClientName);
	ClearArray(g_hMaxClientSpeedRound);
	ClearArray(g_hMaxClientSpeedGame);
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client) || !IsClientAuthorized(client)){
			continue;
		}
		
		InsertNewPlayer(client);
	}
	
	g_bGameEnded = false;
	g_bRoundEnded = false;
}

public OnClientConnected(client){
	
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Initialize(client);
}

/****************************************************************


C A L L B A C K   F U N C T I O N S


****************************************************************/

public ConVarChange_Unit(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_iPlugin_Unit = StringToInt(newVal);
}

public ConVarChange_DisplayTick(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_fPlugin_DisplayTick = StringToFloat(newVal);
	
	if(g_hTimer_Think != INVALID_HANDLE){
		KillTimer(g_hTimer_Think);
		g_hTimer_Think = INVALID_HANDLE;
	}
	
	g_hTimer_Think = CreateTimer(g_fPlugin_DisplayTick, Timer_Think, INVALID_HANDLE, TIMER_REPEAT);
	
}

public ConVarChange_FloodTime(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_fPlugin_FloodTime = StringToFloat(newVal);
}

public ConVarChange_SpeedToSpecs(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	g_bPlugin_ShowSpeedToSpecs = bool:StringToInt(newVal);
}


public Action:Command_TopSpeed(client,args){
	
	if(g_fLastCommand > GetGameTime()){
		
		PrintToChat(client,"[SM] %t","Flooding the server");
		
		return Plugin_Handled;
	}
	
	if(g_cvarFloodTime != INVALID_HANDLE){
		
		g_fLastCommand = GetGameTime() + g_fPlugin_FloodTime;
	}
	else {
		
		g_fLastCommand = GetGameTime() + 0.75;
	}
	
	ShowBestGame();
	
	return Plugin_Handled;
}

public Action:Command_ListTopSpeed(client,args){
	
	
	
	new size = GetArraySize(g_hClientSteamId);
	
	PrintToConsole(client,"array size: %d",size);
	
	if((size != GetArraySize(g_hClientName)) || (size != GetArraySize(g_hMaxClientSpeedRound)) || (size != GetArraySize(g_hMaxClientSpeedGame))){
		
		LogError("ERROR: array size is different from other arrays. Report to %s on %s",PLUGIN_AUTHOR,PLUGIN_URL);
		return Plugin_Handled;
	}
	
	PrintToConsole(client,"Listing Top Speeds:");
	
	new String:auth[STEAMAUTH_LENGTH];
	new String:name[MAX_NAME_LENGTH];
	new Float:gamespeed;
	new Float:roundspeed;
	
	for(new i=0;i<size;i++){
		
		GetArrayString(g_hClientSteamId,i,auth,sizeof(auth));
		
		GetArrayString(g_hClientName,i,name,sizeof(name));
		
		gamespeed = GetArrayCell(g_hMaxClientSpeedGame,i);
		
		roundspeed = GetArrayCell(g_hMaxClientSpeedRound,i);
		
		PrintToConsole(client,"Name: %.64s; SteamID: %.32s; gamespeed: %.4f; roundspeed: %.4f",name,auth,gamespeed,roundspeed);
	}
	
	
	return Plugin_Handled;
}


public OnRoundStart(Handle:event, const String:name[], bool:broadcast){
	
	SetSpeedArrayRoundZero();
	g_bRoundEnded = false;
	g_bGameEnded = false;
	
}
public OnRoundEnd(Handle:event, const String:name[], bool:broadcast){
	
	g_bRoundEnded = true;
	
	new timeleft=0;
	GetMapTimeLeft(timeleft);
	
	if(timeleft <= 0){
		GameEnd();
	}
	else {
		ShowBestRound();
	}
}

public Action:Timer_Think(Handle:timer){
	
	if(g_iPlugin_Enable != 1){
		
		return Plugin_Handled;
	}
	
	if(g_bRoundEnded || g_bGameEnded || IsVoteInProgress()){
		return Plugin_Handled;
	}
	
	Server_PrintDebug("-------------------TICK---------------------");
	
	for (new client=1;client<=MaxClients;client++){
		
		/*for(new i=0;i<size;i++){
		
		GetArrayString(g_hClientSteamId,i,steamid,sizeof(steamid));
		
		PrintToServer("array: %s - %f - %f",steamid,GetArrayCell(g_hMaxClientSpeedRound,i),GetArrayCell(g_hMaxClientSpeedGame,i));
		}*/
		
		ShowSpeedMeter(client);
	}
	
	Server_PrintDebug("--------------------------------------------");
	return Plugin_Handled;
}

public Event_PlayerNameChange(Handle:event, const String:name[], bool:broadcast) {
	
	decl client;
	decl String:oldName[MAX_NAME_LENGTH];
	decl String:newName[MAX_NAME_LENGTH];
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!Client_IsValid(client) || !IsClientInGame(client)){return;}
	
	GetEventString(event,"newname",newName,sizeof(newName));
	GetEventString(event,"oldname",oldName,sizeof(oldName));
	
	if(!StrEqual(oldName,newName,true)){
		
		decl String:clientAuth[STEAMAUTH_LENGTH];
		GetClientAuthString(client,clientAuth,sizeof(clientAuth));
		
		new id = FindStringInArray(g_hClientSteamId,clientAuth);
		
		if(id != -1){
			
			SetArrayString(g_hClientName,id,newName);
		}
	}
}
/*****************************************************************


P L U G I N   F U N C T I O N S


*****************************************************************/

stock ShowSpeedMeter(player){
	
	if(!Client_IsValid(player) || !IsClientInGame(player) || IsFakeClient(player)){
		return;
	}
	
	new client = -1;
	new Obs_Mode:observMode = Client_GetObserverMode(player);
	
	if(g_bPlugin_ShowSpeedToSpecs && IsClientObserver(player) && (observMode == OBS_MODE_CHASE || observMode == OBS_MODE_IN_EYE)){
		
		client = Client_GetObserverTarget(player);
		Client_PrintDebug(player,"#1 you are dead/spectator and specing: %N",client);
	}
	else if(IsPlayerAlive(player)){
		Client_PrintDebug(player,"#2 you are alive");
		client = player;
	}
	else {
		Client_PrintDebug(player,"#3 you are not spec and not alive?");
		return;
	}
	
	if(!Client_IsValid(client)){
		Client_PrintDebug(player,"#4 your target %N isn't valid",client);
		return;
	}
	if(!IsClientInGame(client)){
		Client_PrintDebug(player,"#5 your target %N isn't in game",client);
		return;
	}
	if(!IsPlayerAlive(client)){
		Client_PrintDebug(player,"#6 your target %N isn't alive",client);
		return;
	}
	if(!IsClientAuthorized(client)){
		Client_PrintDebug(player,"#7 your target %N isn't authed",client);
		return;
	}
	
	new Float:clientVel[3];
	Entity_GetAbsVelocity(client,clientVel);
	
	new Float:fallSpeed = clientVel[2];
	
	clientVel[2] = 0.0;
	
	new Float:speed = GetVectorLength(clientVel);
	
	if((g_off_MoveType == -1) || ((g_off_MoveType != -1) && (GetEntData(client,g_off_MoveType) == -65534))){
		
		new String:clientAuth[STEAMAUTH_LENGTH];
		GetClientAuthString(client,clientAuth,sizeof(clientAuth));
		
		new clientIndex = FindStringInArray(g_hClientSteamId,clientAuth);
		
		if(clientIndex == -1){
			LogError("didn't find client with steamid in array g_hClientSteamId");
			clientIndex = InsertNewPlayer(client);
		}
		
		if(GetArrayCell(g_hMaxClientSpeedRound,clientIndex) < speed){
			SetArrayCell(g_hMaxClientSpeedRound,clientIndex,speed);
		}
		
		if(GetArrayCell(g_hMaxClientSpeedGame,clientIndex) < speed){
			SetArrayCell(g_hMaxClientSpeedGame,clientIndex,speed);
		}
	}
	
	if(!g_bIsHL2DM){
		
		if((speed == 0.0) && (fallSpeed == 0.0)){
			
			if(!g_bClientSetZero[player]){
				
				PrintHintText(player, "%t\n%.1f %s", "Current speed",0.0,g_szUnitMess_Name[g_iPlugin_Unit]);
				if(IsSoundPrecached("UI/hint.wav")){
					StopSound(player, SNDCHAN_STATIC, "UI/hint.wav");
				}
				g_bClientSetZero[player] = true;
			}
			return;
		}
		g_bClientSetZero[player] = false;
		
		PrintHintText(player, "%t\n%.1f %s", "Current speed", speed*g_fUnitMess_Calc[g_iPlugin_Unit],g_szUnitMess_Name[g_iPlugin_Unit]);
		
		if(IsSoundPrecached("UI/hint.wav")){
			StopSound(player, SNDCHAN_STATIC, "UI/hint.wav");
		}
	}
	else {
		
		SetHudTextParams(0.01, 1.0, g_fPlugin_DisplayTick, 255, 255, 255, 255, 0, 6.0, 0.01, 0.01);
		ShowHudText(player, -1, "%t %.1f %s", "Current speed", speed*g_fUnitMess_Calc[g_iPlugin_Unit],g_szUnitMess_Name[g_iPlugin_Unit]);
	}
}

stock ShowBestRound(){
	
	SortBestRound();
	
	new String:clientName[35];
	new size = GetArraySize(g_hClientName);
	new String:clientSteamId[STEAMAUTH_LENGTH];
	new String:arraySteamId[STEAMAUTH_LENGTH];
	
	CPrintToChatAll("{red}[Adv Speed Meter] {green}%t","The fastest players in this round");
	
	for(new i=0;i<size;i++){
		
		GetArrayString(g_hClientName,i,clientName,sizeof(clientName));
		GetArrayString(g_hClientSteamId,i,arraySteamId,sizeof(arraySteamId));
		
		for(new client=1;client<=MaxClients;client++){
			
			if(IsClientInGame(client)){
				
				GetClientAuthString(client,clientSteamId,sizeof(clientSteamId));
				
				if(StrEqual(arraySteamId,clientSteamId,false)){
					
					CPrintToChat(client,"{green}%d{red}. %s ({green}%.1f %s{red})",i+1,clientName,(Float:GetArrayCell(g_hMaxClientSpeedRound,i)*g_fUnitMess_Calc[g_iPlugin_Unit]),g_szUnitMess_Name[g_iPlugin_Unit]);
				}
				else if(i < 3){
					
					CPrintToChat(client,"{green}%d{red}. {green}%s (%.1f %s)",i+1,clientName,(Float:GetArrayCell(g_hMaxClientSpeedRound,i)*g_fUnitMess_Calc[g_iPlugin_Unit]),g_szUnitMess_Name[g_iPlugin_Unit]);
				}
			}
		}
	}
	
}

stock GameEnd(){
	
	g_bGameEnded = true;
	
	ShowBestGame();
}

stock ShowBestGame(){
	
	SortBestGame();
	
	new String:clientName[35];
	new size = GetArraySize(g_hClientName);
	new String:clientSteamId[STEAMAUTH_LENGTH];
	new String:arraySteamId[STEAMAUTH_LENGTH];
	
	CPrintToChatAll("{red}[Adv Speed Meter] {green}%t","The fastest players on this map");
	
	for(new i=0;i<size;i++){
		
		GetArrayString(g_hClientName,i,clientName,sizeof(clientName));
		GetArrayString(g_hClientSteamId,i,arraySteamId,sizeof(arraySteamId));
		
		for(new client=1;client<=MaxClients;client++){
			
			if(IsClientInGame(client)){
				
				GetClientAuthString(client,clientSteamId,sizeof(clientSteamId));
				
				if(StrEqual(arraySteamId,clientSteamId,false)){
					
					CPrintToChat(client,"{green}%d{red}. %s ({green}%.1f %s{red})",i+1,clientName,(Float:GetArrayCell(g_hMaxClientSpeedGame,i)*g_fUnitMess_Calc[g_iPlugin_Unit]),g_szUnitMess_Name[g_iPlugin_Unit]);
				}
				else if(i < 3){
					
					CPrintToChat(client,"{green}%d{red}. {green}%s (%.1f %s)",i+1,clientName,(Float:GetArrayCell(g_hMaxClientSpeedGame,i)*g_fUnitMess_Calc[g_iPlugin_Unit]),g_szUnitMess_Name[g_iPlugin_Unit]);
				}
			}
		}
	}
}

stock SortBestRound(){
	
	new size = GetArraySize(g_hClientName);
	
	//we want to swap the current and the next array index so size-1 to prevent out of bounds at the end.
	new i,j;
	for (i=0;i<size;i++) { 
		for (j=i;j<size;j++) { 
			if (GetArrayCell(g_hMaxClientSpeedRound,i) < GetArrayCell(g_hMaxClientSpeedRound,j)) { 
				SwapArrayItems(g_hClientSteamId,i,j);
				SwapArrayItems(g_hClientName,i,j);
				SwapArrayItems(g_hMaxClientSpeedRound,i,j);
				SwapArrayItems(g_hMaxClientSpeedGame,i,j);
			} 
		} 
	}
}

stock SortBestGame(){
	
	new size = GetArraySize(g_hClientName);
	
	//we want to swap the current and the next array index so size-1 to prevent out of bounds at the end.
	new i,j;
	for (i=0;i<size;i++) { 
		for (j=i;j<size;j++) { 
			if (GetArrayCell(g_hMaxClientSpeedGame,i) < GetArrayCell(g_hMaxClientSpeedGame,j)) { 
				SwapArrayItems(g_hClientSteamId,i,j);
				SwapArrayItems(g_hClientName,i,j);
				SwapArrayItems(g_hMaxClientSpeedRound,i,j);
				SwapArrayItems(g_hMaxClientSpeedGame,i,j);
			} 
		} 
	}
}

stock SetSpeedArrayRoundZero(){
	
	new size = GetArraySize(g_hMaxClientSpeedRound);
	
	for(new i=0;i<size;i++){
		
		SetArrayCell(g_hMaxClientSpeedRound,i,0.0);
	}
}


ClientAll_Initialize(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client) || !IsClientAuthorized(client)){
			continue;
		}
		
		Client_Initialize(client);
	}
}

Client_Initialize(client){
	
	//Variables
	Client_InitializeVariables(client);
	
	//Functions
	InsertNewPlayer(client);
	
}

Client_InitializeVariables(client){

	//Variables:
	g_bClientSetZero[client] = false;
}


stock InsertNewPlayer(client){
	
	new String:clientAuth[STEAMAUTH_LENGTH];
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	new String:clientName[STEAMAUTH_LENGTH];
	GetClientName(client,clientName,sizeof(clientName));
	
	new id = FindStringInArray(g_hClientSteamId,clientAuth);
	
	if(id == -1){
		
		PushArrayString(g_hClientSteamId,clientAuth);
		PushArrayString(g_hClientName,clientName);
		PushArrayCell(g_hMaxClientSpeedRound,0.0);
		PushArrayCell(g_hMaxClientSpeedGame,0.0);
	}
	else {
		
		SetArrayString(g_hClientName,id,clientName);
	}
	
	id = FindStringInArray(g_hClientSteamId,clientAuth);
	
	if(id == -1){
		
		LogError("still can't find steamid in array g_hClientSteamId (id = %d)",id);
	}
	
	return id;
}

	