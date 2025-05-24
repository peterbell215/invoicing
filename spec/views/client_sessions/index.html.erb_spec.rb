require 'rails_helper'

RSpec.describe "client_sessions/index", type: :view do
  before(:each) do
    assign(:client_sessions, [
      ClientSession.create!(),
      ClientSession.create!()
    ])
  end

  it "renders a list of client_sessions" do
    render
    cell_selector = 'div>p'
  end
end
