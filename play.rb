require 'date'

some_times = ['11/12/08 10:47', '11/12/08 13:23']

date_time = DateTime.strptime(some_times[0], '%m/%d/%y %H:%M')
reg_in_minutes = (60 * date_time.hour) + (date_time.minute)
puts "#{reg_in_minutes / 60}:#{reg_in_minutes.to_s[1..2]}"
