# frozen_string_literal: true

class ReleaseUpdateService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidProductError < StandardError; end
  class InvalidPlatformError < StandardError; end
  class InvalidVersionError < StandardError; end
  class InvalidConstraintError < StandardError; end
  class InvalidChannelError < StandardError; end
  class UpdateResult < OpenStruct; end

  def initialize(account:, product:, platform:, version:, constraint: nil, channel: 'stable')
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidProductError.new('product must be present') unless
      product.present?

    raise InvalidPlatformError.new('platform must be present') unless
      platform.present?

    raise InvalidVersionError.new('current version must be present') unless
      version.present?

    raise InvalidChannelError.new('channel must be present') unless
      channel.present?

    @account    = account
    @product    = product
    @platform   = platform
    @version    = version
    @constraint = constraint
    @channel    = channel
  end

  def call
    current_version = current_semver.to_s
    current_release =
      if current_version.present?
        available_releases.find_by(version: current_version)
      else
        nil
      end

    next_version = next_semver.to_s
    next_release =
      if next_version.present?
        unyanked_releases.find_by(version: next_version)
      else
        nil
      end

    UpdateResult.new(
      current: current_release,
      next: next_release,
    )
  end

  private

  attr_reader :account,
              :product,
              :platform,
              :version,
              :constraint,
              :channel

  def available_releases
    @available_releases ||= account.releases.for_product(product)
                                            .for_platform(platform)
                                            .for_channel(channel)
  end

  def unyanked_releases
    @unyanked_releases ||= available_releases.unyanked
  end

  def unyanked_versions
    @unyanked_versions ||= unyanked_releases.limit(10_000)
                                            .pluck(:version)
  end

  def current_semver
    @current_semver ||= Semverse::Version.new(version)
  rescue Semverse::InvalidVersionFormat
    raise InvalidVersionError.new 'current version must be a valid semver: x.y.z or x.y.z-beta.1'
  end

  def next_semver
    semvers = unyanked_versions.map { |v| Semverse::Version.new(v) }
                               .reject { |v| v <= current_semver }

    if constraint.present?
      semver = Semverse::Version.new(constraint)
      rule   =
        if channel.present?
          "~> #{semver.major}.#{semver.minor}-#{channel}"
        else
          "~> #{semver.major}.#{semver.minor}"
        end

      return Semverse::Constraint.satisfy_best(
        [Semverse::Constraint.new(rule)],
        semvers
      )
    end

    semvers.sort.last
  rescue Semverse::InvalidVersionFormat
    raise InvalidConstraintError.new 'version constraint must be a valid semver: x.y or x.y-rc.1'
  rescue Semverse::NoSolutionError
    nil
  end
end
