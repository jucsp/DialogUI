# 📜 DialogUI Enhanced

> **A beautiful, enhanced fork of the original DialogUI addon**

**DialogUI Enhanced** is an improved fork of the original [DialogUI addon](https://github.com/Jslquintero/DialogUI) that transforms World of Warcraft's quest and gossip dialogs with a stunning parchment-themed interface. This fork adds powerful new features while maintaining the beautiful aesthetic that made the original so popular.

## 🌟 What's New in This Fork

This enhanced version builds upon the original DialogUI foundation and adds:

- **🎯 Movable Windows** - Drag quest and gossip windows anywhere on screen
- **💾 Persistent Positioning** - Window positions are saved between game sessions  
- **⚙️ Advanced Configuration Panel** - Beautiful in-game settings window with:
  - Scale adjustment (0.5x to 2.0x)
  - Transparency control (10% to 100%)
  - Font size scaling (0.5x to 2.0x)
- **🎨 Unified Parchment Theme** - All windows use consistent papiro aesthetic
- **⌨️ ESC Key Support** - Press ESC or Decline to close quest windows properly
- **🖼️ Enhanced Icon System** - Native gossip icons with proper fallback handling

## 📸 Gallery

<div style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;">
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-34-14.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-34-24.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-34-35.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-35-57.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-37-32.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-37-38.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-41-14.png" style="width: 30%; min-width: 200px;" />
  <img src="https://raw.githubusercontent.com/Jslquintero/DialogUI/main/src/preview/Screenshot%20From%202025-06-18%2000-42-06.png" style="width: 30%; min-width: 200px;" />
</div>

## ⚡ Quick Start

1. **Install**: Extract to your `Interface/AddOns/` folder
2. **Enable**: Activate "DialogUI" in your addon list
3. **Configure**: Use `/dialogui` in chat to open settings
4. **Enjoy**: Beautiful, movable quest and gossip windows!

## 🎮 Commands

| Command | Description |
|---------|-------------|
| `/dialogui` | Open configuration window |
| `/resetdialogs` | Reset all window positions |
| `/debugdialogs` | Show debug information |

## 🔧 Compatibility

- ✅ **Vanilla WoW** (1.12.1)
- ✅ **Turtle WoW** (Custom client)
- ✅ **Classic Era** servers
- ⚠️ Designed for English client (Spanish support can be added by editing gossip functions)

## 🎨 Original Inspiration

This addon was inspired by [DialogueUI](https://www.curseforge.com/wow/addons/dialogueui) and uses enhanced Blizzard original code with native icon handling.

## 📋 About This Fork

This is an **enhanced fork** of the original [DialogUI by Jslquintero](https://github.com/Jslquintero/DialogUI). The original author created an excellent foundation for learning WoW addon development. This fork aims to contribute new features and improvements back to the community while maintaining the beautiful parchment aesthetic that makes DialogUI special.

**Original Author**: [Jslquintero](https://github.com/Jslquintero)  
**Fork Maintainer**: [Your GitHub Username]  
**Original Repository**: https://github.com/Jslquintero/DialogUI

## 🐛 Reporting Issues

## 🐛 Reporting Issues

**Before reporting any issue:**
1. Disable all other addons
2. Keep only DialogUI active  
3. Test if the problem persists
4. If it does, please report it!

### How to Report

- **Original DialogUI Issues**: [Original Repository Issues](https://github.com/Jslquintero/DialogUI/issues/new)
- **Enhanced Fork Issues**: [This Fork's Issues](https://github.com/jucsp/DialogUI/issues/new)

Please specify which version you're using and include any error messages or screenshots.

## 🎨 Customization

Feel free to customize the look completely! Every image is in **TGA format** for easy editing.

### 🖼️ Customize Icons
Edit gossip icons at:
```
DialogUI/src/assets/art/icons/GossipIcons.xcf
```

### 🎨 Customize Frame Style  
Edit button styles and frame backgrounds at:
```
DialogUI/src/assets/art/parchment/ParchmentLayout.xcf
```

### 🛠️ How to Edit

1. **Add/Remove Icons**: All gossip icons are individual TGA files in `/src/assets/art/icons/`
2. **Change Frame Background**: Edit the parchment textures and button styles
3. **Export Process**: Use GIMP 3 with [Batcher plugin](https://kamilburda.github.io/batcher/) for quick TGA batch export

**Recommended Tools:**
- **GIMP 3** with [Batcher plugin](https://kamilburda.github.io/batcher/) for batch TGA export
- Any image editor that supports TGA format

**File Format**: All images must be in **Truevision Graphics Adapter (TGA)** format to work properly in WoW.

---

## 🌍 Español

**DialogUI Enhanced** es una versión mejorada del addon original [DialogUI](https://github.com/Jslquintero/DialogUI) que transforma los diálogos de misiones y conversaciones de World of Warcraft con una hermosa interfaz temática de pergamino.

### ✨ Nuevas Funciones

- **Ventanas móviles**: Arrastra las ventanas donde quieras
- **Posiciones persistentes**: Se guardan entre sesiones
- **Panel de configuración avanzado**: Escala, transparencia y tamaño de fuente
- **Soporte para tecla ESC**: Cierra ventanas con ESC o Rechazar
- **Tema unificado**: Todas las ventanas usan el mismo estilo de pergamino

### 🎯 Comandos

- `/dialogui` - Abrir ventana de configuración
- `/resetdialogs` - Reiniciar posiciones de ventanas
- `/debugdialogs` - Mostrar información de debug

### 📝 Nota Importante

El addon está optimizado para cliente en inglés. Para usarlo en español, edita las funciones de gossip en `gossip.frame.lua`.

---

## 📄 License

This enhanced fork maintains the same spirit of learning and sharing as the original DialogUI project.

# ¡Perzonalizar!

Sientete libre de agregar/iconos o cambiar el fondo del panel completamente, cada imagen esta ahora en formato Truevision Graphics Adapter (TGA)

Recomiendo utilizar Gimp 3 con el plugin [Batcher](https://kamilburda.github.io/batcher/) para exportar rápidamente los archivos.

Para cambiar los iconos de los dialogos puedes dirigirte a :

> DialogUI/src/assets/art/icons/GossipIcons.xcf

Para cambiar el estilo de los botones puedes dirigirte a :

> DialogUI/src/assets/art/parchment/ParchmentLayout.xcf
