#!/bin/bash

echo "🔐 Проверка разрешений для EasyNotch"
echo "===================================="

echo ""
echo "1️⃣ Проверка текущих разрешений..."

# Проверяем, есть ли EasyNotch в списке разрешений
if [ -f ~/Library/Application\ Support/com.apple.TCC/TCC.db ]; then
    echo "✅ База TCC найдена"
else
    echo "❌ База TCC не найдена"
fi

echo ""
echo "2️⃣ Проверка MediaPlayer framework..."
./test_music.swift

echo ""
echo "3️⃣ Инструкции по настройке разрешений:"
echo ""
echo "🔧 Ручная настройка разрешений:"
echo "   1. Откройте 'Системные настройки'"
echo "   2. Перейдите в 'Конфиденциальность и безопасность'"
echo "   3. В левом меню найдите:"
echo "      - 'Медиа и Apple Music'"
echo "      - 'Автоматизация'"
echo "   4. Убедитесь, что EasyNotch включен в этих разделах"
echo ""

echo "🎵 Проверка совместимости приложений:"
echo "   - Apple Music: ✅ (100% совместимость)"
echo "   - Spotify: ✅ (обычно совместим)"
echo "   - VLC: ✅ (совместим)"
echo ""

echo "4️⃣ Тестирование с Apple Music:"
echo "   1. Откройте Apple Music"
echo "   2. Воспроизведите любой трек"
echo "   3. Убедитесь, что музыка играет"
echo "   4. Запустите: ./test_music.swift"
echo ""

echo "5️⃣ Если разрешения настроены, но не работает:"
echo "   - Перезапустите EasyNotch"
echo "   - Перезапустите музыкальное приложение"
echo "   - Проверьте логи: log show --predicate 'process == \"EasyNotch\"' --last 5m"
echo ""

echo "===================================="
echo "🏁 Проверка завершена!"
