require 'rails_helper'

describe Staff::TopController, 'before login' do
  let(:staff_member) { create(:staff_member) }

  describe 'Restrict to access by IP Address' do
    before do
      Rails.application.config.baukis[:restrict_ip_addresses] = true
    end

    example 'allow' do
      AllowedSource.create!(namespace: 'staff', ip_address: '0.0.0.0')
      get :index
      expect(response).to render_template('staff/top/index')
    end

    example 'deny' do
      AllowedSource.create!(namespace: 'staff', ip_address: '192.168.0.*')
      get :index
      expect(response).to render_template('errors/forbidden')
    end
  end
end

describe Staff::TopController, 'after login' do
  let(:staff_member) { create(:staff_member) }

  before do
    session[:staff_member_id] = staff_member.id
    session[:last_access_time] = 1.second.ago
  end

  describe '#index' do
    example 'if be normal, display staff/top/dashboard.' do
      get :index
      expect(response).to render_template('staff/top/dashboard')
    end

    example 'Set suspended flag, force to logout.' do
      staff_member.update_column(:suspended, true)
      get :index
      expect(session[:staff_member_id]).to be_nil
      expect(response).to redirect_to(staff_root_url)
    end

    example 'Your session has been timed out.' do
      session[:last_access_time] =
        Staff::Base::TIMEOUT.ago.advance(seconds: -1)
      get :index
      expect(session[:staff_member_id]).to be_nil
      expect(response).to redirect_to(staff_login_url)
    end
  end
end
