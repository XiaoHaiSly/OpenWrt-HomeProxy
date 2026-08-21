include $(TOPDIR)/rules.mk

LUCI_TITLE:=The modern ImmortalWrt proxy platform for ARM64/AMD64
LUCI_PKGARCH:=all
LUCI_DEPENDS:= \
	+sing-box \
	+firewall4 \
	+kmod-nft-tproxy \
	+ucode-mod-digest \
	+ucode-mod-math \
	+wget-ssl \
	+curl \
	+unzip

LUCI_EXTRA_DEPENDS:=sing-box (>=1.14.0_alpha1)
PKG_NAME:=luci-app-homeproxy

define Package/luci-app-homeproxy/conffiles
/etc/config/homeproxy
/etc/homeproxy/certs/
/etc/homeproxy/cache/
/etc/homeproxy/custom/
/etc/homeproxy/ruleset/
/etc/homeproxy/resources/direct_list.txt
/etc/homeproxy/resources/proxy_list.txt
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	-sh $(CURDIR)/update-resources.sh
endef

include $(TOPDIR)/feeds/luci/luci.mk
