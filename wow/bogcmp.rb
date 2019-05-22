#!/usr/bin/ruby
require 'rubygems'
require 'Sqlconnect'
require 'Dbconnect'
require 'netaddr'

=begin
Legend for Status Code (0-1 reflect up/down changes, 3-5 reflect BOG discrepancies):
	-----------------------------------------
	| Code |	Details			|
	-----------------------------------------
	|   0  | DOWN, WAS UP 		|
	-----------------------------------------
	|   1  | UP, WAS DOWN			|
	-----------------------------------------
	|   2  | UP + NOT in BOG		|
	-----------------------------------------
	|   3  | DOWN + in BOG			|
	-----------------------------------------
	|   4  | NOT in WOW + in BOG		|
	-----------------------------------------
=end

#Connect SQL Server and MySQL Server
sqls = Sqlconnect.new
sqlh = sqls.connect_database
dbs = Dbconnect.new
dbh = dbs.connect_database

#Import BOG IP Addresses - Regex matches starting and trailing whitespace
slash = sqlh.select_all('select distinct IP_Address from dbo.VW_SEC_Customer')
bogips = Array.new
slash.each do |z|
   # ignore blank rows
   next unless z[0] != nil
   # rip out whitespace
   z[0].strip!
   # only add things to the array that look legit
   if(z[0].match('^(\d{1,3}\.){3}\d{1,3}$')) then
      bogips.push(NetAddr.ip_to_i(z[0]))
   end
end

#Import WOW IP Addresses
wowup=Array.new
wowdown=Array.new
# query this way (by max(id) so we always have the most recent status for
#  a given ip address
wowid = dbh.query('select max(id) from history group by ip_addr')
wowid.each do |id|
   result = dbh.query("select ip_addr, status from history where id='#{id}'")
   result.each do | ip_addr, status |
      if(status.to_i == 0) then
         wowdown.push(ip_addr.to_i)
      else
         wowup.push(ip_addr.to_i)
      end
   end
   result.free
end

# Live IPs which are not in BOG
wowup.each do |liveaddr|
   if (!bogips.include?(liveaddr))
#      puts NetAddr.i_to_ip(liveaddr) + " is up but not in BOG database!"
      dbh.query("insert into alert (ip_addr, alert_code) values (#{liveaddr}, '2')")
#   else
#      puts NetAddr.i_to_ip(liveaddr) + " is up and in BOG database!"
   end
end

# Dead IPs which are in BOG
wowdown.each do |deadaddr|
   if (bogips.include?(deadaddr))
#      puts NetAddr.i_to_ip(deadaddr) + " is down but in BOG database!"
      dbh.query("insert into alert (ip_addr, alert_code) values (#{deadaddr}, '3')")
#   else
#      puts NetAddr.i_to_ip(deadaddr) + " is down and not in BOG database!"
   end
end

# IPs in BOG which are not anywhere
bogips.each do |bogaddr|
   if (!wowdown.include?(bogaddr) && !wowup.include?(bogaddr))
#      puts NetAddr.i_to_ip(bogaddr) + " is in BOG database and I have never heard of it!"
      dbh.query("insert into alert (ip_addr, alert_code) values (#{bogaddr}, '4')")
#   else
#      puts NetAddr.i_to_ip(bogaddr) + " is in BOG database and WOW"
   end
end

#Data Sanitization
#Code 0: No action is required
#Code 1: These IP addresses exist on wire as well as in BOG
#	 Compare other fields such as Asset_Name, Alias and DNS
#Code 2: First look for other details so that just IP Address can be updated
#	 If not found, add a new entry
#Code 3: Remove Details. Manual verfication required as these could be offline
#	 resources
#Code 4: These could be networks not scanned by WOW. Scrutinize manually

#Error Handling and termination for both databases
dbs.error_handling
sqls.error_handling
