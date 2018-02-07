RSpec.describe Timeout, skip_library: true do
  it 'should raise when block' do
    expect do
      Timeout.timeout(0.1) do
        gets
      end
    end.to raise_error(Timeout::Error)
  end
end
