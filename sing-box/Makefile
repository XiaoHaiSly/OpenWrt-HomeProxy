# SPDX-License-Identifier: GPL-3.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.14.0_beta8
PKG_RELEASE:=1
PKG_SOURCE_VERSION:=1.14.0-beta.8-reF1nd

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/reF1nd/sing-box/tar.gz/v$(PKG_SOURCE_VERSION)?
PKG_HASH:=1e8deada998853a42b8a02bbdeb52442175ab58332550fad205ac3282242de94
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
USERID:=sing-box=5566:sing-box=5566

PKG_CONFIG_DEPENDS:= \
	CONFIG_SING_BOX_BUILD_ACME \
	CONFIG_SING_BOX_BUILD_CLASH_API \
	CONFIG_SING_BOX_BUILD_DHCP \
	CONFIG_SING_BOX_BUILD_GRPC \
	CONFIG_SING_BOX_BUILD_GVISOR \
	CONFIG_SING_BOX_BUILD_QUIC \
	CONFIG_SING_BOX_BUILD_SNELL \
	CONFIG_SING_BOX_BUILD_TAILSCALE \
	CONFIG_SING_BOX_BUILD_UTLS \
	CONFIG_SING_BOX_BUILD_WIREGUARD

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/sagernet/sing-box
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/sing-box
GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/sing-box
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=The universal proxy platform
  URL:=https://sing-box.sagernet.org/
  DEPENDS:=$(GO_ARCH_DEPENDS) \
	+ca-bundle \
	+kmod-inet-diag \
	+kmod-netlink-diag \
	$(if $(CONFIG_SING_BOX_BUILD_GVISOR),+kmod-tun)
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform supporting various protocols.
endef

define Package/sing-box/conffiles
/etc/config/sing-box
/etc/sing-box/
endef

define Package/sing-box/config
  if PACKAGE_sing-box
	config SING_BOX_BUILD_ACME
		bool "Build with ACME support"
		default y

	config SING_BOX_BUILD_CLASH_API
		bool "Build with Clash API support"
		default y

	config SING_BOX_BUILD_DHCP
		bool "Build with DHCP support"
		default y

	config SING_BOX_BUILD_GRPC
		bool "Build with gPRC support"
		default n

	config SING_BOX_BUILD_GVISOR
		bool "Build with gVisor support"
		default y

	config SING_BOX_BUILD_QUIC
		bool "Build with QUIC support"
		default y

	config SING_BOX_BUILD_SNELL
		bool "Build with Snell support"
		default y

	config SING_BOX_BUILD_TAILSCALE
		bool "Build with Tailscale support"
		default y

	config SING_BOX_BUILD_UTLS
		bool "Build with uTLS support"
		default y

	config SING_BOX_BUILD_WIREGUARD
		bool "Build with WireGuard support"
		default y
  endif
endef

GO_PKG_TAGS:=$(strip \
	$(if $(CONFIG_SING_BOX_BUILD_ACME),with_acme) \
	$(if $(CONFIG_SING_BOX_BUILD_CLASH_API),with_clash_api) \
	$(if $(CONFIG_SING_BOX_BUILD_DHCP),with_dhcp) \
	$(if $(CONFIG_SING_BOX_BUILD_GRPC),with_grpc) \
	$(if $(CONFIG_SING_BOX_BUILD_GVISOR),with_gvisor) \
	$(if $(CONFIG_SING_BOX_BUILD_QUIC),with_quic) \
	$(if $(CONFIG_SING_BOX_BUILD_SNELL),with_snell) \
	$(if $(CONFIG_SING_BOX_BUILD_TAILSCALE),with_tailscale) \
	$(if $(CONFIG_SING_BOX_BUILD_UTLS),with_utls) \
	$(if $(CONFIG_SING_BOX_BUILD_WIREGUARD),with_wireguard) \
)

GO_PKG_TAGS:=$(subst $(space),$(comma),$(GO_PKG_TAGS))

define Build/Compile
	$(call GoPackage/Build/Compile)
endef

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/sing-box $(1)/usr/bin/sing-box

	$(INSTALL_DIR) $(1)/etc/sing-box
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/release/config/config.json $(1)/etc/sing-box

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF) ./files/sing-box.conf $(1)/etc/config/sing-box
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/sing-box.init $(1)/etc/init.d/sing-box
endef

$(eval $(call BuildPackage,sing-box))
