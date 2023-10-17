# frozen_string_literal: true

# To deliver this notification:
#
# GeneralNotification.with(post: @post).deliver_later(current_user)
# GeneralNotification.with(post: @post).deliver(current_user)

class GeneralNotification < BaseNotification
  # Add your delivery methods
  #
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  # param :post

  # Define helper methods to make rendering easier.
  #
  def message
    # if params[:legacy]
    params[:message]
    # else
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
  #
  # def url
  #   post_path(params[:post])
  # end
end
