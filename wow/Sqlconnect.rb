#!/usr/bin/ruby
require 'rubygems'
require 'dbi'
require 'parseconfig'

class Sqlconnect
  def initialize()
  end

  def connect_database()
    #Import Database Connectivity Parameters from config file
    @config = ParseConfig.new('config/my.conf')
    
    @dsn = @config.get_value('my_dsn')
    @user = @config.get_value('my_user')
    @pass = @config.get_value('my_pass')
 
    @dbc = DBI.connect("dbi:ODBC:#{@dsn}", "#{@user}", "#{@pass}")
    return @dbc
  end

  def error_handling()
    #Database Error Handling
    rescue DBI::DatabaseError => e
      puts "An error occurred"
      puts "Error code:    #{e.err}"
      puts "Error message: #{e.errstr}"
      puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
      @dbc.rollback
    ensure
      # disconnect from server
      @dbc.disconnect if @dbc
  end

end
