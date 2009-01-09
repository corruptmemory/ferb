# Helper module to make it easy to use Ferb within Rails
#
# Author::    Jim Powers (mailto:jim@corruptmemory.com)
# Copyright:: Copyright (c) 2008-2009 Jim Powers
# License::   Distributed under the terms of the LGPLv3.0 or newer.
#             For details see the LGPL30 file
#
# To use require <tt>ferb_helper</tt> in your environment.rb file.  Then
# include <tt>FerbHelper</tt> in any helper files you wish.  Also, to use
# within your controllers add the following to your application cotroller:
#
# def self.inherited(subclass)
#   super(subclass)
#   subclass.send :include, FerbHelper
# end
#
require 'ferb'
module FerbHelper
  def self.included(base)
    base.send :include, Ferb
    path_suffix = ''
    if base.name =~ /Helper$/i
      path_suffix = "#{base.name.gsub(/Helper$/,'').underscore}/"
    elsif base.name =~ /Controller$/i
      path_suffix = "#{base.name.gsub(/Controller$/,'').underscore}/"
    end
    base.template_root = Pathname.new(RAILS_ROOT)+'app/views/' + path_suffix
  end
end
