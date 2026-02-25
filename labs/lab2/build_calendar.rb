require "date"

# Валидация аргументов
if ARGV.length != 4
  puts "Запуск: ruby build_calendar.rb teams.txt 01.08.2026 01.06.2027 calendar.txt"
  exit
end

input_file, start_date, end_date, output_file = ARGV

# Чтение файла
unless File.exist?(input_file)
  puts "Файл не найден"
  exit
end

teams = []

File.readlines(input_file, chomp: true).each do |line|
  line.strip!
  next if line.empty?

  parts = line.split(/[.—]\s*/)
  if parts.size != 3
    puts "Ошибка в строке: #{line}"
    exit
  end

  id = parts[0].strip.to_i
  name = parts[1].strip
  city = parts[2].strip

  teams << { id: id, name: name, city: city }
end

if teams.size < 2
  puts "Команд должно быть минимум 2"
  exit
end

# Валидация дат
begin
  start_date = Date.strptime(start_date, "%d.%m.%Y")
  end_date = Date.strptime(end_date, "%d.%m.%Y")
rescue
  puts "Неверный формат даты"
  exit
end

if start_date > end_date
  puts "Начальная дата больше конечной"
  exit
end

# Заполнение матчей
all_matches = []
(0...teams.size).each do |i|
  (i+1...teams.size).each do |j|
    all_matches << [teams[i], teams[j]]
  end
end

all_matches.shuffle!

valid_days = []
date = start_date
while date <= end_date
  valid_days << date if [5, 6, 0].include?(date.wday)
  date += 1
end

if valid_days.empty?
  puts "Нет допустимых дней в диапазоне"
  exit
end

# Создание расписания
remaining_matches = all_matches.dup
schedule = {}
valid_days.each do |day|
  schedule[day] = { "12:00" => [], "15:00" => [], "18:00" => [] }
end

valid_days.each do |day|
  busy_teams = {}
  times = ["12:00", "15:00", "18:00"]

  times.each do |time|
    2.times do
      match_found = nil
      remaining_matches.each_with_index do |match, ind|
        team1, team2 = match
        if !busy_teams[team1[:id]] && !busy_teams[team2[:id]]
          match_found = ind
          break
        end
      end

      if match_found
        match = remaining_matches.delete_at(match_found)
        team1, team2 = match
        schedule[day][time] << match
        busy_teams[team1[:id]] = true
        busy_teams[team2[:id]] = true
      else
        break
      end
    end
  end

  break if remaining_matches.empty?
end

unless remaining_matches.empty?
  puts "Не удалось распределить все матчи"
  exit
end

# Запись в файл
File.open(output_file, "w") do |file|
  valid_days.each do |date|
    next if schedule[date]["12:00"].empty? && schedule[date]["15:00"].empty? && schedule[date]["18:00"].empty?
    file.puts "=== #{date.strftime('%A, %d %B %Y')} ==="

    times = ["12:00", "15:00", "18:00"]
    times.each do |time|
      games = schedule[date][time]
      games.each do |team1, team2|
        file.puts "#{time} — #{team1[:id]}. #{team1[:name]} (#{team1[:city]}) vs #{team2[:id]}. #{team2[:name]} (#{team2[:city]})"
      end
    end
    file.puts
  end
end

puts "Календарь успешно создан: #{output_file}"