RSpec.describe Hubspot::Association do
  before { Hubspot.configure(hapikey: 'demo') }

  describe '.create' do
    let(:company) { create :company }
    let(:contact) { create :contact }

    context 'with a valid ID' do
      cassette
      subject { described_class.create(company.id, contact.id, described_class::COMPANY_TO_CONTACT) }

      it 'associates the resources' do
        expect(subject).to be true
        expect(company.contact_ids.resources).to eq [contact.id]
      end
    end

    context 'with an invalid ID' do
      cassette
      subject { described_class.create(company.id, 1234, described_class::COMPANY_TO_CONTACT) }

      it 'raises an error' do
        expect { subject }.to raise_error(Hubspot::RequestError, /One or more associations are invalid/)
      end
    end
  end

  describe '.batch_create' do
    let(:portal_id) { 62515 }
    let(:company) { create :company }
    let(:contact) { create :contact }
    let(:deal) { Hubspot::Deal.create!(portal_id, [], [], {}) }

    subject { described_class.batch_create(associations) }

    context 'with a valid request' do
      cassette
      let(:associations) do
        [
          { from_id: deal.deal_id, to_id: contact.id, definition_id: described_class::DEAL_TO_CONTACT },
          { from_id: deal.deal_id, to_id: company.id, definition_id: described_class::DEAL_TO_COMPANY }
        ]
      end

      it 'associates the resources' do
        expect(subject).to be true
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.vids).to eq [contact.id]
        expect(find_deal.company_ids).to eq [company.id]
      end
    end

    context 'with an invalid ID' do
      cassette
      let(:associations) do
        [
          { from_id: deal.deal_id, to_id: 1234, definition_id: described_class::DEAL_TO_CONTACT },
          { from_id: deal.deal_id, to_id: company.id, definition_id: described_class::DEAL_TO_COMPANY }
        ]
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Hubspot::RequestError, /One or more associations are invalid/)
        find_deal = Hubspot::Deal.find(deal.deal_id)
        expect(find_deal.vids).to eq []
        expect(find_deal.company_ids).to eq []
      end
    end
  end
end
