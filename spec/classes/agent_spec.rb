require 'spec_helper'

describe 'sensu::agent', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'with default values for all parameters' do
        it { should compile.with_all_deps }

        it { should contain_class('sensu')}
        it { should contain_class('sensu::agent')}

        it {
          should contain_package('sensu-agent').with({
            'ensure'  => 'installed',
            'name'    => 'sensu-agent',
            'before'  => 'File[sensu_etc_dir]',
            'require' => 'Class[Sensu::Repo]',
          })
        }

        agent_content = <<-END.gsub(/^\s+\|/, '')
          |--- {}
        END

        it {
          should contain_file('sensu_agent_config').with({
            'ensure'  => 'file',
            'path'    => '/etc/sensu/agent.yml',
            'content' => agent_content,
            'require' => 'Package[sensu-agent]',
            'notify'  => 'Service[sensu-agent]',
          })
        }

        it {
          should contain_service('sensu-agent').with({
            'ensure' => 'running',
            'enable' => true,
            'name'   => 'sensu-agent',
          })
        }
      end
    end
  end
end
