# Maintainer: Cesar <yugurta@gmail.com>
# Contributor: CachyOS Linux Architect Team

pkgname=klivetext
pkgver=1.0.0
pkgrel=1
pkgdesc="Universal Screen OCR & Data Detector for KDE Plasma 6 (macOS Live Text style with actionable phone, email, URL and IBAN entities)"
arch=('any')
url="https://github.com/cesarconte/klivetext"
license=('GPL-3.0-or-later')
depends=(
    'python'
    'spectacle'
    'tesseract'
    'wl-clipboard'
    'imagemagick'
    'qt6-declarative'
    'kirigami'
)
optdepends=(
    'kdeconnect: Send detected phone numbers or text directly to connected mobile devices'
    'dolphin: Context menu integration for images'
)
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/cesarconte/${pkgname}/archive/v${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
    cd "${srcdir}/${pkgname}-${pkgver}" 2>/dev/null || cd "${srcdir}/${pkgname}" 2>/dev/null || cd "${startdir}"

    install -Dm755 bin/klivetext "${pkgdir}/usr/bin/klivetext"

    install -d "${pkgdir}/usr/share/${pkgname}/src/ui"
    cp -r src/* "${pkgdir}/usr/share/${pkgname}/src/"

    install -Dm644 data/klivetext_servicemenu.desktop "${pkgdir}/usr/share/kio/servicemenus/org.cesar.klivetext.desktop"
    install -Dm644 data/org.cesar.klivetext.desktop "${pkgdir}/usr/share/applications/org.cesar.klivetext.desktop"
    install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
}
