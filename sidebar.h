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

#ifndef SIDEBAR_H
#define SIDEBAR_H

#include <limits.h>

#define SIDEBAR_DEFAULT_WIDTH 24
#define SIDEBAR_MINIMUM_WIDTH 20
#define SIDEBAR_MAXIMUM_WIDTH 32
#define SIDEBAR_PANE_MINIMUM_WIDTH 20
#define SIDEBAR_SESSION_NONE UINT_MAX

struct client;
struct screen_redraw_ctx;
struct session;

int	 sidebar_session_default_visible(struct session *);
u_int	 sidebar_session_default_width(struct session *);
void	 sidebar_refresh_client(struct client *);
int	 sidebar_client_visible(struct client *);
u_int	 sidebar_client_width(struct client *, u_int);
u_int	 sidebar_client_offset(struct client *, u_int);
u_int	 sidebar_client_size_x(struct client *, u_int);
int	 sidebar_select_line(struct client *, u_int);
void	 sidebar_clear_client_override(struct client *);
int	 sidebar_set_client_override(struct client *, int);
int	 sidebar_toggle_client(struct client *);
void	 sidebar_focus_client(struct client *);
void	 sidebar_unfocus_client(struct client *);
void	 sidebar_move_client_selection(struct client *, int);
void	 sidebar_activate_client_selection(struct client *);
void	 sidebar_commit_client_selection(struct client *);
int	 sidebar_handle_key(struct client *, key_code);
void	 sidebar_draw(struct screen_redraw_ctx *);

#endif /* SIDEBAR_H */
