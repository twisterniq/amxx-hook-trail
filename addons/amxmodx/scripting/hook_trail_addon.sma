/*
 * Author: https://t.me/twisternick (https://dev-cs.ru/members/444/)
 *
 * Official resource topic: https://dev-cs.ru/resources/635/
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hook_trail_api>

new const PLUGIN_VERSION[] = "1.0";

#if !defined MAX_MENU_LENGTH
	#define MAX_MENU_LENGTH 512
#endif

/****************************************************************************************
****************************************************************************************/

// Don't comment if you're using Admin Loader by neugomon
//#define ADMIN_LOADER_NEUGOMON

#define HOOK_TRAIL_MENU (MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0)

const PLAYERS_PER_PAGE = 8;

/****************************************************************************************
****************************************************************************************/

new g_iMenuPlayers[MAX_PLAYERS+1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS+1];
new g_iAccessMarker = ADMIN_LEVEL_C;
new g_iAccessMenu = ADMIN_IMMUNITY;

public plugin_init()
{
	register_plugin("Hook Trail Addon", PLUGIN_VERSION, "w0w");
	register_dictionary("hook_trail_addon.ini");

	register_clcmd("hookmenu", "func_HookTrailCmd");
	register_clcmd("say /hookmenu", "func_HookTrailCmd");
	register_clcmd("say_team /hookmenu", "func_HookTrailCmd");

	register_menu("func_HookTrailMenu", HOOK_TRAIL_MENU, "func_HookTrailMenu_Handler");

	new pCvar;

	pCvar = create_cvar("hook_trail_access", "p", FCVAR_NONE, "HOOK_TRAIL_CVAR_ACCESS");
	hook_cvar_change(pCvar, "hook_CvarChange_Access");

	pCvar = create_cvar("hook_trail_access_menu", "a", FCVAR_NONE, "HOOK_TRAIL_CVAR_ACCESS_MENU");
	hook_cvar_change(pCvar, "hook_CvarChange_Access_Menu");

	AutoExecConfig(true, "hook_trail_addon");
}

#if !defined ADMIN_LOADER_NEUGOMON
public client_putinserver(id)
#else
public client_admin(id)
#endif
{
	if(g_iAccessMarker > 0 && get_user_flags(id) & g_iAccessMarker)
		hook_trail_user_manage(id, true);
#if defined ADMIN_LOADER_NEUGOMON
	else
		hook_trail_user_manage(id, false);
#endif
}

public func_HookTrailCmd(id)
{
	if(g_iAccessMenu > 0 && !(get_user_flags(id) & g_iAccessMenu))
		return PLUGIN_HANDLED;

	func_HookTrailMenu(id, 0);

	return PLUGIN_HANDLED;
}

public func_HookTrailMenu(id, iPage)
{
	if(iPage < 0)
		return PLUGIN_HANDLED;

	new iPlayerCount;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_alive(i))
			continue;

		g_iMenuPlayers[id][iPlayerCount++] = i;
	}

	SetGlobalTransTarget(id);

	new i = min(iPage * PLAYERS_PER_PAGE, iPlayerCount);
	new iStart = i - (i % PLAYERS_PER_PAGE);
	new iEnd = min(iStart + PLAYERS_PER_PAGE, iPlayerCount);
	g_iMenuPosition[id] = iPage = iStart / PLAYERS_PER_PAGE;

	new szMenu[MAX_MENU_LENGTH], iMenuItem, iKeys = (MENU_KEY_0), iPagesNum;
	iPagesNum = (iPlayerCount / PLAYERS_PER_PAGE + ((iPlayerCount % PLAYERS_PER_PAGE) ? 1 : 0));

	new iLen = formatex(szMenu, charsmax(szMenu), "\y%l \d\R%d/%d^n^n", "HOOK_TRAIL_MENU_TITLE", iPage + 1, iPagesNum);

	for(new a = iStart, iPlayer; a < iEnd; ++a)
	{
		iPlayer = g_iMenuPlayers[id][a];

		iKeys |= (1<<iMenuItem);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%d. \w%n %l^n", ++iMenuItem, iPlayer, hook_trail_has_user(iPlayer) ? "HOOK_TRAIL_MENU_HAS" : "HOOK_TRAIL_MENU_EMPTY");
	}

	if(iEnd != iPlayerCount)
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y9. \w%l^n\y0. \w%l", "HOOK_TRAIL_MENU_NEXT", iPage ? "HOOK_TRAIL_MENU_BACK" : "HOOK_TRAIL_MENU_EXIT");
		iKeys |= (MENU_KEY_9);
	}
	else
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y0. \w%l", iPage ? "HOOK_TRAIL_MENU_BACK" : "HOOK_TRAIL_MENU_EXIT");

	show_menu(id, iKeys, szMenu, -1, "func_HookTrailMenu");
	return PLUGIN_HANDLED;
}

public func_HookTrailMenu_Handler(id, iKey)
{
	switch(iKey)
	{
		case 8: func_HookTrailMenu(id, ++g_iMenuPosition[id]);
		case 9: func_HookTrailMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][(g_iMenuPosition[id] * PLAYERS_PER_PAGE) + iKey];

			if(!is_user_connected(iTarget))
			{
				client_print_color(id, print_team_red, "%l", "HOOK_TRAIL_MENU_ERROR");
				return func_HookTrailMenu(id, g_iMenuPosition[id]);
			}

			new bool:bHasHook = hook_trail_has_user(iTarget);
			hook_trail_user_manage(iTarget, !bHasHook);
			client_print_color(id, iTarget, "%l", bHasHook ? "HOOK_TRAIL_MENU_TAKEN" : "HOOK_TRAIL_MENU_GIVEN", iTarget);
			func_HookTrailMenu(id, g_iMenuPosition[id]);
		}
	}
	return PLUGIN_HANDLED;
}

public hook_CvarChange_Access(pCvar, const szOldValue[], const szNewValue[])
{
	g_iAccessMarker = read_flags(szNewValue);
}

public hook_CvarChange_Access_Menu(pCvar, const szOldValue[], const szNewValue[])
{
	g_iAccessMenu = read_flags(szNewValue);
}