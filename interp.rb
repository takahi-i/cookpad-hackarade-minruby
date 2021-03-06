require "minruby"


class RubyFunction
  attr_reader :params, :body

  def initialize(params, body)
    @params = params
    @body = body
  end
end

class Environments
  def initialize()
    @envs = []
    @envs.push({})
  end

  def get(key)
    @envs.last[key]
  end

  def set(key, value)
    @envs.last[key] = value
  end

  def pop
    @envs.pop
  end

  def push(env)
    @envs.push(env)
  end

  def to_s
    @envs.to_s
  end
end


# An implementation of the evaluator
def evaluate(exp, env)
  # exp: A current node of AST
  # env: An environment (explained later)
  case exp[0]

#
## Problem 1: Arithmetics
#

  when "lit"
    exp[1] # return the immediate value as is

  when "+"
    evaluate(exp[1], env) + evaluate(exp[2], env)
  when "-"
    # Subtraction.  Please fill in.
    # Use the code above for addition as a reference.
    # (Almost just copy-and-paste.  This is an exercise.)
    evaluate(exp[1], env) - evaluate(exp[2], env)
  when "*"
    evaluate(exp[1], env) * evaluate(exp[2], env)
  when "/"
    evaluate(exp[1], env) / evaluate(exp[2], env)
  when "%"
    evaluate(exp[1], env) % evaluate(exp[2], env)

  
#
## Problem 2: Statements and variables
#

  when "stmts"
    # Statements: sequential evaluation of one or more expressions.
    #
    # Advice 1: Insert `pp(exp)` and observe the AST first.
    # Advice 2: Apply `evaluate` to each child of this node.
    exp.slice(1..exp.size).each{|c|
      evaluate(c, env)
    }


  # The second argument of this method, `env`, is an "environement" that
  # keeps track of the values stored to variables.
  # It is a Hash object whose key is a variable name and whose value is a
  # value stored to the corresponded variable.

  when "var_ref"
    # Variable reference: lookup the value corresponded to the variable
    #
    # Advice: env[???]
    env.get(exp[1])

  when "var_assign"
    # Variable assignment: store (or overwrite) the value to the environment
    #
    # Advice: env[???] = ???
    env.set(exp[1], evaluate(exp[2], env))

#
## Problem 3: Branchs and loops
#

  when "if"
    # Branch.  It evaluates either exp[2] or exp[3] depending upon the
    # evaluation result of exp[1],
    #
    # Advice:
    #   if ???
    #     ???
    #   else
    #     ???
    #   end
    left_value = evaluate(exp[1][1], env)
    right_value = evaluate(exp[1][2], env)

    case exp[1][0]
    when ">"
      if left_value > right_value
        evaluate(exp[2], env)
      else
        evaluate(exp[3], env)
      end
    when "<"
      if left_value < right_value
        evaluate(exp[2], env)
      else
        evaluate(exp[3], env)
      end
    when "=="
      if left_value == right_value
        evaluate(exp[2], env)
      else
        evaluate(exp[3], env)
      end
    else
      raise(NotImplementedError)
    end

  when "while"

    left_value = get_value(exp[1][1], env)
    right_value = get_value(exp[1][2], env)
    while condition(exp[1][0], left_value, right_value)
      evaluate(exp[2], env)
      left_value = get_value(exp[1][1], env)
      right_value = get_value(exp[1][2], env)
    end


#
## Problem 4: Function calls
#

  when "func_call"
    # Lookup the function definition by the given function name.
    func = $function_definitions[exp[1]]

    if func.nil?
      # We couldn't find a user-defined function definition;
      # it should be a builtin function.
      # Dispatch upon the given function name, and do paticular tasks.
      case exp[1]
      when "p"
        # MinRuby's `p` method is implemented by Ruby's `p` method.
        p(evaluate(exp[2], env))
      when "Integer"
        Integer(evaluate(exp[2], env))
      when "fizzbuzz"
        fizzbuzz(get_value(exp[2], env))
      else
        raise("unknown builtin function")
      end
    else


#
## Problem 5: Function definition
#

      # (You may want to implement "func_def" first.)
      #
      # Here, we could find a user-defined function definition.
      # The variable `func` should be a value that was stored at "func_def":
      # parameter list and AST of function body.
      #
      # Function calls evaluates the AST of function body within a new scope.
      # You know, you cannot access a varible out of function.
      # Therefore, you need to create a new environment, and evaluate the
      # function body under the environment.
      #
      # Note, you can access formal parameters (*1) in function body.
      # So, the new environment must be initialized with each parameter.
      #
      # (*1) formal parameter: a variable as found in the function definition.
      # For example, `a`, `b`, and `c` are the formal parameters of
      # `def foo(a, b, c)`.
      params = func.params
      body = func.body
      local_env = {}
      local_env[params[0]] = evaluate(exp[2], env)
      env.push(local_env)
      result = evaluate(body, env)
      env.pop
      result
    end

  when "func_def"
    # Function definition.
    #
    # Add a new function definition to function definition list.
    # The AST of "func_def" contains function name, parameter list, and the
    # child AST of function body.
    # All you need is store them into $function_definitions.
    #
    # Advice: $function_definitions[???] = ???
    func_name = exp[1]
    $function_definitions[func_name] = RubyFunction.new(exp[2], exp[3])


#
## Problem 6: Arrays and Hashes
#

  # You don't need advices anymore, do you?
  when "ary_new"
    exp.slice(1..exp.size).map{|item| evaluate(item, env)}

  when "ary_ref"
    evaluate(exp[1], env)[evaluate(exp[2], env)]

  when "ary_assign"
    evaluate(exp[1], env)[evaluate(exp[2], env)] = evaluate(exp[3], env)

  when "hash_new"
    Hash[*exp.slice(1..exp.size).map{|item| evaluate(item, env)}]

  else
    p("error")
    raise("unknown node")
  end
end

def fizzbuzz(n)
  if n % 3 == 0
    if n % 5 == 0
      p("FizzBuzz")
    else
      p("Fizz")
    end
  else
    if n % 5 == 0
      p("Buzz")
    else
      p(n)
    end
  end
end

def condition(sign, left_value, right_value)
  case sign
  when ">"
    return left_value > right_value
  when "<"
    return left_value < right_value
  end
end

def get_value(exp, env)
  case exp[0]
  when "lit"
    return exp[1]
  else
    return evaluate(exp, env)
  end
end


$function_definitions = {}
env = Environments.new()

# `minruby_load()` == `File.read(ARGV.shift)`
# `minruby_parse(str)` parses a program text given, and returns its AST
evaluate(minruby_parse(minruby_load()), env)

