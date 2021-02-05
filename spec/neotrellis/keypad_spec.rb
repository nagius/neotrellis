module Neotrellis

	RSpec.describe Keypad do
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

		it 'count events with read error' do
			expect(seesaw).to receive(:read_byte).with(16, 4).and_raise(ReadError)
			expect(keypad.count_events).to eq 0
		end

		it 'raise if set a wrong event' do
			expect{keypad.set_event(1, event: "wrongevent", enabled: true)}.to raise_error(RuntimeError)
		end

		it 'enable an event callback' do
			expect(seesaw).to receive(:write).with(16, 1, 1, 17)
			keypad.set_event(1, event: Keypad::KEY_PRESSED) {}
		end

		it 'disable an event callback' do
			expect(seesaw).to receive(:write).with(16, 1, 1, 8)
			keypad.set_event(1, event: Keypad::KEY_RELEASED, enabled: false) {}
		end

		it 'sync with no event' do
			expect(seesaw).to receive(:read_byte).with(16, 4).and_return(0)
			keypad.sync
		end

		it 'sync with one unconfigured event' do
			expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
			expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_return([03])

			keypad.sync
		end

		it 'sync with one event and read error' do
			expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
			expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_raise(ReadError)

			keypad.sync
		end

		it 'sync with two configured events' do
			callback_count1 = 0
			callback_count2 = 0

			# Key one
			expect(seesaw).to receive(:write).with(16, 1, 0, 9)
			keypad.set_event(0, event: Keypad::KEY_RELEASED, enabled: true) do |event|
				callback_count2 += 1
				expect(event.key).to eq 0
				expect(event.edge).to eq Keypad::KEY_RELEASED
			end

			# Key two
			expect(seesaw).to receive(:write).with(16, 1, 1, 17)
			keypad.set_event(1, event: Keypad::KEY_PRESSED, enabled: true) do |event|
				callback_count1 += 1
				expect(event.key).to eq 1
				expect(event.edge).to eq Keypad::KEY_PRESSED
			end

			expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
			expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_return([02, 07])
			keypad.sync

			expect(callback_count1).to eq 1
			expect(callback_count2).to eq 1
		end

		it 'sync with one event configured on both edges' do
			callback_count = 0

			expect(seesaw).to receive(:write).with(16, 1, 0, 17)
			expect(seesaw).to receive(:write).with(16, 1, 0, 9)
			keypad.set_event(0, event: Keypad::KEY_BOTH) do |event|
				callback_count += 1
				expect(event.key).to eq 0
				expect(event.edge).to eq Keypad::KEY_PRESSED if callback_count == 1
				expect(event.edge).to eq Keypad::KEY_RELEASED if callback_count == 2
			end

			expect(seesaw).to receive(:read_byte).with(16, 4).and_return(1)
			expect(seesaw).to receive(:read_bytes).with(1, 16, 16).and_return([03, 02])
			keypad.sync

			expect(callback_count).to eq 2
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
end

# vim: ts=4:sw=4:ai
