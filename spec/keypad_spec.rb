
RSpec.describe Neotrellis::Keypad do
	let(:seesaw) { double("SeeSaw") }
	let(:keypad) { described_class.new(seesaw) }
	let(:pin)    { 12 }
	let(:gpio)   { double("YaGPIO") }

	it 'instanciate with default parameters' do
		expect(keypad).to_not be_nil
	end

	it 'count events' do
		expect(seesaw).to receive(:read_byte).with(16, 4).and_return(2)
		expect(keypad.count_events).to eq 2
	end

	it 'raise if set a wrong action' do
		expect{keypad.set_event(1, "wrongaction", true)}.to raise_error(RuntimeError)
	end

	it 'enable an event callback' do
		expect(seesaw).to receive(:write).with(16, 1, 1, 17)
		keypad.set_event(1, Neotrellis::Keypad::KEY_PRESSED, true) {}
	end

	it 'disable an event callback' do
		expect(seesaw).to receive(:write).with(16, 1, 1, 8)
		keypad.set_event(1, Neotrellis::Keypad::KEY_RELEASED, false) {}
	end

	it 'sync with no events' do
		expect(seesaw).to receive(:read_byte).with(16, 4).and_return(0)
		keypad.sync
	end

	it 'sync with one unconfigured events' do
		expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
		expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_return([03])

		keypad.sync
	end

	it 'sync with two configured events' do
		callback_count1 = 0
		callback_count2 = 0

		# Key one
		expect(seesaw).to receive(:write).with(16, 1, 0, 9)
		keypad.set_event(0, Neotrellis::Keypad::KEY_RELEASED, true) do |event|
			callback_count2 += 1
			expect(event.key).to eq 0
			expect(event.edge).to eq Neotrellis::Keypad::KEY_RELEASED
		end

		# Key two
		expect(seesaw).to receive(:write).with(16, 1, 1, 17)
		keypad.set_event(1, Neotrellis::Keypad::KEY_PRESSED, true) do |event|
			callback_count1 += 1
			expect(event.key).to eq 1
			expect(event.edge).to eq Neotrellis::Keypad::KEY_PRESSED
		end

		expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
		expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_return([02, 07])
		keypad.sync

		expect(callback_count1).to eq 1
		expect(callback_count2).to eq 1
	end

	it 'enable then disable interrupt' do
		allow(YaGPIO).to receive(:new).with(pin, YaGPIO::INPUT).and_return(gpio)
		expect(gpio).to receive(:set_interrupt).with(YaGPIO::EDGE_FALLING)
		expect(seesaw).to receive(:write).with(16, 2, 1)

		keypad.enable_interrupt(pin)
		expect(keypad.interrupt?).to be true

		expect(seesaw).to receive(:write).with(16, 3, 1)
		expect(gpio).to receive(:close)
		keypad.disable_interrupt
		expect(keypad.interrupt?).to be false
	end

	it 'raise if wait for an event with not interrupt' do
		expect{keypad.wait_for_event}.to raise_error(RuntimeError)
	end

	it 'wait for an event' do
		allow(YaGPIO).to receive(:new).with(pin, YaGPIO::INPUT).and_return(gpio)
		expect(gpio).to receive(:set_interrupt).with(YaGPIO::EDGE_FALLING)
		expect(seesaw).to receive(:write).with(16, 2, 1)
		allow(YaGPIO).to receive(:wait)

		keypad.enable_interrupt(pin)
		keypad.wait_for_event
	end

	it 'stop waiting for an event' do
		allow(YaGPIO).to receive(:resume)
		keypad.resume
	end
end

# vim: ts=4:sw=4:ai
