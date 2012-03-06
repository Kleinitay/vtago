echo "---------------------------------------------"
echo "|       starting installation script        |"
echo "|  installing ffmpeg, opencv and mediainfo  |"
echo "---------------------------------------------"
echo ""
echo "----------- ffpeg installation -----------"
# install dependencies for ffmpeg, x264
cd
sudo apt-get remove ffmpeg x264 libx264-dev yasm
sudo apt-get update
sudo apt-get install build-essential git-core checkinstall texi2html libfaac-dev \
      libopencore-amrnb-dev libopencore-amrwb-dev libsdl1.2-dev libtheora-dev \
          libvorbis-dev libx11-dev libxfixes-dev zlib1g-dev
# install yasm
echo "Installing yasm"
cd
wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
tar xzvf yasm-1.2.0.tar.gz
cd yasm-1.2.0
./configure
make
sudo checkinstall --pkgname=yasm --pkgversion="1.2.0" --backup=no --deldoc=yes --default
#install x264
echo "installing x264"
cd
git clone git://git.videolan.org/x264
cd x264
./configure --enable-static
make
sudo checkinstall --pkgname=x264 --default --pkgversion="3:$(./version.sh | \
      awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes
#install lame
echo "installing lame"
sudo apt-get remove libmp3lame-dev
sudo apt-get install nasm
cd
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.tar.gz
tar xzvf lame-3.99.tar.gz
cd lame-3.99
./configure --enable-nasm --disable-shared
make
sudo checkinstall --pkgname=lame-ffmpeg --pkgversion="3.99" --backup=no --default \
      --deldoc=yes
#install libvpx
echo "installing libvpx"
cd
git clone http://git.chromium.org/webm/libvpx.git
cd libvpx
./configure
make
sudo checkinstall --pkgname=libvpx --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no \
      --default --deldoc=yes
#install ffmpeg
echo "installing ffmpeg"
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-libfaac --enable-libmp3lame --enable-libopencore-amrnb \
      --enable-libopencore-amrwb --enable-libtheora --enable-libvorbis --enable-libvpx \
          --enable-libx264 --enable-nonfree --enable-postproc --enable-version3 --enable-x11grab
make
sudo checkinstall --pkgname=ffmpeg --pkgversion="5:$(./version.sh)" --backup=no \
      --deldoc=yes --default
hash x264 ffmpeg ffplay ffprobe

echo "---------------- openCV installation ----------------"
sudo apt-get install build-essential libgtk2.0-dev libjpeg62-dev libtiff4-dev libjasper-dev libopenexr-dev cmake python-dev python-numpy libtbb-dev libeigen2-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev
cd
wget http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.2/OpenCV-2.2.0.tar.bz2
tar -xvf OpenCV-2.2.0.tar.bz2
cd OpenCV-2.2.0/
cmake CMakeLists.txt
make
sudo make install
echo "echo/usr/local/lib" >> etc/ld.so.conf.d/opencv.conf
sudo ldconfig
echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" >> /etc/bash.bashrc
echo "export PKG_CONFIG_PATH" >> /etc/bash.bashrc
echo "--------------- mediainfo installation ----------------"
cd
wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.11-1_i386.Debian_5.0.deb
wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.11-1_i386.Debian_5.0.deb
wget http://downloads.sourceforge.net/zenlib/libzen0_0.3.8-1_i386.Debian_5.0.deb
sudo dpkg -i libzen0_0.3.8-1_i386.Debian_5.0.deb
sudo dpkg -i libmediainfo0_0.7.11-1_i386.Debian_5.0.deb
sudo dpkg -i mediainfo_0.7.11-1_i386.Debian_5.0.deb



