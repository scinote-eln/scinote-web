class Token < ActiveRecord::Base

	validates :token, presence: true
	validates :ttl, presence: true

	belongs_to :user, foreign_key: 'user_id', class_name: 'User', inverse_of: :tokens

end