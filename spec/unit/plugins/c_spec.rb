
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2010 VMware, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rbconfig'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

C_GCC = <<EOF
Reading specs from /usr/lib/gcc/x86_64-redhat-linux/3.4.6/specs
Configured with: ../configure --prefix=/usr ... --host=x86_64-redhat-linux
Thread model: posix
gcc version 3.4.6 20060404 (Red Hat 3.4.6-3)
EOF

C_GLIBC_2_3_4 = <<EOF
GNU C Library stable release version 2.3.4, by Roland McGrath et al.
Copyright (C) 2005 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 3.4.6 20060404 (Red Hat 3.4.6-3).
Compiled on a Linux 2.4.20 system on 2006-08-12.
Available extensions:
        GNU libio by Per Bothner
        crypt add-on version 2.1 by Michael Glad and others
        linuxthreads-0.10 by Xavier Leroy
        The C stubs add-on version 2.1.2.
        BIND-8.2.3-T5B
        NIS(YP)/NIS+ NSS modules 0.19 by Thorsten Kukuk
        Glibc-2.0 compatibility add-on by Cristian Gafton 
        GNU Libidn by Simon Josefsson
        libthread_db work sponsored by Alpha Processor Inc
Thread-local storage support included.
For bug reporting instructions, please see:
<http://www.gnu.org/software/libc/bugs.html>.
EOF

C_GLIBC_2_5 = <<EOF
GNU C Library stable release version 2.5, by Roland McGrath et al.
Copyright (C) 2006 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 4.1.2 20080704 (Red Hat 4.1.2-44).
Compiled on a Linux 2.6.9 system on 2009-09-02.
Available extensions:
	The C stubs add-on version 2.1.2.
	crypt add-on version 2.1 by Michael Glad and others
	GNU Libidn by Simon Josefsson
	GNU libio by Per Bothner
	NIS(YP)/NIS+ NSS modules 0.19 by Thorsten Kukuk
	Native POSIX Threads Library by Ulrich Drepper et al
	BIND-8.2.3-T5B
	RT using linux kernel aio
Thread-local storage support included.
For bug reporting instructions, please see:
<http://www.gnu.org/software/libc/bugs.html>.
EOF

C_CL = <<EOF
Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.762 for 80x86
Copyright (C) Microsoft Corporation.  All rights reserved.
EOF

C_VS = <<EOF

Microsoft (R) Visual Studio Version 8.0.50727.762.
Copyright (C) Microsoft Corp 1984-2005. All rights reserved.
EOF

C_XLC = <<EOF
IBM XL C/C++ Enterprise Edition for AIX, V9.0
Version: 09.00.0000.0000
EOF

C_SUN = <<EOF
cc: Sun C 5.8 Patch 121016-06 2007/08/01
EOF

C_HPUX = <<EOF
/opt/ansic/bin/cc:
        $Revision: 92453-07 linker linker crt0.o B.11.47 051104 $
        LINT B.11.11.16 CXREF B.11.11.16
        HP92453-01 B.11.11.16 HP C Compiler
         $ PATCH/11.00:PHCO_27774  Oct  3 2002 09:45:59 $ 
EOF

describe Ohai::System, "plugin c" do

  before(:each) do
    @plugin = get_plugin("c")

    @plugin[:languages] = Mash.new
    #gcc
    allow(@plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(0, "", C_GCC))
    #glibc
    allow(@plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC_2_3_4, ""))
    #ms cl
    allow(@plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(0, "", C_CL))
    #ms vs
    allow(@plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(0, C_VS, ""))
    #ibm xlc
    allow(@plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC, ""))
    #sun pro
    allow(@plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", C_SUN))
    #hpux cc
    allow(@plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(0, C_HPUX, ""))
  end

  #gcc
  it "should get the gcc version from running gcc -v" do
    expect(@plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(0, "", C_GCC))
    @plugin.run
  end

  it "should set languages[:c][:gcc][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:gcc][:version]).to eql("3.4.6")
  end

  it "should set languages[:c][:gcc][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:gcc][:description]).to eql(C_GCC.split($/).last)
  end

  it "should not set the languages[:c][:gcc] tree up if gcc command fails" do
    allow(@plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:gcc) if @plugin[:languages][:c]
  end

  #glibc
  it "should get the glibc x.x.x version from running /lib/libc.so.6" do
    expect(@plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC_2_3_4, ""))
    @plugin.run
  end

  it "should set languages[:c][:glibc][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:glibc][:version]).to eql("2.3.4")
  end

  it "should set languages[:c][:glibc][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:glibc][:description]).to eql(C_GLIBC_2_3_4.split($/).first)
  end

  it "should not set the languages[:c][:glibc] tree up if glibc command fails" do
    allow(@plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(1, "", ""))
    allow(@plugin).to receive(:shell_out).with("/lib64/libc.so.6").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:glibc) if @plugin[:languages][:c]
  end

  it "should get the glibc x.x version from running /lib/libc.so.6" do
    allow(@plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC_2_5, ""))
    expect(@plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC_2_5, ""))
    @plugin.run
    expect(@plugin.languages[:c][:glibc][:version]).to eql("2.5")
  end

  #ms cl
  it "should get the cl version from running cl /?" do
    expect(@plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(0, "", C_CL))
    @plugin.run
  end

  it "should set languages[:c][:cl][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:cl][:version]).to eql("14.00.50727.762")
  end

  it "should set languages[:c][:cl][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:cl][:description]).to eql(C_CL.split($/).first)
  end

  it "should not set the languages[:c][:cl] tree up if cl command fails" do
    allow(@plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:cl) if @plugin[:languages][:c]
  end

  #ms vs
  it "should get the vs version from running devenv.com /?" do
    expect(@plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(0, C_VS, ""))
    @plugin.run
  end

  it "should set languages[:c][:vs][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:vs][:version]).to eql("8.0.50727.762")
  end

  it "should set languages[:c][:vs][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:vs][:description]).to eql(C_VS.split($/)[1])
  end

  it "should not set the languages[:c][:vs] tree up if devenv command fails" do
    allow(@plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:vs) if @plugin[:languages][:c]
  end

  #ibm xlc
  it "should get the xlc version from running xlc -qversion" do
    expect(@plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC, ""))
    @plugin.run
  end

  it "should set languages[:c][:xlc][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:xlc][:version]).to eql("9.0")
  end

  it "should set languages[:c][:xlc][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:xlc][:description]).to eql(C_XLC.split($/).first)
  end

  it "should not set the languages[:c][:xlc] tree up if xlc command fails" do
    allow(@plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:xlc) if @plugin[:languages][:c]
  end

  it "should set the languages[:c][:xlc] tree up if xlc exit status is 249" do
    allow(@plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(63744, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:xlc) if @plugin[:languages][:c]
  end

  #sun pro
  it "should get the cc version from running cc -V -flags" do
    expect(@plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", C_SUN))
    @plugin.run
  end

  it "should set languages[:c][:sunpro][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:sunpro][:version]).to eql("5.8")
  end

  it "should set languages[:c][:sunpro][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:sunpro][:description]).to eql(C_SUN.chomp)
  end

  it "should not set the languages[:c][:sunpro] tree up if cc command fails" do
    allow(@plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:sunpro) if @plugin[:languages][:c]
  end

  it "should not set the languages[:c][:sunpro] tree if the corresponding cc command fails on linux" do
    fedora_error_message = "cc: error trying to exec 'i686-redhat-linux-gcc--flags': execvp: No such file or directory"

    allow(@plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", fedora_error_message))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:sunpro) if @plugin[:languages][:c]
  end

  it "should not set the languages[:c][:sunpro] tree if the corresponding cc command fails on hpux" do
    hpux_error_message = "cc: warning 901: unknown option: `-flags': use +help for online documentation.\ncc: HP C/aC++ B3910B A.06.25 [Nov 30 2009]"
    allow(@plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", hpux_error_message))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:sunpro) if @plugin[:languages][:c]
  end

  #hpux cc
  it "should get the cc version from running what cc" do
    expect(@plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(0, C_HPUX, ""))
    @plugin.run
  end

  it "should set languages[:c][:hpcc][:version]" do
    @plugin.run
    expect(@plugin.languages[:c][:hpcc][:version]).to eql("B.11.11.16")
  end

  it "should set languages[:c][:hpcc][:description]" do
    @plugin.run
    expect(@plugin.languages[:c][:hpcc][:description]).to eql(C_HPUX.split($/)[3].strip)
  end

  it "should not set the languages[:c][:hpcc] tree up if cc command fails" do
    allow(@plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(1, "", ""))
    @plugin.run
    expect(@plugin[:languages][:c]).not_to have_key(:hpcc) if @plugin[:languages][:c]
  end

end
