module Neotrellis

	RSpec.describe NeoPixel do

		let(:seesaw) do
			double("SeeSaw")
		end

		let(:neopixel) do
			expect(seesaw).to receive(:write).once.with(14, 1, 3)
			expect(seesaw).to receive(:write).once.with(14, 3, 0, 48)
			described_class.new(seesaw, 16, false)
		end

		it 'instanciate with default number of pixel' do
			expect(neopixel).to_not be_nil
		end

		it 'instanciate with 32 pixels' do
			expect(seesaw).to receive(:write).once.with(14, 1, 3)
			expect(seesaw).to receive(:write).once.with(14, 3, 0, 96)

			described_class.new(seesaw, 32)
		end

		it 'set brightness within range' do
			neopixel.brightness = 0.5
			expect(neopixel.brightness).to eq 0.5
		end

		it 'set brightness outside range' do
			neopixel.brightness = 3
			expect(neopixel.brightness).to eq 1

			neopixel.brightness = -2
			expect(neopixel.brightness).to eq 0
		end

		it 'set pixel within range' do
			expect(seesaw).to receive(:write).with(14, 4, 0, 9, 0, 255, 0)
			neopixel.set(3, NeoPixel::RED)
		end

		it 'set pixel outside range' do
			expect{neopixel.set(17, NeoPixel::PURPLE)}.to raise_error(RuntimeError)
		end

		it 'set pixel with autoshow' do
			neopixel.autoshow = true
			expect(seesaw).to receive(:write).with(14, 4, 0, 9, 0, 0, 255)
			expect(seesaw).to receive(:write).with(14, 5)
			neopixel.set(3, NeoPixel::BLUE)
		end

		it 'flush buffer' do
			expect(seesaw).to receive(:write).with(14, 5)
			neopixel.show
		end

		it 'fill all buffer with one color' do
			16.times do |i|
				expect(seesaw).to receive(:write).with(14, 4, 0, i*3, 255, 0, 0)
			end
			neopixel.fill(NeoPixel::GREEN)
		end

		it 'create a new color' do
			color = NeoPixel::Color.new(128, 234, 98)
			expect(color.r).to eq(128)
			expect(color.g).to eq(234)
			expect(color.b).to eq(98)
		end

		it 'create a new color with brightness' do
			color = NeoPixel::Color.new(128, 234, 98)
			expect(color.to_b(0.5)).to eq([117, 64, 49])
		end
	end
end

# vim: ts=4:sw=4:ai
