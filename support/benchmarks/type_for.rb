# -*- ruby encoding: utf-8 -*-

require 'mime/types'
require 'benchmark'
require 'debugger'

module Benchmarks
  class TypeFor
    def self.report(repeats)
      new(repeats.to_i).report
    end

    def initialize(repeats = nil)
      @repeats    = repeats.to_i
      @repeats    = 1000 if repeats <= 0
      @expected   = {}
      index       = MIME::Types.send(:__types__).
        instance_variable_get(:@extension_index)
      index.each { |k, v|
        @expected[k] = v.sort { |a, b| a.priority_compare(b) }.uniq
      }
      @extensions = @expected.keys.sort.uniq
    end

    def perform
      @repeats.times {
        @extensions.each { |extension|
          unless MIME::Types.type_for(extension) == @expected[extension]
            raise ArgumentError, extension
          end
        }
      }
    end

    def report
      Benchmark.bm(17) do |mark|
        mark.report('gsub:') { perform }

        type_for_with_split
        mark.report('split:') { perform }

        type_for_with_index_regex
        mark.report('index:') { perform }
      end
    end

    def type_for_with_split
      MIME::Types.send(:define_method, :type_for) do |fn, pf = false|
        types = Array(fn).flat_map { |fn|
          @extension_index[fn.chomp.downcase.split(/\./o).last]
        }.compact.sort { |a, b| a.priority_compare(b) }.uniq

        if pf
          MIME.deprecated(self, __method__,
                          "using the platform parameter")
          types.select(&:platform?)
        else
          types
        end
      end
    end

    def type_for_with_index_regex
      MIME::Types.send(:define_method, :type_for) do |fn, pf = false|
        types = Array(fn).flat_map { |fn|
          @extension_index[fn.chomp.downcase[/\.?([^.]*?)$/, 0]]
        }.compact.sort { |a, b| a.priority_compare(b) }.uniq

        if pf
          MIME.deprecated(self, __method__,
                          "using the platform parameter")
          types.select(&:platform?)
        else
          types
        end
      end
    end
  end
end
