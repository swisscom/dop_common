# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.synced_folder '.', '/vagrant', type: 'rsync',
    rsync__exclude: ['.bundle/'], rsync__auto: true

  config.vm.define 'rhel6.example.com' do |machine|
    machine.vm.box = 'puppetlabs/centos-6.6-64-nocm'
    machine.vm.provision 'shell', inline: 'yum install -y gcc git epel-release centos-release-scl'
    machine.vm.provision 'shell', inline: 'yum install -y ruby ruby-devel rubygem-bundler'
    machine.vm.provision 'shell', inline: 'yum install -y ruby193 ruby193-ruby-devel ruby193-rubygem-bundler'
    machine.vm.provision 'shell', inline: 'yum install -y rh-ruby22 rh-ruby22-ruby-devel rh-ruby22-rubygem-bundler'
  end

  config.vm.define 'rhel7.example.com' do |machine|
    machine.vm.box = 'puppetlabs/centos-7.0-64-nocm'
    machine.vm.provision 'shell', inline: 'yum install -y gcc git'
    machine.vm.provision 'shell', inline: 'yum install -y ruby ruby-devel rubygem-bundler'
    machine.vm.provision 'shell', inline: 'yum install -y ruby193 ruby193-ruby-devel ruby193-rubygem-bundler'
    machine.vm.provision 'shell', inline: 'yum install -y rh-ruby22 rh-ruby22-ruby-devel rh-ruby22-rubygem-bundler'
  end

end
