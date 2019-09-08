
# TODO setup logger
# TODO debug flag

# TODO doc avec event et sans event

# TODO verifier assert boolean

# Check function a passer en private 
# TODO read_raw en private

require 'i2c'
require 'pp'

# Helper to display hex number as string
class Numeric
	def to_shex
		"0x%02X" % [self]
	end
end

module Neotrellis
	# Driver for Seesaw i2c generic conversion trip
	# :param String device: Linux I2C-dev file the SeeSaw is connected to
	# :param Integer addr: I2C address of the SeeSaw device
	class SeeSaw
		# Default SeeSaw I2C address is 0x49
		DEFAULT_I2C_ADDR = 0x49
		HW_ID_CODE = 0x55

		STATUS_BASE = 0x00
		STATUS_SWRST = 0x7F
		STATUS_HW_ID = 0x01
		STATUS_VERSION = 0x02

	# TODO arguments nommer
		def initialize(device, addr = DEFAULT_I2C_ADDR, debug: false)
		# TOD ogetino erreru

			@i2c = I2C.create(device)
			@addr = addr
			@debug = debug

			sw_reset
		rescue I2C::AckError
			STDERR.puts "I2C initialization error, check your wiring and I2C addresses."
			raise
		end

		# Trigger a software reset of the SeeSaw chip
		def sw_reset()
			write(STATUS_BASE, STATUS_SWRST, 0xFF)

			# Give some time to the device to reset (but not when testing)
			sleep(0.5) unless testing?

			chip_id = read_byte(STATUS_BASE, STATUS_HW_ID)

			if chip_id != HW_ID_CODE
				raise "Seesaw hardware ID returned #{chip_id.to_shex} is not correct! Expected #{HW_ID_CODE.to_shex}. Please check your wiring."
			end
		end

		def version()
			# 4 bytes for Unsigned Int Big Endian
			@i2c.read(@addr, 4, STATUS_BASE, STATUS_VERSION).unpack('I>').first
		end

	# TODO refactor with read_raw
		def read_byte(base_reg, function_reg)
			@i2c.read(@addr, 1, base_reg, function_reg).ord
		end

		def read_bytes(size, base_reg, function_reg)
			@i2c.read(@addr, size, base_reg, function_reg).unpack("C#{size}")
		end

		def read_raw(len, base_reg, function_reg)
			@i2c.read(@addr, len, base_reg, function_reg)
		end

		def write(base_reg, function_reg, *data)
			# TODO doc data must be byte array or string big endian
			puts "DEBUG: I2C WRITE: %02X %02X %s" % [base_reg, function_reg, data.map{|i| "%02X" % [i]}.join(' ')] if @debug
			@i2c.write(@addr, base_reg, function_reg, *data)
		end

		private

		def testing?
			ENV['RSPEC_TEST']&.downcase == 'true'
		end
	end
end

# vim: ts=4:sw=4:ai
