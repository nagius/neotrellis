# Neotrellis - Driver for Adafruit's NeoTrellis keypad
# Copyleft 2019 - Nicolas AGIUS <nicolas.agius@lps-it.fr>

###########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

require 'ya_gpio'

module Neotrellis
	# Driver for the Neotrellis 4x4 keypad.
	#
	# @example Print a message when key #3 is pressed
	#   seesaw = Neotrellis::Seesaw.new(device: "/dev/i2c-1", addr: 0x2E)
	#   keypad = Neotrellis::Keypad.new(seesaw)
	#   keypad.set_event(2, event: Neotrellis::Keypad::KEY_PRESSED) { |event|
	#   	puts "Key #{event.key} pressed"
	#	}
	#   loop do
	#   	sleep(1)
	#   	puts "Processing pending events"
	#   	keypad.sync
	#   end
	#
	# @example Print a message when key #3 is released using interruption on GPIO pin 22
	#   seesaw = Neotrellis::Seesaw.new(device: "/dev/i2c-1", addr: 0x2E)
	#   keypad = Neotrellis::Keypad.new(seesaw)
	#   keypad.set_event(2, event: Neotrellis::Keypad::KEY_RELEASED) { |event|
	#   	puts "Key #{event.key}"
	#		puts event.edge == Neotrellis::Keypad::KEY_PRESSED ? "pressed" : "released"
	#	}
	#   keypad.enable_interrupt(22)
	#   keypad.wait_for_event
	#
	# @example Stop waiting for events when key #4 is pressed
	#   seesaw = Neotrellis::Seesaw.new(device: "/dev/i2c-1", addr: 0x2E)
	#   keypad = Neotrellis::Keypad.new(seesaw, interrupt_pin: 22)
	#   keypad.set_event(3, event: Neotrellis::Keypad::KEY_PRESSED) {
	#   	keypad.resume
	#	}
	#   keypad.wait_for_event
	#   puts "loop ended"
	class Keypad

		private
			# Internal SeeSaw registers
			KEYPAD_BASE = 0x10

			KEYPAD_STATUS = 0x00
			KEYPAD_EVENT = 0x01
			KEYPAD_INTENSET = 0x02
			KEYPAD_INTENCLR = 0x03
			KEYPAD_COUNT = 0x04
			KEYPAD_FIFO = 0x10

		public

		KEY_HIGH = 0     # Key is pressed
		KEY_LOW = 1      # Key is released
		KEY_RELEASED = 2 # Key is falling edge
		KEY_PRESSED = 3  # Key is rising edge

		# Initialize the keypad driven by a Seesaw chip.
		#
		# @param seesaw [Neotrellis::SeeSaw] Seesaw driver
		# @param interrupt_pin [Integer] GPIO pin used by the interruption handler. If false, the interruption mode will be disabled.
		# @param debug [Boolean] Enable debug ouput on stdout
		def initialize(seesaw, interrupt_pin: false, debug: false)
			@seesaw = seesaw
			@debug = debug
			@callbacks = {}

			enable_interrupt(interrupt_pin) if interrupt_pin
		end

		# Get the number of events (key pressed or released) waiting to be processed in the Seesaw buffer.
		#
		# @return [Integer] Number of events
		def count_events
			@seesaw.read_byte(KEYPAD_BASE, KEYPAD_COUNT)
		end

		# Register a callback to execute when a key's event is processed.
		#
		# @param key [Integer] ID of the key. Must be between 0 and 15 (for the 4x4 keypad)
		# @param event [Neotrellis::Keypad::KEY_PRESSED|Neotrellis::Keypad::KEY_RELEASED] Type of event to react to.
		# @param enabled [Boolean] If false, the callback will be disabled.
		# @param block [Block] Code to execute when the event is trigerred. A Neotrellis::Keypad::KeyEvent will be passed as argument to the block.
		def set_event(key, event:, enabled: true, &block)
			raise "event must be one of KEY_PRESSED, KEY_RELEASED" unless [KEY_PRESSED, KEY_RELEASED].include? event
			raise "enabled must be a boolean" unless [true, false].include? enabled

			# Convert data to SeeSaw's binary registers
			key_b = (key/4)*8 + (key%4)
			edge_b = (1 << (event+1)) | ( enabled ? 1 : 0 )

			@seesaw.write(KEYPAD_BASE, KEYPAD_EVENT, key_b, edge_b)
			@callbacks[KeyEvent.new(key, event)] = block
		end

		# Trigger the callback for each event waiting to be processed.
		# This method will be automatically called when the interruption mode is enabled.
		def sync
			count = count_events()
			if count >0
				read_events(count).each do |event|
					trigger_event(event)
				end
			end
		end

		# Enable the interruption mode.
		# In this mode, the `sync()`  method will be automatically called when an interruption is triggered by the Seesaw device.
		# The INT ligne of the keypad need to be connected to this GPIO pin.
		#
		# @param pin [Integer] GPIO pin to configure for interruption on. Pin number is in the BCM numbering, as reported by Sysfs.
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

		# Tell if the interruption mode is enabled.
		#
		# @return [Boolean] True if interruption mode is enabled.
		def interrupt?
			@interrupt_enabled
		end

		# Disable interruption mode and release the GPIO pin.
		def disable_interrupt
			@interrupt_enabled=false
			@seesaw.write(KEYPAD_BASE, KEYPAD_INTENCLR, 0x01)
			@gpio.close
		end

		# Wait for an interruption and process all pending event.
		# The interruption mode must be enabled for this method to work.
		# This is a blocking method. Use `resume()` inside a callback to stop waiting.
		def wait_for_event
			raise "Interrupt is not enabled. Setup enable_interrupt() first" unless interrupt?
			YaGPIO::wait([@gpio])
		end

		# Stop waiting for an event in the interruption mode.
		# This need to be run from a callback triggered by `wait_for_event()`.
		def resume
			YaGPIO::resume
		end

		# Represent an event attached to a key
		class KeyEvent
			attr_reader :key  # Key ID
			attr_reader :edge # Event type

			# Create a new event.
			#
			# @param key [Integer] Key ID related to the event
			# @param edge [Neotrellis::Keypad::KEY_PRESSED|Neotrellis::Keypad::KEY_RELEASED] Type of event
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
