/* -*-C-*-

$Id: prdb4.c,v 1.4 2006/01/13 05:47:35 cph Exp $

Copyright 2004,2005 Massachusetts Institute of Technology

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

*/

/* Interface to the Berkeley DB library
   Tested with versions 4.2 and 4.3  */

#include "scheme.h"
#include "prims.h"
#include <errno.h>
#include <db.h>

#define UNIFIED_VERSION							\
  ((DB_VERSION_MAJOR * 0x10000)						\
   + (DB_VERSION_MINOR * 0x100)						\
   + DB_VERSION_PATCH)

#if (UNIFIED_VERSION >= 0x040300)
#  define VERSION_43 1
#endif
#if (UNIFIED_VERSION >= 0x040400)
#  define VERSION_44 1
#endif

#define ARG_DB(n) ((DB *) (arg_ulong_integer (n)))
#define ARG_DB_ENV(n) ((DB_ENV *) (arg_ulong_integer (n)))
#define ARG_DB_TXN(n) ((DB_TXN *) (arg_ulong_integer (n)))
#define ARG_UINT32(n) ((u_int32_t) (arg_ulong_integer (n)))
#define OPT_STRING_ARG(n) (((ARG_REF (n)) == SHARP_F) ? 0 : (STRING_ARG (n)))
#define OPT_STRING_VAL(v) (((v) == 0) ? SHARP_F : (char_pointer_to_string (v)))
#define ARG_FILE_MODE(n) (arg_index_integer ((n), 010000))

#define ANY_TO_UINT(x) (ulong_to_integer ((unsigned long) (x)))

#define RETURN_RC(rc) PRIMITIVE_RETURN (long_to_integer (rc))

#define RC_TO_NAME_CASE(code, name)					\
  case code:								\
    PRIMITIVE_RETURN (char_pointer_to_symbol (name))

DEFINE_PRIMITIVE ("DB4:RC->NAME", Prim_db4_rc_to_name, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    long rc = (arg_integer (1));
    switch (rc)
      {
	RC_TO_NAME_CASE (0, "ok");
#ifdef VERSION_43
	RC_TO_NAME_CASE (DB_BUFFER_SMALL, "db_buffer_small");
#endif
	RC_TO_NAME_CASE (DB_DONOTINDEX, "db_donotindex");
#ifndef VERSION_43
	RC_TO_NAME_CASE (DB_FILEOPEN, "db_fileopen");
#endif
	RC_TO_NAME_CASE (DB_KEYEMPTY, "db_keyempty");
	RC_TO_NAME_CASE (DB_KEYEXIST, "db_keyexist");
	RC_TO_NAME_CASE (DB_LOCK_DEADLOCK, "db_lock_deadlock");
	RC_TO_NAME_CASE (DB_LOCK_NOTGRANTED, "db_lock_notgranted");
#ifdef VERSION_43
	RC_TO_NAME_CASE (DB_LOG_BUFFER_FULL, "db_log_buffer_full");
#endif
	RC_TO_NAME_CASE (DB_NOSERVER, "db_noserver");
	RC_TO_NAME_CASE (DB_NOSERVER_HOME, "db_noserver_home");
	RC_TO_NAME_CASE (DB_NOSERVER_ID, "db_noserver_id");
	RC_TO_NAME_CASE (DB_NOTFOUND, "db_notfound");
	RC_TO_NAME_CASE (DB_OLD_VERSION, "db_old_version");
	RC_TO_NAME_CASE (DB_PAGE_NOTFOUND, "db_page_notfound");
	RC_TO_NAME_CASE (DB_REP_DUPMASTER, "db_rep_dupmaster");
	RC_TO_NAME_CASE (DB_REP_HANDLE_DEAD, "db_rep_handle_dead");
	RC_TO_NAME_CASE (DB_REP_HOLDELECTION, "db_rep_holdelection");
	RC_TO_NAME_CASE (DB_REP_ISPERM, "db_rep_isperm");
	RC_TO_NAME_CASE (DB_REP_NEWMASTER, "db_rep_newmaster");
	RC_TO_NAME_CASE (DB_REP_NEWSITE, "db_rep_newsite");
	RC_TO_NAME_CASE (DB_REP_NOTPERM, "db_rep_notperm");
#ifndef VERSION_43
	RC_TO_NAME_CASE (DB_REP_OUTDATED, "db_rep_outdated");
#endif
#ifdef VERSION_43
	RC_TO_NAME_CASE (DB_REP_STARTUPDONE, "db_rep_startupdone");
#endif
	RC_TO_NAME_CASE (DB_REP_UNAVAIL, "db_rep_unavail");
	RC_TO_NAME_CASE (DB_RUNRECOVERY, "db_runrecovery");
	RC_TO_NAME_CASE (DB_SECONDARY_BAD, "db_secondary_bad");
	RC_TO_NAME_CASE (DB_VERIFY_BAD, "db_verify_bad");
#ifdef VERSION_43
	RC_TO_NAME_CASE (DB_VERSION_MISMATCH, "db_version_mismatch");
#endif
	RC_TO_NAME_CASE (DB_ALREADY_ABORTED, "db_already_aborted");
	RC_TO_NAME_CASE (DB_DELETED, "db_deleted");
#ifndef VERSION_44
	RC_TO_NAME_CASE (DB_LOCK_NOTEXIST, "db_lock_notexist");
#endif
	RC_TO_NAME_CASE (DB_NEEDSPLIT, "db_needsplit");
#ifdef VERSION_43
	RC_TO_NAME_CASE (DB_REP_EGENCHG, "db_rep_egenchg");
	RC_TO_NAME_CASE (DB_REP_LOGREADY, "db_rep_logready");
	RC_TO_NAME_CASE (DB_REP_PAGEDONE, "db_rep_pagedone");
#endif
	RC_TO_NAME_CASE (DB_SURPRISE_KID, "db_surprise_kid");
	RC_TO_NAME_CASE (DB_SWAPBYTES, "db_swapbytes");
	RC_TO_NAME_CASE (DB_TIMEOUT, "db_timeout");
	RC_TO_NAME_CASE (DB_TXN_CKP, "db_txn_ckp");
	RC_TO_NAME_CASE (DB_VERIFY_FATAL, "db_verify_fatal");
	RC_TO_NAME_CASE (EINVAL, "einval");
	RC_TO_NAME_CASE (ENOMEM, "enomem");
	RC_TO_NAME_CASE (EAGAIN, "eagain");
	RC_TO_NAME_CASE (ENOSPC, "enospc");
	RC_TO_NAME_CASE (ENOENT, "enoent");
	RC_TO_NAME_CASE (EACCES, "eacces");
      }
  }
  PRIMITIVE_RETURN (SHARP_F);
}

#define NAME_TO_RC_CASE(name2, code)					\
  if ((strcmp (name, (name2))) == 0)					\
    PRIMITIVE_RETURN (long_to_integer (code))

DEFINE_PRIMITIVE ("DB4:NAME->RC", Prim_db4_name_to_rc, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    const char * name = (arg_interned_symbol (1));
    NAME_TO_RC_CASE ("ok", 0);
#ifdef VERSION_43
    NAME_TO_RC_CASE ("db_buffer_small", DB_BUFFER_SMALL);
#endif
    NAME_TO_RC_CASE ("db_donotindex", DB_DONOTINDEX);
#ifndef VERSION_43
    NAME_TO_RC_CASE ("db_fileopen", DB_FILEOPEN);
#endif
    NAME_TO_RC_CASE ("db_keyempty", DB_KEYEMPTY);
    NAME_TO_RC_CASE ("db_keyexist", DB_KEYEXIST);
    NAME_TO_RC_CASE ("db_lock_deadlock", DB_LOCK_DEADLOCK);
    NAME_TO_RC_CASE ("db_lock_notgranted", DB_LOCK_NOTGRANTED);
#ifdef VERSION_43
    NAME_TO_RC_CASE ("db_log_buffer_full", DB_LOG_BUFFER_FULL);
#endif
    NAME_TO_RC_CASE ("db_noserver", DB_NOSERVER);
    NAME_TO_RC_CASE ("db_noserver_home", DB_NOSERVER_HOME);
    NAME_TO_RC_CASE ("db_noserver_id", DB_NOSERVER_ID);
    NAME_TO_RC_CASE ("db_notfound", DB_NOTFOUND);
    NAME_TO_RC_CASE ("db_old_version", DB_OLD_VERSION);
    NAME_TO_RC_CASE ("db_page_notfound", DB_PAGE_NOTFOUND);
    NAME_TO_RC_CASE ("db_rep_dupmaster", DB_REP_DUPMASTER);
    NAME_TO_RC_CASE ("db_rep_handle_dead", DB_REP_HANDLE_DEAD);
    NAME_TO_RC_CASE ("db_rep_holdelection", DB_REP_HOLDELECTION);
    NAME_TO_RC_CASE ("db_rep_isperm", DB_REP_ISPERM);
    NAME_TO_RC_CASE ("db_rep_newmaster", DB_REP_NEWMASTER);
    NAME_TO_RC_CASE ("db_rep_newsite", DB_REP_NEWSITE);
    NAME_TO_RC_CASE ("db_rep_notperm", DB_REP_NOTPERM);
#ifndef VERSION_43
    NAME_TO_RC_CASE ("db_rep_outdated", DB_REP_OUTDATED);
#endif
#ifdef VERSION_43
    NAME_TO_RC_CASE ("db_rep_startupdone", DB_REP_STARTUPDONE);
#endif
    NAME_TO_RC_CASE ("db_rep_unavail", DB_REP_UNAVAIL);
    NAME_TO_RC_CASE ("db_runrecovery", DB_RUNRECOVERY);
    NAME_TO_RC_CASE ("db_secondary_bad", DB_SECONDARY_BAD);
    NAME_TO_RC_CASE ("db_verify_bad", DB_VERIFY_BAD);
#ifdef VERSION_43
    NAME_TO_RC_CASE ("db_version_mismatch", DB_VERSION_MISMATCH);
#endif
    NAME_TO_RC_CASE ("db_already_aborted", DB_ALREADY_ABORTED);
    NAME_TO_RC_CASE ("db_deleted", DB_DELETED);
#ifndef VERSION_44
    NAME_TO_RC_CASE ("db_lock_notexist", DB_LOCK_NOTEXIST);
#endif
    NAME_TO_RC_CASE ("db_needsplit", DB_NEEDSPLIT);
#ifdef VERSION_43
    NAME_TO_RC_CASE ("db_rep_egenchg", DB_REP_EGENCHG);
    NAME_TO_RC_CASE ("db_rep_logready", DB_REP_LOGREADY);
    NAME_TO_RC_CASE ("db_rep_pagedone", DB_REP_PAGEDONE);
#endif
    NAME_TO_RC_CASE ("db_surprise_kid", DB_SURPRISE_KID);
    NAME_TO_RC_CASE ("db_swapbytes", DB_SWAPBYTES);
    NAME_TO_RC_CASE ("db_timeout", DB_TIMEOUT);
    NAME_TO_RC_CASE ("db_txn_ckp", DB_TXN_CKP);
    NAME_TO_RC_CASE ("db_verify_fatal", DB_VERIFY_FATAL);
    NAME_TO_RC_CASE ("einval", EINVAL);
    NAME_TO_RC_CASE ("enomem", ENOMEM);
    NAME_TO_RC_CASE ("eagain", EAGAIN);
    NAME_TO_RC_CASE ("enospc", ENOSPC);
    NAME_TO_RC_CASE ("enoent", ENOENT);
    NAME_TO_RC_CASE ("eacces", EACCES);
  }
  error_bad_range_arg (1);
  PRIMITIVE_RETURN (UNSPECIFIC);
}

static SCHEME_OBJECT
DEFUN (convert_dbtype, (type), DBTYPE type)
{
  switch (type)
    {
    case DB_BTREE: return (char_pointer_to_symbol ("btree"));
    case DB_HASH: return (char_pointer_to_symbol ("hash"));
    case DB_RECNO: return (char_pointer_to_symbol ("recno"));
    case DB_QUEUE: return (char_pointer_to_symbol ("queue"));
    default: return (long_to_integer (type));
    }
}

static DBTYPE
DEFUN (arg_dbtype, (n), int n)
{
  const char * s = (arg_interned_symbol (n));
  if ((strcmp (s, "btree")) == 0)
    return (DB_BTREE);
  else if ((strcmp (s, "hash")) == 0)
    return (DB_HASH);
  else if ((strcmp (s, "recno")) == 0)
    return (DB_RECNO);
  else if ((strcmp (s, "queue")) == 0)
    return (DB_QUEUE);
  else
    {
      error_bad_range_arg (n);
      return (DB_UNKNOWN);
    }
}

DEFINE_PRIMITIVE ("DB4:DB-STRERROR", Prim_db4_db_strerror, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN (char_pointer_to_string (db_strerror (arg_integer (1))));
}

DEFINE_PRIMITIVE ("DB4:DB-CREATE", Prim_db4_db_create, 3, 3, 0)
{
  PRIMITIVE_HEADER (3);
  CHECK_ARG (3, WEAK_PAIR_P);
  {
    DB * db;
    int rc = (db_create ((&db), (ARG_DB_ENV (1)), (ARG_UINT32 (2))));
    if (rc == 0)
      SET_PAIR_CDR ((ARG_REF (3)), (ANY_TO_UINT (db)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-GET-ENV", Prim_db4_db_get_env, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
#ifdef VERSION_43
    DB_ENV * db_env = ((db -> get_env) (db));
    SET_PAIR_CAR (p, (ANY_TO_UINT (db_env)));
    RETURN_RC (0);
#else
    DB_ENV * db_env;
    int rc = ((db -> get_env) (db, (&db_env)));
    if (rc == 0)
      SET_PAIR_CAR (p, (ANY_TO_UINT (db_env)));
    RETURN_RC (rc);
#endif
  }
}

DEFINE_PRIMITIVE ("DB4:DB-OPEN", Prim_db4_db_open, 7, 7, 0)
{
  PRIMITIVE_HEADER (7);
  {
    DB * db = (ARG_DB (1));
    RETURN_RC
      ((db -> open) (db,
		     (ARG_DB_TXN (2)),
		     (OPT_STRING_ARG (3)),
		     (OPT_STRING_ARG (4)),
		     (arg_dbtype (5)),
		     (ARG_UINT32 (6)),
		     (ARG_FILE_MODE (7))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-GET-DBNAME", Prim_db4_db_get_dbname, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    const char * filename;
    const char * db_name;
    int rc = ((db -> get_dbname) (db, (&filename), (&db_name)));
    if (rc == 0)
      {
	SET_PAIR_CAR (p, (OPT_STRING_VAL (filename)));
	SET_PAIR_CDR (p, (OPT_STRING_VAL (db_name)));
      }
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-GET-TYPE", Prim_db4_db_get_type, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    DBTYPE type;
    int rc = ((db -> get_type) (db, (&type)));
    if (rc == 0)
      SET_PAIR_CAR (p, (convert_dbtype (type)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-GET-OPEN-FLAGS", Prim_db4_db_get_open_flags, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    u_int32_t flags;
    int rc = ((db -> get_open_flags) (db, (&flags)));
    if (rc == 0)
      SET_PAIR_CAR (p, (ulong_to_integer (flags)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-GET-TRANSACTIONAL", Prim_db4_db_get_transactional, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
#ifdef VERSION_43
    SET_PAIR_CAR (p, (BOOLEAN_TO_OBJECT ((db -> get_transactional) (db))));
    RETURN_RC (0);
#else
    int b;
    int rc = ((db -> get_transactional) (db, (&b)));
    if (rc == 0)
      SET_PAIR_CAR (p, (BOOLEAN_TO_OBJECT (b)));
    RETURN_RC (rc);
#endif
  }
}

DEFINE_PRIMITIVE ("DB4:DB-CLOSE", Prim_db4_db_close, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    DB * db = (ARG_DB (1));
    RETURN_RC ((db -> close) (db, (ARG_UINT32 (2))));
  }
}

DEFINE_PRIMITIVE ("DB4:SIZEOF-DBT", Prim_db4_sizeof_dbt, 0, 0, 0)
{
  PRIMITIVE_HEADER (0);
  PRIMITIVE_RETURN (ulong_to_integer (sizeof (DBT)));
}

static DBT *
DEFUN (arg_dbt, (n), int n)
{
  SCHEME_OBJECT s = (ARG_REF (n));
  if (!STRING_P (s))
    error_wrong_type_arg (n);
  if ((STRING_LENGTH (s)) != (sizeof (DBT)))
    error_bad_range_arg (n);
  return ((DBT *) (STRING_LOC (s, 0)));
}

DEFINE_PRIMITIVE ("DB4:DB-GET-PAGESIZE", Prim_db4_db_get_pagesize, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB * db = (ARG_DB (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    u_int32_t pagesize;
    int rc = ((db -> get_pagesize) (db, (&pagesize)));
    if (rc == 0)
      SET_PAIR_CAR (p, (ulong_to_integer (pagesize)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:INIT-DBT", Prim_db4_init_dbt, 4, 4, 0)
{
  PRIMITIVE_HEADER (4);
  CHECK_ARG (2, STRING_P);
  {
    DBT * dbt = (arg_dbt (1));
    SCHEME_OBJECT s = (ARG_REF (2));
    u_int32_t ulen = (STRING_LENGTH (s));
    memset (dbt, 0, (sizeof (*dbt)));
    (dbt -> data) = (STRING_LOC (s, 0));
    (dbt -> size) = ulen;
    (dbt -> ulen) = ulen;
    (dbt -> flags) = DB_DBT_USERMEM;
    if ((ARG_REF (3)) != SHARP_F)
      {
	(dbt -> dlen) = (ARG_UINT32 (3));
	(dbt -> doff) = (((ARG_REF (4)) == SHARP_F) ? ulen : (ARG_UINT32 (4)));
	(dbt -> flags) |= DB_DBT_PARTIAL;
      }
  }
  PRIMITIVE_RETURN (UNSPECIFIC);
}

DEFINE_PRIMITIVE ("DB4:DBT-SIZE", Prim_db4_dbt_size, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN (ulong_to_integer ((arg_dbt (1)) -> size));
}

DEFINE_PRIMITIVE ("DB4:DB-GET", Prim_db4_db_get, 5, 5, 0)
{
  PRIMITIVE_HEADER (5);
  {
    DB * db = (ARG_DB (1));
    RETURN_RC ((db -> get) (db,
			    (ARG_DB_TXN (2)),
			    (arg_dbt (3)),
			    (arg_dbt (4)),
			    (ARG_UINT32 (5))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-PUT", Prim_db4_db_put, 5, 5, 0)
{
  PRIMITIVE_HEADER (5);
  {
    DB * db = (ARG_DB (1));
    RETURN_RC ((db -> put) (db,
			    (ARG_DB_TXN (2)),
			    (arg_dbt (3)),
			    (arg_dbt (4)),
			    (ARG_UINT32 (5))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-DEL", Prim_db4_db_del, 4, 4, 0)
{
  PRIMITIVE_HEADER (4);
  {
    DB * db = (ARG_DB (1));
    RETURN_RC ((db -> del) (db,
			    (ARG_DB_TXN (2)),
			    (arg_dbt (3)),
			    (ARG_UINT32 (4))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-CREATE", Prim_db4_db_env_create, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, WEAK_PAIR_P);
  {
    DB_ENV * db_env;
    int rc = (db_env_create ((&db_env), (ARG_UINT32 (1))));
    if (rc == 0)
      SET_PAIR_CDR ((ARG_REF (2)), (ANY_TO_UINT (db_env)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-OPEN", Prim_db4_db_env_open, 4, 4, 0)
{
  PRIMITIVE_HEADER (4);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    RETURN_RC
      ((db_env -> open) (db_env,
			 (OPT_STRING_ARG (2)),
			 (ARG_UINT32 (3)),
			 (ARG_FILE_MODE (4))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-GET-HOME", Prim_db4_db_env_get_home, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    const char * home;
    int rc = ((db_env -> get_home) (db_env, (&home)));
    if (rc == 0)
      SET_PAIR_CAR (p, (char_pointer_to_string (home)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-GET-OPEN-FLAGS", Prim_db4_db_env_get_open_flags, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, PAIR_P);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    u_int32_t flags;
    int rc = ((db_env -> get_open_flags) (db_env, (&flags)));
    if (rc == 0)
      SET_PAIR_CAR (p, (ulong_to_integer (flags)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-CLOSE", Prim_db4_db_env_close, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    RETURN_RC ((db_env -> close) (db_env, (ARG_UINT32 (2))));
  }
}

DEFINE_PRIMITIVE ("DB4:SIZEOF-DB-LOCK", Prim_db4_sizeof_db_lock, 0, 0, 0)
{
  PRIMITIVE_HEADER (0);
  PRIMITIVE_RETURN (ulong_to_integer (sizeof (DB_LOCK)));
}

static DB_LOCK *
DEFUN (arg_db_lock, (n), int n)
{
  SCHEME_OBJECT s = (ARG_REF (n));
  if (!STRING_P (s))
    error_wrong_type_arg (n);
  if ((STRING_LENGTH (s)) != (sizeof (DB_LOCK)))
    error_bad_range_arg (n);
  return ((DB_LOCK *) (STRING_LOC (s, 0)));
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-LOCK-ID", Prim_db4_db_env_lock_id, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (2, WEAK_PAIR_P);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    SCHEME_OBJECT p = (ARG_REF (2));
    u_int32_t id;
    int rc = ((db_env -> lock_id) (db_env, (&id)));
    if (rc == 0)
      SET_PAIR_CDR (p, (ulong_to_integer (id)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-LOCK-ID-FREE", Prim_db4_db_env_lock_id_free, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    RETURN_RC ((db_env -> lock_id_free) (db_env, (ARG_UINT32 (2))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-LOCK-GET", Prim_db4_db_env_lock_get, 6, 6, 0)
{
  PRIMITIVE_HEADER (6);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    RETURN_RC
      ((db_env -> lock_get) (db_env,
			     (ARG_UINT32 (2)),
			     (ARG_UINT32 (3)),
			     (arg_dbt (4)),
			     (arg_ulong_integer (5)),
			     (arg_db_lock (6))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-LOCK-PUT", Prim_db4_db_env_lock_put, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    RETURN_RC ((db_env -> lock_put) (db_env, (arg_db_lock (2))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-ENV-TXN-BEGIN", Prim_db4_db_env_txn_begin, 4, 4, 0)
{
  PRIMITIVE_HEADER (4);
  CHECK_ARG (4, WEAK_PAIR_P);
  {
    DB_ENV * db_env = (ARG_DB_ENV (1));
    DB_TXN * db_txn;
    int rc =
      ((db_env -> txn_begin) (db_env,
			      (ARG_DB_TXN (2)),
			      (&db_txn),
			      (ARG_UINT32 (3))));
    if (rc == 0)
      SET_PAIR_CDR ((ARG_REF (4)), (ANY_TO_UINT (db_txn)));
    RETURN_RC (rc);
  }
}

DEFINE_PRIMITIVE ("DB4:DB-TXN-COMMIT", Prim_db4_db_txn_commit, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    DB_TXN * db_txn = (ARG_DB_TXN (1));
    RETURN_RC ((db_txn -> commit) (db_txn, (ARG_UINT32 (2))));
  }
}

DEFINE_PRIMITIVE ("DB4:DB-TXN-ABORT", Prim_db4_db_txn_abort, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    DB_TXN * db_txn = (ARG_DB_TXN (1));
    RETURN_RC ((db_txn -> abort) (db_txn));
  }
}
