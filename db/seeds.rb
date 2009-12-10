# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

Practitioner.create(:first_name => "David", :last_name => "Savage", :permalink => "david-savage", :email => "sav@beamazing.co.nz",
                    :password => "secret", :password_confirmation => "secret", :biz_hours_start => "8", :biz_hours_end => "18", 
                    :working_days => "1,2,3,4" )
Practitioner.create(:first_name => "Megan", :last_name => "Savage", :permalink => "megan-savage", :email => "megan@beamazing.co.nz",
                    :password => "secret", :password_confirmation => "secret", :biz_hours_start => "8", :biz_hours_end => "18", 
                    :working_days => "4,5" )

