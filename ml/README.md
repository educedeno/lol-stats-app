# LoL Win Predictor — ML Pipeline

Modelo de clasificación binaria que predice si gana el equipo azul dado el estado
de la partida en el minuto 10.

## Setup

```bash
cd ml
python -m venv .venv
.venv\Scripts\activate           # Windows
pip install -r requirements.txt
```

## Entrenar

```bash
python train.py
```

Salidas:
- `model.joblib` — modelo serializado para Python.
- `win_predictor.dart` — modelo en Dart (para Flutter).
- `feature_names.txt` — orden esperado de las features.
- `metrics.txt` — accuracy, AUC, matriz de confusión.

## Probar

```bash
python predict_test.py
```

Toma 5 partidas al azar del CSV y muestra la predicción vs la realidad.
