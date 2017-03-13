require 'rubygems'
require 'sinatra'
require 'active_record'
require 'sqlite3'
require 'securerandom'
require 'require_all'
require_all 'models'

run Sinatra::Application
