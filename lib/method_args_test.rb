require 'method_args'

MethodArgsHelper.get_args("a")

def foo(*a, &b)
  p a
  p b
end

def goo(*a, &b)
  foo(*a,&b)
end
