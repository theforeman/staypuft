module Staypuft
  class Deployment::Passwords < Deployment::AbstractParamScope
    PASSWORD_LIST = :admin, :ceilometer_user, :cinder_db, :cinder_user,
        :glance_db, :glance_user, :heat_db, :heat_user, :heat_cfn_user, :mysql_root,
        :keystone_db, :keystone_user, :neutron_db, :neutron_user, :nova_db, :nova_user,
        :swift_admin, :swift_user, :amqp, :amqp_nssdb, :keystone_admin_token,
        :ceilometer_metering_secret, :heat_auth_encrypt_key, :horizon_secret_key,
        :swift_shared_secret, :neutron_metadata_proxy_secret

    OTHER_ATTRS_LIST = :mode, :single_password

    USER_SERVICES_PASSWORDS = :ceilometer_user, :cinder_user, :glance_user, :heat_user,
        :heat_cfn_user, :keystone_user, :neutron_user, :nova_user, :swift_user

    def self.param_scope
      'passwords'
    end

    param_attr *OTHER_ATTRS_LIST, *PASSWORD_LIST

    def initialize(deployment)
      super deployment
      self.single_password_confirmation = single_password
    end

    module Mode
      SINGLE = 'single'
      RANDOM = 'random'
      LABELS = { RANDOM => N_('Generate random password for each service'),
                 SINGLE => N_('Use single password for all services') }
      TYPES  = LABELS.keys
      HUMAN  = N_('Service Password')
    end

    validates :mode, presence: true, inclusion: { in: Mode::TYPES }

    # using old hash syntax here since if:, while validly parsing as :if => in
    # ruby itself, in irb the parser treats it as an if keyword, as does both
    # emacs and rubymine, which really messes with indention, etc.
    validates :single_password,
              :presence     => true,
              :confirmation => true,
              :if           => :single_mode?,
              :length       => { minimum: 6 }

    class Jail < Safemode::Jail
      allow :effective_value, :ceilometer_metering_secret, :heat_auth_encrypt_key,
        :horizon_secret_key, :swift_shared_secret, :neutron_metadata_proxy_secret
    end

    def set_defaults
      self.mode = Mode::RANDOM
      PASSWORD_LIST.each do |password_field|
        self.send("#{password_field}=", SecureRandom.hex)
      end
    end

    def single_mode?
      mode == Mode::SINGLE
    end

    def effective_value(password_field)
      if single_mode?
        single_password
      else
        send(password_field)
      end
    end

    def id # compatibility with password_f
      single_password
    end

    def user_services_passwords
      usp = {}
      USER_SERVICES_PASSWORDS.each do |user|
        usp[user] = single_mode? ? single_password : self.send(user) 
      end
      usp
    end
  end
end
