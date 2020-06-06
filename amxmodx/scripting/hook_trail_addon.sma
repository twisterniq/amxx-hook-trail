/*
 * Author: https://t.me/twisterniq (https://dev-cs.ru/members/444/)
 *
 * Official resource topic: https://dev-cs.ru/resources/635/
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hook_trail_api>

#pragma semicolon 1

public stock const PluginName[] = "Hook Trail Addon";
public stock const PluginVersion[] = "1.1.7";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/Hook-Trail";
public stock const PluginDescription[] = "Hook Trail add-on. It allows to use hook to players with access and to give access via menu.";

/****************************************************************************************
****************************************************************************************/

new const CONFIG_NAME[] = "hook_trail_addon";

// Don't comment if you're using Admin Loader by neugomon
//#define ADMIN_LOADER_NEUGOMON

// Number of players that will be shown in menu per page. Can't be more than 8
const PLAYERS_PER_PAGE = 8;

#if !defined MAX_MENU_LENGTH
	#define MAX_MENU_LENGTH 512
#endif

#if defined ADMIN_LOADER_NEUGOMON
	#define client_putinserver client_admin
#endif

new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1];
new g_iAccessHook = ADMIN_LEVEL_C;
new g_iAccessMenu = ADMIN_IMMUNITY;

public plugin_init()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor);
#endif

	register_dictionary("hook_trail_addon.txt");

	new szCmd[][] = { "hookmenu", "/hookmenu", "!hookmenu", ".hookmenu" };
	register_clcmd_list(szCmd, "@func_HookTrailCmd");

	register_menu("@func_HookTrailMenu", 1023, "@func_HookTrailMenu_Handler");

	new pCvar;

	pCvar = create_cvar(
		.name = "hook_trail_access",
		.string = "p",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "HOOK_TRAIL_CVAR_ACCESS"));
	set_pcvar_string(pCvar, "");
	hook_cvar_change(pCvar, "@OnAccessHookChange");

	pCvar = create_cvar(
		.name = "hook_trail_access_menu",
		.string = "a",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "HOOK_TRAIL_CVAR_ACCESS_MENU"));
	set_pcvar_string(pCvar, "");
	hook_cvar_change(pCvar, "@OnAccessMenuChange");

	AutoExecConfig(true, CONFIG_NAME);

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	server_cmd("exec %s/plugins/%s.cfg", szPath, CONFIG_NAME);
	server_exec();
}

public client_putinserver(id)
{
	if(g_iAccessHook > 0 && get_user_flags(id) & g_iAccessHook)
	{
		hook_trail_user_manage(id, true);
	}
#if defined ADMIN_LOADER_NEUGOMON
	else
	{
		hook_trail_user_manage(id, false);
	}
#endif
}

@func_HookTrailCmd(const id)
{
	if(g_iAccessMenu > 0 && !(get_user_flags(id) & g_iAccessMenu))
	{
		return PLUGIN_HANDLED;
	}

	@func_HookTrailMenu(id, 0);

	return PLUGIN_HANDLED;
}

@func_HookTrailMenu(const id, iPage)
{
	if(iPage < 0)
	{
		return;
	}

	new iPlayerCount;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_alive(i))
		{
			continue;
		}

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
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y0. \w%l", iPage ? "HOOK_TRAIL_MENU_BACK" : "HOOK_TRAIL_MENU_EXIT");
	}

	show_menu(id, iKeys, szMenu, -1, "@func_HookTrailMenu");
}

@func_HookTrailMenu_Handler(const id, iKey)
{
	switch(iKey)
	{
		case 8:
		{
			@func_HookTrailMenu(id, ++g_iMenuPosition[id]);
		}
		case 9:
		{
			@func_HookTrailMenu(id, --g_iMenuPosition[id]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[id][(g_iMenuPosition[id] * PLAYERS_PER_PAGE) + iKey];

			if(!is_user_connected(iTarget))
			{
				client_print_color(id, print_team_red, "%l", "HOOK_TRAIL_MENU_ERROR");
				@func_HookTrailMenu(id, g_iMenuPosition[id]);

				return PLUGIN_HANDLED;
			}

			new bool:bHasHook = hook_trail_has_user(iTarget);
			hook_trail_user_manage(iTarget, !bHasHook);
			client_print_color(id, iTarget, "%l", bHasHook ? "HOOK_TRAIL_MENU_TAKEN" : "HOOK_TRAIL_MENU_GIVEN", iTarget);
			@func_HookTrailMenu(id, g_iMenuPosition[id]);
		}
	}

	return PLUGIN_HANDLED;
}

@OnAccessHookChange(const iHandle, const szOldValue[], const szNewValue[])
{
	g_iAccessHook = read_flags(szNewValue);
}

@OnAccessMenuChange(const iHandle, const szOldValue[], const szNewValue[])
{
	g_iAccessMenu = read_flags(szNewValue);
}

// thx wopox1337 (https://dev-cs.ru/threads/222/page-7#post-76442)
stock register_clcmd_list(const cmd_list[][], const function[], flags = -1, const info[] = "", FlagManager = -1, bool:info_ml = false, const size = sizeof(cmd_list))
{
#pragma unused info
#pragma unused FlagManager
#pragma unused info_ml

    for(new i; i < size; i++)
	{
        register_clcmd(cmd_list[i], function, flags, info, FlagManager, info_ml);
    }
}