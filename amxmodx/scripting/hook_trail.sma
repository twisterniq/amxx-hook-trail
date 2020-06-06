/*
 * Author: https://t.me/twisterniq (https://dev-cs.ru/members/444/)
 *
 * Official resource topic: https://dev-cs.ru/resources/635/
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>

#pragma semicolon 1

public stock const PluginName[] = "Hook Trail";
public stock const PluginVersion[] = "2.1.7";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/Hook-Trail";
public stock const PluginDescription[] = "Ability to use hook with API";

new const CONFIG_NAME[] = "hook_trail";

// Hook sprite that players will see
new const g_szSprite[] = "sprites/hook/yellow_circle.spr";

#define CHECK_NATIVE_PLAYER(%0) \
    if (!(1 <= %0 <= MaxClients)) { \
        abort(AMX_ERR_NATIVE, "Player out of range (%d)", %0); \
    }

const TASK_ID_HOOK = 100;

enum _:CVARS
{
	CVAR_LIFETIME,
	Float:CVAR_DEFAULT_SPEED
};

new g_eCvar[CVARS];

enum _:FORWARDS
{
	FORWARD_ON_START,
	FORWARD_ON_FINISH,
	FORWARD_ON_USE
};

new g_iForward[FORWARDS];

new g_pSpriteTrailHook;

new bool:g_bAlive[MAX_PLAYERS + 1];
new bool:g_bCanUseHook[MAX_PLAYERS + 1];
new g_iHookOrigin[MAX_PLAYERS + 1][3];
new bool:g_bHookUse[MAX_PLAYERS + 1];
new bool:g_bNeedRefresh[MAX_PLAYERS + 1];
new Float:g_flHookSpeed[MAX_PLAYERS + 1];

public plugin_precache()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor);
#endif

	if(!file_exists(g_szSprite))
	{
		set_fail_state("Model ^"%s^" does not exist", g_szSprite);
	}

	g_pSpriteTrailHook = precache_model(g_szSprite);
}

public plugin_init()
{
	register_dictionary("hook_trail.txt");

	register_clcmd("+hook", "@func_HookEnable");
	register_clcmd("-hook", "@func_HookDisable");

	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "@OnPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@OnPlayerKilled_Post", true);

	g_iForward[FORWARD_ON_START] = CreateMultiForward("hook_trail_on_start", ET_STOP, FP_CELL);
	g_iForward[FORWARD_ON_FINISH] = CreateMultiForward("hook_trail_on_finish", ET_IGNORE, FP_CELL);
	g_iForward[FORWARD_ON_USE] = CreateMultiForward("hook_trail_on_use", ET_STOP, FP_CELL);

	bind_pcvar_num(create_cvar(
		.name = "hook_trail_life_time",
		.string = "2",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "HOOK_TRAIL_CVAR_LIFE_TIME"),
		.has_min = true,
		.min_val = 1.0,
		.has_max = true,
		.max_val = 25.0),
		g_eCvar[CVAR_LIFETIME]);

	bind_pcvar_float(create_cvar(
		.name = "hook_trail_default_speed",
		.string = "700",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "HOOK_TRAIL_CVAR_DEFAULT_SPEED"),
		.has_min = true,
		.min_val = 1.0),
		g_eCvar[CVAR_DEFAULT_SPEED]);

	AutoExecConfig(true, CONFIG_NAME);

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	server_cmd("exec %s/plugins/%s.cfg", szPath, CONFIG_NAME);
	server_exec();

	new iEnt = rg_create_entity("info_target", true);

	if(iEnt)
	{
		SetThink(iEnt, "@think_Hook");
		set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
	}
}

public client_putinserver(id)
{
	g_flHookSpeed[id] = g_eCvar[CVAR_DEFAULT_SPEED];
}

public client_disconnected(id)
{
	g_bAlive[id] = g_bHookUse[id] = g_bCanUseHook[id] = false;
	remove_task(id);
}

@OnPlayerSpawn_Post(const id)
{
	if(is_user_alive(id))
	{
		g_bAlive[id] = true;
		g_bHookUse[id] = false;
	}
}

@OnPlayerKilled_Post(const iVictim)
{
	g_bAlive[iVictim] = g_bHookUse[iVictim] = false;
	remove_task(iVictim);
}

@func_HookEnable(const id)
{
	if(!g_bAlive[id])
	{
		return PLUGIN_HANDLED;
	}

	if(!g_bCanUseHook[id])
	{
		client_print_color(id, print_team_red, "%l", "HOOK_TRAIL_ERROR_ACCESS");
		return PLUGIN_HANDLED;
	}

	new iResult;
	ExecuteForward(g_iForward[FORWARD_ON_START], iResult, id);

	if(iResult >= PLUGIN_HANDLED)
	{
		return PLUGIN_HANDLED;
	}

	g_bHookUse[id] = true;
	get_user_origin(id, g_iHookOrigin[id], Origin_AimEndEyes);

	if(!task_exists(id+TASK_ID_HOOK))
	{
		func_RemoveTrail(id);
		func_SetTrail(id);
		set_task_ex(0.1, "@task_HookWings", id+TASK_ID_HOOK, .flags = SetTask_Repeat);
	}

	return PLUGIN_HANDLED;
}

@func_HookDisable(const id)
{
	if(g_bHookUse[id])
	{
		ExecuteForward(g_iForward[FORWARD_ON_FINISH], _, id);
		g_bHookUse[id] = false;
	}

	return PLUGIN_HANDLED;
}

func_SetTrail(const id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	{
		write_byte(TE_BEAMFOLLOW);
		write_short(id);							// entity
		write_short(g_pSpriteTrailHook);			// sprite index
		write_byte(g_eCvar[CVAR_LIFETIME] * 10);	// life
		write_byte(15);								// width
		write_byte(255);							// red
		write_byte(255);							// green
		write_byte(255);							// blue
		write_byte(255);							// brightness
	}
	message_end();
}

func_RemoveTrail(const id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	{
		write_byte(TE_KILLBEAM);
		write_short(id);
	}
	message_end();
}

@task_HookWings(id)
{
	id -= TASK_ID_HOOK;

	if(get_entvar(id, var_flags) & FL_ONGROUND && !g_bHookUse[id])
	{
		remove_task(id+TASK_ID_HOOK);
		func_RemoveTrail(id);
		return;
	}

	static Float:flVelocity[3];
	get_entvar(id, var_velocity, flVelocity);

	if(vector_length(flVelocity) < 10.0)
	{
		g_bNeedRefresh[id] = true;
	}
	else if(g_bNeedRefresh[id])
	{
		g_bNeedRefresh[id] = false;
		func_RemoveTrail(id);
		func_SetTrail(id);
	}
}

@think_Hook(const iEnt)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);

	static iOrigin[3], Float:flVelocity[3], iDistance, iResult;

	for(new i, iPlayer; i < iPlayerCount; i++)
	{
		iPlayer = iPlayers[i];

		if(!g_bHookUse[iPlayer])
		{
			continue;
		}

		ExecuteForward(g_iForward[FORWARD_ON_USE], iResult, iPlayer);

		if(iResult >= PLUGIN_HANDLED)
		{
			remove_task(iPlayer+TASK_ID_HOOK);
			func_RemoveTrail(iPlayer);
			@func_HookDisable(iPlayer);
			continue;
		}

		get_user_origin(iPlayer, iOrigin);
		iDistance = get_distance(g_iHookOrigin[iPlayer], iOrigin);

		if(iDistance > 25)
		{
			flVelocity[0] = (g_iHookOrigin[iPlayer][0] - iOrigin[0]) * (g_flHookSpeed[iPlayer] / iDistance);
			flVelocity[1] = (g_iHookOrigin[iPlayer][1] - iOrigin[1]) * (g_flHookSpeed[iPlayer] / iDistance);
			flVelocity[2] = (g_iHookOrigin[iPlayer][2] - iOrigin[2]) * (g_flHookSpeed[iPlayer] / iDistance);
			set_entvar(iPlayer, var_velocity, flVelocity);
		}
	}

	set_entvar(iEnt, var_nextthink, get_gametime() + 0.1);
}

/****************************************************************************************
****************************************************************************************/

public plugin_natives()
{
	register_library("hook_trail");

	register_native("hook_trail_user_manage",		"@Native_UserManage");
	register_native("hook_trail_has_user",			"@Native_HasUser");
	register_native("hook_trail_get_user_speed",	"@Native_GetUserSpeed");
	register_native("hook_trail_set_user_speed",	"@Native_SetUserSpeed");
}

@Native_UserManage(const iPlugin, const iParams)
{
	enum { arg_player = 1, arg_enable };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer)

	g_bCanUseHook[iPlayer] = bool:get_param(arg_enable);

	if(!g_bCanUseHook[iPlayer])
	{
		g_bHookUse[iPlayer] = false;
		remove_task(iPlayer);
	}
}

bool:@Native_HasUser(const iPlugin, const iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer)

	return g_bCanUseHook[iPlayer];
}

Float:@Native_GetUserSpeed(const iPlugin, const iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer)

	return g_flHookSpeed[iPlayer];
}

Float:@Native_SetUserSpeed(const iPlugin, const iParams)
{
	enum { arg_player = 1, arg_speed };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer)

	new Float:flSpeed = get_param_f(arg_speed);

	if(flSpeed < 1.0)
	{
		abort(AMX_ERR_NATIVE, "Speed must be greater or equal to 1.0");
	}

	g_flHookSpeed[iPlayer] = flSpeed;
}