require 'method_args'

ma = MethodArgs.new
ma.output_arg_info("a=nil,b=2,c={},*d,&e")

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


require 'ferb'

class Foo
  include Ferb
  def_template :sample1, :file => 'sample1.erb'
  def_template :sample2, :file => 'sample2.erb'
  def_template 'sample3(a,b = {}, *c, &d)', :file => 'sample3.erb'
end

foo = Foo.new
foo.sample2
foo.sample1(1,2,3,4,5) { 1 }
foo.sample3(1,2,3,4,5) { 1 }