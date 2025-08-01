# Система квестов GModsaken

## Обзор
Система квестов для выживших добавляет дополнительную цель в игру - сбор мусора и активация интерфейсов Combine для получения дополнительного времени.

## Компоненты системы

### 1. Объекты квестов

#### Мусорный бак (TrashDumpster)
- **Модель**: `models/props_junk/trashdumpster02.mdl`
- **Позиция**: `Vector(-512.406738, -1772.493896, -79.968750)`
- **Назначение**: Цель для сдачи мусора
- **Особенности**: Статичный объект, не исчезает во время раунда

#### Мусор (Trash)
- **Модели**: Различные модели мусора из `models/props_junk/`
- **Позиции спавна**: 10 фиксированных точек на карте
- **Назначение**: Собирается игроками и сдается в мусорный бак
- **Награда**: -20 секунд до победы выживших за каждый мусор

#### Интерфейсы Combine (CombineInterface)
- **Модель**: `models/props_combine/combine_interface001.mdl`
- **Позиции спавна**: 3 фиксированные точки (случайный выбор)
- **Назначение**: Активация для получения времени
- **Награда**: -30 секунд до победы выживших
- **Кулдаун**: 90 секунд после использования

### 2. Механики взаимодействия

#### Сбор мусора
1. Игрок подходит к мусору и нажимает E
2. Система проверяет, находится ли игрок рядом с мусорным баком (радиус 200 единиц)
3. Если да - мусор удаляется, уменьшается время до победы выживших, обновляется статистика
4. Если нет - игрок получает уведомление о необходимости подойти к мусорному баку

#### Автоматический сбор
- При физическом контакте мусора с мусорным баком (радиус 100 единиц)
- Мусор автоматически удаляется и уменьшается время до победы выживших
- Награда присваивается ближайшему выжившему

#### Активация интерфейсов
1. Игрок подходит к интерфейсу и нажимает E
2. Система проверяет кулдаун (90 секунд)
3. Если кулдаун истек - интерфейс активируется, уменьшается время до победы выживших
4. Если кулдаун активен - игрок получает уведомление с оставшимся временем

### 3. HUD система

#### Основной HUD квестов
- **Позиция**: Правый верхний угол экрана
- **Отображается**: Только выжившим во время игры
- **Информация**:
  - Количество собранного мусора (0/10)
  - Количество использованных интерфейсов
  - Общее сокращенное время до победы
  - Прогресс-бар выполнения мусорных квестов
  - Подсказки для игроков

#### Подсказки объектов
- **Отображаются**: При приближении к объектам квестов (радиус 300 единиц)
- **Информация**:
  - Тип объекта
  - Инструкции по взаимодействию
  - Статус кулдауна (для интерфейсов)

### 4. Сетевая синхронизация

#### Серверные функции
- `GM:InitializeQuests()` - создание объектов квестов
- `GM:CleanupQuests()` - удаление объектов квестов
- `GM:CollectTrash(trash, player)` - обработка сбора мусора
- `GM:UseCombineInterface(interface, player)` - обработка активации интерфейса

#### Сетевые сообщения
- `GModsaken_UpdateQuestStats` - обновление статистики квестов
- `GModsaken_QuestInteraction` - взаимодействие с объектами квестов

### 5. Команды администратора

#### Управление квестами
- `gmodsaken_force_init_quests` - принудительная инициализация
- `gmodsaken_cleanup_quests` - принудительная очистка
- `gmodsaken_quest_stats` - просмотр статистики

#### Отладка
- `gmodsaken_quest_stats_client` - клиентская статистика

### 6. Интеграция с гейммодом

#### Автоматическая инициализация
- Квесты создаются автоматически при начале раунда
- Задержка 2 секунды для стабилизации

#### Автоматическая очистка
- Квесты удаляются при окончании раунда
- Вызывается хук `GModsaken_GameEnded`

#### Хуки событий
- `GModsaken_GameStarted` - инициализация квестов
- `GModsaken_GameEnded` - очистка квестов

### 7. Координаты объектов

#### Мусорный бак
```
X: -512.406738
Y: -1772.493896
Z: -79.968750
```

#### Точки спавна мусора
1. `Vector(-3682.334229, 2990.098633, 15.012653)`
2. `Vector(-1697.571411, 73.499260, -83.968750)`
3. `Vector(132.388412, 1901.763428, -71.911926)`
4. `Vector(1104.948364, 2495.072510, 32.031250)`
5. `Vector(767.933655, 4239.131348, 32.031250)`
6. `Vector(787.569946, -1721.306030, -79.968750)`
7. `Vector(1613.433716, -423.299652, -79.968750)`
8. `Vector(-2201.997314, -111.184998, -447.968750)`
9. `Vector(-2531.063965, -2112.684326, 320.031250)`
10. `Vector(-3810.473145, 4571.469238, -31.968750)`

#### Точки спавна интерфейсов
1. `Vector(-1689.872314, -932.624512, -79.646790)`
2. `Vector(1451.787476, -805.976807, -79.968750)`
3. `Vector(-3872.618164, 5643.802246, -31.968750)`

### 8. Звуковые эффекты

#### Сбор мусора
- `items/ammo_pickup.wav` - звук успешного сбора

#### Активация интерфейса
- `buttons/button15.wav` - звук активации
- `ambient/machines/steam_release_1.wav` - звук пара (с задержкой 0.5с)

#### Ошибки
- `buttons/button10.wav` - звук ошибки/кулдауна

### 9. Визуальные эффекты

#### Активация интерфейса
- Эффект `cball_explode` в позиции интерфейса

### 10. Статистика

#### Отслеживаемые параметры
- `TrashCollected` - количество собранного мусора
- `InterfacesUsed` - количество использованных интерфейсов
- `TimeAdded` - общее сокращенное время до победы выживших

#### Обновление
- Каждые 5 секунд отправляется обновление всем клиентам
- При каждом взаимодействии с объектами квестов

## Технические детали

### Файлы системы
- `gamemode/sh_quests.lua` - общие функции и данные
- `gamemode/sv_quests.lua` - серверная логика
- `gamemode/cl_quests.lua` - клиентский HUD

### Интеграция
- Включение файлов в `gamemode/init.lua`
- Вызовы в `gamemode/sv_lobby.lua` (StartRound, EndRound)

### Совместимость
- Работает только с выжившими
- Не влияет на убийц
- Автоматически отключается в лобби 