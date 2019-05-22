#!/usr/bin/ruby
=begin
This script grabs a list of subnets separated by newline from assets.txt file in the same directory and performs ICMP ping sweep.
It then stores a list of responsive hosts to the 'history' table in 'wowdb' database.

List all the subnets in configuration file: assets.txt separated by newline.

Needs error handling functions
=end

#Required Gems
require 'rubygems'
require 'netaddr'
require 'net/ping'
include Net
require 'mysql'
require 'parseconfig'
require 'Dbconnect'

dbs = Dbconnect.new
dbh = dbs.connect_database

# PING Method to check the host upto three times
def pinger(current_ip)
   first_ping = Ping::ICMP.new("#{current_ip}", nil, 1)
   if(first_ping.ping)
#      puts "Alive..!!"
      return 1
   else
#      puts "First Dead.. Trying Second"
      second_ping = Ping::ICMP.new("#{current_ip}", nil, 1)
      if(second_ping.ping)
#         puts "Second Alive..!!"
          return 1
      else
#         puts "Second Dead.. Trying Third"
         third_ping = Ping::ICMP.new("#{current_ip}", nil, 1)
         if(third_ping.ping)
#            puts "Third Alive..!!"
             return 1
         else
#            puts "DEAD..!!"
            return nil
         end
      end
   end
end


##FIX## INDENT

##### NOT USING ANY MORE #########
#For every run, add a RESET record row in database. This shall serve as starting point in alert script
# dbh.query("insert into history (ip_addr, status) values ('0', '0')")
##### NOT USING ANY MORE #########

#Open file instance to read subnets - results is handle for local text output file for debugging
#results = File.open("results.txt", "w")
assets = File.open("config/subnet.conf", "r")

print "Starting to scan subnets!\n"

#Grab one line at a time - one subnet
while (net = assets.gets)
(
net.chomp!
#Check if starts with #(comment) and ommit from loop if yes
unless (net.match(/\A#/))
(
print " Scanning #{net}...\n"
#Create the object
ip_object = NetAddr::CIDR.create(net)
#Size of array; we don't need network IP and broadcast IP
ip_number = (ip_object.size-2)
#Array of all IPs in subnet
ip_list = ip_object.range(0, ip_object.size-1)
#For every valid IP, ping and report
(1..ip_number).each {|n|
current_ip = ip_list[n]
# pinger is the ping method
pi = pinger(current_ip)
if (pi)
  dbh.query("insert into history (ip_addr, status) values (inet_aton('#{ip_list[n]}'), '1')")
  #results.write "#{ip_list[n]} is alive\n"
  #puts "#{ip_list[n]} is alive\n"
  else
  dbh.query("insert into history (ip_addr, status) values (inet_aton('#{ip_list[n]}'), '0')")
  # results.write "#{ip_list[n]} is dead\n"
  #puts "#{ip_list[n]} is dead\n"
end
}
)
end
)
end

print "Subnet scan complete!\n"

#results.close
assets.close

# close database connection, printing an error message if necessary
dbs.error_handling
