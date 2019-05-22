#!/usr/bin/ruby
=begin
This script checks for current and previous status of each IP address in history table.
If there is a change in status, it will store that IP in alert table.

NOTE: In any database table, the field has to be 'int unsigned' or bigger
Most of the IP addresses after conversion by inet_aton() go beyond standard signed int range which is 2147483647

Legend for Status Code (0-1 reflect up/down changes, 3-5 reflect BOG discrepancies):
  -----------------------------------------
  | Code |  Details     |
  -----------------------------------------
  |   0  | DOWN, WAS UP     |
  -----------------------------------------
  |   1  | UP, WAS DOWN     |
  -----------------------------------------
  |   2  | UP + NOT in BOG    |
  -----------------------------------------
  |   3  | DOWN + in BOG      |
  -----------------------------------------
  |   4  | NOT in WOW + in BOG    |
  -----------------------------------------

=end

#Required Gems
require 'rubygems'
require 'mysql'
require 'parseconfig'
require 'net/smtp'
require 'Dbconnect'
require 'Resolver'

#Connect Database
dbs = Dbconnect.new
dbh = dbs.connect_database

#Import Email Parameters
config = ParseConfig.new('config/my.conf')
sender = config.get_value('sender_email_id')
rcvr = config.get_value('receiver_email_id')
mail_server = config.get_value('mail_server')
mail_port = config.get_value('mail_port')

#IP Address Resolver Class
mydns = Resolver.new

##Contents of the message
msgstr = <<END_OF_MESSAGE
From: #{sender}
To: #{rcvr}
Subject: WoW Status Change Alert

END_OF_MESSAGE

msgstr_plus = <<THIS
Additional Alerts for Alert Code: 2, 3 and 4

THIS

#Grab all existing IDs in alert table
active_alerts = dbh.query("select id from alert where id not in " +
                          "(select alert_id from notification) order by id")

ip_status = Hash.new
active_alerts.each do |alert_id|
###FIX### make this use bind variables at some point
  ip_status[alert_id] = dbh.query("select inet_ntoa(ip_addr), time, alert_code from alert where id = #{alert_id}").fetch_row
  ### change this to check for a number of statuses including 2 (host down but active in slash)
  ###  and 3 (host up but not active in slash)
  ### would be cool to try to resolve these addresses against both NOC and (if fail)
  ###  AD DNS too!

  #Call name resolver functions
  def_dns = mydns.default(ip_status[alert_id][0])
  ad_dns = mydns.ad(ip_status[alert_id][0])

  if(ip_status[alert_id][2].to_i == 1)
    msgstr << "#{ip_status[alert_id][0]} (#{def_dns}/#{ad_dns}) was down, NOW UP (#{ip_status[alert_id][1]})\n"
  elsif(ip_status[alert_id][2].to_i == 0)
    msgstr << "#{ip_status[alert_id][0]} (#{def_dns}/#{ad_dns}) was up, NOW DOWN (#{ip_status[alert_id][1]})\n"
  elsif(ip_status[alert_id][2].to_i == 2)
    msgstr_plus << "#{ip_status[alert_id][0]} (#{def_dns}/#{ad_dns}) is UP but missing in BOG (#{ip_status[alert_id][1]})\n"
  elsif(ip_status[alert_id][2].to_i == 3)
    msgstr_plus << "#{ip_status[alert_id][0]} (#{def_dns}/#{ad_dns}) is DOWN but appears in BOG (#{ip_status[alert_id][1]})\n"
  elsif(ip_status[alert_id][2].to_i == 4)
    msgstr_plus << "#{ip_status[alert_id][0]} (#{def_dns}/#{ad_dns}) is missing in WOW but appears in BOG (#{ip_status[alert_id][1]})\n"
  end
#  puts ip_status[alert_id].fetch_row[0]
  #ip_status = dbh.prepare("select inet_ntoa(ip_addr), alert_code from alert where id = ?")
  #ip_status.execute(alert_id)    
end


msgstr << "============================================================\n"
puts msgstr

puts msgstr_plus
##Use send email method -> modify from email.rb

##Send the message
#Net::SMTP.start(mail_server, mail_port) do |smtp|
# smtp.send_message msgstr, sender, rcvr

## update the notification table

ip_status.keys.sort{|a,b| a[0].to_i<=>b[0].to_i}.each do |alert_id|
  ##USE BIND VARS!
  dbh.query("insert into notification (alert_id) values (#{alert_id})")
end

# close database connection, printing an error message if necessary
dbs.error_handling
