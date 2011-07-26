#--
###############################################################################
#                                                                             #
# A component of athena, the database file converter.                         #
#                                                                             #
# Copyright (C) 2007-2011 University of Cologne,                              #
#                         Albertus-Magnus-Platz,                              #
#                         50923 Cologne, Germany                              #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# athena is free software; you can redistribute it and/or modify it under the #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# athena is distributed in the hope that it will be useful, but WITHOUT ANY   #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with athena. If not, see <http://www.gnu.org/licenses/>.              #
#                                                                             #
###############################################################################
#++

require 'nuggets/util/cli'
require 'athena'

module Athena

  class CLI < ::Util::CLI

    class << self

      def defaults
        super.merge(
          :config => 'config.yaml',
          :input  => '-',
          :output => '-',
          :target => nil
        )
      end

    end

    def run(arguments)
      spec = options[:spec] || options[:spec_fallback]
      abort "No input format (spec) specified and none could be inferred." unless spec
      abort "Invalid input format (spec): #{spec}. Use `-L' to get a list of available specs." unless Athena.valid_input_format?(spec)

      format = options[:format] || options[:format_fallback]
      abort "No output format specified and none could be inferred." unless format
      abort "Invalid output format: #{format}. Use `-l' to get a list of available formats." unless Athena.valid_output_format?(format)

      target_config = if t = options[:target]
        config[target = t.to_sym]
      else
        [options[:target_fallback] || 'generic', ".#{spec}", ":#{format}"].inject([]) { |s, t|
          s << (s.last ? s.last + t : t)
        }.reverse.find { |t| config[target = t.to_sym] }
      end or abort "Config not found for target: #{target}."

      parser = Athena.parser(target_config, spec)

      input = options[:input]
      input = arguments.shift unless input != defaults[:input] || arguments.empty?
      options[:input] = File.directory?(input) ? Dir.open(input) : open_file_or_std(input)

      quit unless arguments.empty?

      options[:output] = open_file_or_std(options[:output], true)

      if Athena.deferred_output?(format)
        res = parser.parse(options[:input])

        res.map { |record|
          record.to(format)
        }.flatten.sort.uniq.each { |line|
          options[:output].puts line
        }
      elsif Athena.raw_output?(format)
        res = Athena.with_format(format, options[:output]) { |_format|
          parser.parse(options[:input]) { |record|
            record.to(_format)
          }
        }
      else
        res = Athena.with_format(format) { |_format|
          parser.parse(options[:input]) { |record|
            options[:output].puts record.to(_format)
          }
        }
      end
    end

    private

    def merge_config(args = [default])
      super
    end

    def opts(opts)
      opts.on('-c', '--config YAML', "Config file [Default: #{defaults[:config]}#{' (currently not present)' unless File.readable?(defaults[:config])}]") { |config|
        quit "Can't find config file: #{config}" unless File.readable?(config)

        options[:config] = config
      }

      opts.separator ''

      opts.on('-i', '--input FILE',  "Input file [Default: STDIN]") { |input|
        options[:input] = input

        parts = File.basename(input).split('.')
        options[:spec_fallback]   = parts.last.downcase
        options[:target_fallback] = parts.size > 1 ? parts[0..-2].join('.') : parts.first
      }

      opts.on('-s', '--spec SPEC', "Input format (spec) [Default: file extension of <input-file>]") { |spec|
        options[:spec] = spec.downcase
      }

      opts.on('-L', '--list-specs', "List available input formats (specs) and exit") {
        puts 'Available input formats (specs):'

        Athena.input_formats.each { |format, name|
          puts "  - #{format}#{" (= #{name})" if format != name.to_s}"
        }

        exit
      }

      opts.separator ''

      opts.on('-o', '--output FILE',  "Output file [Default: STDOUT]") { |output|
        options[:output] = output
        options[:format_fallback] = output.split('.').last.downcase
      }

      opts.on('-f', '--format FORMAT', "Output format [Default: file extension of <output-file>]") { |format|
        options[:format] = format.downcase
      }

      opts.on('-l', '--list-formats', "List available output formats and exit") {
        puts 'Available output formats:'

        Athena.output_formats.each { |format, name|
          puts "  - #{format}#{" (= #{name})" if format != name.to_s}"
        }

        exit
      }

      opts.separator ''

      opts.on('-t', '--target ID', "Target whose config to use [Default: <input-file> minus file extension,", "plus '.<spec>', plus ':<format>' (reversely in turn)]") { |target|
        options[:target] = target
      }
    end

  end

end