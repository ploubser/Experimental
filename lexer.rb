module JGrep
  class Lexer
    attr_accessor :statements, :binary_operators, :unary_operators, :functions, :callstack, :presidence_symbols

    def initialize(code)
      @statements = []
      @callstack = []
      @binary_operators = []
      @unary_operators = []
      @presidence_symbols = []
      @functions = {}
      instance_eval File.read("test.ebnf")
      tokenize(code)
      parse_tokens
    end

    def define_statement(statement)
      @statements << statement
    end

    def define_binary_operators(operators)
      operators.split(",").each do |op|
        @binary_operators << op
      end
    end

    def define_unary_operators(operators)
      operators.split(",").each do |op|
        @unary_operators << op
      end
    end

    def define_presidence_symbols(pres)
      pres.split(",").each do |p|
        @presidence_symbols << p
      end
    end

    def create_ebnf(&block)
      block.call
    end

    def parse_tokens
      require 'pp'
      pp @callstack
      @callstack.each do |token|
        valid = true
        unless @binary_operators.include?(token) || @unary_operators.include?(token) || @presidence_symbols.include?(token)
          @statements.each do |statement|
            next if token =~ statement
            valid = false
          end
        end
        raise RuntimeError, "Invalid token found - #{token}" unless valid
      end
    end

    def tokenize(code)
      code.split(" ").each do |statement|
        if statement =~ /(#{@unary_operators.join("|")})(.+)/
          @callstack += [$1, $2]
 #       elsif statement =~/^(#{@presidence_symbols.map{|x| "\\#{x}"}.join("|")})+(.+)/
 #         @callstack += [$1, $2]
#        elsif statement =~/^(.+)(#{@presidence_symbols.map{|x| "\\#{x}"}.join("|")})/
#          @callstack += [$1, $2]
        else
          @callstack << statement
        end
      end
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /define_function_(.*)_as/
        self.class.send(:define_method, $1.to_sym, block)
      end
    end

    # Move to somewhere else that makes sense.
    def execute_callstack
      @callstack.each_with_index do |statement,i|
        unless @binary_operators.include?(statement) || @unary_operators.include?(statement) || @presidence_symbols.include?(statement)
          values = statement.split("=")
          values.each_with_index do |val,j|
            if val =~ /.*\(.*\)/
              values[j] = eval(val)
            end
          end
          @callstack[i] = eval(values.join(" == "))
        end
      end
      eval @callstack.join(" ")
    end
  end
end

lexer = JGrep::Lexer.new("add(0,1)=1 and sub(2,1)=1 && mult(3,3)=9")
puts lexer.execute_callstack
