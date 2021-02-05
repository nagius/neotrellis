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

require 'i2c'

# Monkey patch, sorry
class Numeric
	# Helper to display hex number as string
	def to_shex
		"0x%02X" % [self]
	end
end

module Neotrellis
	# Driver for Seesaw i2c generic conversion chip.
	# See https://www.adafruit.com/product/3657 for example board.
	#
	# @example Display Seesaw's device version
	#   seesaw = Neotrellis::Seesaw.new(device: "/dev/i2c-1", addr: 0x2E)
	#   puts seesaw.version
	class Seesaw

		DEFAULT_I2C_ADDR = 0x49  # Default SeeSaw I2C address

		private
			# SeeSaw hardware ID
			HW_ID_CODE = 0x55

			# Internal SeeSaw registers
			STATUS_BASE = 0x00
			STATUS_SWRST = 0x7F
			STATUS_HW_ID = 0x01
			STATUS_VERSION = 0x02

		public

		# Initialize a Seesaw chip on the i2c bus.
		# It use the i2c kernel driver to communicate with the chip.
		#
		# @param device [String] Linux I2C-dev file the SeeSaw device is connected to
		# @param addr [Integer] I2C address of the SeeSaw device
		# @param debug [Boolean] Enable debug ouput on stdout
		def initialize(device: '/dev/i2c-0', addr: DEFAULT_I2C_ADDR, debug: false)
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

		# Get the version of the Seesaw chip
		#
		# @return [Integer] Version number
		def version()
			# 4 bytes for Unsigned Int Big Endian
			@i2c.read(@addr, 4, STATUS_BASE, STATUS_VERSION).unpack('I>').first
		end

		# Read a byte from a Seesaw register
		#
		# @param base_reg [Byte] Base register address
		# @param function_reg [Byte] Function register address
		#
		# @return [Byte] Value read in the given register
		# @raise [ReadError] If no data is returned form the underlying I2C device
		def read_byte(base_reg, function_reg)
			read_raw(1, base_reg, function_reg).ord
		end

		# Read bytes from a Seesaw register
		#
		# @param size [Integer] Number of bytes to read
		# @param base_reg [Byte] Base register address
		# @param function_reg [Byte] Function register address
		#
		# @return [Array] Array of bytes read in the given register
		# @raise [ReadError] If no data is returned form the underlying I2C device
		def read_bytes(size, base_reg, function_reg)
			read_raw(size, base_reg, function_reg).unpack("C#{size}")
		end

		# Write data to the given register
		#
		# @param base_reg [Byte] Base register address
		# @param function_reg [Byte] Function register address
		# @param data [Array] Data to write. Must be an array of bytes or a binary string with big endian format
		def write(base_reg, function_reg, *data)
			puts "DEBUG: I2C WRITE: %02X %02X %s" % [base_reg, function_reg, data.map{|i| "%02X" % [i]}.join(' ')] if @debug
			@i2c.write(@addr, base_reg, function_reg, *data)
		end

		private

		def read_raw(size, base_reg, function_reg)
			data = @i2c.read(@addr, size, base_reg, function_reg)
			if @debug
				data_str = data.nil? ? 'nil' : data.unpack("C#{size}").map{|i| "%02X" % [i]}.join(' ')
				puts "DEBUG: I2C READ: %02X %02X %s" % [base_reg, function_reg, data_str]
			end

			raise ReadError, "No data" if data.nil?
			data
		end

		def testing?
			ENV['RSPEC_TEST']&.downcase == 'true'
		end
	end
end

# vim: ts=4:sw=4:ai
