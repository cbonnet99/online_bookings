# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

Practitioner.create(:first_name => "David", :last_name => "Savage", :permalink => "david-savage", :email => "sav@beamazing.co.nz",
                    :password => "secret", :password_confirmation => "secret", :working_hours => "9-10,10:30-11:30,12-1,1:30-2:30,3-4,4:30-5:30", 
                    :working_days => "1,3" )
Practitioner.create(:first_name => "Megan", :last_name => "Savage", :permalink => "megan-savage", :email => "megan@beamazing.co.nz",
                    :password => "secret", :password_confirmation => "secret", :working_hours => "9-10,10:30-11:30,12-1,1:30-2:30,3-4,4:30-5:30", 
                    :working_days => "2,4" )

