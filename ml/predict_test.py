"""
Test rápido del modelo entrenado.
Uso: python predict_test.py
"""

from pathlib import Path

import joblib
import pandas as pd

ROOT = Path(__file__).parent
MODEL = ROOT / "model.joblib"
CSV = ROOT / "high_diamond_ranked_10min.csv"


def main() -> None:
    model = joblib.load(MODEL)
    df = pd.read_csv(CSV)
    if "gameId" in df.columns:
        df = df.drop(columns=["gameId"])
    X = df.drop(columns=["blueWins"])

    # Tomamos 5 filas al azar y predecimos
    sample = X.sample(5, random_state=7)
    real = df.loc[sample.index, "blueWins"].values
    proba = model.predict_proba(sample)[:, 1]
    pred = model.predict(sample)

    print("Probabilidad de que gane el equipo azul:\n")
    for i, idx in enumerate(sample.index):
        print(
            f"  Partida #{idx:5d}  "
            f"pred={'BLUE' if pred[i]==1 else 'RED ':4s}  "
            f"real={'BLUE' if real[i]==1 else 'RED ':4s}  "
            f"proba_blue={proba[i]:.1%}  "
            f"{'✓' if pred[i]==real[i] else '✗'}"
        )


if __name__ == "__main__":
    main()
