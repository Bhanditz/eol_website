require 'rails_helper'
require 'devise'
RSpec.describe User, type: :model do
  describe 'UserFactoryGirl' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'Validation' do
    context 'when valid' do
      it "has a username" do
        expect(build(:user, username: 'user')).to be_valid
      end
      it "has an email" do
        expect(build(:user, email: 'email@eol.org')).to be_valid
      end
      it "accepts email in correct format" do
        correct_emails = %w[user@foo.COM A_US-ER@f.b.org]
        correct_emails.each do |email|
          expect(build(:user, email: email)).to be_valid
        end
      end
      it "has a password" do
        expect(build(:user, password: 'password')).to be_valid
      end
    end

    context 'when invalid' do
      it "rejects empty username" do
         expect(build(:user, username: nil)).to_not be_valid
      end
      it "rejects too short username" do
        expect(build(:user, username: 'usr')).to_not be_valid
      end
      it "rejects too long username" do
        expect(build(:user, username: Faker::Internet.user_name(33))).to_not be_valid
      end
      it "rejects empty email" do
        expect(build(:user, email: nil)).to_not be_valid
      end
      it "rejects duplicate email" do
        create(:user, email: 'user@example.com')
        expect(build(:user, email: 'user@example.com')).to_not be_valid
      end
      it "rejects email in wrong format" do
        wrong_emails = %w[user_at_foo.org example.user@foo.foo@bar_baz.com]
        wrong_emails.each do |email|
          expect(build(:user, email: email)).to_not be_valid
        end
      end
      it "rejects empty password" do
        expect(build(:user, password: nil)).to_not be_valid
      end
      it "rejects too short passwords" do
        expect(build(:user, password: 'pas')).to_not be_valid
      end
      it "rejects too long passwords " do
        expect(build(:user, password:  Faker::Internet.password(33))).to_not be_valid
      end
    end
  end

  describe 'Confirmation' do
    let(:user) { create(:user) }
    before { user.confirm }
    it "updates user's confirmed_at attribute" do
      expect(user.confirmed_at).to_not be_nil
    end
    it "activates user after confirming account" do
      user.after_confirmation
      expect(user.active).to eq(true)
    end
  end

  describe "Delete account" do

    let(:current_user) { create(:user) }
    let(:admin_user) { create(:admin_user) }

    before do
      current_user.confirm
    end

    it "should allow delete his own account" do
      expect(current_user.can_delete_account?(current_user)).to be true
    end

    context "admin user" do
      it "should allow delete any other account" do
        expect(admin_user.can_delete_account?(current_user)).to be true
      end
    end

    context "regular user" do
      it "should not allow delete any other account" do
        expect(current_user.can_delete_account?(admin_user)).to be false
      end
    end

    context "soft delete user" do
      let(:old_password) {current_user.password}
      before { current_user.soft_delete }

      it "should deactivate the user" do
        expect(current_user.active).to be false
      end

      it "should adjust deleted_at time" do
        expect(current_user.deleted_at).not_to be_nil
      end

      it "should set email to nil" do
        expect(current_user.email).to eq("dummy_#{current_user.id}@eol.org")
      end

      it "should set password to nil" do
        expect(current_user.encrypted_password).not_to eq(old_password)
      end
    end
  end
end
