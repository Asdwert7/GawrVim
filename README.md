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

## Кастомные команды
мой конфиг по умолчанию направлен на моментальную работу с файлами в независимости от типа
Поэтому вот несколько команд на включение модулей 
C++ Примеры:
  `:Gawrcpp lsp dbb cmp`   включить
  `:Gawrcpp -dbb`          выключить один флаг
  `:Gawrcpp all / off`     всё сразу
  `:Gawrcpp`               посмотреть статус
  `:Gawrcpp! lsp`          включить и запомнить на следующие запуски
  `:GawrStatus`            статус всех языков

кроме lua все отсальное по аналогии с приставкой `gawr` и окончанием например `py` или `cs`
## GawrSettings: языковые режимы

Тяжёлые возможности **выключены по умолчанию** и включаются командами вида `Gawr<язык>`:
`:Gawrcpp` (C/C++), `:Gawrcs` (C#), `:Gawrpy` (Python), `:Gawrlua` (Lua), `:Gawrall` (все языки сразу).
Набирать можно строчными (`gawrcpp`) — в начале командной строки это превращается в `Gawrcpp`.

| Флаг | Что включает | cpp | cs | py | lua |
|---|---|:-:|:-:|:-:|:-:|
| `lsp` | LSP-сервер + подсветка (treesitter) | ✓ | ✓ | ✓ | ✓ |
| `dbb` | отладчик (nvim-dap + окна dap-ui) | ✓ | ✓ | ✓ | — |
| `cmp` | автодополнение + автоформат при сохранении | ✓ | ✓ | ✓ | — |
| `tidy` | clang-tidy внутри clangd | ✓ | — | — | — |

```
:Gawrcpp lsp dbb cmp        включить флаги
:Gawrcpp -dbb               выключить флаг
:Gawrcpp all                включить lsp, dbb, cmp (tidy — только явно)
:Gawrcpp off                выключить всё
:Gawrcpp                    показать статус
:Gawrcpp set default lsp cmp   включить и запомнить как дефолт этого языка
:Gawrcpp reset default      выключить всё и забыть сохранённый дефолт
:Gawrall set default lsp    то же для всех языков
:GawrStatus                 статус всех языков
:GawrInstall                поставить серверы, отладчики и форматтеры через Mason
```

`:Gawrall` пропускает флаги, которых у языка нет (например `dbb` и `cmp` у Lua), и в конце
выводит одно пояснение: «Некоторые языки не поддерживают флаги […]».
Дефолты хранятся в `~/.local/state/nvim/gawrsettings.json`. Первый раз на новой машине:
`:GawrInstall`, затем например `:Gawrall set default lsp cmp`.

### Отладчик (флаг `dbb`)

- **Клик мышью** по полю слева от текста (номера строк / знаки) — красная точка-брейкпоинт, повторный клик снимает.
- Команда `:Dbb <слово>` (подойдёт и `dbb`, и `bdd`):

| Слово | Действие |
|---|---|
| `br` | поставить/снять брейкпоинт на текущей строке |
| `n`, `next` | далее (continue); без активной сессии — запуск отладки |
| `nn`, `nextnext` | шаг через (step over) |
| `ni`, `nextinner` | шаг внутрь (step into) |
| `out` | шаг наружу |
| `stop` | остановить отладку |
| `ui` | показать/скрыть окна отладчика |

Клавиши (только пока включён `dbb`):

| Клавиша | Действие | Эквивалент |
|---|---|---|
| `F5` / `<leader>dc` | далее | `:Dbb n` |
| `F9` / `<leader>db` | брейкпоинт | `:Dbb br` |
| `F10` / `<leader>do` | шаг через | `:Dbb nn` |
| `F11` / `<leader>di` | шаг внутрь | `:Dbb ni` |
| `F12` / `<leader>dO` | шаг наружу | `:Dbb out` |
| `<leader>dx` | остановить | `:Dbb stop` |
| `<leader>du` | окна отладчика | `:Dbb ui` |

На Mac F-клавиши могут требовать `fn` — тогда пользуйтесь `<leader>d…`, `:Dbb` или кликом по полю.

### Все команды

`Gawrcpp`, `Gawrcs`, `Gawrpy`, `Gawrlua`, `Gawrall`, `GawrStatus`, `GawrInstall`, `Dbb` (`Bdd`).

## Документация

- [`docs/plan-one.md`](docs/plan-one.md) — архитектура и порядок реализации
- [`docs/identity.md`](docs/identity.md) — палитры minimal/Gura/Saba/rice
- [`docs/modules/`](docs/modules/) — документация внедрённых модулей

## Текущее ограничение

Не считайте roadmap списком уже работающих функций. Команды `:GawrPreset`, `:Rice`, DAP, Flutter, web preview и SQL workflow пока запланированы.
