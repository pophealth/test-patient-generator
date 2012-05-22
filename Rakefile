ENV['MEASURE_DIR'] = ENV['MEASURE_DIR'] || File.join('fixtures', 'measure_defs')

Dir['lib/tasks/*.rake'].sort.each do |ext|
  load ext
end