# Code to extract the formal parameter names and types from a function
# given a standard Ruby function argument signature.  Original code based
# on the MethodArgs module written by Mauricio Fernandez <mfp@acm.org>
# (http://eigenclass.org).  Updated to work with function signatures added at
# runtime, also, peroperly handles block arguments.
#
# Author::    Jim Powers (mailto:jim@corruptmemory.com)
# Copyright:: Copyright (c) 2008-2009 Jim Powers
# License::   Distributed under the terms of the LGPLv3.0 or newer.
#             For details see the LGPL30 file
#
# == Example:
#
# require 'method_args'
# MethodArgsHelper.get_args("a, b = {}, *c, &d")
# => ["a", "b", "*c", "&d"]
#
# Very useful for building proxy functions that call an underlying function
#
class MethodArgs
  MAX_ARGS = 20
  attr_reader :params

  def output_method_info(klass, object, meth, is_singleton = false)
    @params = nil
    @values = nil
    num_args = 0
    unless %w[initialize].include?(meth.to_s)
      if is_singleton
        return if class << klass; private_instance_methods(true) end.include?(meth.to_s)
      else
        return if class << object; private_instance_methods(true) end.include?(meth.to_s)
      end
    end
    arity = is_singleton ? object.method(meth).arity : klass.instance_method(meth).arity
    set_trace_func lambda{|event, file, line, id, binding, classname|
      begin
        if event[/call/] && classname == MethodArgsHelper && id == meth
          @params = eval("local_variables", binding)
          @values = eval("local_variables.map{|x| eval(x)}", binding)
          throw :done
        end
      rescue Exception
      end
    }
    if arity >= 0
      num_args = arity
      catch(:done){ object.send(meth, *(0...arity)) }
    else
      # determine number of args (including splat & block)
      MAX_ARGS.downto(arity.abs - 1) do |i|
        catch(:done) do
          begin
            object.send(meth, *(0...i))
          rescue Exception
          end
        end
        next if !@values || @values.compact.empty?
        k = nil
        @values.each_with_index{|x,j| break (k = j) if Array === x}
        if k
          num_args = k+1
        else
          num_args = i
        end
      end
      args = (0...arity.abs-1).to_a
      catch(:done) do
        args.empty? ? object.send(meth) : object.send(meth, *args)
      end
    end
    set_trace_func(nil)
    fmt_params = lambda do |arr, arity|
      arr.inject([[], 0]) do |(a, i), x|
        if Array === @values[i]
          [a << "*#{x}", i+1]
        else
          [a << x, i+1]
        end
      end.first
    end
    original_params = @params
    @params ||= []
    @params = @params[0,num_args]
    @params = fmt_params.call(@params,arity)
    if @params.length < original_params.length
      @params << "&#{original_params[-1]}"
    end
    set_trace_func(nil)
  end
end

class MethodArgsHelper
  @@last_args = nil

  def self.method_added(meth)
    begin
      o = self.allocate
    rescue Exception
      p $!
    end
    ma = MethodArgs.new
    ma.output_method_info(self, o, meth, false)
    @@last_args = ma.params
  end

  def self.get_args(sig)
    class_eval <<EOS
def tester(#{sig})
end
EOS
    @@last_args
  end
end

