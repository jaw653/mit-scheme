/* -*-C-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/osterm.h,v 1.7 1991/03/14 04:22:41 cph Exp $

Copyright (c) 1990-91 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. */

#ifndef SCM_OSTERM_H
#define SCM_OSTERM_H

#include "os.h"

extern unsigned int EXFUN (OS_terminal_get_ispeed, (Tchannel channel));
extern unsigned int EXFUN (OS_terminal_get_ospeed, (Tchannel channel));
extern unsigned int EXFUN (arg_baud_index, (unsigned int argument));
extern unsigned int EXFUN (OS_baud_index_to_rate, (unsigned int index));
extern int EXFUN (OS_baud_rate_to_index, (unsigned int rate));
extern unsigned int EXFUN (OS_terminal_state_size, (void));
extern void EXFUN (OS_terminal_get_state, (Tchannel channel, PTR statep));
extern void EXFUN (OS_terminal_set_state, (Tchannel channel, PTR statep));
extern int EXFUN (OS_terminal_cooked_output_p, (Tchannel channel));
extern void EXFUN (OS_terminal_raw_output, (Tchannel channel));
extern void EXFUN (OS_terminal_cooked_output, (Tchannel channel));
extern int EXFUN (OS_terminal_buffered_p, (Tchannel channel));
extern void EXFUN (OS_terminal_buffered, (Tchannel channel));
extern void EXFUN (OS_terminal_nonbuffered, (Tchannel channel));
extern void EXFUN (OS_terminal_flush_input, (Tchannel channel));
extern void EXFUN (OS_terminal_flush_output, (Tchannel channel));
extern void EXFUN (OS_terminal_drain_output, (Tchannel channel));
extern int EXFUN (OS_job_control_p, (void));
extern int EXFUN (OS_have_ptys_p, (void));
extern CONST char * EXFUN
  (OS_open_pty_master, (Tchannel * master_fd, CONST char ** master_fname));
extern void EXFUN (OS_pty_master_send_signal, (Tchannel channel, int sig));
extern void EXFUN (OS_pty_master_kill, (Tchannel channel));
extern void EXFUN (OS_pty_master_stop, (Tchannel channel));
extern void EXFUN (OS_pty_master_continue, (Tchannel channel));
extern void EXFUN (OS_pty_master_interrupt, (Tchannel channel));
extern void EXFUN (OS_pty_master_quit, (Tchannel channel));
extern void EXFUN (OS_pty_master_hangup, (Tchannel channel));

#endif /* SCM_OSTERM_H */
