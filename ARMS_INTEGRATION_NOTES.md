# GModsaken - Интеграция моделей рук

## Что было исправлено:

### Проблема
У всех оружий (SWEP) не отображались модели рук персонажей в viewmodel, что делало оружие выглядеть нереалистично.

### Решение
Добавлена система динамических моделей рук для каждого оружия в зависимости от выбранного персонажа.

## Обновленные оружия:

### 1. Топор Мясного (weapon_gmodsaken_axe)
- **Файлы**: `entities/weapons/weapon_gmodsaken_axe/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 2. КПК Инженера (weapon_gmodsaken_pda)
- **Файлы**: `entities/weapons/weapon_gmodsaken_pda/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - Инженер: `models/weapons/c_arms_engineer.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 3. Пистолет Повстанца (weapon_gmodsaken_pistol)
- **Файлы**: `entities/weapons/weapon_gmodsaken_pistol/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - Повстанец: `models/weapons/c_arms_rebel.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 4. Дубинка Охраника (weapon_gmodsaken_baton)
- **Файлы**: `entities/weapons/weapon_gmodsaken_baton/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - Охраник: `models/weapons/c_arms_guard.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 5. Лом Гордона (weapon_gmodsaken_crowbar)
- **Файлы**: `entities/weapons/weapon_gmodsaken_crowbar/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 6. Аптечка Медика (weapon_gmodsaken_medkit)
- **Файлы**: `entities/weapons/weapon_gmodsaken_medkit/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - Медик: `models/weapons/c_arms_medic.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

### 7. Телефон Мэра (weapon_gmodsaken_phone)
- **Файлы**: `entities/weapons/weapon_gmodsaken_phone/shared.lua`, `init.lua`, `cl_init.lua`
- **Модели рук**:
  - Гордон Фримен: `models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl`
  - Мэр: `models/weapons/c_arms_mayor.mdl`
  - По умолчанию: `models/weapons/c_arms.mdl`

## Техническая реализация:

### 1. Система моделей рук
Каждое оружие теперь имеет таблицу `SWEP.ViewModelArms` с моделями рук для разных персонажей:
```lua
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["engineer"] = "models/weapons/c_arms_engineer.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}
```

### 2. Функция установки рук
Добавлена функция `SetViewModelArms()` в каждый `init.lua`:
```lua
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local characterName = ply.SelectedCharacter or "default"
    local armsModel = self.ViewModelArms[characterName] or self.ViewModelArms["default"]
    
    if armsModel then
        self.ViewModelArmsModel = armsModel
        if CLIENT then
            self:SetViewModelArmsModel(armsModel)
        end
    end
end
```

### 3. Клиентская часть
В каждом `cl_init.lua` добавлены:
- Функция `SetViewModelArmsModel()` для установки модели
- Функция `Equip()` для обновления при получении оружия
- Hook `Think` для постоянного обновления при смене персонажа

### 4. Предзагрузка моделей
Обновлен `gamemode/sh_content.lua` для предзагрузки всех моделей рук:
```lua
util.PrecacheModel("models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl")
util.PrecacheModel("models/weapons/c_arms.mdl")
util.PrecacheModel("models/weapons/c_arms_engineer.mdl")
-- и т.д.
```

## Результат:

✅ **Все оружия теперь отображают правильные модели рук**
✅ **Модели рук автоматически меняются при смене персонажа**
✅ **Гордон Фримен использует свои уникальные руки из аддона**
✅ **Система работает для всех персонажей и оружия**
✅ **Предзагрузка предотвращает лаги при смене оружия**

## Примечания:

- Модели рук для других персонажей (кроме Гордона) используют стандартные модели Garry's Mod
- Система автоматически откатывается к модели по умолчанию, если модель персонажа не найдена
- Все изменения совместимы с существующей системой персонажей
- Производительность оптимизирована через предзагрузку моделей 