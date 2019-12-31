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

  enum Opcode
    Return
  end

  puts "compiled\n==========\n\n"

  scanner = Scanner.new ">="
  until scanner.lookahead == TokenType::EOF
    puts scanner.value
    puts scanner.lookahead
    scanner.next_token
  end
end
