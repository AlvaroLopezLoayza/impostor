# 🕵️ Impostor — El Juego de las Palabras Secretas

Un juego de fiesta para móvil construido en Flutter. Los jugadores reciben una palabra secreta de una categoría común, pero uno (o más) son **impostores** que no saben la palabra real — o reciben una diferente.

---

## 🎮 Cómo jugar

1. **Configura** el número de jugadores e impostores
2. **Pasa el teléfono** a cada jugador para que vea su palabra en privado
3. Todos **discuten** la palabra sin decirla directamente
4. **Votan** para eliminar al sospechoso
5. ¡Gana el equipo si atrapa al impostor — o el impostor si escapa!

---

## 🗂️ Cómo cambiar las categorías en GitHub

Las palabras del juego viven en:

```
https://raw.githubusercontent.com/AlvaroLopezLoayza/impostor/main/assets/categories.json
```

Para agregar nuevas categorías o palabras:

1. Ve a [`assets/categories.json`](assets/categories.json) en este repositorio
2. Haz clic en el ícono de lápiz (editar)
3. Añade tu categoría siguiendo el formato:

```json
{
  "nombre": "Nombre de la categoría",
  "palabras": [
    {
      "base": "palabra principal",
      "sinonimos": ["sinónimo 1", "sinónimo 2", "sinónimo 3"]
    }
  ]
}
```

4. Confirma el commit — la app usará el JSON actualizado en la próxima sesión de juego (el caché se renueva cada 24 horas, o al tocar "Actualizar palabras").

### ⚠️ Reglas del JSON

- Cada categoría necesita **mínimo 2 palabras**
- Los sinónimos se usan como **pista del impostor** en modo "diferente palabra"  
- Si no hay sinónimos, se usa otra palabra base como decoy
- El JSON malformado mostrará un error amigable en la app

---

## 🏗️ Arquitectura

```
lib/
├── core/
│   ├── constants/     # URLs, TTL del caché, defaults
│   ├── errors/        # Failures tipados (Remote, Cache, Parse, Game)
│   ├── network/       # Dio client
│   ├── router/        # go_router (7 rutas)
│   └── theme/         # Material 3 dark theme + Google Fonts Outfit
├── data/
│   ├── models/        # Freezed + json_serializable
│   ├── datasources/
│   │   ├── remote/    # GitHub raw URL (Dio + retry)
│   │   └── local/     # SharedPreferences (TTL 24h)
│   └── repositories/  # Remote → Cache → Expired cache fallback
├── domain/
│   ├── entities/      # Category, Word, GameSession, PlayerCard
│   ├── repositories/  # Interfaz abstracta
│   └── usecases/      # BuildGameUseCase (lógica de asignación de palabras)
└── presentation/
    ├── providers/     # Riverpod (CategoriesNotifier + GameNotifier)
    └── screens/       # 7 pantallas del flujo del juego
```

---

## ⚙️ Stack técnico

| Tecnología | Uso |
|-----------|-----|
| Flutter 3.x + Dart 3 | Framework principal |
| Riverpod v2 | Estado global |
| Dio | HTTP con retry |
| SharedPreferences | Caché local (TTL 24h) |
| go_router | Navegación declarativa |
| Freezed + json_serializable | Modelos inmutables |
| Google Fonts (Outfit) | Tipografía |
| mocktail | Mocks en tests |

---

## 🚀 Cómo correr el proyecto

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 🧪 Tests

```bash
flutter test
```

Cubre:
- Parsing del JSON (incluyendo casos edge)
- Repositorio (remote → cache → fallback)
- Lógica de asignación de palabras (todos los normales reciben la MISMA palabra)

---

## 📝 Lógica de palabras

> **Todos los jugadores normales reciben exactamente la misma palabra base.**  
> El impostor recibe `null` (modo: sin pista) o una palabra diferente de la categoría (modo: con pista).

Esta decisión asegura que la discusión gire alrededor de una palabra conocida por todos los inocentes, haciendo que el impostor deba adivinar o improvisar.
