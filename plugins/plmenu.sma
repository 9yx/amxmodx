/* AMX Mod X
*   Players Menu Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx> 

new g_menuPosition[33]
new g_menuPlayers[33][32]
new g_menuPlayersNum[33]
new g_menuOption[33]
new g_menuSettings[33]

new g_menuSelect[33][64]
new g_menuSelectNum[33]

#define MAX_CLCMDS 24

new g_clcmdName[MAX_CLCMDS][32]
new g_clcmdCmd[MAX_CLCMDS][64]
new g_clcmdMisc[MAX_CLCMDS][2]
new g_clcmdNum

new g_cstrikeRunning

public plugin_init()
{
  register_plugin("Players Menu","0.1","AMXX Dev Team")
  register_clcmd("amx_kickmenu","cmdKickMenu",ADMIN_KICK,"- displays kick menu")
  register_clcmd("amx_banmenu","cmdBanMenu",ADMIN_BAN,"- displays ban menu")
  register_clcmd("amx_slapmenu","cmdSlapMenu",ADMIN_SLAY,"- displays slap/slay menu")   
  register_clcmd("amx_teammenu","cmdTeamMenu",ADMIN_LEVEL_A,"- displays team menu")    
  register_clcmd("amx_clcmdmenu","cmdClcmdMenu",ADMIN_LEVEL_A,"- displays client cmds menu")     

  register_menucmd(register_menuid("Ban Menu"),1023,"actionBanMenu")
  register_menucmd(register_menuid("Kick Menu"),1023,"actionKickMenu")
  register_menucmd(register_menuid("Slap/Slay Menu"),1023,"actionSlapMenu")
  register_menucmd(register_menuid("Team Menu"),1023,"actionTeamMenu")
  register_menucmd(register_menuid("Client Cmds Menu"),1023,"actionClcmdMenu")   

  g_cstrikeRunning = is_running("cstrike")

  new filename[64]
  build_path( filename , 63 , "$basedir/configs/clcmds.ini" )  
  load_settings( filename )
}

/* Ban menu */

public actionBanMenu(id,key)
{
  switch(key){
  case 7:{
      ++g_menuOption[id]
      g_menuOption[id] %= 3
      
      switch(g_menuOption[id]){
      case 0: g_menuSettings[id] = 0
      case 1: g_menuSettings[id] = 5
      case 2: g_menuSettings[id] = 60
      }     
      
      displayBanMenu(id,g_menuPosition[id])
    }
  case 8: displayBanMenu(id,++g_menuPosition[id])
  case 9: displayBanMenu(id,--g_menuPosition[id])
  default:{
      new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]
      
      new name[32], name2[32], authid[32],authid2[32]
      get_user_name(player,name2,31)
      get_user_authid(id,authid,31)
      get_user_authid(player,authid2,31)
      get_user_name(id,name,31)
      new userid2 = get_user_userid(player)
          
      log_amx("Ban: ^"%s<%d><%s><>^" ban and kick ^"%s<%d><%s><>^" (minutes ^"%d^")", 
        name,get_user_userid(id),authid, name2,userid2,authid2, g_menuSettings[id] )
    
      switch(get_cvar_num("amx_show_activity")) {
      case 2: client_print(0,print_chat,"ADMIN %s: ban %s",name,name2)
      case 1: client_print(0,print_chat,"ADMIN: ban %s",name2)
      }
      
      if (equal("4294967295",authid2)){ /* lan */
        new ipa[32]
        get_user_ip(player,ipa,31,1)
        server_cmd("addip %d %s;writeip",g_menuSettings[id],ipa)
      }
      else
        server_cmd("banid %d #%d kick;writeid",g_menuSettings[id],userid2)
        
      server_exec()
      
      displayBanMenu(id,g_menuPosition[id])
    }
  }
  return PLUGIN_HANDLED
}


displayBanMenu(id,pos){

  if (pos < 0)  return
    
  get_players(g_menuPlayers[id],g_menuPlayersNum[id])
    
  new menuBody[512]
  new b = 0
  new i
  new name[32]
  new start = pos * 7
  
  if (start >= g_menuPlayersNum[id])
    start = pos = g_menuPosition[id] = 0
    
  new len = format(menuBody,511, g_cstrikeRunning ? 
    "\yBan Menu\R%d/%d^n\w^n" : "Ban Menu %d/%d^n^n",
    pos+1,(  g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0 )) )
    
  new end = start + 7
  new keys = (1<<9)|(1<<7)
  
  if (end > g_menuPlayersNum[id])
    end = g_menuPlayersNum[id]
    
  for(new a = start; a < end; ++a)
  {
    i = g_menuPlayers[id][a]
    get_user_name(i,name,31)
    
    if ( is_user_bot(i) || (get_user_flags(i)&ADMIN_IMMUNITY) )
    {
      ++b   
      if ( g_cstrikeRunning )
        len += format(menuBody[len],511-len,"\d%d. %s^n\w",b,name)
      else
        len += format(menuBody[len],511-len,"#. %s^n",name)

    }
    else
    {
      keys |= (1<<b)
      len += format(menuBody[len],511-len,"%d. %s^n",++b,name)
    }
  }
  
  if ( g_menuSettings[id] )
    len += format(menuBody[len],511-len,"^n8. Ban for %d minutes^n" , g_menuSettings[id] )
  else
    len += format(menuBody[len],511-len,"^n8. Ban permanently^n" )
  
  if (end != g_menuPlayersNum[id])
  {
    format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Exit")
    keys |= (1<<8)
  }
  else format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")
  
  show_menu(id,keys,menuBody)
}

public cmdBanMenu(id,level,cid)
{
  if (!cmd_access(id,level,cid,1))  return PLUGIN_HANDLED
    
  g_menuOption[id] = 1
  g_menuSettings[id] = 5
  displayBanMenu(id,g_menuPosition[id] = 0)
  
  return PLUGIN_HANDLED 
}

/* Slap/Slay */

public actionSlapMenu(id,key)
{
  switch(key){
  case 7:{
      ++g_menuOption[id]
      g_menuOption[id] %= 4
      switch(g_menuOption[id]){
      case 1: g_menuSettings[id] = 0
      case 2: g_menuSettings[id] = 1
      case 3: g_menuSettings[id] = 5
      }
      displaySlapMenu(id,g_menuPosition[id])
    }
  case 8: displaySlapMenu(id,++g_menuPosition[id])
  case 9: displaySlapMenu(id,--g_menuPosition[id])
  default:{
      new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]
      
      new name2[32]
      get_user_name(player,name2,31)
      
      if (!is_user_alive(player))
      {
        client_print(id,print_chat,"That action can't be performed on dead client ^"%s^"",name2)
        displaySlapMenu(id,g_menuPosition[id])
        return PLUGIN_HANDLED
      }
            
      new authid[32],authid2[32], name[32]

      get_user_authid(id,authid,31)
      get_user_authid(player,authid2,31)
      get_user_name(id,name,31)
        
      if ( g_menuOption[id] ) {
        log_amx("Cmd: ^"%s<%d><%s><>^" slap with %d damage ^"%s<%d><%s><>^"", 
          name,get_user_userid(id),authid, g_menuSettings[id], name2,get_user_userid(player),authid2 )
        switch(get_cvar_num("amx_show_activity")) {
        case 2: client_print(0,print_chat,"ADMIN %s: slap %s with %d damage",name,name2,g_menuSettings[id])
        case 1: client_print(0,print_chat,"ADMIN: slap %s with %d damage",name2,g_menuSettings[id])
        }     
      }
      else {
        log_amx("Cmd: ^"%s<%d><%s><>^" slay ^"%s<%d><%s><>^"", 
          name,get_user_userid(id),authid, name2,get_user_userid(player),authid2 )
        switch(get_cvar_num("amx_show_activity")) {
        case 2: client_print(0,print_chat,"ADMIN %s: slay %s",name,name2)
        case 1: client_print(0,print_chat,"ADMIN: slay %s",name2)
        }
      }
      
      if ( g_menuOption[id])
        user_slap(player, ( get_user_health(player) >  g_menuSettings[id]  ) ? g_menuSettings[id] : 0 )
      else
        user_kill( player )
      
      displaySlapMenu(id,g_menuPosition[id])
    }
  }
  return PLUGIN_HANDLED
}


displaySlapMenu(id,pos){

  if (pos < 0)  return
    
  get_players(g_menuPlayers[id],g_menuPlayersNum[id])
    
  new menuBody[512]
  new b = 0
  new i
  new name[32], team[4]
  new start = pos * 7
  
  if (start >= g_menuPlayersNum[id])
    start = pos = g_menuPosition[id] = 0
    
  new len = format(menuBody,511, g_cstrikeRunning ? 
    "\ySlap/Slay Menu\R%d/%d^n\w^n" : "Slap/Slay Menu %d/%d^n^n" ,
    pos+1,(  g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0 )) )
    
  new end = start + 7
  new keys = (1<<9)|(1<<7)
  
  if (end > g_menuPlayersNum[id])
    end = g_menuPlayersNum[id]
    
  for(new a = start; a < end; ++a)
  {
    i = g_menuPlayers[id][a]
    get_user_name(i,name,31)
    get_user_team(i,team,3)
    
    if ( !is_user_alive(i) || (get_user_flags(i)&ADMIN_IMMUNITY) )
    {
      ++b   
      if ( g_cstrikeRunning )
        len += format(menuBody[len],511-len,"\d%d. %s\R%s^n\w", b,name,team)
      else
        len += format(menuBody[len],511-len,"#. %s   %s^n",name,team)

    }
    else
    {
      keys |= (1<<b)
      
      len += format(menuBody[len],511-len, g_cstrikeRunning ? 
        "%d. %s\y\R%s^n\w" : "%d. %s   %s^n",++b,name,team)
    }
  }
    
  if ( g_menuOption[id]  )
    len += format(menuBody[len],511-len,"^n8. Slap with %d damage^n",g_menuSettings[id] )
  else
    len += format(menuBody[len],511-len,"^n8. Slay^n")
  
  if (end != g_menuPlayersNum[id])
  {
    format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Exit")
    keys |= (1<<8)
  }
  else format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")
  
  show_menu(id,keys,menuBody)
}

public cmdSlapMenu(id,level,cid)
{
  if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
    
  g_menuOption[id] = 0
  g_menuSettings[id] = 0
  
  displaySlapMenu(id,g_menuPosition[id] = 0)
  
  return PLUGIN_HANDLED 
}

/* Kick */

public actionKickMenu(id,key)
{
  switch(key){
  case 8: displayKickMenu(id,++g_menuPosition[id])
  case 9: displayKickMenu(id,--g_menuPosition[id])
  default:{
      new player = g_menuPlayers[id][g_menuPosition[id] * 8 + key]
                  
      new authid[32],authid2[32], name[32], name2[32]
      get_user_authid(id,authid,31)
      get_user_authid(player,authid2,31)
      get_user_name(id,name,31)
      get_user_name(player,name2,31)      
      new userid2 = get_user_userid(player)
        
      log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>^"", 
          name,get_user_userid(id),authid, name2,userid2,authid2 )
          
      switch(get_cvar_num("amx_show_activity")) {
      case 2: client_print(0,print_chat,"ADMIN %s: kick %s",name,name2)
      case 1: client_print(0,print_chat,"ADMIN: kick %s",name2)
      }
      
      server_cmd("kick #%d",userid2)
      server_exec()
            
      displayKickMenu(id,g_menuPosition[id])
    }
  }
  return PLUGIN_HANDLED
}


displayKickMenu(id,pos){

  if (pos < 0)  return
    
  get_players(g_menuPlayers[id],g_menuPlayersNum[id])
    
  new menuBody[512]
  new b = 0
  new i
  new name[32]
  new start = pos * 8
  
  if (start >= g_menuPlayersNum[id])
    start = pos = g_menuPosition[id] = 0
    
  new len = format(menuBody,511, g_cstrikeRunning ?
    "\yKick Menu\R%d/%d^n\w^n" : "Kick Menu %d/%d^n^n",
    pos+1,(  g_menuPlayersNum[id] / 8 + ((g_menuPlayersNum[id] % 8) ? 1 : 0 )) )
    
  new end = start + 8
  new keys = (1<<9)
  
  if (end > g_menuPlayersNum[id])
    end = g_menuPlayersNum[id]
    
  for(new a = start; a < end; ++a)
  {
    i = g_menuPlayers[id][a]
    get_user_name(i,name,31)
    
    if ( get_user_flags(i) & ADMIN_IMMUNITY )
    {
      ++b   
      if ( g_cstrikeRunning )
        len += format(menuBody[len],511-len,"\d%d. %s^n\w",b,name)
      else
        len += format(menuBody[len],511-len,"#. %s^n",name)

    }
    else
    {
      keys |= (1<<b)
      len += format(menuBody[len],511-len,"%d. %s^n",++b,name)
    }
  }
      
  if (end != g_menuPlayersNum[id])
  {
    format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Exit")
    keys |= (1<<8)
  }
  else  format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")
  
  show_menu(id,keys,menuBody)
}

public cmdKickMenu(id,level,cid)
{
  if (cmd_access(id,level,cid,1))
    displayKickMenu(id,g_menuPosition[id] = 0)
  
  return PLUGIN_HANDLED 
}

/* Team menu */

public actionTeamMenu(id,key)
{
  switch(key){
  case 7:{
      g_menuOption[id] = 1 - g_menuOption[id]
      displayTeamMenu(id,g_menuPosition[id])
    }
  case 8: displayTeamMenu(id,++g_menuPosition[id])
  case 9: displayTeamMenu(id,--g_menuPosition[id])
  default:{
      new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]
      new authid[32],authid2[32], name[32], name2[32]
      get_user_name(player,name2,31)
      get_user_authid(id,authid,31)
      get_user_authid(player,authid2,31)
      get_user_name(id,name,31)
      
      log_amx("Cmd: ^"%s<%d><%s><>^" transfer ^"%s<%d><%s><>^" (team ^"%s^")", 
          name,get_user_userid(id),authid, name2,get_user_userid(player),authid2, g_menuOption[id] ? "TERRORIST" : "CT"  )
      
      switch(get_cvar_num("amx_show_activity")) {
      case 2: client_print(0,print_chat,"ADMIN %s: transfer %s to %s",name,name2,g_menuOption[id] ? "TERRORIST" : "CT" )
      case 1: client_print(0,print_chat,"ADMIN: transfer %s to %s",name2,g_menuOption[id] ? "TERRORIST" : "CT" )
      }
      
      new limitt = get_cvar_num("mp_limitteams")
      set_cvar_num("mp_limitteams",0)
      user_kill(player,1)
      engclient_cmd(player, "chooseteam")
      engclient_cmd(player, "menuselect", g_menuOption[id] ?  "1" : "2" )
      engclient_cmd(player, "menuselect", "5")
      client_cmd(player,"slot1")
      set_cvar_num("mp_limitteams",limitt)
      
      displayTeamMenu(id,g_menuPosition[id])
    }
  }
  return PLUGIN_HANDLED
}


displayTeamMenu(id,pos){

  if (pos < 0)  return
    
  get_players(g_menuPlayers[id],g_menuPlayersNum[id])
    
  new menuBody[512]
  new b = 0
  new i, iteam
  new name[32], team[4]
  new start = pos * 7
  
  if (start >= g_menuPlayersNum[id])
    start = pos = g_menuPosition[id] = 0
    
  new len = format(menuBody,511, g_cstrikeRunning ? 
    "\yTeam Menu\R%d/%d^n\w^n" : "Team Menu %d/%d^n^n",
    pos+1,(  g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0 )) )
    
  new end = start + 7
  new keys = (1<<9)|(1<<7)
  
  if (end > g_menuPlayersNum[id])
    end = g_menuPlayersNum[id]
    
  for(new a = start; a < end; ++a)
  {
    i = g_menuPlayers[id][a]
    get_user_name(i,name,31)
    iteam = get_user_team(i,team,3)
    
    if ( (iteam == (g_menuOption[id] ? 1 : 2))  || (get_user_flags(i)&ADMIN_IMMUNITY) )
    {
      ++b   
      if ( g_cstrikeRunning )
        len += format(menuBody[len],511-len,"\d%d. %s\R%s^n\w",b,name,team)
      else
        len += format(menuBody[len],511-len,"#. %s   %s^n",name,team)

    }
    else
    {
      keys |= (1<<b)
      len += format(menuBody[len],511-len, g_cstrikeRunning ? 
        "%d. %s\y\R%s^n\w" : "%d. %s   %s^n",++b,name,team)
    }
  }
    
  len += format(menuBody[len],511-len,"^n8. Transfer to %s^n",g_menuOption[id] ? "TERRORIST" : "CT" )
  
  if (end != g_menuPlayersNum[id])
  {
    format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Exit")
    keys |= (1<<8)
  }
  else format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")
  
  show_menu(id,keys,menuBody)
}

public cmdTeamMenu(id,level,cid)
{
  if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
    
  g_menuOption[id] = 0

  displayTeamMenu(id,g_menuPosition[id] = 0)
  
  return PLUGIN_HANDLED 
}

/* Client cmds menu */

public actionClcmdMenu(id,key)
{
  switch(key){
  case 7:{
      ++g_menuOption[id]
      g_menuOption[id] %= g_menuSelectNum[id]
      displayClcmdMenu(id,g_menuPosition[id])
    }
  case 8: displayClcmdMenu(id,++g_menuPosition[id])
  case 9: displayClcmdMenu(id,--g_menuPosition[id])
  default:{
      new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]
      new flags = g_clcmdMisc[g_menuSelect[id][g_menuOption[id]]][1]
      if (is_user_connected(player)) {
        new command[64], authid[32], name[32], userid[32]
        copy(command,63,g_clcmdCmd[g_menuSelect[id][g_menuOption[id]]])
        get_user_authid(player,authid,31)
        get_user_name(player,name,31)
        numtostr(get_user_userid(player),userid,31)
        replace(command,63,"%userid%",userid)
        replace(command,63,"%authid%",authid)
        replace(command,63,"%name%",name)
        if (flags & 1){
          server_cmd(command)
          server_exec()
        }
        else if (flags & 2)
          client_cmd(id,command)
        else if (flags & 4)
          client_cmd(player,command)
      }
      if (flags & 8)  displayClcmdMenu(id,g_menuPosition[id])
    }
  }
  return PLUGIN_HANDLED
}


displayClcmdMenu(id,pos){

  if (pos < 0)  return
    
  get_players(g_menuPlayers[id],g_menuPlayersNum[id])
    
  new menuBody[512]
  new b = 0
  new i
  new name[32]
  new start = pos * 7
  
  if (start >= g_menuPlayersNum[id])
    start = pos = g_menuPosition[id] = 0
    
  new len = format(menuBody,511, g_cstrikeRunning ? 
    "\yClient Cmds Menu\R%d/%d^n\w^n" : "Client Cmds Menu %d/%d^n^n",
    pos+1,(  g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0 )) )
    
  new end = start + 7
  new keys = (1<<9)|(1<<7)
  
  if (end > g_menuPlayersNum[id])
    end = g_menuPlayersNum[id]
    
  for(new a = start; a < end; ++a)
  {
    i = g_menuPlayers[id][a]
    get_user_name(i,name,31)
    
    if ( !g_menuSelectNum[id] || get_user_flags(i)&ADMIN_IMMUNITY )
    {
      ++b   
      if ( g_cstrikeRunning )
        len += format(menuBody[len],511-len,"\d%d. %s^n\w",b,name)
      else
        len += format(menuBody[len],511-len,"#. %s^n",name)

    }
    else
    {
      keys |= (1<<b)
      len += format(menuBody[len],511-len,"%d. %s^n",++b,name)
    }
  }
    
  if ( g_menuSelectNum[id] )
    len += format(menuBody[len],511-len,"^n8. %s^n", g_clcmdName[g_menuSelect[id][g_menuOption[id]]] )
  else
    len += format(menuBody[len],511-len,"^n8. No cmds available^n")
  
  if (end != g_menuPlayersNum[id])
  {
    format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Exit")
    keys |= (1<<8)
  }
  else format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")
  
  show_menu(id,keys,menuBody)
}

public cmdClcmdMenu(id,level,cid)
{
  if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
  
  new flags = get_user_flags(id)
  
  g_menuSelectNum[id] = 0
  
  for(new a = 0; a < g_clcmdNum; ++a)
    if (g_clcmdMisc[a][0] & flags)
      g_menuSelect[id][g_menuSelectNum[id]++] = a
  
  g_menuOption[id] = 0
    
  displayClcmdMenu(id,g_menuPosition[id] = 0)
  
  return PLUGIN_HANDLED
}

load_settings( szFilename[] )
{

  if ( !file_exists ( szFilename ) ) 
    return 0
  
  new text[256], szFlags[32], szAccess[32]
  new a,  pos = 0
  
  while ( g_clcmdNum < MAX_CLCMDS && read_file (szFilename,pos++,text,255,a) )
  {
    if ( text[0] == ';' ) continue
      
    if ( parse( text , g_clcmdName[g_clcmdNum] , 31 ,
      g_clcmdCmd[g_clcmdNum] ,63,szFlags,31,szAccess,31 ) > 3 )
    {     
      while ( replace( g_clcmdCmd[ g_clcmdNum ] ,63,"\'","^"") ) {
          // do nothing
      }
      
      g_clcmdMisc[ g_clcmdNum ][1] = read_flags ( szFlags )
      g_clcmdMisc[ g_clcmdNum ][0] = read_flags ( szAccess )
      g_clcmdNum++  
    }
  }
  
  return 1
}