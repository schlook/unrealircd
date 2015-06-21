/*
 * No kicks in channel UnrealIRCd Module (Channel Mode +Q)
 * (C) Copyright 2014 Travis McArthur (Heero) and the UnrealIRCd team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 1, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "config.h"
#include "struct.h"
#include "common.h"
#include "sys.h"
#include "numeric.h"
#include "msg.h"
#include "proto.h"
#include "channel.h"
#include <time.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <io.h>
#endif
#include <fcntl.h>
#include "h.h"
#ifdef _WIN32
#include "version.h"
#endif


ModuleHeader MOD_HEADER(nokick)
  = {
	"chanmodes/nokick",
	"$Id$",
	"Channel Mode +Q",
	"3.2-b8-1",
	NULL 
    };

Cmode_t EXTCMODE_NOKICK;

#define IsNoKick(chptr)    (chptr->mode.extmode & EXTCMODE_NOKICK)

int nokick_check (aClient* sptr, aClient* who, aChannel *chptr, char* comment, long sptr_flags, long who_flags, char **reject_reason);

DLLFUNC int MOD_TEST(nokick)(ModuleInfo *modinfo)
{
	return MOD_SUCCESS;
}

DLLFUNC int MOD_INIT(nokick)(ModuleInfo *modinfo)
{
	CmodeInfo req;

	memset(&req, 0, sizeof(req));
	req.paracount = 0;
	req.flag = 'Q';
	req.is_ok = extcmode_default_requirechop;
	CmodeAdd(modinfo->handle, req, &EXTCMODE_NOKICK);
	
	HookAddEx(modinfo->handle, HOOKTYPE_CAN_KICK, nokick_check);

	
	MARK_AS_OFFICIAL_MODULE(modinfo);
	return MOD_SUCCESS;
}

DLLFUNC int MOD_LOAD(nokick)(int module_load)
{
	return MOD_SUCCESS;
}

DLLFUNC int MOD_UNLOAD(nokick)(int module_unload)
{
	return MOD_SUCCESS;
}

int nokick_check (aClient* sptr, aClient* who, aChannel *chptr, char* comment, long sptr_flags, long who_flags, char **reject_reason)
{
	static char errmsg[256];

	if (MyClient(sptr) && IsNoKick(chptr))
	{
		ircsnprintf(errmsg, sizeof(errmsg), err_str(ERR_CANNOTDOCOMMAND),
				   me.name, sptr->name, "KICK",
				   "channel is +Q");
		*reject_reason = errmsg;
		return EX_DENY; /* Deny, but let opers override if necessary. */
	}

	return EX_ALLOW;
}

