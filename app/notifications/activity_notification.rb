# frozen_string_literal: true

# To deliver this notification:
#
# ActivityNotification.with(post: @post).deliver_later(current_user)
# ActivityNotification.with(post: @post).deliver(current_user)

class ActivityNotification < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  # param :post

  def message
    # if params[:legacy]
      params[:message]
    #else
    # new logic
    # end
  end

  def title
    # if params[:legacy]
    params[:title]
    # else
    # new logic
    # end
  end
  # def url
  #   post_path(params[:post])
  # end
end
