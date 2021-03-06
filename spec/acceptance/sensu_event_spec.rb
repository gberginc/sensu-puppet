require 'spec_helper_acceptance'

describe 'sensu_event', if: RSpec.configuration.sensu_full do
  node = hosts_as('sensu_backend')[0]
  agent = hosts_as('sensu_agent')[0]
  context 'setup agent' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensu::agent':
        backends    => ['sensu_backend:8081'],
        config_hash => {
          'name' => 'sensu_agent',
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(agent, pp, :catch_failures => true)
      apply_manifest_on(agent, pp, :catch_changes  => true)
    end
  end

  context 'default' do
    it 'should work without errors' do
      check_pp = <<-EOS
      include ::sensu::backend
      sensu_check { 'test':
        command       => 'exit 1',
        subscriptions => ['entity:sensu_agent'],
        interval      => 3600,
      }
      EOS
      pp = <<-EOS
      include ::sensu::backend
      sensu_event { 'test for sensu_agent':
        ensure => 'resolve',
      }
      EOS

      apply_manifest_on(node, check_pp, :catch_failures => true)
      on node, 'sensuctl check execute test'
      apply_manifest_on(node, pp, :catch_failures  => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have resolved check' do
      on node, 'sensuctl event info sensu_agent test --format json' do
        data = JSON.parse(stdout)
        expect(data['check']['status']).to eq(0)
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_event { 'test for sensu_agent':
        ensure => 'absent',
      }
      EOS

      # Stop sensu-agent on agent node to avoid re-creating event
      apply_manifest_on(hosts_as('sensu_agent'),
        "service { 'sensu-agent': ensure => 'stopped' }")
      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl event info sensu_agent test'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

