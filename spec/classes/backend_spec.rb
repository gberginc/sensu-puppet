require 'spec_helper'

describe 'sensu::backend', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node) { 'test.example.com' }
      context 'with default values for all parameters' do
        it { should compile.with_all_deps }

        it { should create_class('sensu::backend') }
        it { should contain_class('sensu') }
        it { should_not contain_class('sensu::agent') }
        it { should contain_class('sensu::ssl').that_comes_before('Sensu_configure[puppet]') }

        it {
          should contain_package('sensu-go-cli').with({
            'ensure'  => 'installed',
            'name'    => 'sensu-go-cli',
            'require' => 'Class[Sensu::Repo]',
          })
        }

        it {
          should contain_sensu_api_validator('sensu').with({
            'sensu_api_server' => 'test.example.com',
            'sensu_api_port'   => 8080,
            'use_ssl'          => 'true',
            'require'          => 'Service[sensu-backend]',
          })
        }

        it {
          should contain_sensu_configure('puppet').with({
            'url'                 => 'https://test.example.com:8080',
            'username'            => 'admin',
            'password'            => 'P@ssw0rd!',
            'bootstrap_password'  => 'P@ssw0rd!',
          })
        }

        it {
          should contain_file('sensu_ssl_cert').with({
            'ensure'    => 'file',
            'path'      => '/etc/sensu/ssl/cert.pem',
            'source'    => '/dne/cert.pem',
            'owner'     => 'sensu',
            'group'     => 'sensu',
            'mode'      => '0644',
            'show_diff' => 'false',
            'notify'    => 'Service[sensu-backend]',
          })
        }

        it {
          should contain_file('sensu_ssl_key').with({
            'ensure'    => 'file',
            'path'      => '/etc/sensu/ssl/key.pem',
            'source'    => '/dne/key.pem',
            'owner'     => 'sensu',
            'group'     => 'sensu',
            'mode'      => '0600',
            'show_diff' => 'false',
            'notify'    => 'Service[sensu-backend]',
          })
        }

        it {
          should contain_package('sensu-go-backend').with({
            'ensure'  => 'installed',
            'name'    => 'sensu-go-backend',
            'require' => 'Class[Sensu::Repo]',
          })
        }

        it {
          should contain_file('sensu_backend_state_dir').with({
            'ensure'  => 'directory',
            'path'    => '/var/lib/sensu/sensu-backend',
            'owner'   => 'sensu',
            'group'   => 'sensu',
            'mode'    => '0750',
            'require' => 'Package[sensu-go-backend]',
            'before'  => 'Service[sensu-backend]',
          })
        }

        backend_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |state-dir: "/var/lib/sensu/sensu-backend"
          |cert-file: "/etc/sensu/ssl/cert.pem"
          |key-file: "/etc/sensu/ssl/key.pem"
          |trusted-ca-file: "/etc/sensu/ssl/ca.crt"
        END

        it {
          should contain_file('sensu_backend_config').with({
            'ensure'  => 'file',
            'path'    => '/etc/sensu/backend.yml',
            'content' => backend_content,
            'require' => 'Package[sensu-go-backend]',
            'notify'  => 'Service[sensu-backend]',
          })
        }

        it {
          should contain_service('sensu-backend').with({
            'ensure'    => 'running',
            'enable'    => true,
            'name'      => 'sensu-backend',
            'subscribe' => 'Class[Sensu::Ssl]',
          })
        }
      end

      context 'with use_ssl => false' do
        let(:pre_condition) do
          "class { 'sensu': use_ssl => false }"
        end

        it {
          should contain_sensu_api_validator('sensu').with({
            'sensu_api_server' => 'test.example.com',
            'sensu_api_port'   => 8080,
            'use_ssl'          => 'false',
            'require'          => 'Service[sensu-backend]',
          })
        }

        it {
          should contain_sensu_configure('puppet').with({
            'url'                 => 'http://test.example.com:8080',
            'username'            => 'admin',
            'password'            => 'P@ssw0rd!',
            'bootstrap_password'  => 'P@ssw0rd!',
          })
        }

        it { should_not contain_file('sensu_ssl_cert') }
        it { should_not contain_file('sensu_ssl_key') }

        backend_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |state-dir: "/var/lib/sensu/sensu-backend"
        END

        it {
          should contain_file('sensu_backend_config').with({
            'ensure'  => 'file',
            'path'    => '/etc/sensu/backend.yml',
            'content' => backend_content,
            'require' => 'Package[sensu-go-backend]',
            'notify'  => 'Service[sensu-backend]',
          })
        }

        it { should contain_service('sensu-backend').without_notify }
      end
    end
  end
end

