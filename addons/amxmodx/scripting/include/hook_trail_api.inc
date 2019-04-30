#if defined _hook_trail_api_included
	#endinput
#endif
#define _hook_trail_api_included

/**
 * Manages the mode of player's hook, i.e., enables or disables it.
 *
 * @param id		Client index
 * @param enable	true if hook needs to be enabled, false otherwise
 *
 * @noreturn
 */
native hook_trail_user_manage(id, bool:enable);

/**
 * Checks if the player has access to hook.
 *
 * @param id		Client index
 *
 * @return			true if the player can use hook, false otherwise
 */
native bool:hook_trail_has_user(id);