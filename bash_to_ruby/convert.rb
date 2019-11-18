# encoding: UTF-8

require 'pry'
require './lib'

file = open(ARGV[0], encoding: Encoding::UTF_8)

path = file.path

controler = %w[if]
methods = { puts: "echo" }

puts = methods.keys

lexer = Lexer.new(file)

bp = BasicParser.new

nodes = []

while lexer.peek(0) != Token::EOF
  node = bp.parse(lexer)
  puts "=> " + node.toString()
end

# ln = 0
# while ln != -1
#   lr = lexer.read()
#   ln = lr.getLineNumber()
#   puts lr.getText()
# end

