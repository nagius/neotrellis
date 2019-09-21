
RSpec.describe Neotrellis::SeeSaw do
	let(:dev) { '/dev/i2c-0' }
	let(:i2c) do
		mock = double("I2C")

		# Perform a software reset
		expect(mock).to receive(:write).once.with(0x49, 0, 0x7F, 0xFF)
		expect(mock).to receive(:read).once.with(0x49, 1, 0, 1).and_return("\x55")
		mock
	end

	let(:seesaw) do
		allow(I2C).to receive(:create).with(dev).and_return(i2c)

		described_class.new(dev)
	end

	it 'open an i2c port with default addr' do
		allow(I2C).to receive(:create).with(dev).and_return(i2c)

		expect(Neotrellis::SeeSaw.new(dev)).to_not be_nil
	end

	it 'open an i2c port with custom addr' do
		mock = double("I2C")
		allow(I2C).to receive(:create).with(dev).and_return(mock)

		# Perform a software reset
		expect(mock).to receive(:write).with(0x2E, 0, 0x7F, 0xFF)
		expect(mock).to receive(:read).with(0x2E, 1, 0, 1).and_return("\x55")

		Neotrellis::SeeSaw.new(dev, 0x2E)
	end

	it 'do a sucessful software reset' do
		expect(i2c).to receive(:write).with(0x49, 0, 0x7F, 0xFF)
		expect(i2c).to receive(:read).with(0x49, 1, 0, 1).and_return("\x55")

		seesaw.sw_reset
	end

	it 'do a failed software reset' do
		expect(i2c).to receive(:write).with(0x49, 0, 0x7F, 0xFF)
		expect(i2c).to receive(:read).with(0x49, 1, 0, 1).and_return("\x00")

		expect{seesaw.sw_reset}.to raise_error(RuntimeError)
	end

	it 'read the version' do
		expect(i2c).to receive(:read).with(0x49, 4, 0, 2).and_return("\x00\x00\x25\x32")
		expect(seesaw.version).to eq 9522
	end

	it 'read a byte' do
		expect(i2c).to receive(:read).with(0x49, 1, 2, 3).and_return("A")
		expect(seesaw.read_byte(0x02, 0x03)).to eq 65
	end

	it 'read multiple bytes' do
		expect(i2c).to receive(:read).with(0x49, 4, 2, 3).and_return("ABCD")
		expect(seesaw.read_bytes(4, 0x02, 0x03)).to eq [65, 66, 67, 68]
	end
end

# vim: ts=4:sw=4:ai
