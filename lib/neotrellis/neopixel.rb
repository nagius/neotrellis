
module Neotrellis
	class NeoPixel
		attr_reader :brightness
		attr_accessor :autoshow

		DEFAULT_PIXEL_NUMBER = 16

		private

			NEOPIXEL_BASE = 0x0E

			NEOPIXEL_STATUS = 0x00
			NEOPIXEL_PIN = 0x01
			NEOPIXEL_SPEED = 0x02
			NEOPIXEL_BUF_LENGTH = 0x03
			NEOPIXEL_BUF = 0x04
			NEOPIXEL_SHOW = 0x05

		public

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

		def brightness=(brightness)
			@brightness = [[brightness, 0.0].max, 1.0].min
		end

		def set(pixel, color)
			raise "pixel out of range" unless pixel.between?(0, @n-1)

			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_BUF, *([pixel*@bpp].pack('S>').unpack('C*')), *color.to_b(brightness))
			show if @autoshow
		end

		# Display data in buffer
		def show
			@seesaw.write(NEOPIXEL_BASE, NEOPIXEL_SHOW)
		end

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

# TODO range check
		class Color
			attr_accessor :r, :g, :b

			def initialize(r, g, b)
				@r = r
				@g = g
				@b = b
			end

			def to_b(brightness = 1.0)
				# Order is GRB
				[(@g*brightness).to_i, (@r*brightness).to_i, (@b*brightness).to_i]
			end
		end

	# TODO faire mieux
		OFF = Color.new(0, 0, 0)
		RED = Color.new(255, 0, 0)
		YELLOW = Color.new(255, 150, 0)
		GREEN = Color.new(0, 255, 0)
		CYAN = Color.new(0, 255, 255)
		BLUE = Color.new(0, 0, 255)
		PURPLE = Color.new(180, 0, 255)
	end
end

# vim: ts=4:sw=4:ai
