/* $OpenBSD$ */

/*
 * Copyright (c) 2026 Nicholas Marriott <nicholas.marriott@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>

#include <stdlib.h>

#include "tmux.h"
#include "sidebar.h"

static enum cmd_retval	cmd_focus_sidebar_exec(struct cmd *,
			    struct cmdq_item *);
static enum cmd_retval	cmd_toggle_sidebar_exec(struct cmd *,
			    struct cmdq_item *);
static enum cmd_retval	cmd_set_sidebar_default_exec(struct cmd *,
			    struct cmdq_item *);

const struct cmd_entry cmd_focus_sidebar_entry = {
	.name = "focus-sidebar",
	.alias = NULL,

	.args = { "c:", 0, 0, NULL },
	.usage = "[-c target-client]",

	.flags = CMD_CLIENT_CFLAG,
	.exec = cmd_focus_sidebar_exec
};

const struct cmd_entry cmd_toggle_sidebar_entry = {
	.name = "toggle-sidebar",
	.alias = NULL,

	.args = { "c:", 0, 0, NULL },
	.usage = "[-c target-client]",

	.flags = CMD_CLIENT_CFLAG,
	.exec = cmd_toggle_sidebar_exec
};

const struct cmd_entry cmd_set_sidebar_default_entry = {
	.name = "set-sidebar-default",
	.alias = NULL,

	.args = { "gt:", 1, 1, NULL },
	.usage = "[-g] " CMD_TARGET_SESSION_USAGE " on|off",

	.target = { 't', CMD_FIND_SESSION, 0 },

	.flags = CMD_AFTERHOOK,
	.exec = cmd_set_sidebar_default_exec
};

static enum cmd_retval
cmd_focus_sidebar_exec(__unused struct cmd *self, struct cmdq_item *item)
{
	struct client	*tc = cmdq_get_target_client(item);

	if (tc->session == NULL) {
		cmdq_error(item, "no current session");
		return (CMD_RETURN_ERROR);
	}

	sidebar_focus_client(tc);
	recalculate_sizes();
	tty_update_client_offset(tc);
	server_redraw_client(tc);
	return (CMD_RETURN_NORMAL);
}

static enum cmd_retval
cmd_toggle_sidebar_exec(__unused struct cmd *self, struct cmdq_item *item)
{
	struct client	*tc = cmdq_get_target_client(item);

	if (tc->session == NULL) {
		cmdq_error(item, "no current session");
		return (CMD_RETURN_ERROR);
	}

	sidebar_toggle_client(tc);
	recalculate_sizes();
	tty_update_client_offset(tc);
	server_redraw_client(tc);
	return (CMD_RETURN_NORMAL);
}

static enum cmd_retval
cmd_set_sidebar_default_exec(struct cmd *self, struct cmdq_item *item)
{
	struct args				*args = cmd_get_args(self);
	struct cmd_find_state			*target = cmdq_get_target(item);
	struct options				*oo;
	struct options_entry			*o;
	const struct options_table_entry	*oe;
	const char				*value = args_string(args, 0);
	char					*cause;

	if (args_has(args, 'g') && args_has(args, 't')) {
		cmdq_error(item, "only one of -g or -t may be given");
		return (CMD_RETURN_ERROR);
	}
	if (args_has(args, 'g'))
		oo = global_s_options;
	else
		oo = target->s->options;

	o = options_get(oo, "sidebar");
	oe = options_table_entry(o);
	if (options_from_string(oo, oe, oe->name, value, 0, &cause) != 0) {
		cmdq_error(item, "%s", cause);
		free(cause);
		return (CMD_RETURN_ERROR);
	}

	options_push_changes("sidebar");
	recalculate_sizes();
	return (CMD_RETURN_NORMAL);
}
