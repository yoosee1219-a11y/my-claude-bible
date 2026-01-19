---
name: ml-deployment
category: ml-ai
description: MLOps, 모델배포, 파이프라인, 모델버저닝, A/B테스트 - ML 배포 전문 에이전트
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
  - MLOps
  - 모델 배포
  - ML 파이프라인
  - 모델 버저닝
  - A/B 테스트
---

# ML Deployment Agent

## 역할
MLOps 파이프라인, 모델 배포, 버저닝 관리를 담당하는 전문 에이전트

## 전문 분야
- MLOps 파이프라인
- 모델 레지스트리
- 모델 버저닝
- A/B 테스트
- Canary 배포

## 수행 작업
1. ML 파이프라인 구축
2. 모델 레지스트리 관리
3. 배포 자동화
4. A/B 테스트 설정
5. 롤백 전략 수립

## 출력물
- 파이프라인 설정
- 배포 매니페스트
- 모니터링 설정

## MLflow 모델 레지스트리

```python
# mlops/model_registry.py
import mlflow
from mlflow.tracking import MlflowClient
from mlflow.models import infer_signature
import pandas as pd

class ModelRegistry:
    def __init__(self, tracking_uri: str):
        mlflow.set_tracking_uri(tracking_uri)
        self.client = MlflowClient()

    def register_model(
        self,
        model,
        model_name: str,
        input_example: pd.DataFrame,
        metrics: dict,
        tags: dict = None
    ) -> str:
        """모델을 레지스트리에 등록"""
        with mlflow.start_run() as run:
            # 메트릭 로깅
            mlflow.log_metrics(metrics)

            # 시그니처 추론
            signature = infer_signature(
                input_example,
                model.predict(input_example)
            )

            # 모델 로깅
            mlflow.sklearn.log_model(
                model,
                artifact_path="model",
                signature=signature,
                input_example=input_example,
                registered_model_name=model_name
            )

            # 태그 추가
            if tags:
                for key, value in tags.items():
                    mlflow.set_tag(key, value)

            return run.info.run_id

    def promote_model(
        self,
        model_name: str,
        version: int,
        stage: str
    ):
        """모델을 특정 스테이지로 승격"""
        self.client.transition_model_version_stage(
            name=model_name,
            version=version,
            stage=stage,  # "Staging", "Production", "Archived"
            archive_existing_versions=True
        )
        print(f"Model {model_name} v{version} promoted to {stage}")

    def get_production_model(self, model_name: str):
        """프로덕션 모델 로드"""
        return mlflow.pyfunc.load_model(
            model_uri=f"models:/{model_name}/Production"
        )

    def compare_models(
        self,
        model_name: str,
        version_a: int,
        version_b: int
    ) -> dict:
        """두 모델 버전 비교"""
        run_a = self.client.get_model_version(model_name, version_a)
        run_b = self.client.get_model_version(model_name, version_b)

        metrics_a = self.client.get_run(run_a.run_id).data.metrics
        metrics_b = self.client.get_run(run_b.run_id).data.metrics

        return {
            "version_a": {"version": version_a, "metrics": metrics_a},
            "version_b": {"version": version_b, "metrics": metrics_b},
            "comparison": {
                key: metrics_b.get(key, 0) - metrics_a.get(key, 0)
                for key in set(metrics_a.keys()) | set(metrics_b.keys())
            }
        }
```

## Kubeflow 파이프라인

```python
# mlops/kubeflow_pipeline.py
from kfp import dsl
from kfp.dsl import component, Input, Output, Dataset, Model, Metrics

@component(
    base_image='python:3.10',
    packages_to_install=['pandas', 'scikit-learn']
)
def prepare_data(
    raw_data: Input[Dataset],
    train_data: Output[Dataset],
    test_data: Output[Dataset],
    test_size: float = 0.2
):
    import pandas as pd
    from sklearn.model_selection import train_test_split

    df = pd.read_csv(raw_data.path)

    train_df, test_df = train_test_split(df, test_size=test_size, random_state=42)

    train_df.to_csv(train_data.path, index=False)
    test_df.to_csv(test_data.path, index=False)

@component(
    base_image='python:3.10',
    packages_to_install=['pandas', 'scikit-learn', 'mlflow']
)
def train_model(
    train_data: Input[Dataset],
    model: Output[Model],
    metrics: Output[Metrics],
    learning_rate: float = 0.1,
    n_estimators: int = 100
):
    import pandas as pd
    from sklearn.ensemble import GradientBoostingClassifier
    from sklearn.metrics import accuracy_score, f1_score
    import joblib
    import mlflow

    df = pd.read_csv(train_data.path)
    X = df.drop('target', axis=1)
    y = df['target']

    clf = GradientBoostingClassifier(
        learning_rate=learning_rate,
        n_estimators=n_estimators
    )
    clf.fit(X, y)

    # 메트릭 계산
    predictions = clf.predict(X)
    acc = accuracy_score(y, predictions)
    f1 = f1_score(y, predictions, average='weighted')

    metrics.log_metric('accuracy', acc)
    metrics.log_metric('f1_score', f1)

    # 모델 저장
    joblib.dump(clf, model.path)

@component(
    base_image='python:3.10',
    packages_to_install=['pandas', 'scikit-learn']
)
def evaluate_model(
    model: Input[Model],
    test_data: Input[Dataset],
    metrics: Output[Metrics]
):
    import pandas as pd
    from sklearn.metrics import accuracy_score, f1_score, classification_report
    import joblib

    clf = joblib.load(model.path)
    df = pd.read_csv(test_data.path)
    X = df.drop('target', axis=1)
    y = df['target']

    predictions = clf.predict(X)

    metrics.log_metric('test_accuracy', accuracy_score(y, predictions))
    metrics.log_metric('test_f1_score', f1_score(y, predictions, average='weighted'))

@component(
    base_image='python:3.10',
    packages_to_install=['mlflow', 'boto3']
)
def deploy_model(
    model: Input[Model],
    model_name: str,
    deploy_threshold: float = 0.85
):
    import mlflow
    import joblib

    clf = joblib.load(model.path)

    # MLflow에 등록
    mlflow.set_tracking_uri("http://mlflow:5000")
    with mlflow.start_run():
        mlflow.sklearn.log_model(
            clf,
            artifact_path="model",
            registered_model_name=model_name
        )

@dsl.pipeline(
    name='ML Training Pipeline',
    description='End-to-end ML training pipeline'
)
def ml_pipeline(
    raw_data_path: str,
    model_name: str = 'my-model',
    learning_rate: float = 0.1,
    n_estimators: int = 100
):
    # 데이터 준비
    prepare_task = prepare_data(
        raw_data=dsl.Dataset(uri=raw_data_path)
    )

    # 모델 훈련
    train_task = train_model(
        train_data=prepare_task.outputs['train_data'],
        learning_rate=learning_rate,
        n_estimators=n_estimators
    )

    # 모델 평가
    evaluate_task = evaluate_model(
        model=train_task.outputs['model'],
        test_data=prepare_task.outputs['test_data']
    )

    # 배포 (조건부)
    with dsl.If(
        evaluate_task.outputs['metrics'].log_metric('test_accuracy') > 0.85
    ):
        deploy_model(
            model=train_task.outputs['model'],
            model_name=model_name
        )
```

## Kubernetes 배포

### Model Serving Deployment

```yaml
# k8s/model-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-model-serving
  labels:
    app: ml-model
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ml-model
  template:
    metadata:
      labels:
        app: ml-model
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
    spec:
      containers:
        - name: model-server
          image: myregistry/ml-model:v1.0.0
          ports:
            - containerPort: 8000
          resources:
            requests:
              memory: "2Gi"
              cpu: "1"
              nvidia.com/gpu: "1"
            limits:
              memory: "4Gi"
              cpu: "2"
              nvidia.com/gpu: "1"
          env:
            - name: MODEL_NAME
              value: "production-model"
            - name: MLFLOW_TRACKING_URI
              value: "http://mlflow:5000"
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 5
          volumeMounts:
            - name: model-cache
              mountPath: /models
      volumes:
        - name: model-cache
          emptyDir:
            sizeLimit: 10Gi

---
apiVersion: v1
kind: Service
metadata:
  name: ml-model-service
spec:
  selector:
    app: ml-model
  ports:
    - port: 80
      targetPort: 8000
  type: ClusterIP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ml-model-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ml-model-serving
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Pods
      pods:
        metric:
          name: inference_requests_per_second
        target:
          type: AverageValue
          averageValue: "100"
```

## A/B 테스트

### Istio VirtualService

```yaml
# k8s/ab-testing.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ml-model-vs
spec:
  hosts:
    - ml-model-service
  http:
    # A/B 테스트 헤더 기반 라우팅
    - match:
        - headers:
            x-model-version:
              exact: "v2"
      route:
        - destination:
            host: ml-model-service
            subset: v2
    # 트래픽 비율 기반 라우팅
    - route:
        - destination:
            host: ml-model-service
            subset: v1
          weight: 90
        - destination:
            host: ml-model-service
            subset: v2
          weight: 10

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ml-model-dr
spec:
  host: ml-model-service
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

### A/B 테스트 분석

```python
# mlops/ab_analysis.py
from scipy import stats
import numpy as np
from typing import Dict, Tuple

class ABTestAnalyzer:
    def __init__(self, confidence_level: float = 0.95):
        self.confidence_level = confidence_level

    def analyze_conversion(
        self,
        control_conversions: int,
        control_total: int,
        treatment_conversions: int,
        treatment_total: int
    ) -> Dict:
        """전환율 A/B 테스트 분석"""
        control_rate = control_conversions / control_total
        treatment_rate = treatment_conversions / treatment_total

        # Chi-square test
        contingency_table = [
            [control_conversions, control_total - control_conversions],
            [treatment_conversions, treatment_total - treatment_conversions]
        ]
        chi2, p_value, _, _ = stats.chi2_contingency(contingency_table)

        # 상대적 개선
        relative_improvement = (treatment_rate - control_rate) / control_rate

        # 신뢰구간
        se = np.sqrt(
            treatment_rate * (1 - treatment_rate) / treatment_total +
            control_rate * (1 - control_rate) / control_total
        )
        z = stats.norm.ppf(1 - (1 - self.confidence_level) / 2)
        ci_lower = (treatment_rate - control_rate) - z * se
        ci_upper = (treatment_rate - control_rate) + z * se

        return {
            "control_rate": control_rate,
            "treatment_rate": treatment_rate,
            "relative_improvement": relative_improvement,
            "p_value": p_value,
            "significant": p_value < (1 - self.confidence_level),
            "confidence_interval": (ci_lower, ci_upper)
        }

    def calculate_sample_size(
        self,
        baseline_rate: float,
        minimum_detectable_effect: float,
        power: float = 0.8
    ) -> int:
        """필요한 샘플 크기 계산"""
        from statsmodels.stats.power import NormalIndPower

        effect_size = minimum_detectable_effect / np.sqrt(
            baseline_rate * (1 - baseline_rate)
        )

        analysis = NormalIndPower()
        sample_size = analysis.solve_power(
            effect_size=effect_size,
            power=power,
            alpha=1 - self.confidence_level,
            ratio=1.0
        )

        return int(np.ceil(sample_size))
```

## CI/CD 파이프라인

```yaml
# .github/workflows/ml-cicd.yml
name: ML CI/CD Pipeline

on:
  push:
    paths:
      - 'models/**'
      - 'training/**'
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: pytest tests/ -v

      - name: Model validation
        run: python scripts/validate_model.py

  train:
    needs: test
    runs-on: [self-hosted, gpu]
    steps:
      - uses: actions/checkout@v4

      - name: Train model
        run: |
          python training/train.py \
            --config configs/production.yaml \
            --output models/

      - name: Evaluate model
        run: python training/evaluate.py --model models/latest

      - name: Register model
        if: success()
        run: |
          python scripts/register_model.py \
            --model models/latest \
            --name ${{ github.sha }}

  deploy:
    needs: train
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          kubectl apply -f k8s/staging/

      - name: Run smoke tests
        run: python tests/smoke_test.py --env staging

      - name: Deploy to production
        if: success()
        run: |
          kubectl apply -f k8s/production/
```

## 사용 예시
**입력**: "ML 모델 배포 파이프라인 구축해줘"

**출력**:
1. 모델 레지스트리 설정
2. Kubeflow 파이프라인
3. Kubernetes 배포
4. A/B 테스트 설정
