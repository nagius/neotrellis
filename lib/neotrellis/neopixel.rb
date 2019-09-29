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


# Neotrellis is a ruby driver for Adafruit's NeoTrellis keypad
module Neotrellis

	# NeoPixel is the driver of the RGB led array on the Neotrellis device.
	# TODO examples
	class NeoPixel
		attr_reader :brightness   # Get the brightness of the leds.
		attr_accessor :autoshow   # Enable autoshow feature. Automatically call `show()` after each update.

		DEFAULT_PIXEL_NUMBER = 16 # Default number of leds on the neotrellis 4x4 keypad

		private

			NEOPIXEL_BASE = 0x0E

			NEOPIXEL_STATUS = 0x00
			NEOPIXEL_PIN = 0x01
			NEOPIXEL_SPEED = 0x02
			NEOPIXEL_BUF_LENGTH = 0x03
			NEOPIXEL_BUF = 0x04
			NEOPIXEL_SHOW = 0x05

		public

		# Initialize a neopixel array driven by a seesaw chip.
		#
		# @param seesaw [Neotrellis::SeeSaw] Seesaw driver
		# @param size [Integer] Number of leds on the array
		# @param autoshow [Boolean] Automatically call `show()` after each update
		# @param brightness [Float] Brightness of the leds. Must be between 0.0 and 1.0
		def initialize(seesaw, size: DEFAULT_PIXEL_NUMBER, autoshow: true, brightness: 1.0)
			@seesaw = seesaw
			@pin = 3				# NeoPixel bus is on SeeSaw's pin 3
			@n = size 				# Number of NeoPixels on the bus
			@bpp = 3				# 3 bytes per pixel
			@autoshow = autoshow	# Automaticaly display data in buffer
			@brightness = [[brightness, 0.0].max, 1.0].min

			# Size of RGB buffer, 2 bytes for Unsigned Int Big Endian
			buf_length = [@n*@bpp].pack('S>').unpack('C*')

			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_PIN, @pin)
			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_BUF_LENGTH, *buf_length)
		end

		# Set the brightness of the leds
		#
		# @param brightness [Float] Brightness of the leds. Must be between 0.0 and 1.0
		#
		# @return [Float] New brightness value
		def brightness=(brightness)
			@brightness = [[brightness, 0.0].max, 1.0].min
		end

		# Set the color of one pixel.
		# If `autoshow` is false nothing will be displayed until you call the `show()` method.
		#
		# @param pixel [Integer] ID of the pixel in the array. Must be between 0 and `size`-1
		# @param color [Neotrellis::NeoPixel::Color] Color to display by the pixel
		def set(pixel, color)
			raise "pixel out of range" unless pixel.between?(0, @n-1)

			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_BUF, *([pixel*@bpp].pack('S>').unpack('C*')), *color.to_b(brightness))
			show if @autoshow
		end

		# Render the data already written in the Seesaw buffer.
		# If `autoshow` is true, this method is called automatically by `set()` and `fill()`
		def show
			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_SHOW)
		end

		# Set the same color for all pixels of the array.
		# If `autoshow` is false nothing will be displayed until you call the `show()` method.
		#
		# @param color [Neotrellis::NeoPixel::Color] Color to display by the pixels
		def fill(color)
			# Disable auto show while filling the buffer
			current_autoshow = @autoshow
			@autoshow=false

			@n.times do |pixel|
				set(pixel, color)
			end

			@autoshow = current_autoshow
			show if @autoshow
		end

		# Define a color to be set on a pixel
		class Color
			attr_reader :r, :g, :b  # R G B components

			# Create a new color.
			# R G B values must be between 0 and 255
			#
			# @param r [Integer] Red component
			# @param g [Integer] Green component
			# @param b [Integer] Blue component
			def initialize(r, g, b)
				@r = within_range(r)
				@g = within_range(g)
				@b = within_range(b)
			end

			# Apply a brightness to the color.
			#
			# @param brightness [Float] Brightness of the color. Must be between 0.0 and 1.0
			#
			# @return [Array] Color values as integer in the order GRB
			def to_b(brightness = 1.0)
				# Order is GRB
				[(@g*brightness).to_i, (@r*brightness).to_i, (@b*brightness).to_i]
			end

			private

			def within_range(byte)
				[[byte, 0].max, 255].min
			end
		end

		# Default common colors
		OFF 	= Color.new(0, 0, 0)
		RED 	= Color.new(255, 0, 0)
		YELLOW 	= Color.new(255, 150, 0)
		GREEN 	= Color.new(0, 255, 0)
		CYAN 	= Color.new(0, 255, 255)
		BLUE 	= Color.new(0, 0, 255)
		PURPLE 	= Color.new(180, 0, 255)
	end
end

# vim: ts=4:sw=4:ai
