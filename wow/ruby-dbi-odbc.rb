#!/usr/bin/ruby
require 'rubygems'
require 'dbi'

# Replace MY_DSN with the name of your ODBC data
# source. Replace and dbusername with dbpassword with
# your database login name and password.
dbname = "SLASH"
DBI.connect("dbi:ODBC:#{dbname}", '', '') do | dbh |
   # Replace mytable with the name of a table in your database.
   dbh.select_all('select distinct ip_address from dbo.vw_sec_Customer') do | row |
      p row
   end
end

