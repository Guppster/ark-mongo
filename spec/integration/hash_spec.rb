RSpec.describe Arkmongo::Commands::Hash do
  it "executes the command successfully" do
    output = `arkmongo hash`
    expect(output).to eq("EXPECTED")
  end
end
