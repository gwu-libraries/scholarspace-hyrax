class ResqueAdmin
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    return current_user.admin?
  end
end
