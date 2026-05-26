# This file is part of CPEE-LIGHT.
#
# CPEE-LIGHT is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# CPEE-LIGHT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with CPEE-LIGHT (file LICENSE in the main directory).  If not, see
# <http://www.gnu.org/licenses/>.

require 'xml/smart'
require 'riddl/server'
require 'json'

module CPEE
  module Light

    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class GetOne < Riddl::Implementation #{{{
      def response
        op = @a[0]
        value = File.read(op[:read]).to_i rescue 0
        scale = File.read(op[:scale]).to_f rescue 0
        Riddl::Parameter::Simple.new('lumens',value*scale)
      end
    end #}}}
    class GetMany < Riddl::Implementation #{{{
      def response
        op = @a[0]
        cb = @h['CPEE_CALLBACK']
        EM.defer do
          if cb.is_a?(String)
            while true
              Riddl::Client.new(cb).put([
                Riddl::Header.new('CPEE-UPDATE','true'),
                Riddl::Parameter::Simple.new('lumens',value*scale)
              ]) if cb.is_a?(String)
              sleep 1
            end
          end
        end
        @headers << Riddl::Header.new('CPEE-CALLBACK','true')
      end
    end #}}}

    class State < Riddl::Implementation #{{{
      def response
        op = @a[0]
        l = @r[-1].to_i
        if op[l]
          `#{op[l][@p.first.value.to_sym]}`
        else
          @status = 404
        end
      end
    end #}}}

    class Value < Riddl::Implementation #{{{
      def response
        op = @a[0]
        val = @p.first.value.to_i
        split = 100 / (op.length + 1)
        many = (val / split) - 1
        many = (op.length - 1) if many > (op.length - 1)
        0.upto many do |i|
          `#{op[i][:on]}`
        end
        (many + 1).upto(op.length - 1) do |i|
          `#{op[i][:off]}`
        end
      end
    end #}}}

    def self::implementation(opts)
      opts[:lights] ||= [
        { :on => 'gpioset -c gpiochip1 -t0 0=0', :off => 'gpioset -c gpiochip1 -t0 0=1'},
        { :on => 'gpioset -c gpiochip1 -t0 1=0', :off => 'gpioset -c gpiochip1 -t0 1=1'},
        { :on => 'gpioset -c gpiochip1 -t0 2=0', :off => 'gpioset -c gpiochip1 -t0 2=1'}
      ]
      opts[:sensor] ||= {
        :read => '/sys/bus/iio/devices/iio:device0/in_illuminance_raw',
        :scale => '/sys/bus/iio/devices/iio:device0/in_illuminance_scale'
      }

      Proc.new do
        on resource do
          on resource 'light' do
            run Value, opts[:lights] if put 'intensity'
            on resource '\d+' do
              run State, opts[:lights] if put 'state'
            end
          end
          on resource 'sensor' do
            run GetOne, opts[:sensor] if get 'one'
            run GetMany, opts[:sensor] if get 'continuous'
          end
        end
      end
    end

  end
end
