require 'rubygems'
require 'sequel'
require 'lib/baby_sitter'
DB = Sequel.connect('sqlite://babysittertest.db')
