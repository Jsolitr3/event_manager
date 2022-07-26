require 'date'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(number)
  number.to_s.gsub!(/[-)(.)\p{Space}]/, '')
  if number.length == 10
    number
  elsif number.length == 11 and number[0] == 1
    number.slice!(1..-1)
  else
    number = "n/a"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  
  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

end

def day_analysis(days)
  maxCount = 0
  output = []
  tempArr = days.reduce(Hash.new(0)) do |day,count|
    day[count] += 1
    day
  end
  tempArr.each {|day| day[1]>maxCount ? maxCount = day[1] : maxCount}
  tempArr.each {|day| output.push(day[0]) if day[1] == maxCount }
  output.join(" and ")
end

def time_analysis(hours)
  maxCount = 0
  output = []
  tempArr = hours.reduce(Hash.new(0)) do |hour,count|
    hour[count] += 1
    hour
  end
  tempArr.each {|hour| hour[1]>maxCount ? maxCount = hour[1] : maxCount}
  tempArr.each {|hour| output.push(hour[0] + ":00") if hour[1] == maxCount }
  output.join(" and ")
end

puts 'Event manager Initialized!'

contents= CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
days = []
hours = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = row[:homephone]
  days.push(DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M").strftime('%a'))
  hours.push(DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M").strftime('%H'))
  puts clean_phone_number(phone_number)
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
puts "The most popular day(s) for registration is #{day_analysis(days)}"
puts "The most popular time(s) for registration is #{time_analysis(hours)}"