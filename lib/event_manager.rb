require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  cleaned = phone_number.gsub(/\D/, '')
  if cleaned.length < 10
    cleaned = ''
  elsif cleaned.length == 11
    if cleaned[0] == 1
      cleaned = cleaned[1..9]
    else
      cleaned = ''
    end
  elsif cleaned.length > 11
    cleaned = ''
  end
  cleaned
end

hours_occurrences = Hash.new(0)

def log_hour(date, hours_occurrences)
  formatted_date = DateTime.strptime(date, '%m/%d/%y %H:%M')
  hour = formatted_date.hour
  hours_occurrences[hour] += 1
end

weekday_occurrences = Hash.new(0)

def log_weekday(date, weekday_occurrences)
  weekdays = {
    0 => "Sunday",
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday"
  }
  formatted_date = DateTime.strptime(date, '%m/%d/%y %H:%M')
  weekday_number = formatted_date.wday
  weekday_name = weekdays[weekday_number]
  weekday_occurrences[weekday_name] += 1
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_hours = {}
test = []

def best_ads_time?(swag)
  #
end

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  registration_date = row[:regdate]
  log_hour(registration_date, hours_occurrences)
  log_weekday(registration_date, weekday_occurrences)

  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

def find_best_hours(hours_occurrences)
  unformatted = hours_occurrences.sort_by { |key, value| -value }.first(3)
  top_three = [unformatted[0][0], unformatted[1][0], unformatted[2][0]]
  puts "Most people registered within these three hours: #{top_three}"
end

def find_best_day_of_week(weekday_occurrences)
  unformatted = weekday_occurrences.sort_by { |key, value| -value }.first(3)
  top_three = [unformatted[0][0], unformatted[1][0], unformatted[2][0]]
  puts "Most people registered on these three days of the week: #{top_three}"
end

find_best_hours(hours_occurrences)
find_best_day_of_week(weekday_occurrences)
