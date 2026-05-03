# LoL Stats App

App de estadísticas de League of Legends construida en Flutter, con un modelo
de Machine Learning que predice el resultado de las partidas usando el estado
del minuto 10.

Proyecto de **Programación Avanzada en Apps — USFQ**.

## ¿Qué hace?

- 🔍 **Buscar invocadores** por Riot ID (`Nombre#TAG`) usando la Riot API.
- 📊 **Ver estadísticas**: nivel, ranked, historial de partidas, mastery de campeones.
- ⭐ **Guardar favoritos** y búsquedas recientes (sincronizado en Firebase Firestore).
- 🤖 **Win Predictor (ML)**: descarga las últimas 5 partidas y predice si el jugador
  iba a ganar basándose en el estado del minuto 10. Compara la predicción con el
  resultado real y muestra cuántas acertó.

El modelo es un **Random Forest** entrenado con scikit-learn sobre el dataset
público *High Diamond Ranked Games (10 min)* de Kaggle, y exportado a Dart con
m2cgen para que corra dentro de la app sin servidores.

## Plataformas

Funciona en **Windows desktop**, **Web** y **Android** (la web tiene limitación
de CORS para llamadas a la Riot API, así que la experiencia recomendada es
Windows).

## Cómo correrla

### Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.10+
- API Key de Riot — sacar en [developer.riotgames.com](https://developer.riotgames.com)
  (caduca cada 24h)

### Pasos

1. Clona el repo:
   ```bash
   git clone https://github.com/educedeno/lol-stats-app.git
   cd lol-stats-app
   ```

2. Instala dependencias:
   ```bash
   flutter pub get
   ```

3. Crea tu archivo `run.bat` copiando la plantilla:
   ```bash
   copy run.bat.example run.bat
   ```
   Y abre `run.bat` para reemplazar `RGAPI-tu-key-aqui` por tu API key real.

4. Ejecuta la app:
   ```bash
   .\run.bat
   ```

## Pipeline de ML (opcional)

Si quieres re-entrenar el modelo desde cero, todo está en la carpeta `ml/`.
Ver [`ml/README.md`](ml/README.md) para los pasos.

## Stack

- **Flutter** + **Riverpod** (state management)
- **Dio** (HTTP client)
- **Firebase Firestore** (almacenamiento)
- **scikit-learn** + **m2cgen** (modelo ML)
- **Riot Games API** + **Data Dragon** (datos de LoL)
