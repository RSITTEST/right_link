#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require File.expand_path(File.join(File.dirname(__FILE__), '..','..','spec_helper.rb'))
require 'chef/ohai/mixin/rightlink'

describe ::Ohai::Mixin::RightLink do
  shared_examples_for '!windows env' do
    before(:each) do
      @old_RUBY_PLATFORM = RUBY_PLATFORM
      Object.const_set('RUBY_PLATFORM', 'x86_64-darwin13.0.0')
    end

    after(:each) do
      Object.const_set('RUBY_PLATFORM', @old_RUBY_PLATFORM)
    end
  end

  shared_examples_for 'windows env' do
    before(:each) do
      @old_RUBY_PLATFORM = RUBY_PLATFORM
      Object.const_set('RUBY_PLATFORM', 'mswin')
    end

    after(:each) do
      Object.const_set('RUBY_PLATFORM', @old_RUBY_PLATFORM)
    end
  end


  context 'CloudUtilities' do
    subject { Object.new.extend(::Ohai::Mixin::RightLink::CloudUtilities) }
    let(:network) {
      {
        :interfaces => {
          :lo   => { :addresses => { "127.0.0.1" => { 'family' => 'inet' } }, :flags => ["LOOPBACK"] },
          :eth0 => { :addresses => { "50.23.101.210" => { 'family' => 'inet' } }, :flags => [] },
          :eth1 => { :addresses => { "192.168.0.1" => { 'family' => 'inet' } }, :flags => []}
        }
      }
    }
    it 'should query instance ip'

    context '#private_ipv4?' do
      it 'returns true for private ipv4' do
        subject.private_ipv4?("192.168.0.1").should be_true
      end

      it 'returns false for public ipv4' do
        subject.private_ipv4?("8.8.8.8").should_not be_true
      end
    end

    context '#ips' do
      it 'returns list of ips of all network interfaces' do
        subject.ips(network).should_not be_empty
      end

      it "doesn't include localhost ip to list" do
        subject.ips(network).should_not include "127.0.0.1"
      end
    end

    context '#public_ips' do
      it 'returns list of public ips' do
        subject.public_ips(network).any? { |ip| subject.private_ipv4?(ip) }.should_not be true
      end
    end

    context '#private_ips' do
      it 'returns list of private ips' do
        subject.private_ips(network).all? { |ip| subject.private_ipv4?(ip) }.should be true
      end
    end
  end

  context 'DirMetadata' do

    let(:mixin) {
        mixin = Object.new.extend(::Ohai::Mixin::RightLink::DirMetadata)
        mixin
    }

    context 'rightlink metadata dir' do
      context 'on Linux' do
        it_should_behave_like "!windows env"

        it 'should point on /var/spool/cloud/meta-data' do
          mixin.rightlink_metadata_dir.should == '/var/spool/cloud/meta-data'
        end
      end

      context 'on Windows' do
        it_should_behave_like "windows env"

        it 'should point on C:\ProgramData\Rightscale\spool/cloud/meta-data' do
          old_ProgramData = ENV['ProgramData']
          ENV['ProgramData'] = 'C:\ProgramData'
          mixin.rightlink_metadata_dir.should == 'C:\ProgramData/RightScale/spool/cloud/meta-data'
          ENV['ProgramData'] = old_ProgramData
        end
      end
    end

    context 'fetch metadata' do
      let(:metadata_dir) {  File.expand_path(File.join(File.dirname(__FILE__),'test_meta-data_dir')) }

      it 'fetch metadata' do
        mixin.fetch_metadata(metadata_dir).should == {'public_ip' => '1.2.3.4', 'public_hostname'=>'my_public_host_name', 'sub_hash' => {'foo' => 'bar'}}
      end

    end

    context 'dhcp_lease_provider' do

      let(:dhcp_lease_provider_ip) { '1.2.3.4' }

      context 'on Linux' do
        it_should_behave_like "!windows env"

        it "should parse lease information" do
          lease_file = "/var/lib/dhcp/dhclient.eth0.leases"
          lease_info = "dhcp-server-identifier #{dhcp_lease_provider_ip}"
          flexmock(::File).should_receive(:exist?).with(lease_file).and_return(true)
          flexmock(::File).should_receive(:read).with(lease_file).and_return(lease_info)
          mixin.dhcp_lease_provider.should == dhcp_lease_provider_ip
        end

        it "should parse lease information on SuSE" do
          lease_file = "/var/lib/dhcpcd/dhcpcd-eth0.info"
          lease_files = %w{/var/lib/dhcp/dhclient.eth0.leases /var/lib/dhcp3/dhclient.eth0.leases /var/lib/dhclient/dhclient-eth0.leases /var/lib/dhclient-eth0.leases /var/lib/dhcpcd/dhcpcd-eth0.info}
          leases = Hash[lease_files.zip [false]*lease_files.length]
          leases[lease_file] = true
          lease_info = "DHCPSID='#{dhcp_lease_provider_ip}'"
          leases.each { |file, result| flexmock(::File).should_receive(:exist?).with(file).and_return(result) }
          flexmock(::File).should_receive(:read).with(lease_file).and_return(lease_info)
          mixin.dhcp_lease_provider.should == dhcp_lease_provider_ip
        end

        it "should fail is no dhcp lease info found" do
          flexmock(::File).should_receive(:exist?).and_return(false)
          expect { mixin.dhcp_lease_provider }.to raise_error('Cannot determine dhcp lease provider for cloudstack instance')
        end
      end

      context 'on Windows' do

        it_should_behave_like "windows env"

        let(:ipconfig_header) do
<<EOF

Windows IP Configuration

   Host Name . . . . . . . . . . . . : MyMachine
   Primary Dns Suffix  . . . . . . . :
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No
   DNS Suffix Search List. . . . . . : MyCompany.com

EOF
        end

        let(:ipconfig_dhcp) do
<<EOF
Ethernet adapter Local Area Connection:

   Connection-specific DNS Suffix  . : MyCompany.com
   Description . . . . . . . . . . . : Intel(R) 82567LM-3 Gigabit Network Connection
   Physical Address. . . . . . . . . : 00-11-22-33-44-55
   DHCP Enabled. . . . . . . . . . . : Yes
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : 0000::1111:2222:aaaa:bbbb%01(Preferred)
   IPv4 Address. . . . . . . . . . . : 10.10.1.55(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Lease Obtained. . . . . . . . . . : Monday, April 22, 2013 9:00:00 AM
   Lease Expires . . . . . . . . . . : Wednesday, April 22, 2015 9:00:00 AM
   Default Gateway . . . . . . . . . : 10.10.0.1
   DHCP Server . . . . . . . . . . . : #{dhcp_lease_provider_ip}
   DHCPv6 IAID . . . . . . . . . . . : 123456789
   DHCPv6 Client DUID. . . . . . . . : 00-11-22-33-44-55-66-77-88-99-AA-BB-CC-DD
   DNS Servers . . . . . . . . . . . : 10.10.1.1
                                       4.3.2.1
                                       4.3.2.2
                                       4.3.2.3
   NetBIOS over Tcpip. . . . . . . . : Enabled

EOF
        end

        let(:ipconfig_full)  { [ipconfig_header, ipconfig_dhcp].join("\n") }
        let(:expected_sleep) { 10 }
        let(:wait_message)   { "ipconfig /all did not contain any DHCP Servers. Retrying in #{expected_sleep} seconds..." }

        it "should parse 'ipconfig /all' output for DHCP Server" do
          flexmock(mixin).should_receive(:`).with('ipconfig /all').once.and_return(ipconfig_full)
          mixin.dhcp_lease_provider.should == dhcp_lease_provider_ip
        end

        it "should wait indefinitely until DCHP Server appears in output" do
          mock_subject = flexmock(mixin)
          counter = 0
          mock_subject.should_receive(:`).times(3).with('ipconfig /all').and_return do
            counter += 1
            if counter >= 3
              ipconfig_full
            else
              ipconfig_header
            end
          end
          mock_subject.should_receive(:sleep).twice.with(expected_sleep).and_return(true)
          mixin.dhcp_lease_provider.should == dhcp_lease_provider_ip
          counter.should == 3
        end

        it "should timout after 20 minutes" do
          mock_subject = flexmock(mixin)
          counter = 0
          start_time = ::Time.now
          end_time = start_time + 20 * 60 + 1  # 20 minutes, 1 second

          mock_subject.should_receive(:`).times(3).with('ipconfig /all').and_return do
            counter += 1
            if counter >= 3
              flexmock(::Time).should_receive(:now).and_return(end_time)
            end
            ipconfig_header
          end
          mock_subject.should_receive(:sleep).times(3).with(expected_sleep).and_return(true)

          expect { mixin.dhcp_lease_provider.should }.to raise_error('Cannot determine dhcp lease provider for cloudstack instance')
          counter.should == 3
        end
      end
    end

  end

  context 'AzureMetadata' do
    it 'will be refactored, and specs will be provided later'
  end
end

