WORK_DIR=$PWD/bsp-1.2
SRC_DIR=/media/zkmike/0DF83D052A378594/Renesas/RZV/RZV2M/v0102

if [ ! -d $WORK_DIR ]; then
    mkdir $WORK_DIR
else
    rm -rfd $WORK_DIR
    mkdir $WORK_DIR
fi

### Extract the BSP Linux package
cd $WORK_DIR 
unzip $SRC_DIR/r01an5971ej0120-rzv2m-linux.zip
tar -zxvf ./r01an5971ej0120-rzv2m-linux/bsp/rzv2m_bsp_eva_v120.tar.gz


### Extract the DRP Linux Package
cd $WORK_DIR 
unzip $SRC_DIR/r11an0530ej0600-rzv2m-drpai-sp.zip
tar -zxvf ./r11an0530ej0600-rzv2m-drpai-sp/rzv2m_drpai-driver/rzv2m_meta-drpai_ver6.00.tar.gz


### Extract the ISP Linux Package
unzip $SRC_DIR/r01an5978ej0120-rzv2m_isp-support.zip
tar -zxvf ./r01an5978ej0120-rzv2m_isp/rzv2m_isp_support-pkg_v120.tar.gz

cd $WORK_DIR 
# Initialize Yocto Build System
source poky/oe-init-build-env

# Compy RZV2M BSP Yocto Configuratino Files 
cp ../meta-rzv2m/docs/sample/conf/rzv2m/linaro-gcc/*.conf ./conf/

# Apply Patches
# Apply DRP Patch first
echo "Appling DRP Patch"
patch -p2 < ../rzv2m-drpai-conf.patch
# Apply ISP Patch Second
echo "Applying ISP Patch"
patch -p2 < ../rzv2m-isp-conf.patch


# Extract oss_package
7za x $SRC_DIR/r01tu0361ej0120-rzv2m_oss_pkg_v120.7z
# Fetch Linux
bitbake linux-renesas -c fetch
bitbake libmetal -c fetch
# Set Yocto Build to local
sed -i 's/BB_NO_NETWORK = "0"/BB_NO_NETWORK = "1"/g' ./conf/local.conf


# Start Yocto BSP Build System 
bitbake core-image-bsp 
# Start Yocto SDK Build
#bitbake core-image-bsp -c populate_sdk

# Cleamup 
cd $WORK_DIR 
rm -rfd r01an5971ej0120-rzv2m-linux
rm -rfd r01an5978ej0120-rzv2m_isp
rm -rfd r11an0530ej0600-rzv2m-drpai-sp
