

RSpec.describe Neotrellis::Keypad do

	let(:seesaw) { double("SeeSaw") }

	let(:keypad) { described_class.new(seesaw) }

	it 'instanciate with default parameters' do
		expect(keypad).to_not be_nil
	end

	it 'count events' do
		expect(seesaw).to receive(:read_byte).with(16, 4).and_return(2)
		expect(keypad.count_events).to eq 2
	end

end

# vim: ts=4:sw=4:ai
