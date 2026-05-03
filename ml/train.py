"""
LoL Win Predictor — entrenamiento

Dataset: high_diamond_ranked_10min.csv (Kaggle)
Tarea: dado el estado de la partida en el minuto 10, predecir si gana el equipo azul.

Salidas:
- model.joblib       (modelo serializado, para usar desde Python)
- win_predictor.dart (modelo exportado a Dart, para usar en Flutter)
- feature_names.txt  (orden de las features que el modelo espera)
- metrics.txt        (métricas de evaluación)
"""

from pathlib import Path

import joblib
import m2cgen as m2c
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).parent
CSV = ROOT / "high_diamond_ranked_10min.csv"
OUT_MODEL = ROOT / "model.joblib"
OUT_DART = ROOT / "win_predictor.dart"
OUT_FEATS = ROOT / "feature_names.txt"
OUT_METRICS = ROOT / "metrics.txt"


def main() -> None:
    print("=" * 60)
    print("LoL Win Predictor — Training")
    print("=" * 60)

    # ----------- Load -----------
    df = pd.read_csv(CSV)
    print(f"\nDataset cargado: {df.shape[0]} filas, {df.shape[1]} columnas")
    print(f"Columnas: {list(df.columns)[:5]}... (+{df.shape[1]-5} más)")

    # gameId no es feature
    if "gameId" in df.columns:
        df = df.drop(columns=["gameId"])

    label_col = "blueWins"
    if label_col not in df.columns:
        raise SystemExit(f"No se encontró la columna de label '{label_col}'.")

    y = df[label_col].astype(int)
    X = df.drop(columns=[label_col])

    print(f"\nBalance de clases:")
    print(y.value_counts())
    print(f"  → blueWins=1 representa {y.mean():.1%}")

    # ----------- Split -----------
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"\nTrain: {X_train.shape[0]}  |  Test: {X_test.shape[0]}")

    # ----------- Models -----------
    candidates = {
        "Logistic Regression": Pipeline([
            ("scaler", StandardScaler()),
            ("clf", LogisticRegression(max_iter=1000, random_state=42)),
        ]),
        "Random Forest": RandomForestClassifier(
            n_estimators=200, max_depth=10, random_state=42, n_jobs=-1
        ),
        "Gradient Boosting": GradientBoostingClassifier(
            n_estimators=200, max_depth=4, random_state=42
        ),
    }

    results = {}
    print("\n" + "-" * 60)
    print("Comparando modelos en test set...")
    print("-" * 60)
    for name, model in candidates.items():
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        proba = model.predict_proba(X_test)[:, 1]
        acc = accuracy_score(y_test, preds)
        auc = roc_auc_score(y_test, proba)
        results[name] = (model, acc, auc)
        print(f"{name:22s}  accuracy={acc:.4f}  AUC={auc:.4f}")

    best_name = max(results, key=lambda k: results[k][1])
    best_model, best_acc, best_auc = results[best_name]
    print(f"\n🏆 Mejor modelo (overall): {best_name}  (accuracy={best_acc:.4f})")

    # m2cgen no soporta Gradient Boosting; elegimos el mejor entre los exportables
    EXPORTABLE = {"Logistic Regression", "Random Forest"}
    exportable_results = {k: v for k, v in results.items() if k in EXPORTABLE}
    export_name = max(exportable_results, key=lambda k: exportable_results[k][1])
    export_model, export_acc, export_auc = exportable_results[export_name]
    if export_name != best_name:
        print(
            f"   (Para Flutter usaremos {export_name} acc={export_acc:.4f} "
            f"— m2cgen no soporta {best_name})"
        )

    # ----------- Detailed eval del mejor -----------
    preds = best_model.predict(X_test)
    proba = best_model.predict_proba(X_test)[:, 1]
    cm = confusion_matrix(y_test, preds)
    report = classification_report(y_test, preds, target_names=["Red wins", "Blue wins"])

    print("\nMatriz de confusión:")
    print(f"               Pred Red   Pred Blue")
    print(f"  Real Red     {cm[0,0]:8d}   {cm[0,1]:8d}")
    print(f"  Real Blue    {cm[1,0]:8d}   {cm[1,1]:8d}")
    print(f"\nClassification report:\n{report}")

    # ----------- Feature importance (si aplica) -----------
    importances = None
    if hasattr(best_model, "feature_importances_"):
        importances = best_model.feature_importances_
    elif isinstance(best_model, Pipeline) and hasattr(
        best_model.named_steps.get("clf"), "coef_"
    ):
        importances = np.abs(best_model.named_steps["clf"].coef_[0])

    if importances is not None:
        top = sorted(
            zip(X.columns, importances), key=lambda kv: kv[1], reverse=True
        )[:10]
        print("\nTop 10 features más importantes:")
        for feat, imp in top:
            print(f"  {feat:35s}  {imp:.4f}")

    # ----------- Save -----------
    joblib.dump(best_model, OUT_MODEL)
    print(f"\n✓ Modelo guardado en {OUT_MODEL.name}")

    OUT_FEATS.write_text("\n".join(X.columns), encoding="utf-8")
    print(f"✓ Feature names guardadas en {OUT_FEATS.name}")

    # m2cgen no exporta Pipelines completos — extraemos el modelo final
    if isinstance(export_model, Pipeline):
        export_target = export_model.named_steps["clf"]
        scaler = export_model.named_steps.get("scaler")
        scaler_info = ""
        if scaler is not None:
            mean = ", ".join(f"{x:.6f}" for x in scaler.mean_)
            scale = ", ".join(f"{x:.6f}" for x in scaler.scale_)
            scaler_info = (
                "// Modelo exportado: " + export_name + "\n"
                f"// Accuracy en test: {export_acc:.4f}\n"
                "// IMPORTANTE: antes de llamar a score(x), escalar con:\n"
                f"//   mean  = [{mean}]\n"
                f"//   scale = [{scale}]\n"
                "//   x_scaled[i] = (x[i] - mean[i]) / scale[i]\n\n"
            )
    else:
        export_target = export_model
        scaler_info = (
            "// Modelo exportado: " + export_name + "\n"
            f"// Accuracy en test: {export_acc:.4f}\n"
            "// Las features se pasan crudas (sin escalar).\n\n"
        )

    try:
        dart_code = m2c.export_to_dart(export_target)
        OUT_DART.write_text(scaler_info + dart_code, encoding="utf-8")
        print(f"✓ Modelo exportado a Dart: {OUT_DART.name} ({export_name})")
    except Exception as e:
        print(f"\n⚠ No se pudo exportar a Dart con m2cgen: {e}")

    # ----------- Metrics file -----------
    metrics_text = (
        f"Best model: {best_name}\n"
        f"Accuracy:   {best_acc:.4f}\n"
        f"ROC AUC:    {best_auc:.4f}\n\n"
        f"Confusion matrix:\n"
        f"               Pred Red   Pred Blue\n"
        f"  Real Red     {cm[0,0]:8d}   {cm[0,1]:8d}\n"
        f"  Real Blue    {cm[1,0]:8d}   {cm[1,1]:8d}\n\n"
        f"{report}\n"
    )
    OUT_METRICS.write_text(metrics_text, encoding="utf-8")
    print(f"✓ Métricas guardadas en {OUT_METRICS.name}")

    print("\n" + "=" * 60)
    print("Entrenamiento completo.")
    print("=" * 60)


if __name__ == "__main__":
    main()
