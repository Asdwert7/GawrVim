# GawrVim

Персональный конфиг Neovim 0.12 для C/C++, C#, Python, Lua, web, PostgreSQL и Flutter.

Проект находится на ранней стадии: bootstrap lazy.nvim, базовый clangd и CMP работают частично, но архитектура загрузки ещё требует исправления. Полный roadmap — в [`docs/plan-one.md`](docs/plan-one.md).

## Требования

- Neovim 0.12.x
- Git
- Nerd Font для иконок dashboard
- языковые серверы устанавливаются по мере внедрения модулей

## Установка через clone

Сначала сохраните существующий конфиг, если он есть:

```sh
mv ~/.config/nvim ~/.config/nvim.backup
```

Затем:

```sh
git clone <URL_ЭТОГО_РЕПОЗИТОРИЯ> ~/.config/nvim
nvim
```

## Установка через symlink для разработки

```sh
mkdir -p ~/.config
ln -s "/absolute/path/to/GawrVim" ~/.config/nvim
```

Не используйте `ln -sf ... ~/.config/nvim`, если `~/.config/nvim` уже является обычной директорией: команда может создать ссылку **внутри** неё, а не заменить директорию. Сначала переместите старый конфиг:

```sh
mv ~/.config/nvim ~/.config/nvim.backup
ln -s "/absolute/path/to/GawrVim" ~/.config/nvim
```

## Документация

- [`docs/plan-one.md`](docs/plan-one.md) — архитектура и порядок реализации
- [`docs/identity.md`](docs/identity.md) — палитры minimal/Gura/Saba/rice
- [`docs/modules/`](docs/modules/) — документация внедрённых модулей

## Текущее ограничение

Не считайте roadmap списком уже работающих функций. Команды `:GawrPreset`, `:Rice`, DAP, Flutter, web preview и SQL workflow пока запланированы.
