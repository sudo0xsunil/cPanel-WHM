# CloudLinux Shared OS Pro - Automated Installation Script

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![OS](https://img.shields.io/badge/OS-Rocky%20Linux%209-green.svg)](https://rockylinux.org/)
[![OS](https://img.shields.io/badge/OS-AlmaLinux%209-green.svg)](https://almalinux.org/)
[![Author](https://img.shields.io/badge/Author-sudo0xsunil-purple.svg)](https://instagram.com/sudo0xsunil)

An automated bash script to install CloudLinux Shared OS Pro on Rocky Linux 9, AlmaLinux 9, or CentOS 9 systems with cPanel.

**Developed by:** [Sunil Kumar](https://instagram.com/sudo0xsunil) | **Instagram:** [@sudo0xsunil](https://instagram.com/sudo0xsunil)

---

## ⚠️ IMPORTANT DISCLAIMER

**THIS SCRIPT IS FOR INSTALLATION PURPOSES ONLY**

- This script **ONLY** automates the installation process of CloudLinux OS
- You **MUST** purchase a valid CloudLinux license from [CloudLinux Official Website](https://www.cloudlinux.com/) or authorized vendors
- This script does **NOT** provide, bypass, or crack CloudLinux licenses
- **CloudLinux® is a registered trademark** of Cloud Linux Inc.
- I am **NOT affiliated** with CloudLinux Inc. in any way
- This is an **independent automation tool** created for educational and convenience purposes

### Legal Notice
```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHOR OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**By using this script, you agree that:**

1. You will obtain a **valid commercial license** from CloudLinux Inc. or authorized vendors
2. You will comply with all CloudLinux licensing terms and conditions
3. The author (Sunil Kumar / @sudo0xsunil) is **NOT responsible** for:
   - Any licensing violations
   - Any damages to your system
   - Any data loss
   - Any service interruptions
   - Any legal issues arising from improper use
4. You use this script **at your own risk**
5. This script is for **legitimate server administration purposes only**

### License Requirements

To use CloudLinux legally, you **MUST**:
- Purchase a license from: https://www.cloudlinux.com/pricing
- Or contact CloudLinux sales: https://www.cloudlinux.com/contact-us
- Or purchase through authorized CloudLinux partners

**CloudLinux License Information:**
- Official Website: https://www.cloudlinux.com/
- Pricing: https://www.cloudlinux.com/pricing
- Documentation: https://docs.cloudlinux.com/

---

## 📋 Features

- ✅ Automated conversion from Rocky/Alma/CentOS 9 to CloudLinux OS
- ✅ Pre-installation system compatibility checks
- ✅ Automatic backup of system files
- ✅ LVE (Lightweight Virtual Environment) installation
- ✅ CloudLinux LVE Manager for cPanel/WHM
- ✅ GRUB configuration optimization
- ✅ Kernel configuration for optimal LVE performance
- ✅ Detailed logging for troubleshooting
- ✅ Color-coded output for easy monitoring
- ✅ Error handling and rollback support

---

## 🖥️ System Requirements

### Supported Operating Systems
- Rocky Linux 9.x
- AlmaLinux 9.x
- CentOS 9.x

### Prerequisites
- Root access
- Active internet connection
- Minimum 5GB free disk space
- cPanel/WHM installed (recommended)
- **Valid CloudLinux license key** (can be added during or after installation)

---

## 📥 Quick Installation
```bash
curl -sS https://github.com/sudo0xsunil/cPanel-WHM/blob/main/cloud-linux-shared-os-pro.sh | bash
```

Or download and run manually:
```bash
wget https://github.com/sudo0xsunil/cPanel-WHM/blob/main/cloud-linux-shared-os-pro.sh
chmod +x cloud-linux-shared-os-pro.sh
./cloud-linux-shared-os-pro.sh
```


## 🚀 Usage Examples

### Basic Installation
```bash
chmod +x cloud-linux-shared-os-pro.sh
./cloud-linux-shared-os-pro.sh
```

### With License Key
When prompted, enter your CloudLinux activation key.

### Without License Key
Choose "n" when asked about activation key. Activate later:
```bash
rhnreg_ks --activationkey=YOUR-LICENSE-KEY
```

---

## 📖 Post-Installation

### Verify Installation
```bash
uname -r                    # Check kernel
cat /etc/redhat-release     # Check OS version
lvectl start                # Start LVE
lvectl list                 # List LVE limits
```

### Enable CageFS (Optional)
```bash
/usr/sbin/cagefsctl --init
/usr/sbin/cagefsctl --enable-all
```

---

## 🔧 Troubleshooting

### LVE Not Starting
```bash
lsmod | grep lve            # Check if module loaded
modprobe lve                # Load module manually
lvectl start                # Start LVE
```

### Check Logs
```bash
cat /var/log/cloudlinux_installation_*.log
dmesg | grep -i lve
```

---

## 🛡️ How to Obtain CloudLinux License

1. **Direct Purchase:** https://www.cloudlinux.com/pricing
2. **Through Hosting Provider:** Check with your provider
3. **Trial License:** https://www.cloudlinux.com/trial
4. **Authorized Resellers:** https://www.cloudlinux.com/partners

---

## 📧 Support & Contact

**Script Author:** Sunil Kumar  
**Instagram:** [@sudo0xsunil](https://instagram.com/sudo0xsunil)  
**For CloudLinux Support:** https://cloudlinux.zendesk.com/

---

## ⭐ Show Your Support

- ⭐ Star this repository
- 🐦 Follow [@sudo0xsunil](https://instagram.com/sudo0xsunil)
- 🔄 Share with others

---

## 🔗 Useful Links

- **CloudLinux Official:** https://www.cloudlinux.com/
- **Documentation:** https://docs.cloudlinux.com/
- **Pricing:** https://www.cloudlinux.com/pricing
- **Support:** https://cloudlinux.zendesk.com/

---

## ⚖️ Final Legal Notice

**CloudLinux®** is a **registered trademark** of **Cloud Linux Inc.** This script is NOT created, endorsed, or supported by Cloud Linux Inc. Users MUST obtain valid licenses from Cloud Linux Inc. or authorized vendors. Unauthorized use of CloudLinux without a valid license violates Cloud Linux Inc.'s terms of service. The author disclaims all liability for misuse, license violations, or damages. **USE RESPONSIBLY AND LEGALLY.**

For official CloudLinux: https://www.cloudlinux.com/

---

**Made with ❤️ by [Sunil Kumar (@sudo0xsunil)](https://instagram.com/sudo0xsunil)**

**Remember:** Always use licensed software! 🙏
