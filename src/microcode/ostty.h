/* -*-C-*-

$Id: ostty.h,v 1.10 2007/04/22 16:31:23 cph Exp $

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

*/

#ifndef SCM_OSTTY_H
#define SCM_OSTTY_H

#include "os.h"

extern Tchannel OS_tty_input_channel (void);
extern Tchannel OS_tty_output_channel (void);
extern unsigned int OS_tty_x_size (void);
extern unsigned int OS_tty_y_size (void);
extern const char * OS_tty_command_beep (void);
extern const char * OS_tty_command_clear (void);
extern cc_t OS_tty_next_interrupt_char (void);
extern cc_t OS_tty_map_interrupt_char (cc_t);

#endif /* SCM_OSTTY_H */
