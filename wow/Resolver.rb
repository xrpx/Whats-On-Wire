#!/usr/bin/ruby

require 'rubygems'
require 'resolv'
require 'netaddr'

class Resolver

   def default(ip)
   begin
     if (ip=~ /10.10.10.[0-2]?[0-9]?[0-9]/)
       # Integer for 10.10.10.0 -> subtraction gives last octet
       # Looking for >2 because .1 and .2 are firewall interfaces with
       # DNS set up for 10.10.10.1/2
       octet = NetAddr.ip_to_i(ip) - 169886976
#       if (octet > 2)
         ip = "10.10.10.#{octet}"
#       end
       return Resolv.new.getname("#{ip}")
     else
      # Default DNS Query
       return Resolv.new.getname("#{ip}")
     end
   rescue
      @error = "No entry found in Default DNS"
      return @error
   end
   end

   def ad(ip)
   begin
      # AD Server DNS Query 
      if (ip=~ /10.10.10.[0-2]?[0-9]?[0-9]/)
       octet = NetAddr.ip_to_i(ip) - 169886976
#        if (octet > 2)
          ip = "10.10.10.#{octet}"
#        end
          Resolv::DNS.open({:nameserver=>["10.10.10.10","10.10.10.11"]}) do |dns|
          return dns.getname("#{ip}")
        end
      else
       Resolv::DNS.open({:nameserver=>["10.10.10.10","10.10.10.11"]}) do |dns|
         return dns.getname("#{ip}")
       end

     end

   rescue
      @error = "No entry found in AD DNS"
      return @error
   end
   end

end
