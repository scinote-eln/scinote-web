class WopiDiscovery < ActiveRecord::Base

	has_many :wopi_apps, class_name: 'WopiApp', foreign_key: 'wopi_discovery_id', :dependent => :delete_all
	validates :expires, :proof_key_mod, :proof_key_exp, :proof_key_old_mod, :proof_key_old_exp, presence: true

end
