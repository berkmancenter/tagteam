# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# 

require 'yaml'
require 'digest/md5'

#get the Documentation class in here.
Documentation.destroy_all
docs = YAML.load(File.read("#{Rails.root}/db/documentation.yml"))
docs.each do|doc_attr|
  d = Documentation.find_or_initialize_by_match_key(doc_attr.attributes[:match_key])
  d.attributes = doc_attr.attributes
  d.save
end

shared_key_file = "#{Rails.root}/config/initializers/tagteam_shared_key.rb"
unless File.exists?(shared_key_file)
  f = File.new(shared_key_file,'w',0740)
  f.write("SHARED_KEY_FOR_TASKS='#{Digest::MD5.hexdigest(Time.now.to_s + rand(100000).to_s)}'")
  f.close
end
