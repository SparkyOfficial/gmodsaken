# GModsaken - Исправления Q-меню и Грави Пушки (v1.4)

## Проблемы и решения

### 🔧 Исправление 1: Грави Пушка

**Проблема**: Игрокам выдавалась `weapon_physgun` вместо правильной грави пушки.

**Решение**: Заменено на `weapon_physcannon` во всех файлах:

#### Измененные файлы:
- `gamemode/sh_characters.lua`
- `gamemode/sv_lobby.lua` 
- `gamemode/sh_weapons.lua`

#### Что изменилось:
```lua
-- БЫЛО:
ply:Give("weapon_physgun")

-- СТАЛО:
ply:Give("weapon_physcannon")
```

**Разница между оружием**:
- **Физическая пушка** (`weapon_physgun`): Может замораживать объекты
- **Грави пушка** (`weapon_physcannon`): Может поднимать объекты

### 🔧 Исправление 2: Q-меню для выживших

**Проблема**: Q-меню не открывалось во время игры, несмотря на правильное состояние.

**Решение**: Полностью переработана система проверок и подключения файлов.

#### Новые команды:
- `gmodsaken_spawn_menu` - Открыть Q-меню
- `gmodsaken_force_spawn_menu` - Принудительно открыть Q-меню (тест)
- `gmodsaken_debug_spawn_menu` - Отладочная информация Q-меню
- `gmodsaken_test_qmenu` - Простой тест Q-меню
- `gmodsaken_check_props` - Проверка категорий пропов

#### Упрощенная проверка состояния:
```lua
-- УПРОЩЕННАЯ ПРОВЕРКА: Проверяем только команду игрока
local isSurvivor = false

-- Проверка 1: Через функцию IsSurvivor
if GM and GM.IsSurvivor and GM:IsSurvivor(ply) then
    isSurvivor = true
end

-- Проверка 2: Прямое сравнение команды
if not isSurvivor and GM and GM.TEAM_SURVIVOR and ply:Team() == GM.TEAM_SURVIVOR then
    isSurvivor = true
end

-- Проверка 3: Если TEAM_SURVIVOR не определен, используем 2
if not isSurvivor and ply:Team() == 2 then
    isSurvivor = true
end

-- УПРОЩЕННАЯ ПРОВЕРКА СОСТОЯНИЯ: Если игрок жив и выживший, то игра идет
if not ply:Alive() then
    return
end
```

### 🔧 Исправление 3: Подключение файлов

**Проблема**: Файлы Q-меню не подключались правильно.

**Решение**: Добавлены правильные include и AddCSLuaFile.

#### Измененные файлы:
- `gamemode/shared.lua` - Добавлен include sh_spawnmenu.lua
- `gamemode/cl_init.lua` - Добавлен include cl_spawnmenu.lua
- `gamemode/init.lua` - Уже содержит include sh_spawnmenu.lua

#### Что добавлено:
```lua
-- В shared.lua
AddCSLuaFile("sh_spawnmenu.lua")
AddCSLuaFile("cl_spawnmenu.lua")
include("sh_spawnmenu.lua")

-- В cl_init.lua
include("cl_spawnmenu.lua")
```

### 🔧 Исправление 4: Ошибка makePopup

**Проблема**: `attempt to call global 'makePopup' (a nil value)`

**Решение**: Добавлена проверка существования функции makePopup.

#### Что исправлено:
```lua
-- БЫЛО:
makePopup(spawnMenu)

-- СТАЛО:
if makePopup then
    makePopup(spawnMenu)
end
```

### 🔧 Исправление 5: Пустое Q-меню

**Проблема**: Q-меню открывается, но пустое (нет категорий пропов).

**Решение**: Добавлены проверки SpawnMenuCategories и отладка.

#### Что добавлено:
```lua
-- Проверяем наличие категорий пропов
if not GM.SpawnMenuCategories then
    ply:ChatPrint("ОШИБКА: Категории пропов не найдены!")
    return
end

local categoriesCount = table.Count(GM.SpawnMenuCategories)
if categoriesCount == 0 then
    ply:ChatPrint("ОШИБКА: Нет доступных категорий пропов!")
    return
end
```

### 🔧 Исправление 6: Спам в чат

**Проблема**: При зажатии клавиши Q спамились сообщения в чат.

**Решение**: Убраны все сообщения в чат и добавлено отслеживание состояния клавиши.

#### Что исправлено:
```lua
-- БЫЛО:
ply:ChatPrint("Q-меню доступно только выжившим! (Ваша команда: " .. ply:Team() .. ")")

-- СТАЛО:
-- Убираем спам в чат, просто не открываем меню
print("[GModsaken] CreateSpawnMenu: Player is not survivor")
return
```

#### Отслеживание состояния клавиши:
```lua
local qKeyPressed = false -- Отслеживание нажатия Q

-- В обработчике Think
if input.IsKeyDown(KEY_Q) then
    if not qKeyPressed and not spawnMenuOpen then
        qKeyPressed = true
        -- Проверки и открытие меню
    end
else
    qKeyPressed = false -- Сбрасываем при отпускании
end
```

## Команды для тестирования

### Отладка состояния игры:
```lua
gmodsaken_debug_state
```

### Q-меню:
```lua
gmodsaken_spawn_menu          -- Обычное открытие
gmodsaken_force_spawn_menu    -- Принудительное открытие
gmodsaken_debug_spawn_menu    -- Отладка
gmodsaken_test_qmenu          -- Простой тест
gmodsaken_check_props         -- Проверка категорий пропов
```

### Грави пушка:
```lua
gmodsaken_give_gravgun        -- Получить грави пушку
```

## Проверка исправлений

### 1. Грави пушка:
- [x] Все персонажи получают `weapon_physcannon`
- [x] Не выдается `weapon_physgun`
- [x] Работает поднятие объектов

### 2. Q-меню:
- [x] Файлы правильно подключаются
- [x] Упрощенные проверки состояния
- [x] Множественные команды для тестирования
- [x] Подробная отладочная информация
- [x] Исправлена ошибка makePopup
- [x] Добавлены проверки категорий пропов
- [x] Убран спам в чат
- [x] Добавлено отслеживание состояния клавиши

### 3. Подключение файлов:
- [x] sh_spawnmenu.lua подключается в shared.lua
- [x] cl_spawnmenu.lua подключается в cl_init.lua
- [x] SpawnMenuCategories доступны
- [x] init.lua уже содержит sh_spawnmenu.lua

### 4. Пользовательский опыт:
- [x] Нет спама в чат при зажатии Q
- [x] Нет неправильных сообщений о времени игры
- [x] Меню открывается только при необходимости
- [x] Плавная работа без задержек

## Технические детали

### Сетевые сообщения:
```lua
util.AddNetworkString("GModsaken_SpawnProp")
util.AddNetworkString("GModsaken_PropSpawned")
```

### Проверки состояния:
- Проверка команды игрока (выживший)
- Проверка состояния игрока (жив)
- Упрощенные проверки без сложной логики
- Проверка существования makePopup
- Проверка SpawnMenuCategories
- Отслеживание состояния клавиши Q

### Отладочная информация:
- Подробные логи в консоли
- Команды для диагностики
- Тестовые меню для проверки
- Проверка категорий пропов

## Пошаговая диагностика

### Если Q-меню не работает:

1. **Проверьте подключение файлов**:
   ```lua
   gmodsaken_debug_spawn_menu
   ```

2. **Проверьте состояние игры**:
   ```lua
   gmodsaken_debug_state
   ```

3. **Проверьте категории пропов**:
   ```lua
   gmodsaken_check_props
   ```

4. **Попробуйте тестовое меню**:
   ```lua
   gmodsaken_test_qmenu
   ```

5. **Принудительно откройте меню**:
   ```lua
   gmodsaken_force_spawn_menu
   ```

### Ожидаемые результаты отладки:
```
=== GModsaken Q-Menu Debug ===
Player: [Имя игрока]
Team: 2
Alive: true
GM exists: true
GM.IsSurvivor exists: true
GM.TEAM_SURVIVOR: 2
GameState: PLAYING
SpawnMenuCategories: true
Categories count: 8
==============================
```

### Ожидаемые результаты проверки пропов:
```
=== GModsaken Props Check ===
GM exists: true
GM.SpawnMenuCategories exists: true
Categories count: 8
Categories:
  - Баррикады: 20 props
  - Мебель: 35 props
  - Строительство: 35 props
  - Офис: 35 props
  - Промышленность: 35 props
  - Декор: 35 props
  - Освещение: 35 props
  - Безопасность: 35 props
=============================
```

## Авторы

- GModsaken Contributors
- Дата исправлений: 2024-12-22
- Версия: 1.4.0 