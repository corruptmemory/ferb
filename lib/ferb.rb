# This is a mixin module that makes it easy to define methods on a
# class that are expanded using an ERB template
#
# Author::    Jim Powers (mailto:jim@corruptmemory.com)
# Copyright:: Copyright (c) 2008-2009 Jim Powers
# License::   Distributed under the terms of the LGPLv3.0 or newer.  
#             For details see the LGPL30 file
#
# == Example:
# 
# class Foo
#  require 'ferb'
#  include Ferb
#
#  def_template("hello_world(m)","<b><%= m %></b>")
#
# end
#
module Ferb
  require 'erb'
  require 'pathname'
  require 'stringio'
  require 'method_args'

  # Enables support for reloading file templates at run-time
  # if the file timestamp has changed
  def self.enable_reload?
    if defined?(@@enable_reload)
      return @@enable_reload
    else
      return false
    end
  end

  # Enables support for reloading file templates at run-time
  # if the file timestamp has changed
  def self.enable_reload=(val)
    @@enable_reload = val
  end

  # The "callback" when this module is included by a class.  Extends
  # the class with the metods defined in the inner 'ClassMethods'
  # module
  def self.included(base)
    base.extend(ClassMethods)
  end

  def self.build_internal_template(signature,body)
    body_rb = ERB.new(body,nil,'-').src
    <<EOS
def __ferb_#{signature}
#{body_rb}
end
EOS
  end


  # Builds a string representing the definition of the function
  def self.build_template(signature, clean_sig, source_file_data = nil, function = nil)
    unless source_file_data
    <<EOS
def #{signature}
  __ferb_#{clean_sig}
end
EOS
    else
    <<EOS
def #{signature}
  if Ferb.enable_reload?
    full_path = '#{source_file_data[:full_path]}'
    signature = '#{function}'
    if should_reload?(full_path)
      args = {:path => full_path}
      template = Ferb.load_template(args)
      add_timestamp(args[:full_path], args[:timestamp])
      internal_func = Ferb.construct_internal_function_def(signature,template)
      eval(internal_func)
    end
  end
  __ferb_#{clean_sig}
end
EOS
    end
  end    

  def self.load_template(args)
    result = nil
    path = nil
    if args.has_key?(:path)
      path = Pathname.new(args[:path].to_s.strip)
    elsif args.has_key?(:file)
      template_root = args[:template_root]
      unless template_root.is_a?(Pathname)
        template_root = Pathname.new(args[:template_root].to_s)
      end
      args[:template_root] = template_root
      path = template_root+args[:file]
    else
      raise(":file or :path not specified: #{args.inspect}")
    end
    args[:full_path] = path.realpath
    args[:timestamp] = path.mtime
    path.open do |f|
      result = f.read
    end
    result
  end

  def self.get_template_parts(template)
    result = nil
    if template and !template.strip.empty?
      strio = StringIO.new(template)
      first_line = strio.readline
      if first_line.strip =~ /^<!--.*\|(.*)\|.*-->$/
        sig = $1
        body = strio.read
        result = [sig, body]
      else
        body = template
      end
    end
    result
  end

  def self.construct_function_sig(function, sig)
    sig = sig.strip
    if !sig.empty?
      ["#{function.to_s.strip}(#{sig})", "#{function.to_s.strip}(#{MethodArgsHelper.get_args(sig).join(',')})"]
    else
      [function.to_s.strip, nil]
    end
  end

  def self.construct_function_def(function, template, args = nil)
    parts = get_template_parts(template)
    funsig = nil
    clean_sig = nil
    if parts.is_a?(Array)
      funsig, clean_sig = construct_function_sig(function,parts[0])
    else
      funsig = function
    end
    build_template(funsig, clean_sig, args, function)
  end

  def self.construct_internal_function_def(function, template)
    parts = get_template_parts(template)
    funsig = nil
    clean_sig = nil
    body = nil
    if parts.is_a?(Array)
      funsig, clean_sig = construct_function_sig(function,parts[0])
      body = parts[1]
    else
      funsig = function
      body = template
    end
    build_internal_template(funsig, body)
  end

  # Inner module holding the actual methods to be added to the class
  module ClassMethods

    public
    # Hash of file timestamps
    def file_timestamps
      unless defined?(@file_timestamps)
        @file_timestamps = {}
      end
      @file_timestamps
    end

    # Record file timestamps
    def add_timestamp(path, time)
      self.file_timestamps[path.to_s] = time
    end

    # Test file timestamps
    def should_reload?(path)
      time = Pathname.new(path.to_s).mtime
      ts = self.file_timestamps[path]
      if ts and (ts >= time)
        return false;
      else
        return true
      end
    end

    # Returns the root in the file system where ERB templates can be found
    def template_root
      if !defined?(@template_root)
        @template_root = Pathname.new(File.expand_path(File.dirname(__FILE__)))
      end
      @template_root
    end

    # Sets the root in the file system where ERB templates can be found
    def template_root=(location)
      @template_root = Pathname.new(File.expand_path(location.to_s))
    end


    # Defines a template function as an instance method.  Creates the
    # method directly on the class.
    #
    # == Arguments:
    #
    #  <tt>signature</tt> - (string) The complete signature including parameters
    #  <tt>body</tt> - (string) The body of the functionusing ERB syntax
    #
    # == Example:
    #
    # def_template("hello_world(message)","<b><%= message %></b>")
    #
    def def_template(signature,args)
      if args.is_a?(String)
        internal_func = Ferb.construct_internal_function_def(signature,args)
        external_func = Ferb.construct_function_def(signature,args)
        module_eval(internal_func)
        module_eval(external_func)
      elsif args.is_a?(Hash)
        args = { :template_root => template_root}.merge(args)
        template = Ferb.load_template(args)
        add_timestamp(args[:full_path], args[:timestamp])
        internal_func = Ferb.construct_internal_function_def(signature,template)
        external_func = Ferb.construct_function_def(signature,template,args)
        module_eval(internal_func)
        module_eval(external_func)
      end
    end
  end

  def file_timestamps
    unless defined?(@file_timestamps)
      @file_timestamps = {}
    end
    @file_timestamps
  end

  # Record file timestamps
  def add_timestamp(path, time)
    self.file_timestamps[path] = time
  end

  # Test file timestamps
  def should_reload?(path)
    time = Pathname.new(path).mtime
    ts = self.file_timestamps[path]
    if ts and (ts >= time)
      return false;
    else
      return true
    end
  end

  # Returns the root in the file system where ERB templates can be found
  def template_root
    if !defined?(@template_root)
      if self.class.respond_to?(:template_root)
        @template_root = self.class.template_root
      else
        @template_root = Pathname.new(File.expand_path(File.dirname(__FILE__)))
      end
    end
    @template_root
  end

  # Sets the root in the file system where ERB templates can be found
  def template_root=(location)
    @template_root = Pathname.new(File.expand_path(location))
  end

  # Defines a template function in an individual object (only
  # available to a prticular instance) as an instance method.  Creates
  # the method directly on the object (instance).
  #
  # == Arguments:
  #
  #  <tt>signature</tt> - (string) The complete signature including parameters
  #  <tt>body</tt> - (string) The body of the functionusing ERB syntax
  #
  # == Example:
  #
  # obj.def_template("hello_world(message)","<b><%= message %></b>")
  #
  def def_template(signature,args)
    if args.is_a?(String)
      internal_func = Ferb.construct_internal_function_def(signature,args)
      external_func = Ferb.construct_function_def(signature,args)
      eval(internal_func)
      eval(external_func)
    elsif args.is_a?(Hash)
      args = { :template_root => template_root}.merge(args)
      template = Ferb.load_template(args)
      add_timestamp(args[:full_path], args[:timestamp])
      internal_func = Ferb.construct_internal_function_def(signature,template)
      external_func = Ferb.construct_function_def(signature,template,args)
      eval(internal_func)
      eval(external_func)
    end
  end

end
