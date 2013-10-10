require 'spec_helper'

describe "admin/users/show" do
  before(:each) do
    @admin = assign(:admin, stub_model(User,
      :username => "Username",
      :password => "Password"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Username/)
    rendered.should match(/Password/)
  end
end