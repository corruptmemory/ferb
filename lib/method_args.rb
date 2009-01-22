# Code to extract the formal parameter names and types from a function
# given a standard Ruby function argument signature.  Original code based
# on the MethodArgs module written by Mauricio Fernandez <mfp@acm.org>
# (http://eigenclass.org).  Rewritten for the specific case of extracting named
# argument variables from an argument signature.
#
# Author::    Jim Powers (mailto:jim@corruptmemory.com)
# Copyright:: Copyright (c) 2008-2009 Jim Powers
# License::   Distributed under the terms of the LGPLv3.0 or newer.
#             For details see the LGPL30 file
#
# == Example:
#
# require 'method_args'
# ma = MethodArgs.new
# ma.output_arg_info("a=nil,b=2,c={},*d,&e")
# => ["a", "b", "c", "*d", "&e"]
#
# Very useful for building proxy functions that call an underlying function
#
class MethodArgs
  MAX_ARGS = 20
  attr_reader :params, :last_args

  def defined_test_method(sig)
    instance_eval <<EOS
def tester(#{sig})
  @values = {}
  @params = []
  local_variables.each {|x| @values[x] = eval(x) }
  local_variables.each do |x|
    val = @values[x]
    if val.is_a?(Array)
      @params << "*#{'#{x}'}"
    elsif val.is_a?(Proc)
      @params << "&#{'#{x}'}"
    else
      @params << x
    end
  end
  throw :done
end
EOS
  end


  def test_method(*args)
    tester(*args) { 1 }
  end

  def output_arg_info(sig)
    defined_test_method(sig)
    @params = nil
    @values = nil
    meth = method(:tester)
    arity = meth.arity
    if arity >= 0
      catch(:done) do
        test_method(*(0...arity))
      end
    else
      # determine number of args (including splat & block)
      MAX_ARGS.downto(arity.abs - 1) do |i|
        catch(:done) do
          begin
            test_method(*(0...i))
          rescue Exception
          end
        end
      end
    end
    @params
  end
end

