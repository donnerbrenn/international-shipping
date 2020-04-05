# ----------------------------------------
# HEY YOU! YEAH YOU! THE ONE READING THIS!
# ----------------------------------------
# Interested in demoscene on linux? join us in
# the Linux Sizecoding channel! #lsc on IRCNET!
# ----------------------------------------

# notes on the build system:
# ~$ uname -a
# Linux blackle-thinkpad 4.9.0-8-amd64 #1 SMP Debian 4.9.144-3 (2019-02-02) x86_64 GNU/Linux
# ~$ gcc -dumpversion
# 6.3.0
# ~$ nasm --version
# NASM version 2.14
# ~$ lzma --version
# xz (XZ Utils) 5.2.2
# liblzma 5.2.2
# ~$ dpkg-query --showformat='${Version}' --show libfftw3-dev:amd64
# 3.3.5-3
# ~$ dpkg-query --showformat='${Version}' --show libglib2.0-dev
# 2.50.3-2
# ~$ dpkg-query --showformat='${Version}' --show libgtk-3-dev:amd64
# 3.22.11-1
# ~$ dpkg-query --showformat='${Version}' --show mesa-common-dev:amd64
# 13.0.6-1+b2


# not using `pkg-config --libs` here because it will include too many libs

GCC=gcc

CFLAGS = -Os -s -march=nocona -std=gnu11

CFLAGS+= -fno-plt
CFLAGS+= -fno-stack-protector -fno-stack-check
CFLAGS+= -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-exceptions
CFLAGS+= -funsafe-math-optimizations -ffast-math
CFLAGS+= -fomit-frame-pointer
CFLAGS+= -ffunction-sections -fdata-sections 
CFLAGS+= -fmerge-all-constants 
CFLAGS+= -fno-PIC -fno-PIE
CFLAGS+= -malign-data=cacheline
CFLAGS+= -mno-fancy-math-387 -mno-ieee-fp
CFLAGS+= -Wall 
CFLAGS+= -Wextra
CFLAGS+= -no-pie 
#use with gcc7+:
CFLAGS+=-flto

CFLAGS+= -nostartfiles -nodefaultlibs
CFLAGS+= `pkg-config --cflags gtk+-3.0` 
CFLAGS+= -lglib-2.0 
CFLAGS+= -lm -lc 
CFLAGS+= -lGL 
CFLAGS+= -lgtk-3 
CFLAGS+= -lgdk-3 
CFLAGS+= -lgobject-2.0 
CFLAGS+= -lfftw3f 

CFLAGS+= -Wl,--build-id=none 
CFLAGS+= -Wl,-z,norelro
CFLAGS+= -Wl,-z,nocombreloc
CFLAGS+= -Wl,--gc-sections 
CFLAGS+= -Wl,-z,nodynamic-undefined-weak
CFLAGS+= -Wl,--no-ld-generated-unwind-info
CFLAGS+= -Wl,--no-eh-frame-hdr
CFLAGS+= -Wl,-z,noseparate-code 
CFLAGS+= -Wl,--hash-style=sysv
CFLAGS+= -Wl,--whole-archive
CFLAGS+= -Wl,--print-gc-sections
CFLAGS+=-T linker.ld


.PHONY: clean check_size

all : shipping.zip check_size

screenshot.jpg : 1000_samples.png
	convert -quality 100 $< $@

shipping.zip : shipping shipping_unpacked README.txt international_shipping.nfo screenshot.jpg
	zip shipping.zip $^

packer : vondehi/vondehi.asm 
	cd vondehi; nasm -fbin -o vondehi vondehi.asm

shader.frag.min : shader.frag Makefile
	cp shader.frag shader.frag.min
	sed -i 's/m_origin/o/g' shader.frag.min
	sed -i 's/m_direction/d/g' shader.frag.min
	sed -i 's/m_point/k/g' shader.frag.min
	sed -i 's/m_intersected/i/g' shader.frag.min
	sed -i 's/m_color/c/g' shader.frag.min
	sed -i 's/m_mat/m/g' shader.frag.min
	sed -i 's/m_cumdist/y/g' shader.frag.min
	sed -i 's/m_attenuation/l/g' shader.frag.min

	sed -i 's/m_diffuse/o/g' shader.frag.min
	sed -i 's/m_specular/d/g' shader.frag.min
	sed -i 's/m_spec_exp/k/g' shader.frag.min
	sed -i 's/m_reflectance/i/g' shader.frag.min
	sed -i 's/m_transparency/c/g' shader.frag.min

	sed -i 's/MAXDEPTH/4/g' shader.frag.min

	sed -i 's/\bRay\b/Co/g' shader.frag.min
	sed -i 's/\bMat\b/Cr/g' shader.frag.min

shader.h : shader.frag.min Makefile
	mono ./shader_minifier.exe shader.frag.min -o shader.h

shipping.elf : shipping.c shader.h Makefile
	$(GCC) -o $@ $< $(CFLAGS) -DDEFAULT_SAMPLES='"1000"'
	strip -R .crap $@
	readelf -S $@
	#remove section header
	python3 Section-Header-Stripper/section-stripper.py $@

shipping_unpacked : shipping.elf
	
	mv $< $@

shipping : shipping_opt.elf.packed
	mv $< $@

#all the rest of these rules just takes a compiled elf file and generates a packed version of it with vondehi
%_opt.elf : %.elf Makefile
	cp $< $@
	chmod +x $@

%.xz : % Makefile
	-rm $@
	# ./megalania $< > $@
	python3 nicer.py $< -o $@
	#lzma --format=lzma -9 --extreme --lzma1=preset=9,lc=0,lp=0,pb=0,nice=40,depth=32,dict=16384 --keep --stdout $< > $@
	#./LZMA-Vizualizer/LzmaSpec $@

%.packed : %.xz packer Makefile
	cat ./vondehi/vondehi $< > $@
	chmod +x $@

clean :
	-rm *.elf *.xz shader.h shipping shipping_unpacked screenshot.jpg shipping.zip

check_size :
	sh ./sizelimit_check.sh
