namespace :rubber do
  namespace :base do

    rubber.allow_optional_tasks(self)

    before "rubber:setup_gem_sources", "rubber:base:install_rvm"
    task :install_rvm do
      rubber.sudo_script "install_rvm", <<-ENDSCRIPT
        if [[ ! `rvm --version 2> /dev/null` =~ "#{rubber_env.rvm_version}" ]]; then
          cd /tmp
          curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o rvm-installer
          chmod +x rvm-installer
          rm -f /etc/rvmrc
          ./rvm-installer --version #{rubber_env.rvm_version} 
          # Set up the rubygems version
          sed -i 's/rubygems_version=.*/rubygems_version=#{rubber_env.rubygems_version}/' #{rubber_env.rvm_prefix}/config/db

          # Set up the rake version
          sed -i 's/rake.*/rake -v#{rubber_env.rake_version}/' #{rubber_env.rvm_prefix}/gemsets/default.gems
          sed -i 's/rake.*/rake -v#{rubber_env.rake_version}/' #{rubber_env.rvm_prefix}/gemsets/global.gems

          # Set up the .gemrc file
          if [[ ! -f ~/.gemrc ]]; then
            echo "--- " >> ~/.gemrc
          fi

          if ! grep -q 'gem: ' ~/.gemrc; then
            echo "gem: --no-ri --no-rdoc" >> ~/.gemrc
          fi
        fi
      ENDSCRIPT
    end

    # ensure that the rvm profile script gets sourced by reconnecting
    after "rubber:base:install_rvm" do
      teardown_connections_to(sessions.keys)
    end

    after "rubber:base:install_rvm", "rubber:base:install_rvm_ruby"
    task :install_rvm_ruby do
      opts = get_host_options('rvm_ruby')
      install_rvm_ruby_script = <<-ENDSCRIPT
        rvm_ver=$1
        if [[ ! `rvm list default 2> /dev/null` =~ "$rvm_ver" ]]; then
          echo "RVM is compiling/installing ruby $rvm_ver, this may take a while"

          nohup rvm install $rvm_ver &> /tmp/install_rvm_ruby.log &
          sleep 1

          while true; do
            if ! ps ax | grep -q "[r]vm install"; then break; fi
            echo -n .
            sleep 5
          done

          # need to set default after using once or something in env is broken
          rvm use $rvm_ver &> /dev/null
          rvm use $rvm_ver --default

          # Something flaky with $PATH having an entry for "bin" which breaks
          # munin, the below seems to fix it
          rvm use $rvm_ver
          rvm repair environments
          rvm use $rvm_ver
        fi
      ENDSCRIPT
      opts[:script_args] = '$CAPISTRANO:VAR$'
      rubber.sudo_script "install_rvm_ruby", install_rvm_ruby_script, opts
    end

    after "rubber:install_packages", "rubber:base:configure_git" if scm == "git"
    task :configure_git do
      rubber.sudo_script 'configure_git', <<-ENDSCRIPT
        if [[ "#{repository}" =~ "@" ]]; then
          # Get host key for src machine to prevent ssh from failing
          rm -f ~/.ssh/known_hosts
          ! ssh -o 'StrictHostKeyChecking=no' #{repository.gsub(/:.*/, '')} &> /dev/null
        fi
      ENDSCRIPT
    end

    # We need a rails user for safer permissions used by deploy.rb
    after "rubber:install_packages", "rubber:base:custom_install"
    task :custom_install do
      rubber.sudo_script 'custom_install', <<-ENDSCRIPT
        # add the user for running app server with
        if ! id #{rubber_env.app_user} &> /dev/null; then adduser --system --group #{rubber_env.app_user}; fi
          
        # add ssh keys for root 
        if [[ ! -f /root/.ssh/id_dsa ]]; then ssh-keygen -q -t dsa -N '' -f /root/.ssh/id_dsa; fi
      ENDSCRIPT
    end

    after "rubber:install_packages", "rubber:base:install_nogokiri_dependencies"
    task :install_nogokiri_dependencies do
      puts "---------------------------------- its runnnnnnnnnnnnnnninnnnnnnnnnnng-------------------------------"
      rubber.sudo_script 'install_nogokiri_dependencies', <<-ENDSCRIPT
       sudo apt-get -y install libxslt1-dev libxml2-dev
      ENDSCRIPT
    end

    after "rubber:install_packages", "rubber:base:install_ffmpeg"
    task :install_ffmpeg do
      rubber.sudo_script 'install_ffmpeg', <<-ENDSCRIPT
        echo "---------------------------------------------"
        echo "|       starting installation script        |"
        echo "|  installing ffmpeg, opencv and mediainfo  |"
        echo "---------------------------------------------"
        echo ""

        if [[ ! -e ~/ffmpeg_installed.txt ]]; then
          echo "----------- ffpeg installation -----------"
          sudo apt-get -y remove ffmpeg x264 libx264-dev yasm
          sudo apt-get -y update
          sudo apt-get -y install build-essential git-core checkinstall texi2html libfaac-dev \
          libopencore-amrnb-dev libopencore-amrwb-dev libsdl1.2-dev libtheora-dev \
          libvorbis-dev libx11-dev libxfixes-dev zlib1g-dev
          cd
          wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
          tar xzvf yasm-1.2.0.tar.gz
          cd yasm-1.2.0
          ./configure
          make
          make install
          sudo checkinstall --pkgname=yasm --pkgversion="1.2.0" --backup=no --deldoc=yes --default
          cd
          git clone git://git.videolan.org/x264
          cd x264
          ./configure --enable-static
          make
          sudo checkinstall --pkgname=x264 --default --pkgversion="3:$(./version.sh | \
              awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes
          sudo apt-get -y remove libmp3lame-dev
          sudo apt-get -y install nasm
          cd
          wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.tar.gz
          tar xzvf lame-3.99.tar.gz
          cd lame-3.99
          ./configure --enable-nasm --disable-shared
          make
          sudo checkinstall --pkgname=lame-ffmpeg --pkgversion="3.99" --backup=no --default \
              --deldoc=yes
          cd
          sudo apt-get -y install libvpx-dev
          git clone http://git.chromium.org/webm/libvpx.git
          cd libvpx
          ./configure
          make
          sudo checkinstall --pkgname=libvpx --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no \
              --default --deldoc=yes
          cd
          git clone --depth 1 git://source.ffmpeg.org/ffmpeg
          cd ffmpeg
          ./configure --enable-gpl --enable-libfaac --enable-libmp3lame --enable-libopencore-amrnb \
              --enable-libopencore-amrwb --enable-libtheora --enable-libvorbis --enable-libvpx \
              --enable-libx264 --enable-nonfree --enable-postproc --enable-version3 --enable-x11grab
          make
          sudo checkinstall --pkgname=ffmpeg --pkgversion="5:$(./version.sh)" --backup=no \
              --deldoc=yes --default
          hash x264 ffmpeg ffplay ffprobe
          cd
          echo "ffmpeg installed" > ffmpeg_installed.txt
        else
          echo "----ffmpeg already installed----"
        fi
      ENDSCRIPT
    end

    after "rubber:base:install_ffmpeg", "rubber:base:install_opencv"
    task :install_opencv do
      rubber.sudo_script 'install_opencv', <<-ENDSCRIPT
        if [[ ! -e ~/opencv_installed.txt ]]; then
          echo "---------------- openCV installation ----------------"
          sudo apt-get -y install build-essential libgtk2.0-dev libjpeg62-dev libtiff4-dev libjasper-dev libopenexr-dev cmake python-dev python-numpy libtbb-dev libeigen2-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev
          cd
          wget http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.2/OpenCV-2.2.0.tar.bz2
          tar -xvf OpenCV-2.2.0.tar.bz2
          cd OpenCV-2.2.0/
          cmake CMakeLists.txt
          make
          sudo make install
          echo "echo/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf
          sudo ldconfig
          echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" >> /etc/bash.bashrc
          echo "export PKG_CONFIG_PATH" >> /etc/bash.bashrc
          cd
          echo "opencv installed" > opencv_installed.txt
        else
          echo "--------opencv already installed---------"
        fi
      ENDSCRIPT
    end

    after "rubber:base:install_opencv", "rubber:base:install_mediainfo"
    task :install_mediainfo do
      rubber.sudo_script 'install_mediainfo', <<-ENDSCRIPT
        if [[ ! -e ~/mediainfo_installed.txt ]]; then
          echo "--------------- mediainfo installation ----------------"
          cd
          wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.54-1_i386.Debian_5.deb
          wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.54-1_i386.Ubuntu_10.10.deb
          wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.25-1_i386.Ubuntu_10.10.deb
          sudo dpkg -i libzen0_0.4.25-1_i386.Ubuntu_10.10.deb
          sudo dpkg -i libmediainfo0_0.7.54-1_i386.Ubuntu_10.10.deb
          sudo dpkg -i mediainfo_0.7.54-1_i386.Debian_5.deb
          cd
          echo "mediainfo installed" > mediainfo_installed.txt
        else
          echo "----mediainfo already installed----"
        fi
      ENDSCRIPT
    end


  end
end
