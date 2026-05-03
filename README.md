# LoL Stats App

**USFQ - Programación Avanzada en Apps**
Proyecto final - Flutter + Dart

App móvil de estadísticas de League of Legends con tema visual estilo cliente del juego.

---

## Cómo correr el proyecto

```bash
flutter pub get
flutter run
```

> **Nota:** La app funciona en modo MOCK por defecto, sin necesidad de API key.
> Los datos son generados aleatoriamente para demostración.

### Para usar la API real de Riot

1. Obtener una API key en https://developer.riotgames.com
2. Editar `lib/data/api/riot_api_service.dart`:
   ```dart
   static const bool MOCK_MODE = false;
   static const String API_KEY = 'RGAPI-tu-key-aqui';
   ```
3. Implementar las llamadas HTTP reales (los endpoints están comentados en el archivo).

---

## Estructura del proyecto

```
lib/
├── main.dart
├── core/
│   ├── constants/      → Colores, strings, sizes
│   ├── theme/          → Tema dark estilo LoL
│   └── providers/      → Providers globales de Riverpod
├── data/
│   ├── api/            → Riot API service (con mocks)
│   ├── db/             → SQLite (favoritos, recientes)
│   └── models/         → Summoner, Match, Champion
├── features/
│   ├── search/         → Pantalla de búsqueda
│   ├── profile/        → Perfil del invocador
│   ├── match_history/  → Historial de partidas
│   ├── stats/          → Gráficos con fl_chart
│   ├── favorites/      → Lista de favoritos
│   └── ai_recommender/ → Sección de IA (TODO)
└── shared/
    └── widgets/        → MainNavigation
```

---

## Cumplimiento de requisitos del proyecto

| # | Requisito | Implementación |
|---|-----------|---------------|
| 1 | API pública | Riot Games API + datos mock para demostración |
| 2 | Base de datos local | SQLite con `sqflite` (favoritos + búsquedas recientes) |
| 3 | Manejo de estados | Riverpod (`StateNotifier`, `FutureProvider`) |
| 4 | Imágenes + multimedia | `cached_network_image` para CDN de Riot + gráficos `fl_chart` |
| 5 | Diseño atractivo | Tema oscuro con paleta LoL (dorado, cyan, rojo/verde para victoria/derrota) |
| 6 | IA / ML | **Estructura preparada** - implementación pendiente (ver `lib/features/ai_recommender/`) |

---

## Próximo paso: implementar el modelo de IA

La sección de AI Coach ya está estructurada en la app. Lo que falta:

1. **Recolectar datos**: extraer ~5000 partidas de la API de Riot, etiquetadas por rol.
2. **Entrenar modelo**: usar scikit-learn (Python) para entrenar un Random Forest que clasifique el rol jugado a partir de stats (CS/min, daño, visión, KDA).
3. **Exportar a TFLite**: convertir el modelo entrenado a `.tflite`.
4. **Integrar en Flutter**: usar el paquete `tflite_flutter` para correr inferencia en el dispositivo.

El placeholder de la pantalla `AIScreen` ya muestra esta roadmap.

---

## Pantallas

- **Search**: búsqueda por GameName#TAG, búsquedas recientes, ejemplos rápidos.
- **Profile**: ícono, nivel, rangos (Solo/Flex), top 5 campeones por maestría.
- **Match History**: últimas 20 partidas con KDA, CS, oro, daño y visión.
- **Stats**: 3 gráficos con fl_chart - winrate por campeón, KDA en el tiempo, distribución de roles.
- **Favorites**: invocadores guardados localmente (SQLite).
- **AI Coach**: estructura para clasificador de rol, recomendador y predictor de victoria.

---

## Dependencias principales

- `flutter_riverpod` - manejo de estado
- `sqflite` + `path` - base de datos local
- `dio` - cliente HTTP
- `cached_network_image` - cacheo de imágenes
- `fl_chart` - gráficos (barras, líneas, torta)
- `tflite_flutter` (pendiente) - inferencia de modelos ML
