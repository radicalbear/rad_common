require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:admin) { create :admin }
  let(:user) { create :user }
  let(:another) { create :user }
  let(:valid_attributes) { { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name } }
  let(:invalid_attributes) { { first_name: nil } }

  before { login_as admin, scope: :user }

  describe 'PUT update' do
    describe 'with valid params' do
      let(:new_name) { 'Gary' }

      let(:new_attributes) { { first_name: new_name } }

      it 'updates the requested user' do
        put "/users/#{user.id}", params: { user: new_attributes }
        user.reload
        expect(user.first_name).to eq(new_name)
      end

      it 'redirects to the user' do
        put "/users/#{user.id}", params: { user: valid_attributes }
        expect(response).to redirect_to(user)
      end
    end

    describe 'with invalid params' do
      it 're-renders the edit template' do
        put "/users/#{user.id}", params: { user: invalid_attributes }
        expect(response.body).to include 'Please review the problems below'
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested user' do
      user
      expect {
        delete "/users/#{user.id}", headers: { HTTP_REFERER: user_path(user) }
      }.to change(User, :count).by(-1)
    end

    it 'redirects to the users list' do
      delete "/users/#{user.id}", headers: { HTTP_REFERER: user_path(user) }
      expect(response).to redirect_to(users_url)
    end

    it 'can not delete if user created audits' do
      Audited::Audit.as_user(another) { user.update!(first_name: 'Foo') }

      delete "/users/#{another.id}", headers: { HTTP_REFERER: users_path }
      follow_redirect!
      expect(response.body).to include 'User has audit history'
    end

    pending 'can delete if user created audits on itself'
  end
end
