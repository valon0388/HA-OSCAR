#! /usr/bin/env python
#
# Copyright (c) 2009 Okoye Chuka D. <okoye9@gmail.com>  
#                    All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

import os
import sys
sys.path.append("../")
import commands
import halib.Env as env
import halib.Logger as logger
import halib.chaif.Chaif as chaif
import halib.chaif.DatabaseDriver as ddriver
import halib.hatci.Heartbeat as heartbeat
import halib.hatci.DataSynchronization as datasync
import halib.Exit as exit

logger.initialize()

#We try to run a system sanity check
logger.section("HAOSCAR Installation Wizard Running")

logger.section("System Sanity Checks")

if(chaif.sanityCheck() !=  0):
	logger.subsection("sanity check failed, terminating installation")
	exit.open()
logger.subsection("sanity check completed, proceeding to next step")

#We set our environment variables in here
logger.section("Environment Configuration")
env.configureEnvironment()

#Next, we generate system configuration facts to be stored in DB
logger.section("Gathering System Config Info")
sys_config = dict()
sys_config = chaif.systemConfigurator()

#Time to setup our databases and populate it.
logger.section("Database Initialization")
chaif.databaseSetup()

logger.subsection("populating database")
ddriver.insert_db('hainfo',sys_config)

#We start with the HATCI
logger.section("HATCI Setup")
logger.section("Heartbeat Configuration")

if(heartbeat.configure() != 0):
	logger.subsection("heartbeat config failed prematurely, terminating installation")
	

