# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

fr = Country.create(:is_default => true, :country_code => "FR", :name => "France", :locale => "FR", :mobile_phone_prefixes_list => "06,07",
 :landline_phone_prefixes_list => "01,02,03,04,05,08,09",  :sample_first_names => "Jean,Marie,Ben,Marius,Edith,Olivier,Mo,Lise,Jean-Pierre,Theo",
 :sample_last_names => "Martin,Souza,Marcos,Durand,Bonnet,Pujol,Cerdan,Hernin,Lindon", :timezones => "Paris",
 :demo_first_name => "Léa", :demo_last_name => "Martin", :demo_phone => "01 22 33 44 55", :demo_email => "lea@test.fr",
 :demo_password => "demo", :time_slots => "1h,2h,3h,4h,5h,6h,7h,8h,9h,10h,11h,Midi,13h,14h,15h,16h,17h,18h,19h,20h,21h,22h,23h,Minuit",
 :default_start_time1 => 8, :default_end_time1 => 12, :default_start_time2 => 14, :default_end_time2 => 18,
 :currency  => "EUR", :currency_symbol  => "EUR", :currency_before  => false
 )

 PaymentPlan.create(:country => fr, :amount => "1495", :title => "Emails",
   :description =>  "<ul><li>Rappels par emails illimités</li><li>Pas de rappels par SMS</li></ul>")

 PaymentPlan.create(:country => fr, :amount => "2495", :title => "Mini",
   :description =>  "<ul><li>Rappels par emails illimités</li><li><b>50</b> rappels par SMS chaque mois</li></ul>", :sms_credit => 50)

 PaymentPlan.create(:country => fr, :amount => "3995", :title => "Premium",
   :description =>  "<ul><li>Rappels par emails illimités</li><li><b>200</b> rappels par SMS chaque mois</li></ul>", :sms_credit => 200, :highlighted => true)

 PaymentPlan.create(:country => fr, :amount => "9995", :title => "Maxi",
   :description =>  "<ul><li>Rappels par emails illimités</li><li><b>500</b> rappels par SMS chaque mois</li></ul>", :sms_credit => 500)


nz = Country.create(:is_default => false, :country_code => "NZ", :name => "New Zealand",  :locale => "EN", :mobile_phone_prefixes_list => "021,022,027,029",
  :landline_phone_prefixes_list => "03,04,06,07,09",  :sample_first_names => "Liz,Mary,Josh,Ed,Warren,John,Megan,David,Tane",
  :sample_last_names => "Martin,Whenua,Marcos,Yi,Johnson,Jackson,Mana,Batista", :timezones => "Wellington",
   :demo_first_name => "Lea", :demo_last_name => "Martin", :demo_phone => "027 111 22 33", :demo_email => "lea@test.co.nz",
   :demo_password => "demo", :time_slots  =>  "1am,2am,3am,4am,5am,6am,7am,8am,9am,10am,11am,Noon,1pm,2pm,3pm,4pm,5pm,6pm,7pm,8pm,9pm,10pm,11pm,Midnight", 
   :default_start_time1  =>  8, :default_end_time1  => 12, :default_start_time2  => 13, :default_end_time2  => 17,
   :currency  => "NZD", :currency_symbol  => "$", :currency_before  => true
   )

 PaymentPlan.create(:country => nz, :amount => "1495", :title => "Emails",
   :description =>  "<ul><li>Unlimited reminders by email</li><li>No reminder by text messages</li></ul>" )

 PaymentPlan.create(:country => nz, :amount => "2495", :title => "Mini",
   :description =>  "<ul><li>Unlimited reminders by email</li><li><b>50</b> reminders by text message per month</li></ul>", :sms_credit => 50)

 PaymentPlan.create(:country => nz, :amount => "3995", :title => "Premium",
   :description =>  "<ul><li>Unlimited reminders by email</li><li><b>200</b> reminders by text message per month</li></ul>", :sms_credit => 200, :highlighted => true)

 PaymentPlan.create(:country => nz, :amount => "9995", :title => "Maxi",
   :description =>  "<ul><li>Unlimited reminders by email</li><li><b>500</b> reminders by text message per month</li></ul>", :sms_credit => 500)
