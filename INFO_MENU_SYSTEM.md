# GModsaken - Система Информационного Меню (F3)

## Обзор

Система информационного меню предоставляет игрокам удобный доступ к новостям, советам, статистике и полезным командам через нажатие клавиши F3.

## Функции

### 📰 Новости
- Отображение последних обновлений игры
- Категоризация новостей (features, fixes)
- Красивые карточки с датами и описаниями

### 💡 Советы
- Полезные советы по игре
- Информация о способностях персонажей
- Стратегии для выживших и убийц

### 📊 Статистика
- Текущее состояние игры
- Информация о командах и игроках
- Персональная статистика игрока

### ⌨️ Команды
- Список полезных команд
- Описания функций
- Быстрый доступ к отладочным командам

## Управление

### Открытие меню
- **F3** - Основная клавиша для открытия меню
- **gmodsaken_info_menu** - Консольная команда

### Навигация
- Вкладки для переключения между разделами
- Прокрутка в каждом разделе
- Закрытие через крестик или ESC

## Структура файлов

```
gamemode/
├── cl_info_menu.lua          # Основной файл меню
└── cl_init.lua               # Подключение файла
```

## Конфигурация

### Новости
Новости хранятся в массиве `GameNews`:
```lua
local GameNews = {
    {
        date = "2024-12-22",
        title = "🎉 Заголовок новости",
        content = "Описание новости",
        type = "feature" -- feature, fix, update
    }
}
```

### Советы
Советы хранятся в массиве `GameTips`:
```lua
local GameTips = {
    "💡 Совет по игре",
    "💡 Еще один совет"
}
```

## Команды

### Для игроков
- `gmodsaken_info_menu` - Открыть информационное меню

### Отладочные команды
- `gmodsaken_debug_state` - Показать состояние игры
- `gmodsaken_give_gravgun` - Получить грави пушку
- `gmodsaken_test_disintegration` - Тест эффектов
- `gmodsaken_music_volume 0.5` - Громкость музыки
- `gmodsaken_music_toggle` - Включить/выключить музыку

## Визуальный дизайн

### Цветовая схема
- **Фон меню**: Темно-серый с прозрачностью
- **Карточки новостей**: Зеленые (features), красные (fixes)
- **Текст**: Белый с различными оттенками
- **Акценты**: Голубой для команд

### Иконки
- 📰 Новости
- 💡 Советы  
- 📊 Статистика
- ⌨️ Команды
- 🎮 Состояние игры
- 👥 Команды

## Интеграция

### С другими системами
- Автоматическое обновление статистики
- Интеграция с системой персонажей
- Связь с системой команд
- Отображение состояния игры

### Обновления
- Легкое добавление новых новостей
- Простое редактирование советов
- Расширяемая система команд

## Технические детали

### Производительность
- Меню создается только при открытии
- Автоматическая очистка при закрытии
- Оптимизированная отрисовка

### Совместимость
- Работает с существующими системами
- Не конфликтует с другими меню
- Поддержка всех разрешений

## Планы развития

### Будущие функции
- [ ] Система достижений
- [ ] Статистика по раундам
- [ ] Интеграция с веб-API
- [ ] Многоязычная поддержка
- [ ] Настройки интерфейса

### Улучшения
- [ ] Анимации открытия/закрытия
- [ ] Звуковые эффекты
- [ ] Кастомизация тем
- [ ] Экспорт статистики

## Поддержка

### Отладка
```lua
-- Проверка загрузки меню
print("[GModsaken] cl_info_menu.lua loaded")

-- Отладка состояния
concommand.Add("gmodsaken_debug_info_menu", function()
    print("Info menu state:", infoMenuOpen)
    print("Menu valid:", IsValid(infoMenu))
end)
```

### Известные проблемы
- Нет известных проблем

## Авторы

- GModsaken Contributors
- Дата создания: 2024-12-22
- Версия: 1.0.0 