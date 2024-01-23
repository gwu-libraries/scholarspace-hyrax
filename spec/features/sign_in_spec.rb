require 'rails_helper'

RSpec.describe 'user sign-in' do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:content_admin_user) { FactoryBot.create(:content_admin_user) }

  it 'has link to login page on homepage' do
    visit root_path

    within "#login-link" do
      click_on "Staff login"
    end

    expect(current_path).to eq("/users/sign_in")
  end

  it 'can sign in an admin user' do
    visit "/users/sign_in"

    fill_in("user_email", with: admin_user.email)
    fill_in("user_password", with: admin_user.password)
    click_button("Log in")

    expect(current_path).to eq("/dashboard")

    within "#user_utility_links" do
      expect(page).to have_content(admin_user.email)
    end
  end

  it 'can sign in a content-admin user' do
    visit "/users/sign_in"

    fill_in("user_email", with: content_admin_user.email)
    fill_in("user_password", with: content_admin_user.password)
    click_button("Log in")

    expect(current_path).to eq("/dashboard")

    within "#user_utility_links" do
      expect(page).to have_content(content_admin_user.email)
    end
  end

  it 'can sign out a user' do
    visit "/users/sign_in"

    fill_in("user_email", with: content_admin_user.email)
    fill_in("user_password", with: content_admin_user.password)
    click_button("Log in")

    within "#user_utility_links" do
      click_on "Logout"
    end

    expect(current_path).to eq(root_path)
    expect(page).to have_content("Staff login")
  end

  it 'does not sign in a non-existent user' do
    visit "/users/sign_in"

    fill_in("user_email", with: "im-not-a-user@example.com")
    fill_in("user_password", with: "beefaroni2002")
    click_button("Log in")

    expect(current_path).to eq("/users/sign_in")
    expect(page).to have_content("Invalid Email or password")
  end

  it 'does not sign in a user with an incorrect password' do
    visit "/users/sign_in"

    fill_in("user_email", with: content_admin_user.email)
    fill_in("user_password", with: "beefaroni2002")
    click_button("Log in")

    expect(current_path).to eq("/users/sign_in")
    expect(page).to have_content("Invalid Email or password")
  end
end