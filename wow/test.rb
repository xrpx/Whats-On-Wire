#!/usr/bin/ruby

require 'rubygems'
require 'Resolver'
require 'netaddr'
mydns = Resolver.new
ip = gets.chomp 
puts mydns.default(ip)
puts mydns.ad(ip)
