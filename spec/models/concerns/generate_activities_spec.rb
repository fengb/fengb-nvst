require 'spec_helper'


describe GenerateActivities do
  describe '#generate_activities!' do
    class TestClass < OpenStruct
      include GenerateActivities
    end

    subject { TestClass.new(activities: [], raw_activities_data: []) }

    context 'already has activities' do
      before { subject.activities = [1] }

      it 'returns nil' do
        expect(subject.generate_activities!).to be(nil)
      end

      it 'does absolutely nothing' do
        GenerateActivities.should_not_receive(:execute!)
        subject.generate_activities!
      end
    end

    it 'passes raw activity data to GenerateActivities.execute!' do
      subject.raw_activities_data = [4, 2, 5]
      GenerateActivities.should_receive(:execute!).with(4).and_return([4])
      GenerateActivities.should_receive(:execute!).with(2).and_return([2])
      GenerateActivities.should_receive(:execute!).with(5).and_return([5])

      subject.generate_activities!
    end

    it 'adds GenerateActivities.execute! returned values to activities' do
      subject.raw_activities_data = [:a, :z]
      GenerateActivities.stub(execute!: [1, 2])

      subject.generate_activities!
      expect(subject.activities).to eq([1, 2, 1, 2])
    end
  end

  describe '.execute!' do
    let(:investment) { FactoryGirl.create(:investment) }
    let(:data)       { {investment: investment,
                        date:       Date.today - rand(1000),
                        shares:     BigDecimal(rand(100..200)),
                        price:      BigDecimal(1)} }

    def create_activity!(options)
      if options[:lot]
        FactoryGirl.create(:activity, options.merge(lot: options[:lot]))
      else
        lot = Lot.new(investment: options.delete(:investment))
        FactoryGirl.create(:activity, options.merge(lot: lot,
                                                    is_opening: true))
      end
    end

    it 'creates new lot with single activity when none exists' do
      activities = GenerateActivities.execute!(data)
      expect(activities.size).to eq(1)
      expect_data(activities[0], data)
    end

    context 'corresponding lot' do
      let(:existing) do
        create_activity!(investment: investment,
                         date: data[:date],
                         shares: -10,
                         price: data[:price])
      end

      before { Lot.stub(corresponding: existing.lot) }

      it 'reuses the lot' do
        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(1)
        expect_data(activities[0], data, lot: existing.lot)
      end
    end

    context 'existing lot with different open data' do
      let!(:existing) do
        create_activity!(investment: investment,
                         date: Date.today - 2000,
                         shares: -10,
                         price: 5)
      end

      it 'ignores lots it cannot fill' do
        existing.update(shares: 10)
        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(1)
        expect_data(activities[0], data)
        expect(activities[0].lot).to_not eq(existing.lot)
      end

      it 'ignores filled lots' do
        create_activity!(lot: existing.lot,
                         date: Date.today - 1999,
                         shares: 10,
                         price: 4)

        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(1)
        expect_data(activities[0], data)
        expect(activities[0].lot).to_not eq(existing.lot)
      end

      it 'fills when outstanding amount > new amount' do
        existing.update(shares: -300)

        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(1)
        expect_data(activities[0], data, lot: existing.lot)
      end

      it 'fills when outstanding amount == new amount' do
        existing.update(shares: -data[:shares])

        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(1)
        expect_data(activities[0], data, lot: existing.lot)
      end

      it 'fills up and creates new lot with remainder' do
        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(2)
        expect_data(activities[0], lot: existing.lot,
                                   date: data[:date],
                                   shares: -existing.shares,
                                   price: 1)
        expect(activities[1].lot).to_not eq(existing.lot)
        expect_data(activities[1], date: data[:date],
                                   shares: data[:shares] + existing.shares,
                                   price: 1)
      end
    end

    context 'existing lots' do
      let!(:existing) {[
        create_activity!(investment: investment,
                         date: Date.today - 2000,
                         shares: -10,
                         price: 4),
        create_activity!(investment: investment,
                         date: Date.today - 2000,
                         shares: -300,
                         price: 3),
      ]}

      it 'fills up first based on highest price' do
        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(2)
        expect_data(activities[0], lot: existing[0].lot,
                                   date: data[:date],
                                   shares: -existing[0].shares,
                                   price: data[:price])
        expect_data(activities[1], lot: existing[1].lot,
                                   date: data[:date],
                                   shares: data[:shares] + existing[0].shares,
                                   price: data[:price])
      end

      it 'fills up all lots before creating new lot' do
        existing[1].update(shares: -20)

        activities = GenerateActivities.execute!(data)
        expect(activities.size).to eq(3)
        expect_data(activities[0], lot: existing[0].lot,
                                   date: data[:date],
                                   shares: -existing[0].shares,
                                   price: data[:price])
        expect_data(activities[1], lot: existing[1].lot,
                                   date: data[:date],
                                   shares: -existing[1].shares,
                                   price: data[:price])
        expect(activities[2].lot).to_not eq(existing[0].lot)
        expect(activities[2].lot).to_not eq(existing[1].lot)
        expect_data(activities[2], date: data[:date],
                                   shares: data[:shares] + existing.sum(&:shares),
                                   price: data[:price])
      end
    end

    describe 'adjustments' do
      it 'ignores adjustment if == nil' do
        data[:adjustment] = nil
        activities = GenerateActivities.execute!(data)
        expect(activities[0].adjustments).to be_blank
      end

      it 'ignores adjustment if == 1' do
        data[:adjustment] = 1
        activities = GenerateActivities.execute!(data)
        expect(activities[0].adjustments).to be_blank
      end

      it 'creates an adjustment for the activity date' do
        data[:adjustment] = 0.5
        activities = GenerateActivities.execute!(data)
        expect(activities[0].adjustments.size).to eq(1)
        expect_data(activities[0].adjustments[0], date: data[:date],
                                                  ratio: data[:adjustment])
      end

      context 'activity waterfall' do
        before do
          data[:adjustment] = 2
          create_activity!(investment: investment,
                           date: data[:date] - 1,
                           shares: -10,
                           price: data[:price])
        end

        it 'uses the same adjustment for multiple activities' do
          activities = GenerateActivities.execute!(data)

          expect(activities.size).to be > 1
          activities.each do |activity|
            expect(activity.adjustments).to eq([activities[0].adjustments[0]])
          end
        end
      end
    end
  end
end
