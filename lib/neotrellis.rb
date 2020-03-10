require 'neotrellis/seesaw'
require 'neotrellis/neopixel'
require 'neotrellis/keypad'

module Neotrellis
	# Raised in case of read error from the underlying I2C device
	class ReadError < StandardError
	end
end

# vim: ts=4:sw=4:ai
