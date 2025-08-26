#!/bin/bash

echo "🧪 Быстрое тестирование EasyNotch"
echo "=================================="

# Проверяем, что мы в правильной директории
if [ ! -d "EasyNotch" ] || [ ! -d "EasyNotch.xcodeproj" ]; then
    echo "❌ Ошибка: Запустите скрипт из директории проекта EasyNotch"
    echo "Текущая директория: $(pwd)"
    echo "Содержимое: $(ls -d */ 2>/dev/null | head -5)"
    exit 1
fi

echo "1️⃣ Проверка MPNowPlayingInfoCenter..."
./test_music.swift

echo ""
echo "2️⃣ Проверка процессов EasyNotch..."
ps aux | grep EasyNotch | grep -v grep

echo ""
echo "3️⃣ Сборка проекта..."
xcodebuild -project EasyNotch.xcodeproj -scheme EasyNotch -configuration Debug build -quiet

if [ $? -eq 0 ]; then
    echo "✅ Проект успешно собран!"
    
    echo ""
    echo "4️⃣ Запуск приложения..."
    open /Users/fedniko/Library/Developer/Xcode/DerivedData/EasyNotch-*/Build/Products/Debug/EasyNotch.app
    
    echo ""
    echo "🎯 Инструкции по тестированию:"
    echo "   - Наведите мышь в верхнюю центральную область экрана"
    echo "   - Запустите Apple Music или Spotify"
    echo "   - Воспроизведите любой трек"
    echo "   - Проверьте, отображается ли информация в Dynamic Island"
    
else
    echo "❌ Ошибка сборки проекта"
    exit 1
fi

echo ""
echo "=================================="
echo "🏁 Тестирование завершено!"
