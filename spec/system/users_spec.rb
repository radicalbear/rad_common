require 'rails_helper'

describe 'Users', type :system do
  let(:user) { create :user }
  let(:admin) { create :admin }
  let(:password) { 'password' }

  describe 'two factor authentication' do
    let(:authy_id) { '1234567' }

    before do
      expect(Authy::API).to receive(:register_user).and_return(double(:response, ok?: true, id: authy_id))
      user.update!(authy_enabled: true, mobile_phone: '(904) 226-4901')
    end

    it 'allows user to login with authentication token' do
      expect(Authy::API).to receive(:verify).and_return(double(:response, ok?: true))

      visit new_user_session_path
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: password
      click_button 'Sign In'
      expect(page).to have_content 'Remember this device for 7 days'
      fill_in 'authy-token', with: '7721070'
      click_button 'Verify and Sign in'
      expect(page).to have_content 'Signed in successfully'
    end

    it 'does not allow user to login with invalid authy token' do
      visit new_user_session_path

      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: password
      click_button 'Sign In'
      fill_in 'authy-token', with: 'Not the authy token'
      click_button 'Verify and Sign in'
      expect(page).to have_content('The entered token is invalid')
    end

    it 'updates authy when updating an accounts mobile phone' do
      expect(Authy::API).to receive(:user_status).and_return(double(:response, ok?: false))
      expect(Authy::API).to receive(:register_user).and_return(double(:response, ok?: true, id: authy_id))

      login_as(user, scope: :user)
      visit edit_user_registration_path
      fill_in 'user_mobile_phone', with: '(345) 222-1111'
      fill_in 'user_current_password', with: password
      click_button 'Save'
      expect(page).to have_content('Your account has been updated successfully.')
    end
  end

  describe 'authenticated' do
    describe 'user' do
      before do
        login_as(user, scope: :user)
      end

      describe 'index' do
        it 'shows users' do
          visit users_path
          expect(page).to have_content 'Access Denied'
        end
      end

      describe 'profile' do
        it 'updates profile' do
          visit edit_user_registration_path
          expect(find_field('First name').value).to eq user.first_name
          new_name = Faker::Name.first_name
          fill_in 'First name', with: new_name
          fill_in 'Current password', with: password
          click_button 'Save'
          user.reload
          expect(user.first_name).to eq new_name
        end
      end
    end

    describe 'admin' do
      before do
        login_as(admin, scope: :user)
      end

      describe 'index' do
        it 'shows users' do
          visit users_path(status: user.user_status_id)
          expect(page).to have_content user.to_s
        end
      end

      describe 'show' do
        before { visit user_path(user) }

        it 'shows the user' do
          expect(page).to have_content user.to_s
        end

        it 'shows field names in title case' do
          expect(page).to have_content('User Status')
        end

        context 'attribute translation defined in locales' do
          it 'shows translated version of field name' do
            expect(page).to have_content 'Phone number'
            expect(page).not_to have_content 'Mobile Phone'
          end
        end
      end
    end
  end

  describe 'sign up' do
    it 'signs up' do
      visit new_user_registration_path

      fill_in 'First name', with: Faker::Name.first_name
      fill_in 'Last name', with: Faker::Name.last_name
      fill_in 'Email', with: Faker::Internet.user_name + '@example.com'
      fill_in 'user_password', with: password
      fill_in 'user_password_confirmation', with: password

      click_button 'Sign Up'
      expect(page.html).to include('message with a confirmation link has been sent')
    end

    it "can't sign up with invalid email address" do
      visit new_user_registration_path

      fill_in 'First name', with: Faker::Name.first_name
      fill_in 'Last name', with: Faker::Name.last_name
      fill_in 'Email', with: 'test_user@'
      fill_in 'user_password', with: password
      fill_in 'user_password_confirmation', with: password

      click_button 'Sign Up'

      expect(page.html).to include('is not authorized')
    end
  end

  describe 'sign in' do
    it 'can not sign in without active user status' do
      user.update!(user_status: UserStatus.default_pending_status)

      visit new_user_session_path

      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: password

      click_button 'Sign In'
      expect(page.html).to include('Your account has not been approved by your administrator yet.')
    end

    it 'signs in' do
      visit new_user_session_path

      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: password

      click_button 'Sign In'
      expect(page.html).to include('Signed in successfully.')
    end
  end
end