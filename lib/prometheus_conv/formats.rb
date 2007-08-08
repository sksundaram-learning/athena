#--
###############################################################################
#                                                                             #
# A component of prometheus_conv, the prometheus file converter.              #
#                                                                             #
# Copyright (C) 2007 University of Cologne,                                   #
#                    Albertus-Magnus-Platz,                                   #
#                    50932 Cologne, Germany                                   #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# prometheus_conv is free software; you can redistribute it and/or modify it  #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation; either version 2 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# prometheus_conv is distributed in the hope that it will be useful, but      #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with prometheus_conv [*]; if not, write to the Free Software Foundation,    #
# Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.              #
#                                                                             #
# [*] For the complete text of the GNU General Public License see the file    #
#     COPYING or point your browser at <http://www.gnu.org/licenses/gpl.txt>  #
#                                                                             #
###############################################################################
#++

module PrometheusConv

  class Formats

    @formats = {}

    class << self

      def formats
        PrometheusConv::Formats.instance_variable_get :@formats
      end

      def [](format)
        formats[format]
      end

      def valid_format?(format)
        formats.include? format
      end

      def convert(*args)
        raise NotImplementedError, 'must be defined by sub-class'
      end

      private

      def inherited(klass)
        klass.send :register_format, klass.name.split('::').last.downcase
      end

      def register_format(format)
        formats[format] = self
      end

    end

  end
  
end

Dir.glob(__FILE__.sub(/\.rb$/, '/**/*.rb')).each { |rb|
  require rb
}