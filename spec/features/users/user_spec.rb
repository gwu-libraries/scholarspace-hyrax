require 'rails_helper'

RSpec.describe 'create an admin user' do

  before :each do
    @adminrole = Role.find_or_create_by(name: 'admin')
    @contentadminrole = Role.find_or_create_by(name: "content-admin")
  end

  it 'creates a new non-admin user' do
    user = User.new(email: "testing@admin.com", password: "beepbeepbeep123")
    user.save

    expect(user.admin?).to be false
  end

  it 'creates a new admin user' do
    user = User.new(email: "testing@admin.com", password: "beepbeepbeep123")
    user.save

    @adminrole.users << user
    @adminrole.save

    expect(user.admin?).to be true
  end

  it 'can create a content-admin user through the UI' do
    admin_user = User.new(email: "testing@admin.com", password: "beepbeepbeep123")
    admin_user.save

    @adminrole.users << admin_user
    @adminrole.save

    content_admin_user = User.new(email: "content-admin@admin.com", password: "beepbeepbeep123")
    content_admin_user.save

    visit "/users/sign_in"

    fill_in("user_email", with: "testing@admin.com")
    fill_in("user_password", with: "beepbeepbeep123")
    click_button("Log in")

    visit "/roles"

    click_link('content-admin')

    fill_in("role_name", with: "content-admin")
    fill_in("user_key", with: "content-admin@admin.com")

    click_button("Add")

    expect(content_admin_user.contentadmin?).to be true
  end

end