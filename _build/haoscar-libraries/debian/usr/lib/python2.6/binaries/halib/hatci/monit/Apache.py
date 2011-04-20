#! /usr/bin/env python
#
# Copyright (c) 2010 Okoye Chuka D.<okoye9@gmail.com>        
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

if os.path.isfile("/etc/redhat-release"):
	configuration = """
	check process apache with pidfile /var/run/apache2.pid
	start program = "/etc/init.d/httpd start"
	stop program = "/etc/init.d/httpd stop"
	if 5 restarts within 5 cycles then timeout

	check file apachepid with path /var/run/apache2.pid
	if changed timestamp for 4 cycles then exec "/bin/sh /usr/bin/fail-over"
	"""
else:
	configuration = """
	check process apache with pidfile /var/run/apache2.pid
	start program = "/etc/init.d/apache2 start"
	stop program = "/etc/init.d/apache2 stop"
	if 5 restarts within 5 cycles then timeout

	check file apachepid with path /var/run/apache2.pid
	if changed timestamp for 4 cycles then exec "/bin/sh /usr/bin/fail-over"
	"""

def configure():
	return configuration
