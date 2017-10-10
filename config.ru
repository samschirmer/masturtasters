require 'rubygems'
require 'sinatra'
require 'active_record'
require 'sqlite3'
require 'chartkick'
require File.expand_path '../main.rb', __FILE__

run Sinatra::Application
