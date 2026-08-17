# Gruggs Mysterious Menagerie (GMM)

## What is this Mysterious Menagerie

GMM is an add-on that provides automatic summoning of companion pets, and the ability to define specific pets depending on your location or current transmog outfit.

The add-on provides more fine-grained control over the pets that are summoned than the built-in favorites system offers.

## Basic Features

- Randomly selects a companion dependent on player location or transmog outfit.
- Automatic summon on companions.
- Customizable chat announcement message when summoning a companion.
- Pet of the day option will continue summoning the same pet, refereshing every 24 hours.
- and more...

## In-Game Usage

Currently, only slash commands are supported, a GUI is comming soon(tm).

The primary slash command is `/gmm` by default this will open the configuration menu.

### Summoning

These can be added to a macro if you wish.

`/gmm summon` - Summons a random companion based on location or outfit.

`/gmm summon dismiss` - Summons or dismisses companion.

### Collection Management

Managing what pets are available and where can be done with the following commands.

`/gmm pet <action> [context] <link>`

Using this you can add/remove pets from a collection.

**Actions:**

| Actions  | Description                      |
| -------- | -------------------------------- |
| `add`    | Adds a pet to the collection     |
| `remove` | Removes pet from collection      |
| `list`   | Prints collection to chat        |
| `clear`  | Removes all pets from colleciton |

**Context (optional):**

| Context          | Description                                |
| ---------------- | ------------------------------------------ |
| `world`, `w`     | Global (default)                           |
| `continent`, `c` | Continent (Outland, Kalimdor, etc.)        |
| `zone`, `z`      | Zone (Westfall, Hellfire Peninsular, etc.) |
| `outfit`, `o`    | Transmog outfit                            |

#### Examples

```text
/gmm pet list                     → Lists global context (default)
/gmm pet list zone                → Lists current zone
/gmm pet list c                   → Lists current continent
/gmm pet add zone [Speedy]        → Adds pet to current zone
/gmm pet add [Speedy]             → Adds pet to global (default)
/gmm pet remove outfit [Speedy]   → Removes pet from outfit scope
```

## Future

- GUI Based management
- Mounts
- Keybindings
-

## Thanks

Inspired by [GupPet](https://www.curseforge.com/wow/addons/guppet)
