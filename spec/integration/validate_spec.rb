RSpec.describe Arkmongo::Commands::Validate do
  it "executes the command successfully" do
    output = `arkmongo validate`
    expect(output).to eq("EXPECTED")
  end
end
