#!/usr/bin/ruby
=begin
This script checks for current and previous status of each IP address in history table.
If there is a change in status, it will store that IP in alert table.

NOTE: In any database table, the field has to be 'int unsigned' or bigger
Most of the IP addresses after conversion by inet_aton() go beyond standard signed int range which is 2147483647 

=end

#Required Gems
require 'rubygems'
require 'mysql'
require 'parseconfig'
require 'Dbconnect'

dbs = Dbconnect.new
dbh = dbs.connect_database

##FIX## INDENT
  print "Starting audit against IP addresses in database\n"

  # Get IP Address list
  ip_array = dbh.query("select distinct ip_addr from history")

  print " Checking for changes in status and things not in slash\n"

  #Thats the array for current active IPs to loop and check for alerts
  ip_array.each do |ip_addr|

    # Query database for latest and previous status. 
    # results will come in with the most recent check first, then the next most recent check
    status = dbh.query("select status from history where ip_addr = #{ip_addr} order by id desc limit 2") 
    #### if we move to getting list by subnet, first check for no results for an addr
    results = Array.new
    status.each do |x|
      results.push(x[0])
    end
    status.free
    if((results.length > 1) && results[0] != results[1])
      # something changed and we need to alert
      if(results[0].to_i == 1)
        # puts "was down, now up"
        dbh.query("insert into alert (ip_addr, alert_code) values (#{ip_addr}, 1)")
      else
        # puts "was up, now down"
        dbh.query("insert into alert (ip_addr, alert_code) values (#{ip_addr}, 0)")
      end
    else ## if results.length > 0 # ensure there is something there
      ##check results[0]
      ## if it's 0 (down) make sure that ip address isn't in slash
      ##   if it is in slash, add a row to the alert table with status 2
      ## if it's 1 (up) make sure that ip address is in slash
      ##   if it is not in slash, add a row to the alert table with status 3
    end
    #### if it's up (results[0].to_i == 1) check slash to make sure it's in here, if not, alert
  end
  #### check slash to make sure it doesn't know about things not on the wire
  ####  (not just ok to see if it's here, needs to be here and results[0].to_i == 1)
  # print " Checking for things in slash not on the wire\n"

  print "Audit complete\n"

# close database connection, printing an error message if necessary
dbs.error_handling
