require 'spec_helper_acceptance'

describe 'jdk_7_1036' do

  if os[:platform]  =~ /windows/

  else
    # Serverspec examples can be found at
    # http://serverspec.org/resource_types.html
    it 'Should apply the manifest without error' do
      pp = <<-EOS
        node default {

          include fmw_jdk::rng_service

          $java_home_dir       = '/usr/java/jdk1.7.0_75'
          $version             = '10.3.6'
          $middleware_home_dir = '/opt/oracle/middleware_1036'

          Class['fmw_wls::setup'] ->
            Class['fmw_wls::install']

          class { 'fmw_jdk::install':
            java_home_dir => $java_home_dir,
            source_file   => '/software/jdk-7u75-linux-x64.tar.gz',
          }

          # can be removed when all the default are used.
          class { 'fmw_wls':
            version             => $version,
            middleware_home_dir => $middleware_home_dir,
            os_user_uid         => '600',
          }

          include fmw_wls::setup

          # this requires fmw_jdk::install
          class { 'fmw_wls::install':
            java_home_dir => $java_home_dir,
            source_file   => '/software/wls1036_generic.jar',
          }

          class {'fmw_rcu::soa_suite':
            version                => $version,
            java_home_dir          => $java_home_dir,
            middleware_home_dir    => $middleware_home_dir,
            source_file            => '/software/ofm_rcu_linux_11.1.1.7.0_64_disk1_1of1.zip',
            rcu_prefix             => 'DEV20',
            jdbc_connect_url       => 'jdbc:oracle:thin:@10.10.10.15:1521/soarepos.example.com',
            db_connect_url         => '10.10.10.15:1521:soarepos.example.com',
            db_connect_password    => 'Welcome01',
            rcu_component_password => 'Welcome02',
          }

        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true, :acceptable_exit_codes => [0, 2])
      apply_manifest(pp, :catch_failures => true, :acceptable_exit_codes => [0, 2])
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
      shell('sleep 15')
    end

    describe file('/usr/java/jdk1.7.0_75') do
      it { should be_directory }
      it { should be_owned_by 'root' }
    end

    describe file('/usr/java/jdk1.7.0_75/bin/java') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_executable }
    end

    describe file('/usr/bin/java') do
      it { should be_symlink }
      it { should be_linked_to '/etc/alternatives/java' }
    end

    describe group('oinstall') do
      it { should exist }
    end

    describe user('oracle') do
      it { should belong_to_group 'oinstall' }
      it { should have_home_directory '/home/oracle' }
      it { should have_login_shell '/bin/bash' }
    end

    describe file('/etc/oraInst.loc') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_readable.by('others') }
      it { should contain 'inventory_loc=/home/oracle/oraInventory' }
      it { should contain 'inst_group=oinstall' }
    end

    describe file('/tmp/wls_11g.rsp') do
      it { should be_file }
      it { should contain '<data-value name="BEAHOME" value="/opt/oracle/middleware_1036" />' }
    end

    describe file('/home/oracle/oraInventory') do
      it { should be_directory }
      it { should be_owned_by 'oracle' }
      it { should be_grouped_into 'oinstall' }
    end

    describe file('/opt/oracle/middleware_1036') do
      it { should be_directory }
      it { should be_owned_by 'oracle' }
      it { should be_grouped_into 'oinstall' }
    end

    describe file('/opt/oracle/middleware_1036/wlserver_10.3/common/bin/wlst.sh') do
      it { should be_file }
      it { should be_owned_by 'oracle' }
      it { should be_grouped_into 'oinstall' }
      it { should be_executable }
    end


  end
end
