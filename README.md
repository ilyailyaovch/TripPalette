# TripPalette

iOS-приложение для планирования путешествий с календарём периодов.

## Требования

- macOS + Xcode
- [Tuist](https://tuist.dev) `4.200.5` (зафиксирован в `mise.toml`)
- симулятор или устройство с iOS 26+

## Запуск через Tuist

### 1. Установить Tuist

Через [mise](https://mise.jdx.dev) (предпочтительно):

```bash
brew install mise
mise install
```

Или напрямую:

```bash
brew tap tuist/tuist
brew install tuist
```

Проверка:

```bash
tuist version
```

### 2. Сгенерировать проект

Из корня репозитория:

```bash
tuist install
tuist generate
```

- `tuist install` — подтянет SPM-зависимости  
- `tuist generate` — создаст `TripPalette.xcworkspace` / `.xcodeproj` (они в `.gitignore`, локально их нужно генерировать)

Открыть сразу в Xcode:

```bash
tuist generate --open
```

### 3. Собрать и запустить

В Xcode выбери схему **TripPalette** и Run (`⌘R`).

Или из терминала:

```bash
tuist build
tuist run
```

## Полезные команды

```bash
tuist generate --open   # перегенерировать и открыть
tuist clean             # очистить кэш Tuist
tuist edit              # править манифесты Project.swift в Xcode
```

После изменений в `Project.swift` или `Tuist/` снова выполни `tuist generate`.
