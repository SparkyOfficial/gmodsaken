# GModsaken - Интеграция контента

## Что было сделано:

### 1. Интеграция модели Гордона Фримена
- **Источник**: `[HL1]_Dr._Gordon_Freeman_1712141026_2019-04-14-0019/`
- **Перемещено**:
  - Модели: `content/models/player/gmodsaken/gordon/`
  - Материалы: `content/materials/models/gmodsaken/gordon/`
- **Обновлено**: `gamemode/sh_characters.lua` - изменена модель Гордона Фримена на `models/player/gmodsaken/gordon/dr freeman.mdl`

### 2. Интеграция HEV костюма и материалов
- **Источник**: `content necessary for it to work/Black_Mesa_Gordon_Freeman_1502091022_2018-12-10-0054/`
- **Перемещено**:
  - Материалы: `content/materials/models/gmodsaken/bms/`
  - Модели: `content/models/gmodsaken/bms/`

### 3. Обновление оружия на TF2 модели

#### Топор Мясного (weapon_gmodsaken_axe)
- **Обновлено**: `entities/weapons/weapon_gmodsaken_axe/shared.lua`
- **Обновлено**: `entities/weapons/weapon_gmodsaken_axe/init.lua`
- **Новые модели**:
  - ViewModel: `models/weapons/v_models/v_fireaxe_pyro.mdl`
  - WorldModel: `models/weapons/w_models/w_fireaxe.mdl`

#### КПК Инженера (weapon_gmodsaken_pda)
- **Обновлено**: `entities/weapons/weapon_gmodsaken_pda/shared.lua`
- **Обновлено**: `entities/weapons/weapon_gmodsaken_pda/init.lua`
- **Новые модели**:
  - ViewModel: `models/weapons/v_models/v_pda_engineer.mdl`
  - WorldModel: `models/weapons/w_models/w_pda_engineer.mdl`

### 4. Система загрузки контента
- **Создан**: `gamemode/sh_content.lua` - автоматическая загрузка кастомных моделей
- **Обновлено**: `gamemode/shared.lua` - добавлено включение sh_content.lua
- **Обновлено**: `gamemode/init.lua` - добавлено включение sh_content.lua

## Структура папок после интеграции:

```
content/
├── models/
│   ├── player/
│   │   └── gmodsaken/
│   │       └── gordon/
│   │           ├── dr freeman.mdl
│   │           ├── c_arms_dr_freeman.mdl
│   │           └── [все файлы модели]
│   └── gmodsaken/
│       └── bms/
│           └── [HEV костюм модели]
├── materials/
│   └── models/
│       └── gmodsaken/
│           ├── gordon/
│           │   └── [все материалы Гордона]
│           └── bms/
│               └── [HEV костюм материалы]
└── sound/
    └── gmodsaken/
        └── [музыкальные файлы]
```

## Команды для тестирования:

1. `gmodsaken_test` - проверка инициализации гейммода
2. `gmodsaken_my_character` - показать выбранного персонажа
3. `gmodsaken_list_characters` - список доступных персонажей

## Примечания:

- Все модели и материалы теперь находятся в папке `content/` гейммода
- Оружие использует TF2 модели для лучшего визуального качества
- Система автоматически предзагружает все кастомные модели
- Гордон Фримен теперь использует детализированную модель из аддона

## Следующие шаги:

1. Протестировать загрузку всех моделей
2. Проверить корректность отображения материалов
3. Убедиться, что оружие работает с новыми моделями
4. При необходимости добавить дополнительные материалы или звуки 