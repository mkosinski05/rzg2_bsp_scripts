WORK_DIR=$PWD/bsp-1.4-update
SRC_DIR=/media/zkmike/0DF83D052A378594/Renesas/RZV/RZV2L/v0104-update/

if [ ! -d $WORK_DIR ]; then
    mkdir $WORK_DIR
else
    rm -rfd $WORK_DIR
    mkdir $WORK_DIR
fi

### Extract the BSP Linux package
cd $WORK_DIR 
unzip $SRC_DIR/r01an6221ej0102-rzv2l-linux.zip
tar -xf ./r01an6221ej0102-rzv2l-linux/rzv2l_bsp_v100.tar.gz -C .
tar -xf ./r01an6221ej0102-rzv2l-linux/v1.0-to-v1.0update1.patch.tar.gz -C .
patch -p1 < v1.0-to-v1.0update1.patch
cd meta-rzv
for i in ../extra/v1.0update1_patches/*.patch; do patch -p1 < $i; done


### Please modify the following file $WORK_DIR/meta-rzv/recipes-bsp/u-boot/u-boot_2020.10.bb
### Replace SRCREV = "35a832d08bddaf64b3dccbf364732ac7f8dfb647" with
### with    SRCREV = "c12017179a8ca11d38486f1ace08d52a489056d0" 
### to avoid a failing "saveenv" command within the u-boot console
### this will be fixed in one of the next BSPs
sed -i -e 's|35a832d08bddaf64b3dccbf364732ac7f8dfb647|c12017179a8ca11d38486f1ace08d52a489056d0|g' $WORK_DIR/meta-rzv/recipes-bsp/u-boot/u-boot_2020.10.bb

### Copy/Move the 'Mali Graphics library' Zip file (RTK0EF0045Z13001ZJ-v0.51_forV2L_EN.zip) under the BSP directory.
cd $WORK_DIR
unzip $SRC_DIR/RTK0EF0045Z13001ZJ-v0.8_EN.zip 
tar -zxvf RTK0EF0045Z13001ZJ-v0.8_EN/meta-rz-features.tar.gz

### Copy/Move the 'MRZG2L Codec Library v0.4' Zip file (RTK0EF0045Z13001ZJ-v0.51_forV2L_EN.zip) under the BSP directory.
cd $WORK_DIR
unzip $SRC_DIR/RTK0EF0045Z15001ZJ-v0.53_EN.zip
tar zxvf RTK0EF0045Z15001ZJ-v0.51_EN/meta-rz-features.tar.gz

### Copy/Move the DRP Support archive file ( rr11an0549ej0500-rzv2l-drpai-sp.zip ) 
### Extract the 'DRP-AI Driver Support' package file (rzv2l_meta-drpai_ver0.90.tar.gz) under the BSP directory.
### After exacting using the command below, this will add a new directory "meta-drpai" and file "rzv2l-drpai-conf.patch"
cd $WORK_DIR
unzip $SRC_DIR/r11an0549ej0500-rzv2l-drpai-sp.zip -d drp
tar -xvf drp/rzv2l_drpai-driver/rzv2l_meta-drpai_ver5.00.tar.gz

### Copy/Move the ISP Support archive file ( r11an0561ej0100-rzv2l-isp-sp.zip ) 
### Extract the ISP Support Package ( rzv2l_meta-isp_ver1.00.tar.gz ) nder the BSP directory.
### After exacting using the command below, this will add a new directory "meta-isp" and file "rzv2l-isp-conf.patch"
cd $WORK_DIR
unzip $SRC_DIR/r11an0561ej0100-rzv2l-isp-sp.zip 
tar -zxvf ./rzv2l_meta-isp_ver1.00.tar.gz


### Setup the RZV2L MultiOS CM33 
### Install the and boot commands OpenAMP library
cd $WORK_DIR
unzip $SRC_DIR/r01an6238ej0100-rzv2l-cm33-multi-os-pkg.zip -d cm33
unzip cm33/meta-openamp.zip
unzip cm33/meta-rzv2l-freertos.zip

### Set up the Yocto Environment and copy a default configuration
cd $WORK_DIR
source poky/oe-init-build-env
cp ../meta-rzv/docs/template/conf/smarc-rzv2l/*.conf ./conf/


### Apply the patch from the 'DRP-AI Support' package
### (the current directory should still be the 'build' directory)
cd ../build
patch -p2 < ../rzv2l-drpai-conf.patch
### Apply Simple ISP Patch
patch -p2 < ../rzv2l-isp-conf.patch

## Patch RZV2L Multi-OS CM33 layers
sed -i '/${RZ_FEATURE}/a\ \ ${TOPDIR}/../meta-openamp \\' ./conf/bblayers.conf
sed -i '/meta-openamp/a\ \ ${TOPDIR}/../meta-rzv2l-freertos \\' ./conf/bblayers.conf

echo "" >> ./conf/local.conf
echo "IMAGE_INSTALL_append = \" libmetal open-amp rpmsg-sample\"" >> ./conf/local.conf
echo "" >> ./conf/local.conf

# Configure the build system for local build
cd $WORK_DIR../oss_pacakage
sed -i 's/#DL_DIR ?= "${TOPDIR}\/downloads"/DL_DIR ?= "${PWD}\/downloads" /' ./conf/local.conf
sed -i 's/#SSTATE_DIR ?= "${TOPDIR}\/sstate-cache"/SSTATE_DIR ?= "${PWD}\/sstate-cache"/' ./conf/local.conf

### Build
bitbake core-image-weston
bitbake core-image-weston -c populate_sdk

cd $WORK_DIR
rm *.pdf
rm -rfd drp
rm -rfd RTK*
rm -rfd cm33
rm *.gz

