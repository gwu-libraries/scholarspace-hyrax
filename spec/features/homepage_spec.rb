require 'rails_helper'

RSpec.describe "Homepage" do

  before :each do
    visit root_path
  end
  
  context "masthead" do
    it 'displays GW logo in masthead of page' do
      within "#masthead" do
        within "#logo" do
          expect(page).to have_css("img")
        end
      end
    end

    it 'displays application title' do
      within "#masthead" do
        within ".title-wrap" do
          expect(page).to have_content("ScholarSpace")
        end
      end
    end

    it 'take user to homepage when clicking title' do
      within "#masthead" do
        within ".title-wrap" do
          click_on "ScholarSpace"
        end
      end

      expect(current_path).to eq(root_path)
    end

    it 'displays application subtitle' do
      within "#masthead" do
        within ".title-wrap" do
          within ".subtitle-wrap" do
            expect(page).to have_content("A service of GW Libraries and Academic Innovation")
          end
        end
      end
    end
  end

  context "navigation bar" do
    it 'has a link to "Information for Authors" page' do
      within ".navigation-wrap" do
        expect(page).to have_content("Information for Authors")
      end      
    end

    it 'takes user to "Information for Authors" page when clicked' do
      within ".navigation-wrap" do
        click_on "Information for Authors"
      end

      expect(current_path).to eq("/terms")
    end

    it 'has a link to "About" page' do
      within ".navigation-wrap" do
        expect(page).to have_content("About")
      end
    end

    it 'takes user to "About" page when clicked' do
      within ".navigation-wrap" do
        click_on "About"
      end

      expect(current_path).to eq("/about")
    end

    it 'has a link to the "Help" page' do
      within ".navigation-wrap" do
        expect(page).to have_content("Help")
      end
    end

    it 'takes user to "Help" page when clicked' do
      within ".navigation-wrap" do
        click_on "Help"
      end

      expect(current_path).to eq("/help")
    end

    it 'has a link to the "Contact" page' do
      within ".navigation-wrap" do
        expect(page).to have_content("Contact")
      end
    end

    it 'takes user to "Contact" page when clicked' do
      within ".navigation-wrap" do
        click_on "Contact"
      end

      expect(current_path).to eq("/contact")
    end

    it 'takes user to search result page when clicking magnifying glass icon' do
      click_button "search-submit-header"
      expect(current_path).to eq("/catalog")
    end
  end

  context "footer" do
    
    it 'has a link to "staff login"' do
      within "#footer-links" do
        click_on "Staff login"

        expect(current_path).to eq("/users/sign_in")
      end
    end

    it 'has a link to "Campus Advisories"' do
      within "#footer-links" do
        expect(page).to have_content("Campus Advisories")
      end
    end

    it 'has a link to "EO/Nondiscrimination Policy"' do
      within "#footer-links" do
        expect(page).to have_content("EO/Nondiscrimination Policy")
      end
    end

    it 'has a link to "Privacy Notice"' do
      within "#footer-links" do
        expect(page).to have_content("Privacy Notice")
      end
    end

    it 'has a link to "Contact GW"' do
      within "#footer-links" do
        expect(page).to have_content("Contact GW")
      end
    end

    it 'has a link to "Accessibility"' do
      within "#footer-links" do
        expect(page).to have_content("Accessibility")
      end
    end

    it 'has a link to "Terms of Use"' do
      within "#footer-links" do
        expect(page).to have_content("Terms of Use")
      end
    end

    it 'has a link to "Copyright"' do
      within "#footer-links" do
        expect(page).to have_content("Copyright")
      end
    end

    it 'has a link to "A-Z Index"' do
      within "#footer-links" do
        expect(page).to have_content("A-Z Index")
      end
    end
    
    it 'has a link to "Accessibility Feedback Form"' do
      within "#footer-links" do
        expect(page).to have_content("Accessibility Feedback Form")
      end
    end
  end

end