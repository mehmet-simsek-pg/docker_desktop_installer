# Docker Desktop Cross-Platform Installer

Bu repo, **macOS** ve **Windows** üzerinde Docker Desktop kurulumunu kolaylaştırmak için hazırlanmış basit komut dosyaları içerir.

- macOS için: `bash` betiği
- Windows için: `.bat` (batch) betiği
- Her iki tarafta da:
    - Docker Desktop kurulu mu kontrol edilir
    - Gerekli paket yöneticileri kontrol edilir / kurulum yönlendirilir
    - Kurulum sonrası Docker daemon ayağa kalktı mı test edilir
    - `docker --version` ile sonuç doğrulanır

---

## Klasör Yapısı

```text
docker-desktop-installer/
├─ README.md
├─ mac/
│  └─ install-docker-desktop-mac.sh
└─ windows/
   └─ install-docker-desktop-windows.bat
