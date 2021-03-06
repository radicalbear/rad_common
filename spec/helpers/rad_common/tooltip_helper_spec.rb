require 'rails_helper'

describe RadCommon::TooltipHelper do
  let(:html_tag) { 'span' }
  let(:title) { 'Test' }
  let(:placement) { 'bottom' }

  describe '#icon_tooltip' do
    it 'correctly formats to an icon tooltip' do
      tooltip = icon_tooltip(html_tag, title)
      expect(tooltip).to include('span')
      expect(tooltip).to include('title="Test"')
      expect(tooltip).to include('fa-question-circle')
    end

    it 'displays nothing if title is nil' do
      tooltip = icon_tooltip(html_tag, nil)
      expect(tooltip).to eq(nil)
    end

    it 'displays nothing if title is empty string' do
      tooltip = icon_tooltip(html_tag, '')
      expect(tooltip).to eq(nil)
    end

    it 'defaults tooltip placement to top' do
      tooltip = icon_tooltip(html_tag, title)
      expect(tooltip).to include('data-placement="top"')
    end
  end

  describe '#tooltip' do
    it 'does not include the font awesome icon class' do
      tooltip = tooltip(html_tag, title)
      expect(tooltip).not_to include('fa-question-circle')
    end

    it 'displays nothing if title is nil' do
      tooltip = tooltip(html_tag, nil)
      expect(tooltip).to eq(nil)
    end

    it 'displays nothing if title is empty string' do
      tooltip = tooltip(html_tag, '')
      expect(tooltip).to eq(nil)
    end

    it 'changes the tooltip placement with 3rd argument' do
      tooltip = tooltip(html_tag, title, placement)
      expect(tooltip).to include('data-placement="bottom"')
    end
  end
end
