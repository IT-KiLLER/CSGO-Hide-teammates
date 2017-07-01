#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <cstrike>
#include <multicolors>

#define PLUGIN_VERSION "1.0" 
#pragma semicolon 1
#pragma newdecls required
#define TAG_COLOR 	"{green}[SM]{default}"

bool g_bHide[MAXPLAYERS+1] = {false,...};
int g_distanceHide[MAXPLAYERS+1] = {60,...}; 
ConVar sm_hide_default_distance, sm_hide_enabled, sm_hide_minimum, sm_hide_maximum, sm_hide_team;

public Plugin myinfo =  
{ 
	name = "Hide teammates", 
	author = "IT-KiLLER", 
	description = "A plugin that can !hide teammates", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/it-killer" 
} 

public void OnPluginStart() 
{ 
	RegConsoleCmd("sm_hide", Command_Hide); 
	CreateConVar("sm_hide_version", PLUGIN_VERSION, "Plugin by IT-KILLER", FCVAR_DONTRECORD|FCVAR_SPONLY);
	sm_hide_default_distance  = CreateConVar("sm_hide_default_distance", "60", "default distance (0-999)", _, true, 1.0, true, 999.0);
	sm_hide_minimum	= CreateConVar("sm_hide_minimum", "30", "minimum (1-999)", _, true, 1.0, true, 999.0);
	sm_hide_maximum	= CreateConVar("sm_hide_maximum", "300", "maximum (1-999)", _, true, 1.0, true, 999.0);
	sm_hide_enabled	= CreateConVar("sm_hide_enabled", "1", "enabled or disabled", _, true, 0.0, true, 1.0);
	sm_hide_team	= CreateConVar("sm_hide_team", "1", "0=both, 1=CT, 2=T", _, true, 0.0, true, 2.0);
	HookConVarChange(sm_hide_enabled, OnConVarChange);
	for(int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client)) {
				OnClientPutInServer(client);
			}
	}
} 

public void OnClientPutInServer(int client) 
{ 
	if(!sm_hide_enabled.BoolValue) return;
	g_bHide[client] = false;
	g_distanceHide[client] = sm_hide_default_distance.IntValue;
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit); 
} 
/*
public void OnClientDisconnect(int client)
{
	if(!sm_hide_enabled.BoolValue && !IsClientInGame(client)) return;
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}
*/
public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue)) return;
	if (hCvar == sm_hide_enabled)
		for(int client = 1; client <= MaxClients; client++) 
			if(IsClientInGame(client)) {
				g_distanceHide[client] = sm_hide_default_distance.IntValue;
				g_bHide[client] = false; 
				if(sm_hide_enabled.BoolValue)
					SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
				else
					SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
			}
}

public Action Command_Hide(int client, int args) 
{ 
	if(!sm_hide_enabled.BoolValue && !IsClientInGame(client)) return Plugin_Handled;
	int customdistance=-1;

	if (args == 1) {
		char inputArgs[5];
		GetCmdArg(1, inputArgs, sizeof(inputArgs));
		customdistance = StringToInt(inputArgs);
	}

	if((!g_bHide[client] || args == 1 ) && ( customdistance == -1 || (customdistance >= sm_hide_minimum.IntValue && customdistance <= sm_hide_maximum.IntValue) ) )  {
		g_distanceHide[client] = (customdistance >= sm_hide_minimum.IntValue && customdistance <= sm_hide_maximum.IntValue) ? customdistance : sm_hide_default_distance.IntValue;
		CPrintToChat(client,"%s {darkred}!hide{default} teammates are now {green}Enabled{default} with distance: %d. %s", TAG_COLOR, g_distanceHide[client], sm_hide_team.IntValue==1 ? " Only for CTs" : sm_hide_team.IntValue==2 ? "Only for Ts." : "");
		g_bHide[client] = true; 
	} else if (args >=2 || args == 1 ? customdistance!=0 && !(customdistance >= sm_hide_minimum.IntValue && customdistance <= sm_hide_maximum.IntValue) : false) {
		CPrintToChat(client,"%s {darkred}!hide{default} Wrong input, range %d-%d", TAG_COLOR, sm_hide_minimum.IntValue, sm_hide_maximum.IntValue);
	}
	else if (g_bHide[client] || args == 1 && customdistance == 0) {
		CPrintToChat(client,"%s {darkred}!hide{default} teammates are now {darkred}Disabled{default}.", TAG_COLOR);
		g_bHide[client] = false; 
	} 
	return Plugin_Handled; 
} 

public Action Hook_SetTransmit(int target, int client) 
{ 
	if(!sm_hide_enabled.BoolValue) return Plugin_Continue;
	if ( target > 0 && target <= MaxClients && client > 0 && client <= MaxClients ? 
		g_bHide[client] && target != client && OnlyTeam(client) ? 
		GetClientTeam(client) == GetClientTeam(target) && IsPlayerAlive(client) && IsPlayerAlive(target) : false : false) 
	{
		float distance;
		float vec_target[3];
		float vec_client[3];
		GetClientAbsOrigin(target, vec_target);
		GetClientAbsOrigin(client, vec_client);
		distance = GetVectorDistance(vec_target, vec_client, false);
		if (distance < g_distanceHide[client])
			return Plugin_Handled;
	} 
	return Plugin_Continue; 
}  

public bool OnlyTeam(int client)
{
	if(sm_hide_team.IntValue==1)
		return GetClientTeam(client) == CS_TEAM_CT;
	else if (sm_hide_team.IntValue==2)
		return GetClientTeam(client) == CS_TEAM_T;
	return true;
}

