class Token
  EOL = "\n".freeze

  def initialize(line)
    @lineNumber = line
  end

  def getLineNumber
    @lineNumber
  end

  def isIdentifier
    false
  end

  def isNumber
    false
  end

  def isString
    false
  end

  def getNumber
    raise "Called abstract method: child"
  end

  def getText
    ""
  end
end
Token::EOF = Token.new(-1).freeze

class ASNode
  @child = nil
  @storage = 'file'

  def child
    raise "Called abstract method: child"
  end

  def numchildren
    raise "Called abstract method: numchildren"
  end

  def children
    raise "Called abstract method: children"
  end

  def loccation
    raise "Called abstract method: loccation"
  end

  def iterator
    children()
  end
end

class ASNLeaf < ASNode
  @emptry = []

  def initialize(token)
    @token = token
  end

  def numChildren
    0
  end

  def children
    @emptry
  end

  def toString
    token.getText()
  end

  def location
    "at line " + @token.getLineNumber().to_s
  end

  def token
    @token
  end
end

class Lexer
  REGEX_PATTURN = /\s*((#.*)|([0-9]+)|(\".*\")|\$*[A-Z_a-z][A-Z_a-z0-9]*|==|<=|>=|\p{Punct}|\p{ASCII})/.freeze

  def initialize(file)
    @lineNo = 0
    @hasMore = true
    @file = file
    @queue = [] # TokenArray
  end

  def lineNo
    @lineNo
  end

  def read
    if fillQueue(0)
      @queue.delete_at(0)
    else
      Token::EOF
    end
  end

  def peek(i)
    if fillQueue(i)
      @queue.at(i)
    else
      Token::EOF
    end
  end

  def fillQueue(i)
    while i >= @queue.length
      if (@hasMore)
        readLine();
      else
        return false;
      end
    end
    true
  end

  class IdToken < Token
    def initialize(lineNo, id)
      super(lineNo)
      @id = id
    end

    def isIdentifier
      true
    end

    def getText
      @id
    end
  end

  class NumToken < Token
    def initialize(lineNo, num)
      super(lineNo)
      @num = num
    end

    def isNumber
      true
    end

    def getText
      @num.to_s
    end
  end

  class StrToken < Token
    def initialize(lineNo, str)
      super(lineNo)
      @str = str
    end

    def isString
      true
    end

    def getText
      @str
    end
  end

  def readLine
    begin
      line = @file.gets;
    rescue Exception => e
      raise "Parse Exception"
    end

    if line == nil
      @hasMore = false;
      return;
    else
      @lineNo +=1
    end
    matchers = line.scan(REGEX_PATTURN)
    matchers.each do |matcher|
      addToken(@lineNo, matcher);
    end
    @queue.push(IdToken.new(@lineNo, Token::EOL));
  end

  def addToken(lineNo, matcher)
    return if matcher == nil
    return if !matcher[1].nil? # if comment?
    return if matcher[0] == "\n"
    m = matcher[0]

    token =
      if !matcher[2].nil?
        NumToken.new(lineNo, m.to_i);
      elsif !matcher[3].nil?
        StrToken.new(lineNo, m.to_s);
      else
        IdToken.new(lineNo, m.to_s);
      end
    @queue.push(token);
  end
end

class NumberLiteral < ASNLeaf
  def initialize(token)
    super(token)
  end

  def value
    token.getNumber()
  end
end

class Name < ASNLeaf
  def initialize(token)
    super(token)
  end

  def name
    token.getText()
  end
end

class StringLiteral < ASNLeaf
  def initialize(token)
    super(token)
  end

  def value
    token.getText()
  end
end

class ASNList < ASNode
  def initialize(list)
    @children = list
  end

  def child(i)
    @children.at(i)
  end

  def numChildren
    @children.size
  end

  def children
    @children
  end

  def toString
    sep = ""
    str = ""
    @children.each do |child|
      str += sep
      sep = " "
      str += child.toString()
    end
    str
  end

  def location
    @children.each do |child|
      str = chlild.toString()
      return str if str
    end
    ""
  end
end

class BinaryExpr < ASNList
  def initialize(list)
    super(list)
  end

  def left
    child(0)
  end

  def operator
    child(1).token().getText()
  end

  def right
    child(2)
  end

  def toString
    sep = ""
    str = "("
    @children.each do |child|
      str += sep
      sep = " "
      str += child.toString()
    end
    str += ")"
  end
end

class Parser
  class Element
    def parse(lexer, res)
      raise "Called abstract method: parse"
    end

    def match(lexer)
      raise "Called abstract method: match"
    end
  end

  class Node < Element
    def initialize(parser)
      @parser = parser
    end

    def parse(lexer, res)
      res << @parser.parse(lexer)
    end

    def match(lexer)
      @parser.match(lexer)
    end
  end

  class OrNode < Element
    def initialize(parsers)
      @parsers = parsers
    end

    def parse(lexer, res)
      parser = choose(lexer)
      if parser
        res << parser.parse(lexer)
      else
        puts "parser is null"
      end
    end

    def match(lexer)
      choose(lexer) != nil
    end

    def choose(lexer)
      @parsers.each do |parser|
        return parser if parser.match(lexer)
      end
      nil
    end

    def insert(pardser)
      parsers << pardser
    end
  end

  class Repeat < Element
    def initialize(parser, once)
      @parser = parser
      @onlyOnce = once
    end

    def parse(lexer, res)
      while @parser.match(lexer) do
        as_node = @parser.parse(lexer)
        res << as_node if as_node.class.superclass != ASNList || as_node.numChildren() > 0
        break if @onlyOnce
      end
    end

    def match(lexer)
      paser.match(lexer)
    end
  end

  class AToken < Element
    def initialize(type)
      @type = AsLeaf.class if type.nil?
      @factory = Factory.get(type)
    end

    def parse(lexer, res)
      token = lexer.read()
      if (test(token))
        leaf = @factory.make(token)
        res << leaf
      else
        raise "parser execption"
      end
    end

    def match(lexer)
      test(lexer.peek(0))
    end

    def test(token)
      raise "Called abstract method: test"
    end
  end

  class IdToken < AToken
    def initialize(type, r)
      super(type)
      @reserved = r.nil? ? [] : r
    end

    def test(token)
      token.isIdentifier() && !@reserved.include?(token.getText())
    end
  end

  class NumToken < AToken
    def initialize(type)
      super(type)
    end

    def test(token)
      token.isNumber()
    end
  end

  class StrToken < AToken
    def initialize(type)
      super(type)
    end

    def test(token)
      token.isString()
    end
  end

  class Leaf < Element
    def initialize(tokens)
      @tokens = tokens
    end

    def parse(lexer, res)
      t = lexer.read()
      if t.isIdentifier()
        @tokens.each do |token|
          return find(res, t) if token == t.getText()
        end
      end

      # binding.pry

      if @tokens.length > 0
        puts "Parse Exception" + @tokens[0]
      else
        puts "Parse Exception"
      end
    end

    def find(res, token)
      res << ASNLeaf.new(token)
    end

    def match(lexer)
      token = lexer.peek(0)
      if token.isIdentifier()
        @tokens.each do |t|
          return true if t == token.getText()
        end
      end
      false
    end
  end

  class Skip < Leaf
    def initialize(str)
      @str = str
      super(str)
    end

    def str
      @str
    end

    def find(res, token)
    end
  end

  class Precedence
    def initialize(v, a)
      @value = v
      @leftAssoc = a
    end

    def value
      @value
    end

    def leftAssoc
      @leftAssoc
    end
  end

  class Operator < Hash
    LEFT = true.freeze
    RIGHT = false.freeze

    def add(name, prec, leftAssoc)
      store(name, Parser::Precedence.new(prec, leftAssoc))
    end
  end

  class Expr < Element
    def initialize(clazz, parser, operators)
      @factory = Factory.getForASNList(clazz)
      @ops = operators
      @parser = parser
    end

    def parse(lexer, res)
      right = @parser.parse(lexer)
      prec = nextOperator(lexer)
      while !prec.nil?
        right = doShift(lexer, right, prec.value)
        prec = nextOperator(lexer)
      end
      res << right
    end

    def doShift(lexer, left, prec)
      list = []
      list << left
      list << ASNLeaf.new(lexer.read())
      right = @parser.parse(lexer)
      nxt = nextOperator(lexer)
      while !nxt.nil? && rightIsExpr(prec, nxt)
        right = doShift(lexer, right, nxt.value)
        nxt = nextOperator(lexer)
      end
      list << right
      @factory.make(list)
    end

    def nextOperator(lexer)
      token = lexer.peek(0)
      if token.isIdentifier()
        @ops.key?(token.getText()) ? @ops[token.getText()] : nil
      else
        nil
      end
    end

    def rightIsExpr(prec, nextPrec)
      if nextPrec.leftAssoc
        prec < nextPrec.value
      else
        prec <= nextPrec.value
      end
    end

    def match(lexer)
      @parser.match(lexer)
    end
  end

  FACTORY_NAME = "create"
  class Factory
    def initialize(clazz=nil)
      @clazz = clazz
    end

    def make0(arg)
      raise "Called abstract method: make0"
    end

    def make(arg)
      begin
        make0(arg)
      rescue => e
        puts e
      end
    end

    def self.getForASNList(clazz)
      factory = get(clazz)
      if factory.nil?
        factory = Factory.new
        def factory.make0(args)
          if args.length == 1
            args.at(0)
          else
            ASNList.new(args)
          end
        end
      end
      factory
    end

    def self.get(clazz)
      return nil if clazz.nil?

      begin
        raise FACTORY_NAME + "is none" unless clazz.method_defined?(FACTORY_NAME)

        factory = Factory.new(clazz)
        def factory.make0(arg)
          @clazz.send(FACTORY_NAME, arg)
        end
      rescue => e
        puts e
      end

      begin
        factory = Factory.new(clazz)
        def factory.make0(arg)
          # binding.pry if @clazz == IfStmnt
          @clazz.new(arg)
        end
      rescue => e
        puts e
      end

      factory
    end
  end

  def initialize(clazz: nil, parser: nil)
    if !parser.nil?
      @elements = parser.elements;
      @factory = parser.factory;
      reset(clazz)
    else
      reset(clazz)
    end
  end

  def parse(lexer)
    results = []
    # binding.pry if 
    @elements.each do |element|
      # binding.pry if element.class == Parser::Expr && lexer.lineNo == 5
      # binding.pry if element.class == Parser::IdToken && lexer.lineNo == 5
      element.parse(lexer, results)
    end
    # binding.pry if lexer.lineNo == 5
    @factory.make(results)
  end

  def match(lexer)
    if @elements.length == 0
      true
    else
      @elements.at(0).match(lexer)
    end
  end

  def self.rule(clazz=nil)
    Parser.new(clazz: clazz)
  end

  def number(clazz)
    @elements << NumToken.new(clazz)
    self
  end

  def reset(clazz)
    @elements = []
    @factory = Factory.getForASNList(clazz)
    self
  end

  def identifier(reserved: [], clazz: nil)
    @elements << IdToken.new(clazz, reserved)
    self
  end

  def string(clazz)
    @elements << StrToken.new(clazz)
    self
  end

  def token(str)
    @elements << Leaf.new(str)
    self
  end

  def sep(*str)
    @elements << Skip.new(str)
    self
  end

  def ast(parser)
    @elements << Node.new(parser)
    self
  end

  def or(*parser)
    @elements << OrNode.new(parser)
    self
  end

  def option(parser)
    @elements << Repeat.new(parser, true)
    self
  end

  def repeat(parser)
    @elements << Repeat.new(parser, false)
    self
  end

  def expression(clazz, subexp, operators)
    @elements << Expr.new(clazz, subexp, operators)
    self
  end

  def insertChoice(parser)
    e = @elements.at(0)
    if e.kind_of?(OrNode)
      e.insert(parser)
    else
      p2 = Parser.new(clazz: self)
      result(nil)
      self.or(parser, p2)
    end
    self
  end
end

class PrimaryExpr < ASNList
  def initialize(list)
    super(list)
  end

  def create(list)
    list.length == 1 ? list.at(0) : PrimaryExpr.new(list)
  end
end

class NegativeExpr < ASNList
  def initialize(list)
    super(list)
  end

  def operand
    @children.at(0)
  end

  def toString
    "-" + operand().to_s
  end
end

class BlockStmnt < ASNList
  def initialize(list)
    super(list)
  end
end

class IfStmnt < ASNList
  def initialize(list)
    super(list)
  end

  def condition
    child(0)
  end

  def thenBlock
    child(1)
  end

  def elseBlock
    numChildren() > 2 ? child(2) : nil
  end

  def toString
    # binding.pry
    "(if " + condition()&.toString().to_s + " " + thenBlock()&.toString().to_s + " else " + elseBlock()&.toString().to_s + ")"
  end
end

class WhileStmnt < ASNList
  def initialize(list)
    # binding.pry
    super(list)
  end

  def condition
    child(0)
  end

  def body
    child(1)
  end

  def toString
    "(while  " + condition().toString().to_s + " " + body().toString().to_s + ")"
  end
end

class NullStmnt < ASNList
  def initialize(list)
    super(list)
  end
end

class BasicParser
  def initialize
    @reserved = []
    @operators = Parser::Operator.new()

    expr0 = rule()
    primary = rule(PrimaryExpr)
              .or(
                rule().sep("(").ast(expr0).sep(")"),
                rule().number(NumberLiteral),
                rule().identifier(reserved: @reserved, clazz: Name),
                rule().string(StringLiteral)
              )
    factor = rule()
             .or(
                rule(NegativeExpr).sep("-").ast(primary),
                primary
             )
    expr = expr0.expression(BinaryExpr, factor, @operators)

    statement0 = rule()
    block = rule(BlockStmnt)
            .sep("{")
            .option(statement0)
            .repeat(
              rule().sep(";", Token::EOL).option(statement0)
            )
            .sep("}")
    simple = rule(PrimaryExpr).ast(expr)

    @statement = statement0
                .or(
                  rule(IfStmnt).sep("if").ast(expr).ast(block).option(rule().sep("else").ast(block)),
                  rule(WhileStmnt).sep("while").ast(expr).ast(block),
                  simple
                )
    @program = rule().or(@statement, rule(NullStmnt)).sep(";", Token::EOL)

    @reserved << ";"
    @reserved << "}"
    @reserved << Token::EOL

    @operators.add("=",  1, Parser::Operator::RIGHT)
    @operators.add("==", 2, Parser::Operator::LEFT)
    @operators.add(">",  2, Parser::Operator::LEFT)
    @operators.add("<",  2, Parser::Operator::LEFT)
    @operators.add("+",  3, Parser::Operator::LEFT)
    @operators.add("-",  3, Parser::Operator::LEFT)
    @operators.add("*",  4, Parser::Operator::LEFT)
    @operators.add("/",  4, Parser::Operator::LEFT)
    @operators.add("%",  4, Parser::Operator::LEFT)
  end

  def rule(clazz=nil)
    Parser.rule(clazz)
  end

  def parse(lexer)
    @program.parse(lexer)
  end
end
