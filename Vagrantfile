# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.synced_folder '.', '/vagrant', type: 'rsync',
    rsync__exclude: ['.bundle/'], rsync__auto: true

  config.vm.define 'rhel6.example.com' do |machine|
    machine.vm.box = 'puppetlabs/centos-6.6-64-nocm'
    machine.vm.provision 'shell', inline: 'yum install -y epel-release'
    machine.vm.provision 'shell', inline: 'yum install -y ruby ruby-devel gcc rubygem-bundler git'
  end

  config.vm.define 'rhel7.example.com' do |machine|
    machine.vm.box = 'puppetlabs/centos-7.0-64-nocm'
    machine.vm.provision 'shell', inline: 'yum install -y ruby ruby-devel gcc rubygem-bundler git'
  end

end
