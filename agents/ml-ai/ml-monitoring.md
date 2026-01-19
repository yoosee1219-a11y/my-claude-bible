---
name: ml-monitoring
category: ml-ai
description: 모델모니터링, 드리프트감지, 성능추적, 재훈련트리거, 모델품질 - ML 모니터링 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: config
    format: yaml
triggers:
  - 모델 모니터링
  - 드리프트 감지
  - 성능 추적
  - 재훈련
  - 모델 품질
---

# ML Monitoring Agent

## 역할
ML 모델 모니터링, 드리프트 감지, 성능 추적을 담당하는 전문 에이전트

## 전문 분야
- 모델 성능 모니터링
- 데이터 드리프트 감지
- 컨셉 드리프트 감지
- 재훈련 트리거
- 모델 품질 알림

## 수행 작업
1. 성능 메트릭 추적
2. 드리프트 감지 설정
3. 알림 규칙 정의
4. 재훈련 파이프라인 트리거
5. 모니터링 대시보드 구성

## 출력물
- 모니터링 설정
- 드리프트 리포트
- 알림 규칙

## 모델 성능 모니터링

```python
# monitoring/performance_monitor.py
from prometheus_client import Counter, Histogram, Gauge
import numpy as np
from typing import Dict, List
from datetime import datetime, timedelta
import pandas as pd

# Prometheus 메트릭
PREDICTIONS_TOTAL = Counter(
    'model_predictions_total',
    'Total predictions made',
    ['model', 'version']
)

PREDICTION_LATENCY = Histogram(
    'model_prediction_latency_seconds',
    'Prediction latency',
    ['model'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)

MODEL_ACCURACY = Gauge(
    'model_accuracy',
    'Current model accuracy',
    ['model', 'version']
)

DATA_DRIFT_SCORE = Gauge(
    'data_drift_score',
    'Data drift score',
    ['model', 'feature']
)

class ModelPerformanceMonitor:
    def __init__(self, model_name: str, version: str):
        self.model_name = model_name
        self.version = version
        self.predictions_buffer = []
        self.labels_buffer = []

    def log_prediction(
        self,
        prediction: np.ndarray,
        latency: float,
        features: Dict[str, float]
    ):
        """예측 로깅"""
        PREDICTIONS_TOTAL.labels(
            model=self.model_name,
            version=self.version
        ).inc()

        PREDICTION_LATENCY.labels(model=self.model_name).observe(latency)

        self.predictions_buffer.append({
            'prediction': prediction,
            'features': features,
            'timestamp': datetime.now()
        })

    def log_ground_truth(self, prediction_id: str, label: int):
        """실제 레이블 로깅 (지연된 피드백)"""
        self.labels_buffer.append({
            'prediction_id': prediction_id,
            'label': label,
            'timestamp': datetime.now()
        })

    def calculate_metrics(self, window_hours: int = 24) -> Dict:
        """윈도우 기반 메트릭 계산"""
        cutoff = datetime.now() - timedelta(hours=window_hours)

        recent_predictions = [
            p for p in self.predictions_buffer
            if p['timestamp'] > cutoff
        ]

        if not recent_predictions:
            return {}

        predictions = np.array([p['prediction'] for p in recent_predictions])

        metrics = {
            'prediction_count': len(predictions),
            'prediction_mean': float(np.mean(predictions)),
            'prediction_std': float(np.std(predictions)),
            'prediction_distribution': np.histogram(predictions, bins=10)[0].tolist()
        }

        # 레이블이 있으면 정확도 계산
        if self.labels_buffer:
            accuracy = self._calculate_accuracy(recent_predictions)
            metrics['accuracy'] = accuracy
            MODEL_ACCURACY.labels(
                model=self.model_name,
                version=self.version
            ).set(accuracy)

        return metrics

    def _calculate_accuracy(self, predictions: List[Dict]) -> float:
        # 예측과 레이블 매칭
        matched = 0
        correct = 0
        for pred in predictions:
            for label in self.labels_buffer:
                if pred.get('prediction_id') == label.get('prediction_id'):
                    matched += 1
                    if pred['prediction'] == label['label']:
                        correct += 1
                    break
        return correct / matched if matched > 0 else 0.0
```

## 데이터 드리프트 감지

```python
# monitoring/drift_detection.py
from scipy import stats
import numpy as np
from typing import Dict, List, Tuple
from dataclasses import dataclass
from enum import Enum

class DriftType(Enum):
    NO_DRIFT = "no_drift"
    WARNING = "warning"
    DRIFT = "drift"

@dataclass
class DriftResult:
    feature: str
    drift_type: DriftType
    score: float
    p_value: float
    threshold: float

class DataDriftDetector:
    def __init__(
        self,
        reference_data: np.ndarray,
        feature_names: List[str],
        warning_threshold: float = 0.1,
        drift_threshold: float = 0.05
    ):
        self.reference_data = reference_data
        self.feature_names = feature_names
        self.warning_threshold = warning_threshold
        self.drift_threshold = drift_threshold

        # 참조 데이터 통계
        self.reference_stats = self._calculate_stats(reference_data)

    def _calculate_stats(self, data: np.ndarray) -> Dict:
        return {
            'mean': np.mean(data, axis=0),
            'std': np.std(data, axis=0),
            'min': np.min(data, axis=0),
            'max': np.max(data, axis=0),
            'quantiles': np.percentile(data, [25, 50, 75], axis=0)
        }

    def detect_drift(self, current_data: np.ndarray) -> List[DriftResult]:
        """KS 테스트를 사용한 드리프트 감지"""
        results = []

        for i, feature_name in enumerate(self.feature_names):
            ref_feature = self.reference_data[:, i]
            curr_feature = current_data[:, i]

            # Kolmogorov-Smirnov test
            ks_stat, p_value = stats.ks_2samp(ref_feature, curr_feature)

            if p_value < self.drift_threshold:
                drift_type = DriftType.DRIFT
            elif p_value < self.warning_threshold:
                drift_type = DriftType.WARNING
            else:
                drift_type = DriftType.NO_DRIFT

            results.append(DriftResult(
                feature=feature_name,
                drift_type=drift_type,
                score=ks_stat,
                p_value=p_value,
                threshold=self.drift_threshold
            ))

            # Prometheus 메트릭 업데이트
            DATA_DRIFT_SCORE.labels(
                model='production',
                feature=feature_name
            ).set(ks_stat)

        return results

    def detect_covariate_shift(self, current_data: np.ndarray) -> Dict:
        """다변량 드리프트 감지"""
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.model_selection import cross_val_score

        # 참조 데이터: 0, 현재 데이터: 1
        X = np.vstack([self.reference_data, current_data])
        y = np.array([0] * len(self.reference_data) + [1] * len(current_data))

        # 분류기가 두 분포를 구분할 수 있는지 테스트
        clf = RandomForestClassifier(n_estimators=100, random_state=42)
        scores = cross_val_score(clf, X, y, cv=5, scoring='roc_auc')

        # AUC가 0.5에 가까우면 드리프트 없음
        mean_auc = np.mean(scores)

        return {
            'auc': mean_auc,
            'drift_detected': mean_auc > 0.6,
            'severity': 'high' if mean_auc > 0.8 else 'medium' if mean_auc > 0.7 else 'low'
        }

class ConceptDriftDetector:
    """컨셉 드리프트 감지 (모델 성능 저하)"""

    def __init__(self, window_size: int = 1000, threshold: float = 0.05):
        self.window_size = window_size
        self.threshold = threshold
        self.performance_history = []

    def update(self, y_true: int, y_pred: int):
        """새 예측 결과 추가"""
        self.performance_history.append({
            'correct': y_true == y_pred,
            'timestamp': datetime.now()
        })

        # 윈도우 크기 유지
        if len(self.performance_history) > self.window_size * 2:
            self.performance_history = self.performance_history[-self.window_size * 2:]

    def detect(self) -> Tuple[bool, Dict]:
        """ADWIN 알고리즘 기반 드리프트 감지"""
        if len(self.performance_history) < self.window_size:
            return False, {}

        recent = self.performance_history[-self.window_size:]
        previous = self.performance_history[-self.window_size * 2:-self.window_size]

        recent_accuracy = np.mean([p['correct'] for p in recent])
        previous_accuracy = np.mean([p['correct'] for p in previous])

        # 통계적 유의성 테스트
        n1, n2 = len(previous), len(recent)
        p1, p2 = previous_accuracy, recent_accuracy

        pooled_p = (p1 * n1 + p2 * n2) / (n1 + n2)
        se = np.sqrt(pooled_p * (1 - pooled_p) * (1/n1 + 1/n2))

        if se > 0:
            z_score = (p1 - p2) / se
            p_value = 2 * (1 - stats.norm.cdf(abs(z_score)))
        else:
            p_value = 1.0

        drift_detected = p_value < self.threshold and recent_accuracy < previous_accuracy

        return drift_detected, {
            'previous_accuracy': previous_accuracy,
            'recent_accuracy': recent_accuracy,
            'accuracy_drop': previous_accuracy - recent_accuracy,
            'p_value': p_value
        }
```

## 재훈련 트리거

```python
# monitoring/retrain_trigger.py
from typing import Dict, List
import json
from datetime import datetime

class RetrainTrigger:
    def __init__(
        self,
        accuracy_threshold: float = 0.85,
        drift_threshold: float = 0.2,
        performance_drop_threshold: float = 0.05
    ):
        self.accuracy_threshold = accuracy_threshold
        self.drift_threshold = drift_threshold
        self.performance_drop_threshold = performance_drop_threshold

    def evaluate(
        self,
        current_metrics: Dict,
        drift_results: List[DriftResult],
        baseline_metrics: Dict
    ) -> Tuple[bool, str]:
        """재훈련 필요 여부 평가"""
        reasons = []

        # 1. 절대 성능 체크
        if current_metrics.get('accuracy', 1.0) < self.accuracy_threshold:
            reasons.append(f"Accuracy below threshold: {current_metrics['accuracy']:.3f}")

        # 2. 성능 저하 체크
        if baseline_metrics:
            performance_drop = baseline_metrics.get('accuracy', 0) - current_metrics.get('accuracy', 0)
            if performance_drop > self.performance_drop_threshold:
                reasons.append(f"Performance dropped by {performance_drop:.3f}")

        # 3. 데이터 드리프트 체크
        drifted_features = [
            r.feature for r in drift_results
            if r.drift_type == DriftType.DRIFT
        ]
        if len(drifted_features) > len(drift_results) * self.drift_threshold:
            reasons.append(f"Data drift in features: {drifted_features}")

        should_retrain = len(reasons) > 0

        return should_retrain, "; ".join(reasons) if reasons else "No retrain needed"

    async def trigger_retrain(self, reason: str, model_name: str):
        """재훈련 파이프라인 트리거"""
        # Kubeflow 파이프라인 트리거
        from kfp import Client

        client = Client(host='http://kubeflow-pipelines:8888')

        run = client.create_run_from_pipeline_func(
            ml_training_pipeline,
            arguments={
                'model_name': model_name,
                'trigger_reason': reason,
                'timestamp': datetime.now().isoformat()
            }
        )

        return run.run_id
```

## 모니터링 대시보드 (Grafana)

```json
{
  "dashboard": {
    "title": "ML Model Monitoring",
    "panels": [
      {
        "title": "Model Accuracy Over Time",
        "type": "graph",
        "targets": [
          {
            "expr": "model_accuracy{model=\"production\"}",
            "legendFormat": "{{version}}"
          }
        ]
      },
      {
        "title": "Prediction Latency",
        "type": "heatmap",
        "targets": [
          {
            "expr": "rate(model_prediction_latency_seconds_bucket[5m])"
          }
        ]
      },
      {
        "title": "Data Drift Score by Feature",
        "type": "table",
        "targets": [
          {
            "expr": "data_drift_score",
            "format": "table"
          }
        ]
      },
      {
        "title": "Predictions per Second",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(model_predictions_total[1m])",
            "legendFormat": "{{model}}"
          }
        ]
      }
    ]
  }
}
```

## 알림 규칙

```yaml
# prometheus/ml-alerts.yml
groups:
  - name: ml-model-alerts
    rules:
      - alert: ModelAccuracyDrop
        expr: model_accuracy < 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Model accuracy dropped below threshold"
          description: "Model {{ $labels.model }} accuracy is {{ $value }}"

      - alert: HighDataDrift
        expr: data_drift_score > 0.3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Data drift detected"
          description: "Feature {{ $labels.feature }} drift score: {{ $value }}"

      - alert: PredictionLatencyHigh
        expr: histogram_quantile(0.95, rate(model_prediction_latency_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High prediction latency"
          description: "P95 latency is {{ $value }}s"
```

## 사용 예시
**입력**: "ML 모델 모니터링 시스템 구축해줘"

**출력**:
1. 성능 메트릭 추적
2. 드리프트 감지
3. 재훈련 트리거
4. 알림 설정
