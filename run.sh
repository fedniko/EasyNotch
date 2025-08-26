#!/bin/bash

# Скрипт для быстрого запуска EasyNotch

echo "🚀 Запуск EasyNotch..."

# Проверяем, собран ли проект
if [ ! -d "build" ]; then
    echo "📦 Сборка проекта..."
    xcodebuild -project EasyNotch.xcodeproj -scheme EasyNotch -configuration Debug build
fi

# Запускаем приложение
echo "🎵 Запуск приложения..."
open build/Debug/EasyNotch.app

echo "✅ EasyNotch запущен!"
echo "💡 Наведите мышь в верхнюю центральную область экрана для показа Dynamic Island"
echo "🎵 Запустите Apple Music или Spotify для тестирования"
