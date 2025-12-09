#!/usr/bin/env bash
set -euo pipefail

### Yardımcı fonksiyonlar ###
log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

### 1. Platform kontrolü ###
if [[ "$(uname)" != "Darwin" ]]; then
  err "Bu betik yalnızca macOS üzerinde çalıştırılabilir."
  exit 1
fi

MACOS_VERSION_RAW=$(sw_vers -productVersion || echo "0.0.0")
MACOS_MAJOR=$(echo "$MACOS_VERSION_RAW" | cut -d. -f1)
MACOS_MINOR=$(echo "$MACOS_VERSION_RAW" | cut -d. -f2)

log "macOS sürümü: $MACOS_VERSION_RAW"

# Buradaki minimum sürümü istersen değiştir (örn. 11 = Big Sur, 12 = Monterey)
MIN_MAJOR=11

if (( MACOS_MAJOR < MIN_MAJOR )); then
  warn "macOS sürümünüz ($MACOS_VERSION_RAW) Docker Desktop için çok eski olabilir."
  warn "Yine de devam ediyorum, ama kurulum başarısız olabilir."
fi

ARCH=$(uname -m)
log "Mimari: $ARCH"

### 2. Docker zaten kurulu mu? ###
check_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

check_docker_app() {
  if [[ -d "/Applications/Docker.app" ]]; then
    return 0
  else
    return 1
  fi
}

if check_docker_cli && check_docker_app; then
  log "Docker Desktop zaten kurulu görünüyor."
else
  log "Docker Desktop kurulu değil, kurulum başlatılıyor..."
fi

### 3. Homebrew kontrol / kurulum ###
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew yüklü değil. Kurulum başlatılıyor..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Apple Silicon’da brew /opt/homebrew altına kurulur, path’e ekleyelim
  if [[ "$ARCH" == "arm64" ]] && [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log "Homebrew kurulumu tamamlandı."
else
  log "Homebrew zaten yüklü."
fi

# Her ihtimale karşı brew ortamını yükle
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v /usr/local/bin/brew >/dev/null 2>&1; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

### 4. Docker Desktop kurulum ###
if ! check_docker_app; then
  log "Docker Desktop cask kuruluyor (brew install --cask docker)..."
  brew update
  brew install --cask docker
else
  log "/Applications/Docker.app zaten mevcut, brew ile tekrar kurulmuyor."
fi

### 5. Docker Desktop başlatma ###
log "Docker Desktop başlatılıyor..."
open -g -a Docker || warn "Docker.app açılamadı, elle başlatmanız gerekebilir."

### 6. Docker daemon hazır mı testi ###
log "Docker servisinin hazır hale gelmesi bekleniyor (en fazla 3 dakika)..."

MAX_SECONDS=180
SLEEP_INTERVAL=5
ELAPSED=0
READY=0

while (( ELAPSED < MAX_SECONDS )); do
  if check_docker_cli; then
    if docker info >/dev/null 2>&1; then
      READY=1
      break
    fi
  fi
  sleep "$SLEEP_INTERVAL"
  ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
done

if (( READY == 1 )); then
  log "Docker daemon çalışıyor."
else
  warn "Docker daemon hazır görünmüyor. Docker Desktop'ı açıp oturumunuz için lisans onayı vs. vermeniz gerekebilir."
fi

### 7. Kurulum testi ###
log "Kurulum testi: docker --version"

if check_docker_cli; then
  docker --version || warn "docker komutu çalıştırılamadı."
else
  err "docker komutu bulunamadı. Kurulum başarısız ya da PATH'e eklenmemiş olabilir."
  exit 1
fi

log "Test için 'docker run hello-world' komutu ile bir konteyner çalıştırabilirsiniz."
log "Kurulum betiği tamamlandı."
