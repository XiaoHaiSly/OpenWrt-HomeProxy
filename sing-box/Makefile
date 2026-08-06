# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
# reF1nd/sing-box (reF1nd-testing branch) 快照版本
# 上游对应 1.14.0-beta.5,commit 115dbec2cd676e13e9dba7f6e23b932608ace339
PKG_UPSTREAM_VERSION:=1.14.0-beta.5-reF1nd
PKG_VERSION:=1.14.0-beta.5-reF1nd
PKG_RELEASE:=1

# 改为通过 git 拉取 reF1nd 的 fork,而不是官方 SagerNet 的 tar.gz
# 因为 reF1nd-testing 分支持续滚动更新、没有稳定的发布 tar.gz 哈希可核对，
# 这里用具体 commit 锁定版本，保证可复现构建。
PKG_SOURCE_URL:=https://github.com/reF1nd/sing-box.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=115dbec2cd676e13e9dba7f6e23b932608ace339
PKG_SOURCE_DATE:=2026-08-03
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_CPE_ID:=cpe:/a:sagernet:sing-box

PKG_CONFIG_DEPENDS:= \
	CONFIG_SING_BOX_TINY_BUILD_ACME \
	CONFIG_SING_BOX_TINY_BUILD_CLASH_API \
	CONFIG_SING_BOX_TINY_BUILD_DHCP \
	CONFIG_SING_BOX_TINY_BUILD_EMBEDDED_TOR \
	CONFIG_SING_BOX_TINY_BUILD_GRPC \
	CONFIG_SING_BOX_TINY_BUILD_GVISOR \
	CONFIG_SING_BOX_TINY_BUILD_QUIC \
	CONFIG_SING_BOX_TINY_BUILD_TAILSCALE \
	CONFIG_SING_BOX_TINY_BUILD_UTLS \
	CONFIG_SING_BOX_TINY_BUILD_V2RAY_API \
	CONFIG_SING_BOX_TINY_BUILD_WIREGUARD \
	CONFIG_SING_BOX_TINY_BUILD_NAIVE_OUTBOUND \
	CONFIG_SING_BOX_TINY_BUILD_CLOUDFLARED

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

# reF1nd 的 fork 没有改 go.mod 的 module path，仍然是 sagernet/sing-box，
# 所以 GO_PKG / import 路径不需要改。
GO_PKG:=github.com/sagernet/sing-box
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/sing-box
GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_UPSTREAM_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/sing-box/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=The universal proxy platform (reF1nd testing)
  URL:=https://github.com/reF1nd/sing-box
  DEPENDS:=+ca-bundle +kmod-inet-diag
  USERID:=sing-box=5566:sing-box=5566
endef

define Package/sing-box
  $(call Package/sing-box/Default)
  TITLE+= (full version)
  DEPENDS+= +kmod-netlink-diag +kmod-tun
  CONFLICTS:=sing-box-tiny
  VARIANT:=full
  DEFAULT_VARIANT:=1
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform which supports hysteria, SOCKS, Shadowsocks,
  ShadowTLS, Tor, trojan, VLess, VMess, WireGuard and so on.
  This build is based on the reF1nd/sing-box fork (reF1nd-testing branch), which tracks
  upstream sing-box pre-release versions plus extra outbound/inbound features.

  NOTE: The upstream reF1nd fork ships two optional build tags, with_ccm and with_ocm,
  which read local Claude Code / OpenAI Codex OAuth credentials and re-expose them over
  HTTP. This package intentionally does NOT enable those tags.
endef

define Package/sing-box/config
  depends on $(subst @,,$(GO_ARCH_DEPENDS))
endef

define Package/sing-box-tiny
  $(call Package/sing-box/Default)
  TITLE+= (tiny/custom version)
  PROVIDES:=sing-box
  VARIANT:=tiny
endef

Package/sing-box-tiny/description:=$(Package/sing-box/description)

define Package/sing-box-tiny/config
  $(call Package/sing-box/config)

  if PACKAGE_sing-box-tiny
    config SING_BOX_TINY_BUILD_ACME
    bool "Build with ACME TLS certificate issuer support"

    config SING_BOX_TINY_BUILD_CLASH_API
    bool "Build with Clash API support"
    default y

    config SING_BOX_TINY_BUILD_DHCP
    bool "Build with DHCP support"

    config SING_BOX_TINY_BUILD_EMBEDDED_TOR
    bool "Build with embedded Tor support"
    depends on BROKEN

    config SING_BOX_TINY_BUILD_GRPC
    bool "Build with standard gPRC support"
    help
      Standard gRPC has good compatibility but poor performance.

    config SING_BOX_TINY_BUILD_GVISOR
    bool "Build with gVisor support"
    default y if aarch64||arm||i386||x86_64

    config SING_BOX_TINY_BUILD_QUIC
    bool "Build with QUIC support"
    default y
    help
      Required by HTTP3 DNS transports, Naive inbound,
      Hysteria inbound / outbound, and v2ray QUIC transport.

    config SING_BOX_TINY_BUILD_TAILSCALE
    bool "Build with Tailscale support"

    config SING_BOX_TINY_BUILD_UTLS
    bool "Build with uTLS support"
    default y

    config SING_BOX_TINY_BUILD_V2RAY_API
    bool "Build with V2Ray API support"

    config SING_BOX_TINY_BUILD_WIREGUARD
    bool "Build with WireGuard support"
    default y if aarch64||arm||i386||x86_64

    config SING_BOX_TINY_BUILD_NAIVE_OUTBOUND
    bool "Build with NaiveProxy outbound support (reF1nd)"
    default y

    config SING_BOX_TINY_BUILD_CLOUDFLARED
    bool "Build with Cloudflare Tunnel inbound support (reF1nd)"
  endif
endef

# 注意：故意不提供 with_ccm / with_ocm 的开关，理由见上方 description。
ifeq ($(BUILD_VARIANT),full)
  GO_PKG_TAGS:=with_acme,with_clash_api,with_dhcp,with_gvisor,with_quic,with_tailscale,with_utls,with_wireguard,with_naive_outbound,badlinkname,tfogo_checklinkname0
else
  GO_PKG_TAGS:=$(subst $(space),$(comma),$(strip \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_ACME),with_acme) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_CLASH_API),with_clash_api) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_DHCP),with_dhcp) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_EMBEDDED_TOR),with_embedded_tor) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_GRPC),with_grpc) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_GVISOR),with_gvisor) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_QUIC),with_quic) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_TAILSCALE),with_tailscale) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_UTLS),with_utls) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_V2RAY_API),with_v2ray_api) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_WIREGUARD),with_wireguard) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_NAIVE_OUTBOUND),with_naive_outbound) \
	$(if $(CONFIG_SING_BOX_TINY_BUILD_CLOUDFLARED),with_cloudflared) \
	badlinkname tfogo_checklinkname0 \
  ))
endif

define Package/sing-box/conffiles
/etc/config/sing-box
/etc/sing-box/
endef

Package/sing-box-tiny/conffiles=$(Package/sing-box/conffiles)

define Package/sing-box/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/etc/sing-box
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/release/config/config.json $(1)/etc/sing-box

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF) ./files/sing-box.conf $(1)/etc/config/sing-box
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/sing-box.init $(1)/etc/init.d/sing-box
endef

Package/sing-box-tiny/install=$(Package/sing-box/install)

$(eval $(call BuildPackage,sing-box))
$(eval $(call BuildPackage,sing-box-tiny))
