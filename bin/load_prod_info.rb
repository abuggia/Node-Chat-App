#!/usr/bin/ruby

vars = []
File.open('prod.config').each do |line|
  key, val = line.chomp.split('=')
  next unless val

  vars << "#{key.sub(/export /, '')}=#{val.gsub(/'/, '')}"
end

command = "heroku config:add " + vars.join(' ')

puts command