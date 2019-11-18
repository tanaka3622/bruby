f = open(ARGV[0])

str = "#!/bin/bash"
controler = %w[if]
methods = { puts: "echo" }

puts = methods.keys

str << "\n" + "exit 0"
while line = f.gets
  method = line.split(" ")[0]
  # case method

  # end
    
  puts method
end

File.open("./converted.sh","w") do |file|
  file.puts str
end