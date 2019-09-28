
# TODO doc avec event et sans event

# TODO verifier assert boolean

# Check function a passer en private 

require 'ya_gpio'

module Neotrellis
	class Keypad
		KEYPAD_BASE = 0x10

		KEYPAD_STATUS = 0x00
		KEYPAD_EVENT = 0x01
		KEYPAD_INTENSET = 0x02
		KEYPAD_INTENCLR = 0x03
		KEYPAD_COUNT = 0x04
		KEYPAD_FIFO = 0x10

		KEY_HIGH = 0
		KEY_LOW = 1
		KEY_RELEASED = 2
		KEY_PRESSED = 3


		def initialize(seesaw, interrupt_pin: false, debug: false)
			@seesaw = seesaw
			@debug = debug
			@callbacks = {}

			enable_interrupt(interrupt_pin) if interrupt_pin
		end

		def count_events
			@seesaw.read_byte(KEYPAD_BASE, KEYPAD_COUNT)
		end

		def set_event(key, event:, enabled: true, &block)
			raise "event must be one of KEY_PRESSED, KEY_RELEASED" unless [KEY_PRESSED, KEY_RELEASED].include? event
			raise "enabled must be a boolean" unless [true, false].include? enabled

			# Convert data to SeeSaw's binary registers
			key_b = (key/4)*8 + (key%4)
			edge_b = (1 << (event+1)) | ( enabled ? 1 : 0 )

			@seesaw.write(KEYPAD_BASE, KEYPAD_EVENT, key_b, edge_b)
			@callbacks[KeyEvent.new(key, event)] = block
		end

		def sync
			count = count_events()
			if count >0
				read_events(count).each do |event|
					trigger_event(event)
				end
			end
		end

		# pin are in the BCM numbering, as reported by Sysfs
		def enable_interrupt(pin)
			raise "pin must be an integer" unless pin.is_a? Integer

			@interrupt_enabled=true
			@seesaw.write(KEYPAD_BASE, KEYPAD_INTENSET, 0x01)

			@gpio = YaGPIO.new(pin, YaGPIO::INPUT)
			@gpio.set_interrupt(YaGPIO::EDGE_FALLING) do 
				puts "DEBUG Interrupt received." if @debug
				sync
			end
		end

		def interrupt?
			@interrupt_enabled
		end

		def disable_interrupt
			@interrupt_enabled=false
			@seesaw.write(KEYPAD_BASE, KEYPAD_INTENCLR, 0x01)
			@gpio.close
		end

		def wait_for_event
			raise "Interrupt is not enabled. Setup enable_interrupt() first" unless interrupt?
			YaGPIO::wait([@gpio])
		end

		def resume
			YaGPIO::resume
		end

		class KeyEvent
			attr_reader :key, :edge

			def initialize(key, edge)
				@key = key
				@edge = edge
			end

			def to_s
				"Event-#{key}-#{edge}"
			end

			def ==(other)
				@key == other.key && @edge == other.edge
			end

			alias eql? ==

			def hash
				@key.hash ^ @edge.hash # XOR
			end
		end

		private

		def read_events(count)
			@seesaw.read_bytes(count, KEYPAD_BASE, KEYPAD_FIFO).map do |raw|
				# Convert raw event into key number
				val = (raw >> 2) & 0x3F
				key = (val/8)*4 + (val%8)
				edge = raw & 0x3

				KeyEvent.new(key, edge)
			end
		end

		def trigger_event(event)
			callback = @callbacks[event]
			if callback.nil?
				puts "WARNING: No callback defined for #{event}"
			else
				callback.call(event)
			end
		end
	end
end

# vim: ts=4:sw=4:ai
