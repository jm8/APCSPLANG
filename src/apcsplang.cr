# TODO: Write documentation for `Apcsplang`
module Apcsplang
  VERSION = "0.1.0"

  enum TokenType
    EOF
    Number
    Identifier

    # keywords
    And
    Each
    Else
    For
    If
    In
    Mod
    Not
    Or
    Procedure
    Repeat
    Return
    Times
    Until

    # builtins
    Display
    Input
    Insert
    Append
    Remove
    Length

    # symbols
    Plus
    Minus
    Multiply
    Divide
    LeftCurly
    RightCurly
    LeftSquare
    RightSquare
    LeftParen
    RightParen
    LessThan
    GreaterThan
    Equals
    LessOrEqual
    GreaterOrEqual
    NotEquals
    Assign
    Comma
  end

  KEYWORDS = {"AND"       => TokenType::And,
              "EACH"      => TokenType::Each,
              "ELSE"      => TokenType::Else,
              "FOR"       => TokenType::For,
              "IF"        => TokenType::If,
              "IN"        => TokenType::In,
              "MOD"       => TokenType::Mod,
              "NOT"       => TokenType::Not,
              "OR"        => TokenType::Or,
              "PROCEDURE" => TokenType::Procedure,
              "REPEAT"    => TokenType::Repeat,
              "RETURN"    => TokenType::Return,
              "TIMES"     => TokenType::Times,
              "UNTIL"     => TokenType::Until,
              "DISPLAY"   => TokenType::Display,
              "INPUT"     => TokenType::Input,
              "INSERT"    => TokenType::Insert,
              "APPEND"    => TokenType::Append,
              "REMOVE"    => TokenType::Remove,
              "LENGTH"    => TokenType::Length,
  }

  struct Scanner
    @type = TokenType.new(0)
    @value = ""
    @start_index = 0
    @end_index = 0

    def initialize(@text : String)
      @index = 0

      next_token
    end

    def skip_whitespace
      while true
        peek_char = peek
        if peek_char.nil?
          break
        else
          break unless peek_char.whitespace?
        end
        advance
      end
    end

    def next_token(panic = false)
      skip_whitespace
      @start_index = @index
      next_char = peek
      if next_char.nil?
        @type = TokenType::EOF
      else
        if next_char.ascii_number? || next_char == '.'
          lex_number
        elsif next_char.letter?
          lex_identifier
        else
          case next_char
          when '+'
            @type = TokenType::Plus
            advance
          when '-'
            @type = TokenType::Minus
            advance
          when '*'
            @type = TokenType::Multiply
            advance
          when '/'
            if advance == '='
              @type = TokenType::NotEquals
              advance
            else
              @type = TokenType::Equals
            end
            advance
          when '{'
            @type = TokenType::LeftCurly
            advance
          when '}'
            @type = TokenType::RightCurly
            advance
          when '['
            @type = TokenType::LeftSquare
            advance
          when ']'
            @type = TokenType::RightSquare
            advance
          when '('
            @type = TokenType::LeftParen
            advance
          when ')'
            @type = TokenType::RightParen
            advance
          when '<'
            second = advance
            if second == '-'
              @type = TokenType::Assign
              advance
            elsif second == '='
              @type = TokenType::LessOrEqual
              advance
            else
              @type = TokenType::LessThan
            end
          when '>'
            if advance == '='
              @type = TokenType::GreaterOrEqual
              advance
            else
              @type = TokenType::GreaterThan
            end
          when '='
            @type = TokenType::Equals
            advance
          when '≤'
            @type = TokenType::LessOrEqual
            advance
          when '≥'
            @type = TokenType::GreaterOrEqual
            advance
          when '≠'
            @type = TokenType::NotEquals
            advance
          when '←'
            @type = TokenType::Assign
            advance
          when ','
            @type = TokenType::Comma
            advance
          else
            if !panic
              puts "Error: invalid token at index #{@index}. Skipping."
            end
            advance
            return next_token(true)
          end
        end
      end
      @end_index = @index - 1
      @value = @text[@start_index..@end_index]
    end

    def lex_number
      @type = TokenType::Number
      next_char = advance
      until next_char.nil? || !next_char.ascii_number?
        next_char = advance
      end

      if next_char == '.'
        next_char = advance
      end

      until next_char.nil? || !next_char.ascii_number?
        next_char = advance
      end

      end_index = index - 1
    end

    def lex_identifier
      next_char = peek

      until next_char.nil? || !next_char.alphanumeric?
        next_char = advance
      end
      end_index = @index - 1
      @type = KEYWORDS.fetch(@text[@start_index..end_index], TokenType::Identifier)
    end

    def check_keyword
    end

    def peek
      @text[@index]?
    end

    def advance
      @index += 1
      peek
    end

    def lookahead
      @type
    end

    def index
      @index
    end

    def value
      @value
    end
  end

  enum Opcode : UInt8
    Return
    Constant

    #Arithmentic
    Negate
    Add
    Subtract
    Divide
    Multiply
    
    #Relational
    GreaterThan
    GreaterOrEqual
    LessThan
    LessOrEqual
    Equals
    NotEquals

    #Boolean
    And
    Or
    Not

    Display
  end

  alias Value = Float64 | Bool

  struct Program
    @text : String
    def value_type_name(x : Value)
      if x.is_a?(Float64)
        "number"
      elsif x.is_a?(Bool)
        "Boolean"
      else
        x.class.to_s
      end
    end

    def initialize(@text)
      @code = Array(UInt8).new(256)
      #TODO: make `lines` take less memory
      @lines = Array(Int32).new(256)
      @stack = Array(Value).new(256)
      @constants = Array(Value).new(256)
      @ip = 0
    end

    def add_constant(value)
      @constants << value
      @constants.size.to_u8 - 1
    end

    def write_byte(byte : UInt8, line)
      @lines << line
      @code << byte
    end

    def write_byte(byte : Opcode, line)
      @lines << line
      @code << byte.value
    end

    def read_byte
      @ip += 1
      @code[@ip - 1]
    end

    def error(string)
      puts "#{@lines[@ip].to_s.rjust(4)} | #{@text.each_line.skip(@lines[@ip]-1).first}"
      puts "Error: #{string}"
    end

    macro arithop(op, name)
      b = @stack.pop
      a = @stack.pop
      
      if a.is_a?(Float64) && b.is_a?(Float64)
        @stack.push (a {{op.id}} b)
      else
        #TODO: debug information lol
        error "cannot {{name.id}} #{value_type_name a} to #{value_type_name b}"
        return
      end
    end

    macro booleanop(op, name)
      b = @stack.pop
      a = @stack.pop
      
      if a.is_a?(Bool) && b.is_a?(Bool)
        @stack.push (a {{op.id}} b)
      else
        #TODO: debug information lol
        error "cannot {{name.id}} #{value_type_name a} and #{value_type_name b}"
        return
      end
    end

    def execute
      while @ip < @code.size
        opcode = Opcode.new(read_byte)
        case opcode
        when Opcode::Return
          puts @stack.pop
          return
        when Opcode::Display
          print @stack.pop
          print " "
          STDOUT.flush
        when Opcode::Constant
          @stack.push @constants[read_byte]
        when Opcode::Add
          arithop(:+, "add")
        when Opcode::Subtract
          arithop(:-, "subtract")
        when Opcode::Divide
          arithop(:/, "divide")
        when Opcode::Multiply
          arithop(:*, "multiply")
        when Opcode::Negate
          a = @stack.pop
          if a.is_a?(Float64)
            @stack.push(-a)
          else
            error "cannot negate #{value_type_name a}"
            return
          end
        when Opcode::GreaterThan
          arithop(:>, "compare")
        when Opcode::GreaterOrEqual
          arithop(:>=, "compare")
        when Opcode::LessThan
          arithop(:<, "compare")
        when Opcode::LessOrEqual
          arithop(:<=, "compare")
        when Opcode::Equals
          arithop(:==, "compare")
        when Opcode::NotEquals
          arithop(:!=, "compare")
        when Opcode::And
          booleanop(:"&&", "and")
        when Opcode::Or
          booleanop(:"||", "or")
        when Opcode::Not
          a = @stack.pop
          if a.is_a?(Bool)
            @stack.push(!a)
          else
            error "cannot not #{value_type_name a}"
            return
          end
        else
          puts "Invalid instruction #{opcode}. Skipping."
        end
      end
    end
  end

  puts "compiled\n==========\n\n"

  # scanner = Scanner.new ">="
  # until scanner.lookahead == TokenType::EOF
  #   puts scanner.value
  #   puts scanner.lookahead
  #   scanner.next_token
  # end

  program = Program.new "50"
  a = program.add_constant true
  b = program.add_constant false

  program.write_byte(Opcode::Constant, 1)
  program.write_byte(a, 1)

  program.write_byte(Opcode::Constant, 1)
  program.write_byte(b, 1)

  program.write_byte(Opcode::And, 1)
  program.write_byte(Opcode::Display, 1)

  program.execute
end
