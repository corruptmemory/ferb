require 'method_args'

MethodArgsHelper.get_args("a")

def foo(*a, &b)
  p a
  p b
end

def foo1(a, &b)
  p a
  p b
end

def foo2(a, b=nil)
  p a
  p b
end

def foo3(a = nil, &b)
  p a
  p b
end

def foo4(a, b=nil, &c)
  p a
  p b
  p c
end

def goo(*a, &b)
  foo(*a,&b)
end
