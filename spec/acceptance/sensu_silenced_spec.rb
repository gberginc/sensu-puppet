require 'spec_helper_acceptance'

describe 'sensu_silenced', if: RSpec.configuration.sensu_full do
  node = hosts_as('sensu_backend')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_silenced { 'test':
        ensure => 'present',
        subscription => 'entity:sensu_agent',
        labels => { 'foo' => 'baz' },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid silenced' do
      on node, 'sensuctl silenced info entity:sensu_agent:* --format json' do
        data = JSON.parse(stdout)
        expect(data['subscription']).to eq('entity:sensu_agent')
        expect(data['expire']).to eq(-1)
        expect(data['expire_on_resolve']).to eq(false)
        expect(data['metadata']['labels']['foo']).to eq('baz')
      end
    end
  end

  context 'with updates' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_silenced { 'test':
        ensure => 'present',
        subscription => 'entity:sensu_agent',
        expire_on_resolve => true,
        labels => { 'foo' => 'bar' },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid silenced with updated propery' do
      on node, 'sensuctl silenced info entity:sensu_agent:* --format json' do
        data = JSON.parse(stdout)
        expect(data['expire_on_resolve']).to eq(true)
        expect(data['metadata']['labels']['foo']).to eq('bar')
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_silenced { 'test':
        ensure => 'absent',
        subscription => 'entity:sensu_agent',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl silenced info entity:sensu_agent:*'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

