#!/usr/bin/ruby

require 'rubygems'
require 'parseconfig'
require 'crypt/blowfish'

class Crypto

  def encrypt(para)
    key = ParseConfig.new('config/key.conf')
    @key = key.get_value('key')
    blow = Crypt::Blowfish.new(@key)
    @encrypted = blow.encrypt_block(para)
    return @encrypted
  end

  def decrypt(para)
    config = ParseConfig.new('config/crypt.conf')
    key = ParseConfig.new('config/key.conf')
    @parameter = config.get_value('para')
    @key = key.get_value('key')

    blow = Crypt::Blowfish.new(@key)
    @decrypted = blow.decrypt_block(@parameter)
    return @decrypted
  end
end
