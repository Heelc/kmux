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

#include <string.h>

#include "tmux.h"
#include "sidebar.h"

#define SIDEBAR_DIVIDER_WIDTH 1

static struct session	*sidebar_selected_session(struct client *);
static void		 sidebar_default_sort_criteria(
			     struct sort_criteria *);
static struct session	**sidebar_get_sorted_sessions(u_int *);
static void		 sidebar_select_first(struct client *);
static void		 sidebar_select_last(struct client *);
static void		 sidebar_move_selection(struct client *, int);
static void		 sidebar_apply_client_selection(struct client *, int);
static void		 sidebar_prepare_session_switch(struct client *,
			     struct session *);

static u_int
sidebar_current_session_id(struct client *c)
{
	if (c->session == NULL)
		return (SIDEBAR_SESSION_NONE);
	return (c->session->id);
}

static struct session *
sidebar_selected_session(struct client *c)
{
	struct session	*s;

	if (!c->sidebar.focus)
		return (c->session);

	s = session_find_by_id(c->sidebar.selected_session_id);
	if (s == NULL)
		return (c->session);
	return (s);
}

static void
sidebar_default_sort_criteria(struct sort_criteria *sort_crit)
{
	sort_crit->order = SORT_ORDER;
	sort_crit->reversed = 0;
}

static struct session **
sidebar_get_sorted_sessions(u_int *n)
{
	struct sort_criteria	 sort_crit;

	sidebar_default_sort_criteria(&sort_crit);
	return (sort_get_sessions(n, &sort_crit));
}

static void
sidebar_select_first(struct client *c)
{
	struct session	**list;
	u_int		  n;

	list = sidebar_get_sorted_sessions(&n);
	if (n == 0)
		return;
	c->sidebar.selected_session_id = list[0]->id;
}

static void
sidebar_select_last(struct client *c)
{
	struct session	**list;
	u_int		  n;

	list = sidebar_get_sorted_sessions(&n);
	if (n == 0)
		return;
	c->sidebar.selected_session_id = list[n - 1]->id;
}

static void
sidebar_move_selection(struct client *c, int direction)
{
	struct session	*s;
	struct sort_criteria sort_crit;

	s = sidebar_selected_session(c);
	if (s == NULL)
		return;
	sidebar_default_sort_criteria(&sort_crit);
	if (direction > 0)
		s = session_next_session(s, &sort_crit);
	else
		s = session_previous_session(s, &sort_crit);
	if (s != NULL)
		c->sidebar.selected_session_id = s->id;
}

static void
sidebar_prepare_session_switch(struct client *c, struct session *target)
{
	struct window		*w;
	struct window_pane	*wp;
	u_int			 sx;

	if (target == NULL || target->attached != 0 || target->curw == NULL)
		return;

	w = target->curw->window;
	sx = sidebar_client_size_x(c, c->tty.sx);
	if (sx >= w->sx)
		return;

	/*
	 * Switching a detached session into a narrower sidebar client would
	 * otherwise reflow old pane history. Preserve the existing line breaks
	 * for this one resize; new output will use the new width.
	 */
	TAILQ_FOREACH(wp, &w->panes, entry)
		wp->flags |= PANE_RESIZE_NOREFLOW;
}

static void
sidebar_apply_client_selection(struct client *c, int unfocus)
{
	struct session	*target;

	target = sidebar_selected_session(c);
	if (target == NULL) {
		if (unfocus)
			sidebar_unfocus_client(c);
		return;
	}
	if (target != c->session) {
		sidebar_prepare_session_switch(c, target);
		environ_update(target->options, c->environ, target->environ);
		server_client_set_session(c, target);
		if (unfocus)
			server_client_set_key_table(c, NULL);
	}
	if (unfocus)
		sidebar_unfocus_client(c);
	recalculate_sizes();
	tty_update_client_offset(c);
	server_status_client(c);
	server_redraw_client(c);
}

int
sidebar_session_default_visible(struct session *s)
{
	if (s == NULL)
		return (0);
	return (options_get_number(s->options, "sidebar"));
}

u_int
sidebar_session_default_width(struct session *s)
{
	if (s == NULL)
		return (SIDEBAR_DEFAULT_WIDTH);
	return (options_get_number(s->options, "sidebar-width"));
}

void
sidebar_refresh_client(struct client *c)
{
	if (c->sidebar.has_override)
		c->sidebar.visible = c->sidebar.override_visible;
	else
		c->sidebar.visible = sidebar_session_default_visible(c->session);
	c->sidebar.width = sidebar_session_default_width(c->session);

	if (!c->sidebar.visible)
		c->sidebar.focus = 0;
	if (!c->sidebar.focus ||
	    c->sidebar.selected_session_id == SIDEBAR_SESSION_NONE ||
	    session_find_by_id(c->sidebar.selected_session_id) == NULL)
		c->sidebar.selected_session_id = sidebar_current_session_id(c);
}

int
sidebar_client_visible(struct client *c)
{
	sidebar_refresh_client(c);
	return (c->sidebar.visible);
}

u_int
sidebar_client_width(struct client *c, u_int sx)
{
	u_int	width, limit;

	if (!sidebar_client_visible(c) || sx <= SIDEBAR_DIVIDER_WIDTH)
		return (0);
	if (sx <= SIDEBAR_PANE_MINIMUM_WIDTH + SIDEBAR_DIVIDER_WIDTH)
		return (0);

	width = c->sidebar.width;
	if (width < SIDEBAR_MINIMUM_WIDTH)
		width = SIDEBAR_MINIMUM_WIDTH;
	if (width > SIDEBAR_MAXIMUM_WIDTH)
		width = SIDEBAR_MAXIMUM_WIDTH;

	limit = sx - SIDEBAR_PANE_MINIMUM_WIDTH - SIDEBAR_DIVIDER_WIDTH;
	if (width > limit)
		width = limit;

	return (width);
}

u_int
sidebar_client_offset(struct client *c, u_int sx)
{
	u_int	width;

	width = sidebar_client_width(c, sx);
	if (width == 0)
		return (0);
	return (width + SIDEBAR_DIVIDER_WIDTH);
}

u_int
sidebar_client_size_x(struct client *c, u_int sx)
{
	u_int	offset;

	offset = sidebar_client_offset(c, sx);
	if (offset >= sx)
		return (0);
	return (sx - offset);
}

int
sidebar_select_line(struct client *c, u_int line)
{
	struct session	**list;
	u_int		  n;

	list = sidebar_get_sorted_sessions(&n);
	if (line >= n)
		return (0);
	c->sidebar.selected_session_id = list[line]->id;
	return (1);
}

void
sidebar_clear_client_override(struct client *c)
{
	c->sidebar.has_override = 0;
	c->sidebar.override_visible = 0;
	sidebar_refresh_client(c);
}

int
sidebar_set_client_override(struct client *c, int visible)
{
	c->sidebar.has_override = 1;
	c->sidebar.override_visible = !!visible;
	sidebar_refresh_client(c);
	return (c->sidebar.visible);
}

int
sidebar_toggle_client(struct client *c)
{
	return (sidebar_set_client_override(c, !sidebar_client_visible(c)));
}

void
sidebar_focus_client(struct client *c)
{
	(void)sidebar_set_client_override(c, 1);
	c->sidebar.focus = 1;
	c->sidebar.selected_session_id = sidebar_current_session_id(c);
}

void
sidebar_unfocus_client(struct client *c)
{
	c->sidebar.focus = 0;
	c->sidebar.selected_session_id = sidebar_current_session_id(c);
}

void
sidebar_move_client_selection(struct client *c, int direction)
{
	sidebar_move_selection(c, direction);
}

void
sidebar_commit_client_selection(struct client *c)
{
	sidebar_apply_client_selection(c, 1);
}

void
sidebar_activate_client_selection(struct client *c)
{
	sidebar_apply_client_selection(c, 0);
}

int
sidebar_handle_key(struct client *c, key_code key)
{
	key_code	key0;

	sidebar_refresh_client(c);
	if (!c->sidebar.focus || !c->sidebar.visible)
		return (0);

	key0 = key & (KEYC_MASK_KEY|KEYC_MASK_MODIFIERS);
	switch (key0) {
	case 'j':
		sidebar_move_selection(c, 1);
		sidebar_activate_client_selection(c);
		return (1);
	case 'k':
		sidebar_move_selection(c, -1);
		sidebar_activate_client_selection(c);
		return (1);
	case 'g':
		sidebar_select_first(c);
		sidebar_activate_client_selection(c);
		return (1);
	case 'G':
		sidebar_select_last(c);
		sidebar_activate_client_selection(c);
		return (1);
	case C0_CR:
		sidebar_commit_client_selection(c);
		return (1);
	case C0_ESC:
		sidebar_unfocus_client(c);
		break;
	default:
		return (0);
	}

	server_redraw_sidebar(c);
	return (1);
}

void
sidebar_draw(struct screen_redraw_ctx *ctx)
{
	struct client		*c = ctx->c;
	struct tty		*tty = &c->tty;
	struct session		**list, *s;
	struct grid_cell	 gc;
	u_int			 width, y, row, left, n;
	char			 prefix[3];
	size_t			 len;

	width = sidebar_client_width(c, tty->sx);
	if (width == 0)
		return;

	memcpy(&gc, &grid_default_cell, sizeof gc);
	tty_attributes(tty, &gc, &grid_default_cell, NULL, NULL);
	for (y = ctx->oy; y < ctx->oy + ctx->sy; y++) {
		tty_cursor(tty, 0, y);
		tty_repeat_space(tty, width);
	}

	row = 0;
	left = width;
	if (left > 2)
		left -= 2;
	else
		left = 0;
	list = sidebar_get_sorted_sessions(&n);
	for (row = 0; row < n && row < ctx->sy; row++) {
		s = list[row];
		if (row >= ctx->sy)
			break;
		tty_cursor(tty, 0, ctx->oy + row);
		prefix[0] = (s == c->session) ? '>' : ' ';
		prefix[1] = (s->id == c->sidebar.selected_session_id) ? '*' : ' ';
		prefix[2] = '\0';
		tty_putn(tty, prefix, 2, 2);
		len = strlen(s->name);
		if (len > left)
			len = left;
		if (len != 0)
			tty_putn(tty, s->name, len, len);
	}

	for (y = ctx->oy; y < ctx->oy + ctx->sy; y++) {
		tty_cursor(tty, width, y);
		tty_putn(tty, "|", 1, 1);
	}
}
