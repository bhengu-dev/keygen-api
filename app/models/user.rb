# frozen_string_literal: true

class User < ApplicationRecord
  MINIMUM_ADMIN_COUNT = 1

  include PasswordResetable
  include Sluggable
  include Limitable
  include Pageable
  include Roleable
  include Searchable

  SEARCH_ATTRIBUTES = [:id, :email, :first_name, :last_name, :metadata, { full_name: [:first_name, :last_name] }].freeze
  SEARCH_RELATIONSHIPS = { role: %i[name] }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  sluggable attributes: %i[id email]

  has_secure_password

  belongs_to :account
  has_many :licenses, dependent: :destroy
  has_many :products, -> { reorder(nil).select('"products".*, "products"."id", "products"."created_at"').distinct('"products"."id"').order(Arel.sql('"products"."created_at" ASC')) }, through: :licenses
  has_many :machines, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_one :role, as: :resource, dependent: :destroy

  accepts_nested_attributes_for :role, update_only: true

  before_destroy :enforce_admin_minimum_on_account!
  before_update :enforce_admin_minimum_on_account!, if: -> { role.present? && role.changed? }
  before_create :set_user_role!, if: -> { role.nil? }

  before_save -> { self.email = email.downcase }

  validates :first_name, presence: true, if: -> { has_role?(:user) }
  validates :last_name, presence: true, if: -> { has_role?(:user) }
  validates :email, email: true, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :roles, -> (*roles) { joins(:role).where roles: { name: roles.flatten.map { |r| r.to_s.underscore } } }
  scope :product, -> (id) { joins(licenses: [:policy]).where policies: { product_id: id } }
  scope :admins, -> { roles :admin }
  scope :active, -> (status = true) {
    sub_query = License.where('"licenses"."user_id" = "users"."id"').select(1).arel.exists

    if ActiveRecord::Type::Boolean.new.cast(status)
      where(sub_query)
    else
      where.not(sub_query)
    end
  }

  def full_name
    return nil if first_name.nil? || last_name.nil?

    [first_name, last_name].join " "
  end

  def email_domain
    email&.[](/[^@]+@(.+)/, 1)
  end

  def intercom_id
    return unless has_role?(:admin, :developer)

    OpenSSL::HMAC.hexdigest('SHA256', ENV['INTERCOM_ID_SECRET'], id) rescue ''
  end

  # Our async destroy logic needs to be a bit different to prevent accounts
  # from going under the minimum admin threshold
  def destroy_async
    if has_role?(:admin) && account.admins.count <= MINIMUM_ADMIN_COUNT
      errors.add :account, :admins_required, message: "account must have at least #{MINIMUM_ADMIN_COUNT} admin user"

      return false
    end

    super
  end

  private

  def set_user_role!
    grant! :user
  end

  def enforce_admin_minimum_on_account!
    return if !has_role?(:admin) && !was_role?(:admin)

    admin_count = account.admins.count

    # Count is not accounting for the current role changes
    if !has_role?(:admin) && was_role?(:admin)
      admin_count -= 1
    end

    if admin_count < MINIMUM_ADMIN_COUNT
      errors.add :account, :admins_required, message: "account must have at least #{MINIMUM_ADMIN_COUNT} admin user"

      throw :abort
    end
  end
end
