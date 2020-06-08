#if defined _hook_trail_included
	#endinput
#endif
#define _hook_trail_included

#pragma reqlib hook_trail

/**
 * Called when player enables hook.
 *
 * @param id        Client index
 *
 * @return          PLUGIN_CONTINUE to let the client use hook
 *                  PLUGIN_HANDLED or higher to block using hook
 */
forward hook_trail_on_start(const id);

/**
 * Called when player disables hook.
 *
 * @param id        Client index
 *
 * @noreturn
 */
forward hook_trail_on_finish(const id);

/**
 * Called when player uses hook.
 *
 * @param id        Client index
 *
 * @return          PLUGIN_CONTINUE to let the client use hook
 *                  PLUGIN_HANDLED or higher to block using hook
 */
forward hook_trail_on_use(const id);

/**
 * Returns if player has access to use hook.
 *
 * @param id        Client index
 *
 * @return          true if player has it, false otherwise
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native bool:hook_trail_has_user_access(const id);

/**
 * Sets the ability for player to use hook.
 *
 * @param id        Client index
 * @param access    true to give access, false otherwise
 *
 * @noreturn
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native hook_trail_set_user_access(const id, bool:access);

/**
 * Gets the speed of player's hook.
 *
 * @param id        Client index
 *
 * @return          Speed of player's hook
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native Float:hook_trail_get_user_speed(const id);

/**
 * Sets the speed of player's hook.
 *
 * @param id        Client index
 * @param speed     Speed value
 *
 * @noreturn
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native Float:hook_trail_set_user_speed(const id, Float:speed = -1.0);