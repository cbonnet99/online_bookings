# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

Country.create(:is_default => true, :country_code => "FR", :locale => "FR", :mobile_phone_prefixes_list => "06,07",
 :landline_phone_prefixes_list => "01,02,03,04,05,08,09",  :sample_first_names => "Jean,Marie,Ben,Marius,Edith,Laurent,Mo,Lise,Jean-Pierre,Theo",
 :sample_last_names => "Martin,Souza,Marcos,Durand,Adjani,Pujol,Cerdan,Hernin,Lindon", :timezones => "Paris")

Country.create(:is_default => false, :country_code => "NZ", :locale => "EN", :mobile_phone_prefixes_list => "021,022,027,029",
  :landline_phone_prefixes_list => "03,04,06,07,09",  :sample_first_names => "Liz,Mary,Josh,Ed,Warren,John,Megan,David,Tane",
  :sample_last_names => "Martin,Whenua,Marcos,Yi,Johnson,Jackson,Mana,Batista", :timezones => "Wellington")