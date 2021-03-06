require 'spec_helper'

describe 'puppet', :type => :class do
  let :facts do
    {
        :fqdn => 'my_hostname.tldr.domain.com',
    }
  end

  # dirty trick to get the running version of Puppet:
  puppet_version = `facter puppetversion`
  if puppet_version.to_f >= 4.4
    let(:cron_minute) { [3, 33] }
  else
    let(:cron_minute) { [6, 36] }
  end

  describe 'using role' do
    describe 'client' do
      default_params = {
          :'role' => 'client'
      }

      context 'with default configuration' do
        let :params do
          default_params
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppet') }
        it { is_expected.to contain_class('puppet::client') }
        it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
        it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
        ) }
        it { is_expected.to contain_cron('puppet_cron_interval').with(
            'ensure' => 'present',
            'user' => 'root',
            'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
            'minute' => cron_minute,
            'hour' => '*'
        ) }
        it { is_expected.to have_ini_setting_resource_count(0) }
        ''
      end # context 'with no configuration'
      context 'with custom configuration' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppet') }
        it { is_expected.to contain_class('puppet::client') }
        it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
        it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
        ) }
        it { is_expected.to contain_cron('puppet_cron_interval').with(
            'ensure' => 'present',
            'user' => 'root',
            'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
            'minute' => cron_minute,
            'hour' => '*'
        ) }
        context 'cron defaults changed' do
          let(:params) do
            default_params.merge(
                {
                    :'client_agent_service' => {
                        'type' => 'cron',
                        'puppet_bin' => '/usr/bin/puppet',
                        'minute' => '*/20',
                        'cron_structure' => 'echo "Gonna run puppet now!"; %{puppet_bin} %{puppet_args}'
                    }
                })
          end
          it { is_expected.to contain_cron('puppet_cron_interval').with(
              'ensure' => 'present',
              'user' => 'root',
              'command' => 'echo "Gonna run puppet now!"; /usr/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
              'minute' => '*/20',
              'hour' => '*'
          ) }
        end
        context '[main]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_main' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main certname').with(
              'section' => 'main',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
              'section' => 'main',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
              'section' => 'main',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }

        end # context "[main]"

        context '[agent]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

        context '[master]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_master' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master certname').with(
              'section' => 'master',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master server').with(
              'section' => 'master',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master ca_server').with(
              'section' => 'master',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[master]"

        context '[user]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

        context '[main] & [agent] & [master] & [user]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_main' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_master' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_user' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main certname').with(
              'section' => 'main',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
              'section' => 'main',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
              'section' => 'main',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master certname').with(
              'section' => 'master',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master server').with(
              'section' => 'master',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master ca_server').with(
              'section' => 'master',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

      end # context "with configuration"
      context 'variable type and content validations' do
        validations = {
            'must be hash' => {
                :name => %w(conf_main conf_master conf_agent conf_user),
                :valid => [
                    {
                        'setting1' => 'the',
                        'setting2' => 'game'
                    }

                ],
                :invalid => ['string', %w(array), 3, 2.42, true, false, nil],
                :message => 'is not a Hash',
            },
        }
        validations.sort.each do |type, var|
          var[:name].each do |var_name|
            var[:params] = {} if var[:params].nil?
            var[:valid].each do |valid|
              context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
                let(:params) { [default_params, var[:params], {:"#{var_name}" => valid, }].reduce(:merge) }
                it { is_expected.to compile }
                it { is_expected.to contain_ini_setting(
                                        '/etc/puppetlabs/puppet/puppet.conf ' + var_name.sub(/conf_/, '') + ' setting1'
                                    ).with(
                    'setting' => 'setting1',
                    'value' => 'the'
                ) }
                it { is_expected.to contain_ini_setting(
                                        '/etc/puppetlabs/puppet/puppet.conf ' + var_name.sub(/conf_/, '') + ' setting2'
                                    ).with(
                    'setting' => 'setting2',
                    'value' => 'game'
                ) }
              end
            end

            var[:invalid].each do |invalid|
              context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
                let(:params) { [default_params, var[:params], {:"#{var_name}" => invalid, }].reduce(:merge) }
                it 'should fail' do
                  expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
                end
              end
            end
          end # var[:name].each
        end # validations.sort.each

      end # context "with invalid configuration"

      describe 'with hiera_data' do

        describe 'and hiera_merge disabled' do
          context 'with data in a single level' do
            let :facts do
              {
                  :fqdn => 'my_hostname.tldr.domain.com',
                  :specific => 'monkey',
              }
            end
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('puppet') }
            it { is_expected.to contain_class('puppet::client') }
            it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
            it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
            it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
                'owner' => 'root',
                'group' => 'root',
                'mode' => '0644'
            ) }
            it { is_expected.to contain_cron('puppet_cron_interval').with(
                'ensure' => 'present',
                'user' => 'root',
                'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
                'minute' => cron_minute,
                'hour' => '*'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca').with(
                'section' => 'main',
                'setting' => 'ca',
                'value' => 'false',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
                'section' => 'main',
                'setting' => 'server',
                'value' => 'puppet.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
                'section' => 'main',
                'setting' => 'ca_server',
                'value' => 'puppetca.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
          end # context "with data in a single hiera level"
          context 'with data in multiple levels' do
            let :facts do
              {
                  :fqdn => 'my_hostname.tldr.domain.com',
                  :specific => 'monkey',
                  :very_specific => 'multiple'
              }
            end
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('puppet') }
            it { is_expected.to contain_class('puppet::client') }
            it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
            it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
            it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
                'owner' => 'root',
                'group' => 'root',
                'mode' => '0644'
            ) }
            it { is_expected.to contain_cron('puppet_cron_interval').with(
                'ensure' => 'present',
                'user' => 'root',
                'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
                'minute' => cron_minute,
                'hour' => '*'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca').with(
                'section' => 'main',
                'setting' => 'ca',
                'value' => 'true',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
          end # context "with data in multiple levels"
        end # describe "and hiera_merge disabled"

        describe 'and hiera_merge enabled' do
          context 'with data in a single level' do
            let :facts do
              {
                  :fqdn => 'my_hostname.tldr.domain.com',
                  :specific => 'oshiri',
              }
            end
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('puppet') }
            it { is_expected.to contain_class('puppet::client') }
            it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
            it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
            it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
                'owner' => 'root',
                'group' => 'root',
                'mode' => '0644'
            ) }
            it { is_expected.to contain_cron('puppet_cron_interval').with(
                'ensure' => 'present',
                'user' => 'root',
                'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
                'minute' => cron_minute,
                'hour' => '*'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca').with(
                'section' => 'main',
                'setting' => 'ca',
                'value' => 'false',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
                'section' => 'main',
                'setting' => 'server',
                'value' => 'puppet.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
                'section' => 'main',
                'setting' => 'ca_server',
                'value' => 'puppetca.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
          end # context "with data in a single level"
          context 'with data in multiple levels' do
            let :facts do
              {
                  :fqdn => 'my_hostname.tldr.domain.com',
                  :specific => 'monkey',
                  :very_specific => 'true'
              }
            end
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('puppet') }
            it { is_expected.to contain_class('puppet::client') }
            it { is_expected.to contain_package('puppet_client').that_comes_before('Class[puppet::config]') }
            it { is_expected.to contain_class('puppet::config').that_comes_before('Cron[puppet_cron_interval]') }
            it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
                'owner' => 'root',
                'group' => 'root',
                'mode' => '0644'
            ) }
            it { is_expected.to contain_cron('puppet_cron_interval').with(
                'ensure' => 'present',
                'user' => 'root',
                'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
                'minute' => cron_minute,
                'hour' => '*'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
                'section' => 'main',
                'setting' => 'server',
                'value' => 'puppet.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
                'section' => 'main',
                'setting' => 'ca_server',
                'value' => 'puppetca.tldr.domain.com',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main vardir').with(
                'section' => 'main',
                'setting' => 'vardir',
                'value' => '/dev/null',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
            it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca').with(
                'section' => 'main',
                'setting' => 'ca',
                'value' => 'true',
                'path' => '/etc/puppetlabs/puppet/puppet.conf'
            ) }
          end # context "with data in multiple levels"
        end # describe "and hiera_merge enabled"

      end # describe "with hiera_data"

    end # describe 'client'
    describe 'master' do
      default_params = {
          :'role' => 'master'
      }
      context 'with default configuration' do
        let :params do
          default_params
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppet') }
        it { is_expected.to contain_class('puppet::master') }
        it { is_expected.to contain_class('puppet::config').that_notifies('Service[puppetserver]') }
        it { is_expected.to contain_service('puppetserver').that_comes_before('Cron[puppet_cron_interval]') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
        ) }
        it { is_expected.to contain_cron('puppet_cron_interval').with(
            'ensure' => 'present',
            'user' => 'root',
            'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
            'minute' => cron_minute,
            'hour' => '*'
        ) }
        it { is_expected.to have_ini_setting_resource_count(0) }
      end
      context 'with custom configuration' do
        let :params do
          default_params
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppet') }
        it { is_expected.to contain_class('puppet::master') }
        it { is_expected.to contain_class('puppet::config').that_notifies('Service[puppetserver]') }
        it { is_expected.to contain_service('puppetserver').that_comes_before('Cron[puppet_cron_interval]') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
        ) }
        it { is_expected.to contain_cron('puppet_cron_interval').with(
            'ensure' => 'present',
            'user' => 'root',
            'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
            'minute' => cron_minute,
            'hour' => '*'
        ) }
        context 'cron defaults changed' do
          let(:params) do
            default_params.merge(
                {
                    :'client_agent_service' => {
                        'type' => 'cron',
                        'puppet_bin' => '/usr/bin/puppet',
                        'minute' => '*/20',
                        'cron_structure' => 'echo "Gonna run puppet now!"; %{puppet_bin} %{puppet_args}'
                    }
                })
          end
          it { is_expected.to contain_cron('puppet_cron_interval').with(
              'ensure' => 'present',
              'user' => 'root',
              'command' => 'echo "Gonna run puppet now!"; /usr/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
              'minute' => '*/20',
              'hour' => '*'
          ) }
        end
        context '[main]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_main' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main certname').with(
              'section' => 'main',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
              'section' => 'main',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
              'section' => 'main',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }

        end # context "[main]"

        context '[agent]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

        context '[master]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_master' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master certname').with(
              'section' => 'master',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master server').with(
              'section' => 'master',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master ca_server').with(
              'section' => 'master',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[master]"

        context '[user]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end

          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

        context '[main] & [agent] & [master] & [user]' do
          let(:params) do
            default_params.merge(
                {
                    :'conf_main' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_agent' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_master' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    },
                    :'conf_user' => {
                        'server' => 'puppet.tldr.domain.com',
                        'ca_server' => 'puppetca.tldr.domain.com',
                        'certname' => facts[:fqdn]
                    }
                })
          end
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main certname').with(
              'section' => 'main',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main server').with(
              'section' => 'main',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf main ca_server').with(
              'section' => 'main',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master certname').with(
              'section' => 'master',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master server').with(
              'section' => 'master',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf master ca_server').with(
              'section' => 'master',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent certname').with(
              'section' => 'agent',
              'setting' => 'certname',
              'value' => facts[:fqdn],
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent server').with(
              'section' => 'agent',
              'setting' => 'server',
              'value' => 'puppet.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
          it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/puppet.conf agent ca_server').with(
              'section' => 'agent',
              'setting' => 'ca_server',
              'value' => 'puppetca.tldr.domain.com',
              'path' => '/etc/puppetlabs/puppet/puppet.conf'
          ) }
        end # context "[agent]"

      end # context "with configuration"
      context 'with fileserver configuration' do
        let(:params) do
          default_params.merge(
              {
                  :'master_fileserver_config' => {
                      'files' => {},
                      'miles' => {},
                  },
              }
          )
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppet') }
        it { is_expected.to contain_class('puppet::master') }
        it { is_expected.to contain_class('puppet::config').that_notifies('Service[puppetserver]') }
        it { is_expected.to contain_service('puppetserver').that_comes_before('Cron[puppet_cron_interval]') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with(
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
        ) }
        it { is_expected.to contain_cron('puppet_cron_interval').with(
            'ensure' => 'present',
            'user' => 'root',
            'command' => '/opt/puppetlabs/bin/puppet agent --onetime --ignorecache --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay',
            'minute' => cron_minute,
            'hour' => '*'
        ) }
        # Files fileserver config
        it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/fileserver.conf files path').with(
            'section' => 'files',
            'setting' => 'path',
            'value' => '/etc/puppetlabs/code/files',
            'path' => '/etc/puppetlabs/puppet/fileserver.conf',
            'key_val_separator' => ' ',
        ) }
        it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/fileserver.conf files allow').with(
            'section' => 'files',
            'setting' => 'allow',
            'value' => '*',
            'path' => '/etc/puppetlabs/puppet/fileserver.conf',
            'key_val_separator' => ' ',
        ) }
        it { is_expected.to contain_puppet_authorization__rule('fileserver_files').with(
            'match_request_path' => '^/file_(metadata|content)s?/files/',
            'match_request_type' => 'regex',
            'match_request_method' => ['get', 'post'],
            'allow' => '*',
            'sort_order' => 300,
            'path' => '/etc/puppetlabs/puppetserver/conf.d/auth.conf'
        ) }
        it { is_expected.to contain_puppet_authorization__rule('fileserver_files').
            that_notifies('Service[puppetserver]') }


        # Miles fileserver config
        it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/fileserver.conf miles path').with(
            'section' => 'miles',
            'setting' => 'path',
            'value' => '/etc/puppetlabs/code/miles',
            'path' => '/etc/puppetlabs/puppet/fileserver.conf',
            'key_val_separator' => ' ',
        ) }
        it { is_expected.to contain_ini_setting('/etc/puppetlabs/puppet/fileserver.conf miles allow').with(
            'section' => 'miles',
            'setting' => 'allow',
            'value' => '*',
            'path' => '/etc/puppetlabs/puppet/fileserver.conf',
            'key_val_separator' => ' ',
        ) }
        it { is_expected.to contain_puppet_authorization__rule('fileserver_miles').with(
            'match_request_path' => '^/file_(metadata|content)s?/miles/',
            'match_request_type' => 'regex',
            'match_request_method' => ['get', 'post'],
            'allow' => '*',
            'sort_order' => 300,
            'path' => '/etc/puppetlabs/puppetserver/conf.d/auth.conf'
        ) }
        it { is_expected.to contain_puppet_authorization__rule('fileserver_miles').
            that_notifies('Service[puppetserver]') }

      end # context "with fileserver configuration"
    end
  end # describe 'using role'
  describe 'using nonexistent roles' do
    let :params do
      {
          :'role' => 'you just lost it'
      }
    end
    it do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /The role can either be 'client' or 'master' not 'you just lost it'/)
    end
  end # describe "nonexistent roles"
end # describe 'puppet'
