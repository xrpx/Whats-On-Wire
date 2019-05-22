#!/usr/bin/ruby

#Required Gems
require 'rubygems'
require 'mysql'
require 'parseconfig'
require 'Dbconnect'

dbs = Dbconnect.new
dbh = dbs.connect_database

#Restore database dump from file wowdb.sql in same directory
dump_data = `mysqldump -u #{db_admin} -p #{db_admin_pass} #{db} < db/wowdb.sql`

puts dbs.error_handling
