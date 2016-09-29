class MyModuleCommentsController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: :index
  before_action :check_add_permissions, only: [:new, :create]
  before_action :check_edit_permissions, only: [:edit, :update]
  before_action :check_destroy_permissions, only: [:destroy]

  def index
    @comments = @my_module.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json do
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = 'index.html.erb'
        partial = 'list.html.erb' if @last_comment_id > 0
        more_url = ''
        if @comments.count > 0
          more_url = url_for(my_module_my_module_comments_url(@my_module,
                                                              format: :json,
                                                              from: @comments
                                                                    .first.id))
        end
        render json: {
          perPage: @per_page,
          resultsNumber: @comments.length,
          moreUrl: more_url,
          html: render_to_string(
            partial: partial,
            locals: {
              comments: @comments,
              more_comments_url: more_url
            }
          )
        }
      end
    end
  end

  def new
    @comment = Comment.new(
      user: current_user
    )
  end

  def create
    @comment = Comment.new(
      message: comment_params[:message],
      user: current_user)

    respond_to do |format|
      if (@comment.valid? && @my_module.comments << @comment)
        # Generate activity
        Activity.create(
          type_of: :add_comment_to_module,
          user: current_user,
          project: @my_module.experiment.project,
          my_module: @my_module,
          message: t(
            'activities.add_comment_to_module',
            user: current_user.full_name,
            module: @my_module.name
          )
        )

        format.html {
          flash[:success] = t(
            "my_module_comments.create.success_flash",
            module: @my_module.name)
          redirect_to session.delete(:return_to)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "comment.html.erb",
              locals: {
                comment: @comment
              }
            })
          },
          status: :created
        }
      else
        response.status = 400
        format.html { render :new }
        format.json {
          render json: {
            errors: @comment.errors.to_hash(true)
          }
        }
      end
    end
  end

  def edit
    @update_url =
      my_module_my_module_comment_path(@my_module, @comment, format: :json)
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: '/comments/edit.html.erb'
          )
        }
      end
    end
  end

  def update
    @comment.message = comment_params[:message]
    respond_to do |format|
      format.json do
        if @comment.save
          # Generate activity
          Activity.create(
            type_of: :edit_module_comment,
            user: current_user,
            project: @my_module.experiment.project,
            my_module: @my_module,
            message: t(
              'activities.edit_module_comment',
              user: current_user.full_name,
              module: @my_module.name
            )
          )
          render json: {}, status: :ok
        else
          render json: { errors: @comment.errors.to_hash(true) },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        if @comment.destroy
          # Generate activity
          Activity.create(
            type_of: :delete_module_comment,
            user: current_user,
            project: @my_module.experiment.project,
            my_module: @my_module,
            message: t(
              'activities.delete_module_comment',
              user: current_user.full_name,
              module: @my_module.name
            )
          )
          render json: {}, status: :ok
        else
          render json: { message: I18n.t('comments.delete_error') },
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_vars
    @last_comment_id = params[:from].to_i
    @per_page = COMMENTS_SEARCH_LIMIT
    @my_module = MyModule.find_by_id(params[:my_module_id])

    unless @my_module
      render_404
    end
  end

  def check_view_permissions
    unless can_view_module_comments(@my_module)
      render_403
    end
  end

  def check_add_permissions
    unless can_add_comment_to_module(@my_module)
      render_403
    end
  end

  def check_edit_permissions
    @comment = Comment.find_by_id(params[:id])
    render_403 unless @comment.present? && can_edit_module_comment(@comment)
  end

  def check_destroy_permissions
    @comment = Comment.find_by_id(params[:id])
    render_403 unless @comment.present? && can_delete_module_comment(@comment)
  end

  def comment_params
    params.require(:comment).permit(:message)
  end
end
