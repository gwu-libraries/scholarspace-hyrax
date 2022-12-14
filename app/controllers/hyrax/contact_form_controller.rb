require 'dotenv/load'
module Hyrax
  class ContactFormController < ApplicationController
    before_action :build_contact_form
    layout 'homepage'

    def new; end

    def create
      success = verify_recaptcha(action: 'contact', minimum_score: ENV['RECAPTCHA_MINIMUM_SCORE'].to_f, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'])
      checkbox_success = verify_recaptcha unless success
      if success || checkbox_success
        ContactMailer.contact(@contact_form).deliver_now
        flash.now[:notice] = 'Thank you for your message!'
        after_deliver
        @contact_form = ContactForm.new
      else
        if !success
          @show_checkbox_recaptcha = true
        end
        render :new
      end
#    def create
#      # not spam and a valid form 
#      if verify_recaptcha
#        if @contact_form.valid?
#          ContactMailer.contact(@contact_form).deliver_now
#          flash.now[:notice] = 'Thank you for your message!'
#          after_deliver
#          @contact_form = ContactForm.new
#        else
#          flash.now[:error] = 'Sorry, this message was not sent successfully. '
#          flash.now[:error] << @contact_form.errors.full_messages.map(&:to_s).join(", ")
#        end
#      else
#        flash.now[:error] = 'Error passing CAPTCHA'
#      end
#      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end

    def handle_create_exception(exception)
      logger.error("Contact form failed to send: #{exception.inspect}")
      flash.now[:error] = 'Sorry, this message was not delivered.'
      render :new
    end

    # Override this method if you want to perform additional operations
    # when a email is successfully sent, such as sending a confirmation
    # response to the user.
    def after_deliver; end

#    def honeypot_fields
#    {
#      :my_custom_comment_body => 'Do not fill in this field, sucka!',
#      :another_thingy => 'Really... do not fill out!'
#    }
#    end
    
    invisible_captcha only: [:create, :update], honeypot: :gwsshoney
    
    private

      def build_contact_form
        @contact_form = Hyrax::ContactForm.new(contact_form_params)
      end

      def contact_form_params
        return {} unless params.key?(:contact_form)
        params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
      end
  end
end
