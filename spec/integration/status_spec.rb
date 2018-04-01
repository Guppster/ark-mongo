RSpec.describe Arkmongo::Commands::Status do
  it "executes the command successfully" do
    output = `arkmongo status`
    expect(output).to eq("EXPECTED")
  end
end
