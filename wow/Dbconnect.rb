#!/usr/bin/ruby

require 'mysql'
require 'parseconfig'

class Dbconnect
#require 'mysql'
#require 'parseconfig'

   def initialize()
   end

   def connect_database()
   #Import Database Connectivity Parameters from config file
   @config = ParseConfig.new('config/my.conf')

   @db_host = @config.get_value('db_host')
   @db_user = @config.get_value('db_user')
   @db_pass = @config.get_value('db_pass')
   @db = @config.get_value('db')

   #Open Database Instance

     # connect to the MySQL server
     @dbc = Mysql.real_connect(@db_host, @db_user, @db_pass, @db)
     return @dbc
   end

#   def get_server_info()
#     # get server version string and display it
#      @dbc.get_server_info
#   end

   def error_handling()
   #Database Error Handling
     rescue Mysql::Error => e
       puts "Error code: #{e.errno}"
       puts "Error message: #{e.error}"
       puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
     ensure
    # disconnect from server
     @dbc.close if @dbc
   end

end
