# frozen_string_literal: true

module RailsSimpleAuth
  module Models
    module Concerns
      module TemporaryUser
        extend ActiveSupport::Concern

        included do
          scope :temporary, -> { where(temporary: true) }
          scope :permanent, -> { where(temporary: false) }
          scope :temporary_expired, lambda { |days = nil|
            cleanup_days = days || RailsSimpleAuth.configuration.temporary_user_cleanup_days
            temporary.where(created_at: ...cleanup_days.days.ago)
          }
        end

        def temporary?
          return false unless respond_to?(:temporary)

          temporary == true
        end

        def permanent?
          !temporary?
        end

        def convert_to_permanent!(email:, password:)
          transaction do
            lock!

            if self.class.permanent.where.not(id: id).exists?(email_address: email)
              errors.add(:email_address, 'has already been taken')
              raise ActiveRecord::RecordInvalid, self
            end

            update!(
              email_address: email,
              password: password,
              temporary: false
            )

            send_confirmation_email! if respond_to?(:send_confirmation_email!)
          end
        end
      end
    end
  end
end
