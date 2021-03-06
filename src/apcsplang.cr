require "option_parser"
require "admiral"

# TODO: Write documentation for `Apcsplang`
module Apcsplang
  VERSION = "0.1.0"

  enum TokenType
    EOF
    Number
    Identifier
    StringLiteral

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
    RepeatTimes
    Until

    # builtins
    Display
    Displayln
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

    #Boolean
    True
    False
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
              "TIMES"     => TokenType::RepeatTimes,
              "UNTIL"     => TokenType::Until,
              "DISPLAY"   => TokenType::Display,
              "DISPLAYLN" => TokenType::Displayln,
              "INPUT"     => TokenType::Input,
              "INSERT"    => TokenType::Insert,
              "APPEND"    => TokenType::Append,
              "REMOVE"    => TokenType::Remove,
              "LENGTH"    => TokenType::Length,
              "true"      => TokenType::True,
              "false"     => TokenType::False,
  }

  struct Scanner
    @type = TokenType.new(0)
    @value = ""
    @start_index = 0
    @end_index = 0
    @line = 1

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
        elsif next_char == '"' || next_char == '\''
          lex_string(next_char)
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
              @type = TokenType::Divide
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
              error "unexpected character '#{next_char}'. Skipping..."
            end
            advance
            return next_token(true)
          end
        end
      end
      unless @type == TokenType::StringLiteral || @type == TokenType::Identifier
        @end_index = @index - 1
        @value = @text[@start_index..@end_index]
      end
      lookahead
    end

    def error(err)
      STDERR.puts "#{@line.to_s.rjust(4)} | #{@text.each_line.skip(@line - 1).first}"
      STDERR.puts "Scanning error: #{err}"
    end

    def line
      @line
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

      
    end

    def lex_string(end_delimiter)
      @type = TokenType::StringLiteral
      str = String.build do |str|
        next_char = advance
        until next_char.nil? || next_char == end_delimiter
          if next_char == '\\'
            next_char = advance
            case next_char
            when '"'
              str << '"'
            when '\''
              str << '\''
            when '\\'
              str << '\\'
            when 'e'
              str << '\e'
            when 'f'
              str << '\f'
            when 'n'
              str << '\n'
            when 'r'
              str << '\r'
            when 't'
              str << '\t'
            when 'v'
              str << '\v'
            else
              # TODO: should this throw an error?
              str << next_char
            end
          else
            str << next_char
          end
          next_char = advance
        end
      end
      advance # consume right "
      @value = str
      end_index = index - 1
    end

    def lex_identifier
      next_char = peek

      until next_char.nil? || !next_char.alphanumeric?
        next_char = advance
      end
      @end_index = @index - 1
      @value = @text[@start_index..@end_index]
      @type = KEYWORDS.fetch(@value, TokenType::Identifier)
    end

    def check_keyword
    end

    def peek
      @text[@index]?
    end

    def advance
      @index += 1
      next_char = peek
      if next_char == '\n'
        @line += 1
      end
      next_char
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

    # Arithmentic
    Negate
    Add
    Subtract
    Divide
    Multiply
    Mod

    # Relational
    GreaterThan
    GreaterOrEqual
    LessThan
    LessOrEqual
    Equals
    NotEquals

    # Boolean
    And
    Or
    Not

    Void

    Display
    Displayln

    Discard

    #Variables
    SetVariable
    GetVariable

    #boolean
    True
    False

    #control flow
    Jump
    JumpIfFalse
    JumpIfTrue
    Loop

    #arrays
    Array
    Index
  end

  struct Void
  end

  alias Value = Float64 | Bool | String | Void | Array(Value)

  struct Program

    def last_index
      @code.size - 1  
    end

    @text : String

    def value_type_name(x : Value)
      case
      when x.is_a?(Void)
        "nothing"
      when x.is_a?(Float64)
        "number"
      when x.is_a?(Bool)
        "Boolean"
      when x.is_a?(String)
        "string"
      else
        x.class.to_s
      end
    end

    def initialize(@text)
      @code = Array(UInt8).new(256)
      # TODO: make `lines` take less memory
      @lines = Array(Int32).new(256)
      @stack = Array(Value).new(256)
      @constants = Array(Value).new(256)
      @variables = Array(Value).new(256)
      @ip = 0
    end

    def add_constant(value)
      @constants << value
      @constants.size.to_u8 - 1
    end

    def new_variable
      @variables << Void.new
      @variables.size.to_u8 - 1
    end

    def set_variable(variable_id : UInt8, line)
      write_byte(Opcode::SetVariable, line)
      write_byte(variable_id, line)
    end

    def get_variable(variable_id : UInt8, line)
      write_byte(Opcode::GetVariable, line)
      write_byte(variable_id, line)
    end

    def write_byte(byte : UInt8, line)
      @lines << line
      @code << byte
    end

    def write_byte(byte : Opcode, line)
      @lines << line
      @code << byte.value
    end

    def write_two_bytes(bytes : UInt16, line)
      first = ((bytes & 0xff00) >> 8).to_u8
      second = (bytes & 0x00ff).to_u8
      @lines << line
      @lines << line
      @code << first
      @code << second
    end

    def push_new_constant(constant : Value, line)
      id = add_constant(constant)
      write_byte(Opcode::Constant, line)
      write_byte(id, line)
    end

    def save_loop
      last_index
    end

    def write_loop(loop_type : Opcode, target, line)
      write_byte(loop_type, line)
      write_two_bytes((@ip - target).to_u16, line)
    end

    def write_jump(jump_type : Opcode, line)
      write_byte(jump_type, line)
      write_two_bytes(0, line)
      last_index - 1
    end

    def patch_jump(index : Int32)
      jump = @code.size - index - 2 #-2 to adjust for the bytecode of the jump offset itself
      #TODO: add checks for if it's too big
      first = ((jump & 0xff00) >> 8).to_u8
      second = (jump & 0x00ff).to_u8
      @code[index] = first
      @code[index+1] = second
    end


    def read_byte
      @ip += 1
      @code[@ip - 1]
    end

    def read_two_bytes
      first = read_byte.to_u16
      second = read_byte.to_u16
      (first << 8) + second
    end

    def error(string)
      STDERR.puts "#{@lines[@ip].to_s.rjust(4)} | #{@text.each_line.skip(@lines[@ip] - 1).first}"
      STDERR.puts "Runtime error: #{string}"
    end

    macro arithop(op, name)
      b = @stack.pop
      a = @stack.pop
      
      if a.is_a?(Float64) && b.is_a?(Float64)
        @stack.push (a {{op.id}} b)
      else
        #TODO: debug information lol
        error "cannot {{name.id}} #{value_type_name a} to #{value_type_name b} (both must be numbers)"
        return
      end
    end

    macro booleanop(op, name)
      b = @stack.pop
      a = @stack.pop
      
      if a.is_a?(Bool) && b.is_a?(Bool)
        @stack.push (a {{op.id}} b)
      else
        error "cannot {{name.id}} #{value_type_name a} and #{value_type_name b} (both must be Booleans)"
        return
      end
    end

    macro equalsop(op, name)
      b = @stack.pop
      a = @stack.pop
      
      if a.class == b.class
        @stack.push (a {{op.id}} b)
      else
        error "cannot {{name.id}} #{value_type_name a} and #{value_type_name b} (must be the same type)"
        return
      end
    end

    def value_string(x)
      if x.is_a?(Void)
        ""
      elsif x.is_a?(Float64)
        x.to_s.sub(/\.0+$/, "")
      else
        x.to_s
      end
    end

    def execute
      while @ip < @code.size
        opcode = Opcode.new(read_byte)
        case opcode
        # when Opcode::Return
        #   puts @stack.pop
        #   return
        when Opcode::Void
          @stack.push Void.new
        when Opcode::True
          @stack.push true
        when Opcode::False
          @stack.push false
        when Opcode::Discard
          @stack.pop
        when Opcode::Display
          print value_string(@stack.pop)
          print " "
          STDOUT.flush
        when Opcode::Displayln
          puts value_string(@stack.pop)
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
        when Opcode::SetVariable
          value = @stack.pop
          if value.is_a?(Void)
            error("cannot set variable to nothing (maybe the right hand side doesn't return?)")
            return
          else
            @variables[read_byte] = value
          end
        when Opcode::GetVariable
          value = @variables[read_byte]
          if value.is_a?(Void)
            error("variable does not exist")
            return
          else
            @stack.push value
          end
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
          equalsop(:==, "compare")
        when Opcode::NotEquals
          equalsop(:!=, "compare")
        when Opcode::Mod
          arithop(:%, "modulus")
        when Opcode::And
          booleanop(:"&&", "and")
        when Opcode::Or
          booleanop(:"||", "or")
        when Opcode::JumpIfFalse
          value = @stack.pop
          if value.is_a?(Bool)
            jump = read_two_bytes
            if value == false
              @ip += jump
            end
          else
            error "if statement must have a Boolean value, not a #{value_type_name value}"
            return
          end
        when Opcode::JumpIfTrue
          value = @stack.pop
          if value.is_a?(Bool)
            jump = read_two_bytes
            if value == true
              @ip += jump
            end
          else
            error "if statement must have a Boolean value, not a #{value_type_name value}"
            return
          end
        when Opcode::Loop
          jump = read_two_bytes
          @ip -= jump
        when Opcode::Jump
          jump = read_two_bytes
          @ip += jump
        when Opcode::Not
          a = @stack.pop
          if a.is_a?(Bool)
            @stack.push(!a)
          else
            error "cannot not #{value_type_name a}"
            return
          end
        when Opcode::Index
          arr = @stack.pop
          index = @stack.pop
          if arr.is_a?(Array)
            if index.is_a?(Float64) && index.to_i32 == index && index > 0 
              begin
                @stack.push arr[index.to_i32-1]
              rescue
                error "array index out of range"
                return
              end
            else
              error "array index is not a positive integer"
              return
            end
          else
            error "cannot index #{value_type_name arr}"
            return
          end
        when Opcode::Array
          length = read_byte
          last_stack = @stack.size - 1
          first_stack = last_stack - length + 1
          array = @stack[first_stack..last_stack]
          @stack.delete_at(first_stack..last_stack)          
          @stack.push array
        else
          STDERR.puts "Invalid instruction #{opcode}. Abort! (something went wrong with the interpreter)"
          return
        end
      end
    end

    def disassemble
      puts "CONSTANTS"
      constant_index = 0
      until constant_index >= @constants.size
        puts "#{constant_index.to_s.rjust(4, '0')} #{@constants[constant_index]}"
        constant_index += 1
      end
      puts "\n\nCODE"
      instruction_index = 0
      until instruction_index >= @code.size
        opcode = Opcode.new(@code[instruction_index])
        print "#{instruction_index.to_s.rjust(4, '0')} [#{opcode.value.to_s.rjust(2,'0')}]#{opcode.to_s}"
        case opcode
        when Opcode::Constant
          puts " #{@code[instruction_index + 1]}\t(#{@constants[@code[instruction_index + 1]]})"
          instruction_index += 1
        when Opcode::GetVariable, Opcode::SetVariable
          puts " #{@code[instruction_index + 1]}"
          instruction_index += 1
        when Opcode::JumpIfFalse, Opcode::JumpIfTrue, Opcode::Jump
          jump = (@code[instruction_index + 1].to_u16 << 8) + @code[instruction_index + 2].to_u16 + 2 # idk why
          puts " #{jump}\t->#{instruction_index+jump}"
          instruction_index += 2
        when Opcode::Loop
          jump = (@code[instruction_index + 1].to_u16 << 8) + @code[instruction_index + 2].to_u16
          puts " #{jump}\t->#{instruction_index-jump}"
          instruction_index += 2
        else
          puts ""
        end
        instruction_index += 1
      end
    end
  end

  class ParseException < Exception
    @message = "an unknown error occured while parsing"

    def initialize(@line, @message : String)
    end

    getter line : Int32
    getter message : String | Nil
  end

  struct Parser
    def initialize(@text : String)
      @scanner = Scanner.new(@text)
      @code = Program.new(@text)
      @variable_names = Hash(String, UInt8).new
    end

    # def error(err)
    #   STDERR.puts "#{[@ip].to_s.rjust(4)} | #{@text.each_line.skip(@lines[@ip]-1).first}"
    #   STDERR.puts "Parse error: #{string}"
    # end

    def lookup_variable(name)
      if @variable_names.has_key?(name)
        @variable_names[name]
      else
        var = @code.new_variable
        @variable_names[name] = var
        var
      end
    end

    def program
      @code
    end

    # number
    def number_expr
      @code.push_new_constant(@scanner.value.to_f, @scanner.line)
      @scanner.next_token
    end

    def string_expr
      @code.push_new_constant(@scanner.value, @scanner.line)
      @scanner.next_token
    end

    # '(' expression ')'
    def paren_expr
      @scanner.next_token # eat '('
      expression          # parse expression
      if @scanner.lookahead != TokenType::RightParen
        raise ParseException.new(@scanner.line, "expected ')' to close parenthesses, found '#{@scanner.value}'")
      end
      @scanner.next_token # eat ')'
    end

    #   identifier
    # | identifier '(' expression {',' expression} ')'
    def identifier_expr_or_assignment
      name = @scanner.value
      @scanner.next_token
      case @scanner.lookahead 
      when TokenType::LeftSquare
        @scanner.next_token # consume '['
        expression
        if @scanner.lookahead != TokenType::RightSquare
          raise ParseException.new(@scanner.line, "Unexpected token '#{@scanner.value}': expected ']' to close '['")
        end
        @scanner.next_token
        case @scanner.lookahead
        when TokenType::Assign
          raise ParseException.new(@scanner.line, "Unexpected token '#{@scanner.value}': assignment cannot be an expression")
        else
          id = lookup_variable(name)
          @code.get_variable(id, @scanner.line)
          @code.write_byte(Opcode::Index, @scanner.line)
        end
      when TokenType::Assign
        # puts "hi"
        @scanner.next_token #consume id
        expression()
        id = lookup_variable(name)
        @code.set_variable(id, @scanner.line) #doens't set it!!
      else
        id = lookup_variable(name)
        @code.get_variable(id, @scanner.line)
      end

      # return if there is no call
      # return unless @scanner.lookahead == TokenType::LeftParen

      # #there is a call
      # loop do
      #   expression
      #   break if @scanner.lookahead == TokenType::LeftParen

      #   if @scanner.lookahead != TokenType::Comma
      #     raise ParseException.new(@scanner.line, "expected ')' or ',' in argument list, found #{@scanner.value}")
      #   end

      #   @scanner.next_token
      # end

      # @scanner.next_token #eat ')'

      # puts "write call"
    end

    def identifier_expr
      name = @scanner.value
      @scanner.next_token
      case @scanner.lookahead 
      when TokenType::Assign
        raise ParseException.new(@scanner.line, "Unexpected token '#{@scanner.value}': assignment cannot be an expression")
      when TokenType::LeftSquare
        @scanner.next_token # consume '['
        expression
        puts @scanner.lookahead
        if @scanner.lookahead != TokenType::RightSquare
          raise ParseException.new(@scanner.line, "Unexpected token '#{@scanner.value}': expected ']' to close '['")
        end
        @scanner.next_token
        case @scanner.lookahead
        when TokenType::Assign
          raise ParseException.new(@scanner.line, "Unexpected token '#{@scanner.value}': assignment cannot be an expression")
        else
          id = lookup_variable(name)
          @code.get_variable(id, @scanner.line)
          @code.write_byte(Opcode::Index, @scanner.line)
        end
      else
        id = lookup_variable(name)
        @code.get_variable(id, @scanner.line)
      end
    end

    def repeat_statement
      @scanner.next_token # consume REPEAT
      if @scanner.lookahead == TokenType::Until
        @scanner.next_token # consume Until
        begining = @code.save_loop
        expression
        exit_jump = @code.write_jump(Opcode::JumpIfTrue, @scanner.line)
        
        if @scanner.lookahead != TokenType::LeftCurly
          raise ParseException.new(@scanner.line, "expected '{', found '#{@scanner.value}' (IF statement requires curly braces)")
        end
        @scanner.next_token

        block


        if @scanner.lookahead != TokenType::RightCurly
          raise ParseException.new(@scanner.line, "expected '}', found '#{@scanner.value}' (didn't close IF statement)")
        end
        @scanner.next_token

        @code.write_loop(Opcode::Loop, begining, @scanner.line)
        
      end
    end

    def if_statement
      @scanner.next_token # consume IF
      expression
      
      if @scanner.lookahead != TokenType::LeftCurly
        raise ParseException.new(@scanner.line, "expected '{', found '#{@scanner.value}' (IF statement requires curly braces)")
      end
      @scanner.next_token

      false_body_jump = @code.write_jump(Opcode::JumpIfFalse, @scanner.line)
      
      block

      if @scanner.lookahead != TokenType::RightCurly
        raise ParseException.new(@scanner.line, "expected '}', found '#{@scanner.value}' (didn't close IF statement)")
      end
      @scanner.next_token #consume '}'
 

      if @scanner.lookahead == TokenType::Else
        @scanner.next_token # consume 'ELSE'
        after_if_jump = @code.write_jump(Opcode::Jump, @scanner.line)
        @code.patch_jump(false_body_jump)
        if @scanner.lookahead != TokenType::LeftCurly
          raise ParseException.new(@scanner.line, "expected '{', found '#{@scanner.value}' (ELSE requires curly braces)")
        end
        @scanner.next_token # consume '{'


        block

        if @scanner.lookahead != TokenType::RightCurly
          raise ParseException.new(@scanner.line, "expected '}', found '#{@scanner.value}' (didn't close ELSE block)")
        end
        @scanner.next_token #consume '}'
        @code.patch_jump(after_if_jump)
      else
        @code.patch_jump(false_body_jump)
      end
    end

    def block
      loop do
        case @scanner.lookahead
        when TokenType::EOF, TokenType::RightCurly
          break
        else
          declaration
        end
      end
    end

    def boolean_expr(value)
      @scanner.next_token #consume value
      @code.write_byte(value ? Opcode::True : Opcode::False, @scanner.line)
    end
      

    def display_stat
      @scanner.next_token # consume DISPLAY
      if @scanner.lookahead != TokenType::LeftParen
        raise ParseException.new(@scanner.line, "expected '(', found '#{@scanner.value}' (DISPLAY requires parentheses)")
      end

      @scanner.next_token # consume '('
      if @scanner.lookahead == TokenType::RightParen
        @code.write_byte(Opcode::Void, @scanner.line)
        @code.write_byte(Opcode::Display, @scanner.line)
        @scanner.next_token # consume ')'
        return
      end
      expression

      if @scanner.lookahead != TokenType::RightParen
        raise ParseException.new(@scanner.line, "expected ')', found '#{@scanner.value}' (expected closing parenthesis for DISPLAY statement)")
      end

      @code.write_byte(Opcode::Display, @scanner.line)

      @scanner.next_token # consume ')'
    end

    def displayln_stat
      @scanner.next_token # consume DISPLAYln
      if @scanner.lookahead != TokenType::LeftParen
        raise ParseException.new(@scanner.line, "unexpected token '#{@scanner.value}' (DISPLAYLN requires parentheses)")
      end

      @scanner.next_token # consume '('
      if @scanner.lookahead == TokenType::RightParen
        @code.write_byte(Opcode::Void, @scanner.line)
        @code.write_byte(Opcode::Displayln, @scanner.line)
        @scanner.next_token # consume ')'
        return
      end

      expression

      if @scanner.lookahead != TokenType::RightParen
        raise ParseException.new(@scanner.line, "unexpected token '#{@scanner.value}' (expected closing parenthesis for DISPLAYLN statement)")
      end

      @code.write_byte(Opcode::Displayln, @scanner.line)

      @scanner.next_token # consume ')'
    end

    def list_expr
      @scanner.next_token # consume '['
      length = 0
      loop do
        expression
        length += 1
        if @scanner.lookahead == TokenType::Comma
          @scanner.next_token
          next
        elsif @scanner.lookahead == TokenType::RightSquare
          @scanner.next_token
          break
        else
          raise ParseException.new(@scanner.line, "unexpected token '#{@scanner.value}' (expected ',' or ']' in list literal)")
        end
      end
      @code.write_byte(Opcode::Array, @scanner.line)
      @code.write_byte(length.to_u8, @scanner.line)
    end

    # identifierexpr | numberexpr | parenexpr
    def primary(is_statement = false)
      case @scanner.lookahead
      when TokenType::Not
        @scanner.next_token
        expression
        @code.write_byte(Opcode::Not, @scanner.line)
      when TokenType::Minus
        @scanner.next_token
        expression
        @code.write_byte(Opcode::Negate, @scanner.line)
      when TokenType::Identifier
        identifier_expr
      when TokenType::True
        boolean_expr(true)
      when TokenType::False
        boolean_expr(false)
      when TokenType::StringLiteral
        string_expr
      when TokenType::Number
        number_expr
      when TokenType::LeftParen
        paren_expr
      when TokenType::LeftSquare
        list_expr
      else
        raise ParseException.new(@scanner.line, "unexpected token '#{@scanner.value}' (expected an expression#{is_statement ? " or statement" : ""})")
      end
    end

    def expression(is_statement = false)
      primary(is_statement)

      binop(0)

      if is_statement
        @code.write_byte(Opcode::Discard, @scanner.line)
      end
    end

    def declaration
      statement
    end

    def statement
      case @scanner.lookahead
      when TokenType::Display
        display_stat
      when TokenType::Displayln
        displayln_stat
      when TokenType::Repeat
        repeat_statement
      when TokenType::Identifier
        identifier_expr_or_assignment
      when TokenType::If
        if_statement
      else
        expression(true)
      end
    end

    def parse_start
      loop do
        declaration
        if @scanner.lookahead == TokenType::EOF
          break
        end
      end
    end

    def binop(minimum_precedence)
      while true
        precedence = get_precedence(@scanner.lookahead)
        if (precedence < minimum_precedence)
          return # don't push anything else besides lhs if it is a lower precednce or invalid operator
        end

        operator = @scanner.lookahead
        @scanner.next_token

        primary # get rhs of expression and push it

        next_precedence = get_precedence(@scanner.lookahead)

        if precedence < next_precedence # parse the rhs first, before writing the operator
          binop(precedence + 1)
        end

        case operator
        when TokenType::And
          @code.write_byte(Opcode::And, @scanner.line)
        when TokenType::Or
          @code.write_byte(Opcode::Or, @scanner.line)
        when TokenType::LessThan
          @code.write_byte(Opcode::LessThan, @scanner.line)
        when TokenType::LessOrEqual
          @code.write_byte(Opcode::LessOrEqual, @scanner.line)
        when TokenType::GreaterThan
          @code.write_byte(Opcode::GreaterThan, @scanner.line)
        when TokenType::GreaterOrEqual
          @code.write_byte(Opcode::GreaterOrEqual, @scanner.line)
        when TokenType::Equals
          @code.write_byte(Opcode::Equals, @scanner.line)
        when TokenType::NotEquals
          @code.write_byte(Opcode::NotEquals, @scanner.line)
        when TokenType::Plus
          @code.write_byte(Opcode::Add, @scanner.line)
        when TokenType::Minus
          @code.write_byte(Opcode::Subtract, @scanner.line)
        when TokenType::Multiply
          @code.write_byte(Opcode::Multiply, @scanner.line)
        when TokenType::Divide
          @code.write_byte(Opcode::Divide, @scanner.line)
        when TokenType::Mod
          @code.write_byte(Opcode::Mod, @scanner.line)
        end
        
      end
    end

    PrecedenceTable = {
      TokenType::And            => 10,
      TokenType::Or             => 10,
      TokenType::LessThan       => 20,
      TokenType::LessOrEqual    => 20,
      TokenType::GreaterThan    => 20,
      TokenType::GreaterOrEqual => 20,
      TokenType::Equals         => 30,
      TokenType::NotEquals      => 30,
      TokenType::Plus           => 30,
      TokenType::Minus          => 30,
      TokenType::Multiply       => 40,
      TokenType::Divide         => 40,
      TokenType::Mod            => 40,
    }

    def get_precedence(operator)
      PrecedenceTable.fetch(operator, -1) # default precedence (-1) is not an operator
    end
  end

  class App < Admiral::Command
    define_help description: "Runs the program", short: h

    define_version "0.1.0", short: v

    define_flag disassemble : Bool,
      description: "Shows disassembly instead of running program",
      default: false,
      short: d

    define_flag eval : Bool,
      description: "Runs code from command line arguments",
      default: false,
      short: c,
      long: code

    define_argument file : String

    def run
      if flags.eval
        source = arguments.file
        if !source.nil?
          run_string(arguments.file, flags.disassemble)
        else
          STDERR.puts "Please specify source code when using -c."
        end
      else
        filename = arguments.file
        if filename
          if File.file?(filename)
            text = File.read(filename)
            if !text.nil?
              run_string(text, flags.disassemble)
            else
              STDERR.puts "Unable to read file #{filename}"
            end
          else
            STDERR.puts "Unable to open file #{filename}"
          end
        else
          puts help
        end
      end
    end

    def run_string(source_maybenil, disassemble)
      if source_maybenil.nil?
        source = ""
      else
        source = source_maybenil
      end
      begin
        parser = Parser.new(source)
        parser.parse_start
      rescue e : ParseException
        STDERR.puts "#{e.line.to_s.rjust(4)} | #{source.each_line.skip(e.line-1).first}"
        STDERR.puts "Syntax error: #{e.message}"
      else
        program = parser.program
        if disassemble
          puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
          program.disassemble
          puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        else
          program.execute
        end
      end
    end

    App.run
  end
end