FactoryGirl.define do
  factory :activity do
    date       { Date.today - rand(100..300) }
    tax_date   { date }
    shares     { rand(100.0..1000.0).to_d.round(2) }
    price      { rand(10.0..100.0).to_d.round(2) }

    after(:build) do |activity, evaluator|
      if activity.lot.nil?
        activity.lot = FactoryGirl.build(:lot) do |lot|
          lot.activities << activity
        end

        activity.is_opening = true
      end
    end
  end
end
