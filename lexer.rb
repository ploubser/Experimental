require 'rubygems'
require 'pp'
require 'colorize'

module JGrep
  class Lexer
    attr_accessor :comparison_operators, :statements, :binary_operators, :unary_operators, :functions, :callstack, :presidence_symbols

    def initialize(code)
      @statements = []
      @callstack = []
      @binary_operators = []
      @unary_operators = []
      @presidence_symbols = []
      @functions = {}
      @comparison_operators = {}
      instance_eval File.read("test.ebnf")
      @token_error = false
      @parse_error = false
      @function_errors = []
      @callstack = []
      @result_stack = []
      @callstack = code.split(" ").map{|x| tokenize(x)}.flatten
      exit_with_tokenize_error if @token_error == true
      parse_tokens
    end

    def exit_with_tokenize_error
      puts "Parse Error found. Invalid token(s) found."
      puts @result_stack.map{|x| (x.first == :fail) ? x[1].red : x[1].white}.join(" ")
      exit 1
    end

    def define_comparison_operators(comparison_operators)
      @comparison_operators = comparison_operators
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
      @result_stack.each_with_index do |token, i|

      end
    end

    def tokenize(statement)
      if statement =~ /^(#{@unary_operators.join("|")})(.+)/
        @result_stack << [:suc, $1, :u]
        return [$1, tokenize($2)]
      elsif statement =~ /^(#{@presidence_symbols.map{|x| "\\#{x}"}.join("|")})+(.+)/
        @result_stack << [:suc,$1, :ps]
        return ["(", tokenize($2)]
      elsif statement =~ /^(.+)(#{@presidence_symbols.map{|x| "\\#{x}"}.join("|")})$/
        @result_stack << [:suc,$2, :pe]
        return [tokenize($1), ")"]
      elsif @binary_operators.include?(statement)
        @result_stack << [:suc, statement, :b]
        return statement
      else
        @statements.each do |s|
          if statement =~ s
            @result_stack << [:suc, statement, :s]
            return statement
          else
            @token_error = true
            @result_stack << [:fail, statement]
            return statement
          end
        end
      end
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /define_function_(.*)_as/
        self.class.send(:define_method, $1.to_sym, block)
      else
        @function_errors << method.to_s
        nil
      end
    end

    def exit_with_function_errors
      func_errors = @result_stack.map do |x|
        if x[1] =~ /(#{@function_errors.join("|")})/
          mname = $1
          mparams = x[1].split(mname)
          mname.red + mparams.join("")
        else
          x[1]
        end
      end.join(" ")

      puts func_errors
      puts "Undefined function(s) found. Exiting"
      exit!
    end

    # Move to somewhere else that makes sense.
    def execute_callstack
      @callstack.each_with_index do |statement,i|
        unless @binary_operators.include?(statement) || @unary_operators.include?(statement) || ["(", ")"].include?(statement)
          values = statement.split(/(#{@comparison_operators.join("|")})/)
          values.each_with_index do |val,j|
            if val =~ /.*\(.*\)/
              values[j] = eval(val)
            end
          end
          begin
            @callstack[i] = eval(values.join(" "))
          rescue Exception => e
          end
        end
      end
      exit_with_function_errors unless @function_errors.empty?
      eval @callstack.join(" ")
    end
  end
end

lexer = JGrep::Lexer.new("!(add(sub(1,5),1,5)==2 and sub(2,1)<=2) or mult(3,3,9)>9 or foo[1>2")
puts lexer.execute_callstack
