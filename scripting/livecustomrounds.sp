#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgo_colors>

// *************************************************** //
//Здесь можно добавлять оружия. Команды тоже, но осторожно :
//You can add weapons here. Commands too, but carefully :

char aWeapons[][] = { "weapon_AK47", "weapon_M4A1", "weapon_AWP", "weapon_MP5SD", "weapon_AUG", "weapon_MAG7", "weapon_XM1014", "weapon_SCAR20", "weapon_P90", "weapon_Negev", "weapon_M249", "weapon_MP7" },
aPistols[][] = { "weapon_FiveSeven", "weapon_Deagle", "weapon_Tec9", "weapon_USP_Silencer", "weapon_P250", "weapon_Glock", "weapon_HKP2000", "weapon_Revolver", "weapon_CZ75A", "weapon_Elite" },
aCommands[][] = { "none_None", "sv_Jump_Impulse 120", "sv_Jump_Impulse 1200", "Weapon_Accuracy_Nospread 1", "mp_Teammates_Are_Enemies 1", "mp_Radar_Showall 1", "sv_Gravity 200", "sv_Gravity 1000", "sm_Drug @all"},

szVotingTitle[160],
szRoundWeapon[64],
szRoundPistol[64],
szRoundCommand[64],
aWeaponName[2][64],
aPistolName[2][64],
aCommandName[2][64];

ConVar g_timeout,g_democracy,g_votetime,g_gravity,g_teammates,g_jump,g_spread,g_radar;
int g_iGrenadeOffsets[] = {15, 17, 16, 14, 18, 17},iPlayersCount,iVotesCount,iRound;
bool bTimeOut, bCustomRoundEnd;
float fDiff,fSecToMin,fTimeOut,fVotetime,fGravity;
Handle hrTimerWeapons[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Live Custom Rounds",
	author = "XTANCE",
	description = "Create custom rounds with weapons and commands",
	version = "1",
	url = "https://t.me/xtance"
};

public OnPluginStart()
{
	LoadTranslations("livecustomrounds.phrases");
	RegAdminCmd("sm_round", XRound, ADMFLAG_BAN, "Choose custom round");
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Pre);
	g_democracy = CreateConVar("g_democracy", "0", "Голосование за кастомный раунд | Custom round vote (1/0)");
	g_timeout = CreateConVar("g_timeout", "300.0", "Как часто можно делать раунд, в секундах | How often a round can be made, in seconds");
	g_votetime = CreateConVar("g_votetime", "20.0", "Сколько длится голосование, в секундах | How long voting lasts, in seconds");
	AutoExecConfig(true, "livecustomrounds");
}

public void OnMapStart()
{
	bCustomRoundEnd = false;
	bTimeOut = true;
	fDiff = 0.5;
	iRound = 1337;
	iPlayersCount = 0;
	iVotesCount = 0;
	fTimeOut = g_timeout.FloatValue;
	fVotetime = g_votetime.FloatValue;
	fSecToMin = fTimeOut / 60;
	g_gravity = FindConVar("sv_gravity");
	g_jump = FindConVar("sv_jump_impulse");
	g_teammates = FindConVar("mp_teammates_are_enemies");
	g_spread = FindConVar("weapon_accuracy_nospread");
	g_radar = FindConVar("mp_radar_showall");
	fGravity = GetConVarFloat(g_gravity);
}

public Action XRound(int iClient, int args)
{
	char szText[160];
	SetGlobalTransTarget(iClient);
	if (bTimeOut)
	{
		iPlayersCount = 0;
		iVotesCount = 0;	
		Menu mWeapons = new Menu(hWeapons, MENU_ACTIONS_ALL);
		FormatEx(szText, sizeof(szText), "%t", "szTitleWeapons");
		SetMenuTitle(mWeapons, szText);
		for (new i = 0; i < sizeof(aWeapons); i++)
		{
			ExplodeString(aWeapons[i], "_", aWeaponName, 2, 64, true);
			AddMenuItem(mWeapons, aWeapons[i], aWeaponName[1]);
		}
		mWeapons.ExitButton = false;
		DisplayMenu(mWeapons, iClient, MENU_TIME_FOREVER);
	}
	else
	{
		FormatEx(szText, sizeof(szText), "%t", "szTimeout", fSecToMin);
		CGOPrintToChat(iClient, szText);
	}
	return Plugin_Handled;
}

public int hWeapons(Menu mWeapons, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szText[128];
			SetGlobalTransTarget(param1);
			FormatEx(szText, sizeof(szText), "%t", "szTitlePistols");
			mWeapons.GetItem(param2, szRoundWeapon, sizeof(szRoundWeapon));
			ExplodeString(szRoundWeapon, "_", aWeaponName, 2, 64, true);
			Menu mPistols = new Menu(hPistols, MENU_ACTIONS_ALL);
			SetMenuTitle(mPistols, szText);
			for (new i = 0; i < sizeof(aPistols); i++)
			{
				ExplodeString(aPistols[i], "_", aPistolName, 2, 64, true);
				AddMenuItem(mPistols, aPistols[i], aPistolName[1]);
			}
			mPistols.ExitButton = false;
			DisplayMenu(mPistols, param1, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			delete mWeapons;
		}
	}
	return 0;
}

public int hPistols(Menu mPistols, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szText[128];
			SetGlobalTransTarget(param1);
			FormatEx(szText, sizeof(szText), "%t", "szTitleCommand");
			mPistols.GetItem(param2, szRoundPistol, sizeof(szRoundPistol));
			ExplodeString(szRoundPistol, "_", aPistolName, 2, 64, true);
			Menu mCommands = new Menu(hCommands, MENU_ACTIONS_ALL);
			SetMenuTitle(mCommands, szText);
			for (new i = 0; i < sizeof(aCommands); i++)
			{
				ExplodeString(aCommands[i], "_", aCommandName, 2, 64, true);
				AddMenuItem(mCommands, aCommands[i], aCommandName[1]);
			}
			mCommands.ExitButton = false;
			DisplayMenu(mCommands, param1, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			delete mPistols;
		}
	}
	return 0;
}

public int hCommands(Menu mCommands, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			
			mCommands.GetItem(param2, szRoundCommand, sizeof(szRoundCommand));
			ExplodeString(szRoundCommand, "_", aCommandName, 2, 64, true);
			if (bTimeOut) {
				CreateTimer(fTimeOut, rTimerTime);
				bTimeOut = false;
				VoteOrNot();
			}
			else
			{
				char szText[160];
				SetGlobalTransTarget(param1);
				FormatEx(szText, sizeof(szText), "%t", "szTimeout", fSecToMin);
				CGOPrintToChat(param1, szText);
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			delete mCommands;
		}
	}
	return 0;
}

void VoteOrNot()
{
	if (g_democracy.BoolValue)
	{
		FormatEx(szVotingTitle, sizeof(szVotingTitle), ">> CR : %s+%s+%s ?", aWeaponName[1], aPistolName[1], aCommandName[1]);
		CreateTimer(fVotetime, rTimerVote);
		Menu mvote = new Menu(hvote, MENU_ACTIONS_ALL);
		mvote.SetTitle("%s",szVotingTitle);
		mvote.AddItem("itemyes","+");
		mvote.AddItem("itemno","-");
		mvote.ExitButton = false;
		//mvote.DisplayVoteToAll(12);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i > 0)
			{
				if (IsClientInGame(i))
				{
					DisplayMenu(mvote, i, 12);
				}
			}
		} 
	}
	else
	{
		NextRoundIsCustom();
	}
}


public Action Event_RoundStart(Event event, const char[] name, bool Broadcast)
{
	if (iRound == (CS_GetTeamScore(2) + CS_GetTeamScore(3)))
	{
		ServerCommand(szRoundCommand);
		RemoveMap();
	}
	if ((bCustomRoundEnd) || (CS_GetTeamScore(2) + CS_GetTeamScore(3) == 0))
	{
		SetConVarFloat(g_gravity, fGravity, true, false);
		SetConVarInt(g_teammates, 0, true, false);
		SetConVarInt(g_radar, 0, true, false);
		SetConVarInt(g_spread, 0, true, false);
		SetConVarInt(g_jump, 301, true, false);
	}
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool Broadcast)
{
	if (iRound+1 == (CS_GetTeamScore(2) + CS_GetTeamScore(3)))
	{
		RemoveMap();
		bCustomRoundEnd = true;
		for (int iClient = 1; iClient <= MAXPLAYERS; iClient++)
		{
			RemoveAll(iClient);
		}
	}
	return Plugin_Continue;
}

public HookPlayerSpawn(Handle:event, const String:name[ ], bool:dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(iClient))
    {
		if (iRound == (CS_GetTeamScore(2) + CS_GetTeamScore(3)))
		{
			RemoveAll(iClient);
			hrTimerWeapons[iClient]  = CreateTimer(0.2, rTimerWeapons, iClient);
		}
    }
	return 0;
}

public Action rTimerWeapons(Handle timer, any iClient)
{
	if (IsClientInGame(iClient))
	{
		char szHud[128];
		SetGlobalTransTarget(iClient);
		FormatEx(szHud, sizeof(szHud), "%t", "szStart");
		SetHudTextParams(-1.0, 0.8, 8.0, 0,255,0,255, 0, 6.0, 0.1, 0.2)
		ShowHudText(iClient, 3, szHud);
		FormatEx(szHud, sizeof(szHud), "%s + %s + %s !",aWeaponName[1],aPistolName[1],aCommandName[1]);
		SetHudTextParams(-1.0, 0.85, 8.0, 255,255,0,255, 0, 6.0, 0.1, 0.2)
		ShowHudText(iClient, 4, szHud);
		GivePlayerItem(iClient, szRoundWeapon);
		GivePlayerItem(iClient, szRoundPistol);	
		GivePlayerItem(iClient, "weapon_knife");
	}
	hrTimerWeapons[iClient] = null;
	return Plugin_Handled;
}

public void OnClientDisconnect(int iClient)
{
	if (hrTimerWeapons[iClient] != null)
	{
		KillTimer(hrTimerWeapons[iClient]);
		hrTimerWeapons[iClient] = null;
	}
}


public int hvote(Menu mvote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[32];
			mvote.GetItem(param2, item, sizeof(item));
			if (StrEqual(item, "itemyes"))
			{
				iPlayersCount++;
				iVotesCount++;
			}
			if (StrEqual(item, "itemno"))
			{
				iPlayersCount++;
				iVotesCount--;
			}
		}
	}
	return 0;
}

public Action rTimerTime(Handle timer)
{
	bTimeOut = true;
}

public Action rTimerVote(Handle timer)
{
	if ((iVotesCount / iPlayersCount) >= fDiff)
	{
		PrintToConsoleAll("Players Count = %i, Vote Count = %i",iPlayersCount,iVotesCount);
		NextRoundIsCustom();
	}
	else
	{
		char szFail[256];
		PrintToConsoleAll("Players Count = %i, Vote Count = %i",iPlayersCount,iVotesCount);
		for (int i = 1; i <= MAXPLAYERS; i++)
		{
			if (IsClientInGame(i)){
				Format(szFail, sizeof(szFail), "%T", "szFail", i);
				CGOPrintToChat(i, szFail);
			}
		}
	}
}

void NextRoundIsCustom()
{
	char sz1[256],sz2[256],sz3[256];
	iRound = (CS_GetTeamScore(2) + CS_GetTeamScore(3) + 1);
	PrintToChatAll(" ");
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsClientInGame(i)){
			SetGlobalTransTarget(i);
			FormatEx(sz1, sizeof(sz1), "%t", "sz1", iRound);
			FormatEx(sz2, sizeof(sz2), "%t", "sz2", aWeaponName[1], aPistolName[1]);
			FormatEx(sz3, sizeof(sz3), "%t", "sz3", aCommandName[1]);
			
			CGOPrintToChat(i, sz1);
			CGOPrintToChat(i, sz2);
			CGOPrintToChat(i, sz3);
		}
	}
	PrintToChatAll(" ");
}


void RemoveAll(iClient)
{
	for (int i = 0; i < 5; ++i)
	{
		if (i == 3) RemoveNades(iClient);
		else RemoveWeaponBySlot(iClient, i);
	}
}

void RemoveMap()
{
	// By Kigen (c) 2008 - Please give me credit. :)
	int maxent = GetMaxEntities();
	char weapon[64];
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (StrContains(weapon, "weapon_") != -1)
			{
				RemoveEdict(i);
			}
		}
	}
}


// Code by White Wolf (hlmod.ru)
stock void RemoveNades(int iClient)
{
	while (RemoveWeaponBySlot(iClient, 3))
	{
		for (int i = 0; i < 6; i++)
			SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, g_iGrenadeOffsets[i]);
	}
}

stock bool RemoveWeaponBySlot(int iClient, int slot)
{
	int entity = GetPlayerWeaponSlot(iClient, slot);
	if (IsValidEdict(entity))
	{
		RemovePlayerItem(iClient, entity);
		AcceptEntityInput(entity, "Kill");
		return true;
	}
	return false;
}
