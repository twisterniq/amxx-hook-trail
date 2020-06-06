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
 * @error			If the index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native hook_trail_user_manage(id, bool:enable);

/**
 * Checks if the player has access to hook.
 *
 * @param id		Client index
 *
 * @return			true if the player can use hook, false otherwise
 * @error			If the index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native bool:hook_trail_has_user(id);

/**
 * Gets the speed of player's hook.
 *
 * @param id		Client index
 *
 * @return			Speed of player's hook
 * @error			If the index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native Float:hook_trail_get_user_speed(id);

/**
 * Sets the speed of player's hook.
 *
 * @param id		Client index
 * @param speed		Speed to set
 *
 * @noreturn
 * @error			If the index is not within the range of 1 to MaxClients,
 *					an error will be thrown.
 */
native Float:hook_trail_set_user_speed(id, Float:speed);

/**
 * Called when player enables hook.
 *
 * @return			PLUGIN_CONTINUE to let the client use the hook
 *					PLUGIN_HANDLED or higher to block using the hook
 */
forward hook_trail_on_start(id);

/**
 * Called when player disables hook.
 *
 */
forward hook_trail_on_finish(id);

/**
 * Called when player uses hook.
 *
 * @return			PLUGIN_CONTINUE to let the client use the hook
 *					PLUGIN_HANDLED or higher to block using the hook
 *
 */
forward hook_trail_on_use(id);