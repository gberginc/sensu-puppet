require 'spec_helper'
require 'puppet/provider/sensuctl'

describe Puppet::Provider::Sensuctl do
  subject { Puppet::Provider::Sensuctl }

  context 'sensuctl_list' do
    it 'should list a resource' do
      expected_args = ['check','list','--all-namespaces','--format','json']
      expect(subject).to receive(:sensuctl).with(expected_args)
      subject.sensuctl_list('check')
    end

    it 'should list a resource without all namespaces' do
      expected_args = ['namespace','list','--format','json']
      expect(subject).to receive(:sensuctl).with(expected_args)
      subject.sensuctl_list('namespace')
    end
  end

  context 'sensuctl_create' do
    before(:each) do
      @tmp = Tempfile.new()
      allow(Tempfile).to receive(:new).with('sensuctl').and_return(@tmp)
      allow(subject).to receive(:sensuctl).with(['create','--file',@tmp.path])
    end

    it 'should have JSON with type' do
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
      j = JSON.parse(File.read(@tmp.path))
      expect(j['type']).to eq('Test')
    end

    it 'should have JSON with api_version' do
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
      j = JSON.parse(File.read(@tmp.path))
      expect(j['api_version']).to eq('core/v2')
    end

    it 'should have JSON with metadata' do
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
      j = JSON.parse(File.read(@tmp.path))
      expect(j['metadata']).to eq('name' => 'test')
    end

    it 'should have JSON with spec' do
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
      j = JSON.parse(File.read(@tmp.path))
      expect(j['spec']).to eq({'foo' => 'bar'})
    end

    it 'should have JSON with only valid keys' do
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
      j = JSON.parse(File.read(@tmp.path))
      expect(j.keys).to eq(['type','api_version','metadata','spec'])
    end

    it 'should create a resource' do
      expect(subject).to receive(:sensuctl).with(['create','--file',@tmp.path])
      subject.sensuctl_create('test', {name: 'test'}, {foo: 'bar'})
    end
  end

  context 'sensuctl_delete' do
    it 'should delete a resource' do
      expected_args = ['check','delete','test','--skip-confirm']
      expect(subject).to receive(:sensuctl).with(expected_args)
      subject.sensuctl_delete('check','test')
    end
  end
end
