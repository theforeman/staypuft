module Staypuft
  class Deployment::Passwords < Deployment::AbstractParamScope

    USER_SERVICES_PASSWORDS = :admin, :ceilometer_user, :cinder_user, :glance_user, :heat_user,
        :heat_cfn_user, :keystone_user, :neutron_user, :nova_user, :swift_user, :swift_admin, :amqp

    DB_SERVICES_PASSWORDS = :cinder_db, :glance_db, :heat_db, :mysql_root, :keystone_db,
        :neutron_db, :nova_db, :amqp_nssdb

    OTHER_PASSWORDS = :keystone_admin_token, :ceilometer_metering_secret, :heat_auth_encrypt_key,
        :horizon_secret_key, :swift_shared_secret, :neutron_metadata_proxy_secret

    PASSWORD_LIST = USER_SERVICES_PASSWORDS + DB_SERVICES_PASSWORDS + OTHER_PASSWORDS

    OTHER_ATTRS_LIST = :mode, :single_password

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

    def services_passwords(filter=nil)
      list = case filter
             when :user
               USER_SERVICES_PASSWORDS
             when :db
               DB_SERVICES_PASSWORDS
             else
               PASSWORD_LIST
             end

      list.inject({}) do |h,name|
        h.update name => single_mode? ? single_password : self.send(name)
      end
    end

    def param_hash
      { "mode" => mode, "single_password" => single_password}
    end
  end
end
