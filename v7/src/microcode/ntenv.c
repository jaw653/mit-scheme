/* -*-C-*-

$Id: ntenv.c,v 1.6 1993/08/21 03:21:19 gjr Exp $

Copyright (c) 1992-1993 Massachusetts Institute of Technology

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

#include "nt.h"
#include "osenv.h"
#include <stdlib.h>

#ifdef WINNT
#include <string.h>
#endif

time_t
DEFUN_VOID (OS_encoded_time)
{
  time_t t;
  STD_UINT_SYSTEM_CALL (syscall_time, t, (NT_time (0)));
  return (t);
}

void
DEFUN (OS_decode_time, (t, buffer), time_t t AND struct time_structure * buffer)
{
  struct tm * ts;
  STD_PTR_SYSTEM_CALL (syscall_localtime, ts, (NT_localtime (&t)));
  (buffer -> year) = ((ts -> tm_year) + 1900);
  (buffer -> month) = ((ts -> tm_mon) + 1);
  (buffer -> day) = (ts -> tm_mday);
  (buffer -> hour) = (ts -> tm_hour);
  (buffer -> minute) = (ts -> tm_min);
  (buffer -> second) = (ts -> tm_sec);
  {
    /* In localtime() encoding, 0 is Sunday; in ours, it's Monday. */
    int wday = (ts -> tm_wday);
    (buffer -> day_of_week) = ((wday == 0) ? 6 : (wday - 1));
  }
}

time_t
DEFUN (OS_encode_time ,(buffer), struct time_structure * buffer)
{
  time_t t;
  struct tm ts_s, * ts;
  ts = &ts_s;
  (ts -> tm_year) = ((buffer -> year) - 1900);
  (ts -> tm_mon) = ((buffer -> month) - 1);
  (ts -> tm_mday) = (buffer -> day);
  (ts -> tm_hour) = (buffer -> hour);
  (ts -> tm_min) = (buffer -> minute);
  (ts -> tm_sec) = (buffer -> second);
  {
    /* In localtime() encoding, 0 is Sunday; in ours, it's Monday. */
    int wday = (buffer -> day_of_week);
    (ts -> tm_wday) = ((wday == 6) ? 0 : (wday + 1));
  }
  STD_UINT_SYSTEM_CALL (syscall_mktime, t, (NT_mktime (ts)));
  return (t);
}

double
DEFUN_VOID (OS_process_clock)
{
  /* This must not signal an error in normal use. */
  /* Return answer in milliseconds, was in 1/100th seconds */
  return ((((double) (clock ())) * 1000.0) / ((double) CLOCKS_PER_SEC));
}

double
DEFUN_VOID (OS_real_time_clock)
{
  return ((((double) (clock ())) * 1000.0) / ((double) CLOCKS_PER_SEC));
}

void
DEFUN (OS_process_timer_set, (first, interval),
       clock_t first AND clock_t interval)
{
  return;
}

void
DEFUN_VOID (OS_process_timer_clear)
{
  return;
}

void
DEFUN (OS_real_timer_set, (first, interval),
       clock_t first AND clock_t interval)
{
  OS_process_timer_set (first, interval);
  return;
}

void
DEFUN_VOID (OS_real_timer_clear)
{
  OS_process_timer_clear();
  return;
}

static size_t current_dir_path_size = 0;
static char * current_dir_path = 0;

CONST char *
DEFUN_VOID (OS_working_dir_pathname)
{
  if (current_dir_path) {
    return (current_dir_path);
  }
  if (current_dir_path_size == 0)
    {
      current_dir_path = (NT_malloc (1024));
      if (current_dir_path == 0)
	error_system_call (ENOMEM, syscall_malloc);
      current_dir_path_size = 1024;
    }
  while (1)
    {
      if ((NT_getcwd (current_dir_path, current_dir_path_size)) != 0)
      { strlwr(current_dir_path);
	return (current_dir_path);
      }
#ifdef ERANGE
      if (errno != ERANGE)
	error_system_call (errno, syscall_getcwd);
#endif
      current_dir_path_size *= 2;
      {
	char * new_current_dir_path =
	  (NT_realloc (current_dir_path, current_dir_path_size));
	if (new_current_dir_path == 0)
	  /* ANSI C requires `path' to be unchanged -- we may have to
	     discard it for systems that don't behave thus. */
	  error_system_call (ENOMEM, syscall_realloc);
	current_dir_path = new_current_dir_path;
      }
    }
}

void
DEFUN (OS_set_working_dir_pathname, (name), char * name)
{
  size_t name_size = (strlen (name));
  char * filename = name;

  STD_BOOL_SYSTEM_CALL (syscall_chdir, (SetCurrentDirectory (filename)));

  while (1)
  {
    if (name_size < current_dir_path_size)
    {
      strcpy(current_dir_path, name);
      return;
    }
    current_dir_path_size *= 2;
    {
      char * new_current_dir_path =
	(NT_realloc (current_dir_path, current_dir_path_size));
      if (new_current_dir_path == 0)
	error_system_call (ENOMEM, syscall_realloc);
      current_dir_path = new_current_dir_path;
    }
  }
}
