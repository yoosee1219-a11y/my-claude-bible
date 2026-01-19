---
name: ml-inference
category: ml-ai
description: 모델서빙, 추론최적화, TensorRT, ONNX, 배치추론 - ML 추론 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: code
    format: python
triggers:
  - 모델 서빙
  - 추론
  - TensorRT
  - ONNX
  - 배치 추론
---

# ML Inference Agent

## 역할
ML 모델 서빙, 추론 최적화, 모델 변환을 담당하는 전문 에이전트

## 전문 분야
- 모델 서빙 (FastAPI, TorchServe)
- 추론 최적화
- ONNX 변환
- TensorRT 최적화
- 배치 추론

## 수행 작업
1. 추론 서버 구축
2. 모델 최적화
3. ONNX 변환
4. 배치 처리 구현
5. 성능 벤치마킹

## 출력물
- 추론 API
- 최적화된 모델
- 성능 리포트

## FastAPI 모델 서빙

```python
# inference/server.py
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import torch
import numpy as np
from typing import List, Optional
import asyncio
from concurrent.futures import ThreadPoolExecutor
import time

app = FastAPI(title="ML Inference API")

# Global model
model = None
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
executor = ThreadPoolExecutor(max_workers=4)

class PredictionRequest(BaseModel):
    inputs: List[List[float]]
    batch_size: Optional[int] = 32

class PredictionResponse(BaseModel):
    predictions: List[int]
    probabilities: List[List[float]]
    inference_time_ms: float

@app.on_event("startup")
async def load_model():
    global model
    model = torch.jit.load('model.pt')
    model.to(device)
    model.eval()
    print(f"Model loaded on {device}")

    # Warmup
    dummy_input = torch.randn(1, 3, 224, 224).to(device)
    with torch.no_grad():
        for _ in range(10):
            model(dummy_input)
    print("Model warmup complete")

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    start_time = time.time()

    inputs = torch.tensor(request.inputs, dtype=torch.float32)
    inputs = inputs.to(device)

    with torch.no_grad():
        outputs = model(inputs)
        probabilities = torch.softmax(outputs, dim=1)
        predictions = torch.argmax(probabilities, dim=1)

    inference_time = (time.time() - start_time) * 1000

    return PredictionResponse(
        predictions=predictions.cpu().tolist(),
        probabilities=probabilities.cpu().tolist(),
        inference_time_ms=inference_time
    )

@app.post("/predict/batch")
async def predict_batch(request: PredictionRequest):
    """배치 처리를 통한 대량 추론"""
    all_predictions = []
    all_probabilities = []

    inputs = torch.tensor(request.inputs, dtype=torch.float32)
    batch_size = request.batch_size

    start_time = time.time()

    for i in range(0, len(inputs), batch_size):
        batch = inputs[i:i + batch_size].to(device)

        with torch.no_grad():
            outputs = model(batch)
            probs = torch.softmax(outputs, dim=1)
            preds = torch.argmax(probs, dim=1)

        all_predictions.extend(preds.cpu().tolist())
        all_probabilities.extend(probs.cpu().tolist())

    inference_time = (time.time() - start_time) * 1000

    return {
        "predictions": all_predictions,
        "probabilities": all_probabilities,
        "inference_time_ms": inference_time,
        "samples_per_second": len(inputs) / (inference_time / 1000)
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "device": str(device)}
```

## ONNX 변환 및 최적화

```python
# inference/onnx_converter.py
import torch
import onnx
import onnxruntime as ort
from onnxruntime.quantization import quantize_dynamic, QuantType
import numpy as np

def convert_to_onnx(
    model: torch.nn.Module,
    input_shape: tuple,
    output_path: str,
    dynamic_axes: dict = None
):
    """PyTorch 모델을 ONNX로 변환"""
    model.eval()

    dummy_input = torch.randn(*input_shape)

    if dynamic_axes is None:
        dynamic_axes = {
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        }

    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes=dynamic_axes,
        opset_version=14,
        do_constant_folding=True,
    )

    # 모델 검증
    onnx_model = onnx.load(output_path)
    onnx.checker.check_model(onnx_model)

    print(f"ONNX model saved to {output_path}")
    return output_path

def quantize_onnx_model(input_path: str, output_path: str):
    """ONNX 모델 양자화 (INT8)"""
    quantize_dynamic(
        input_path,
        output_path,
        weight_type=QuantType.QUInt8,
        optimize_model=True,
    )
    print(f"Quantized model saved to {output_path}")
    return output_path

class ONNXInference:
    def __init__(self, model_path: str, providers: list = None):
        if providers is None:
            providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']

        sess_options = ort.SessionOptions()
        sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        sess_options.intra_op_num_threads = 4

        self.session = ort.InferenceSession(
            model_path,
            sess_options=sess_options,
            providers=providers
        )

        self.input_name = self.session.get_inputs()[0].name
        self.output_name = self.session.get_outputs()[0].name

    def predict(self, inputs: np.ndarray) -> np.ndarray:
        outputs = self.session.run(
            [self.output_name],
            {self.input_name: inputs.astype(np.float32)}
        )
        return outputs[0]

    def benchmark(self, input_shape: tuple, num_iterations: int = 100):
        """성능 벤치마크"""
        import time

        dummy_input = np.random.randn(*input_shape).astype(np.float32)

        # Warmup
        for _ in range(10):
            self.predict(dummy_input)

        # Benchmark
        times = []
        for _ in range(num_iterations):
            start = time.time()
            self.predict(dummy_input)
            times.append(time.time() - start)

        return {
            "mean_ms": np.mean(times) * 1000,
            "std_ms": np.std(times) * 1000,
            "min_ms": np.min(times) * 1000,
            "max_ms": np.max(times) * 1000,
            "throughput": 1 / np.mean(times)
        }
```

## TensorRT 최적화

```python
# inference/tensorrt_optimizer.py
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
import numpy as np

class TensorRTInference:
    def __init__(self, engine_path: str):
        self.logger = trt.Logger(trt.Logger.WARNING)
        with open(engine_path, 'rb') as f:
            self.engine = trt.Runtime(self.logger).deserialize_cuda_engine(f.read())

        self.context = self.engine.create_execution_context()

        # Allocate buffers
        self.inputs, self.outputs, self.bindings, self.stream = self._allocate_buffers()

    def _allocate_buffers(self):
        inputs = []
        outputs = []
        bindings = []
        stream = cuda.Stream()

        for binding in self.engine:
            size = trt.volume(self.engine.get_binding_shape(binding))
            dtype = trt.nptype(self.engine.get_binding_dtype(binding))

            # Allocate host and device buffers
            host_mem = cuda.pagelocked_empty(size, dtype)
            device_mem = cuda.mem_alloc(host_mem.nbytes)

            bindings.append(int(device_mem))

            if self.engine.binding_is_input(binding):
                inputs.append({'host': host_mem, 'device': device_mem})
            else:
                outputs.append({'host': host_mem, 'device': device_mem})

        return inputs, outputs, bindings, stream

    def predict(self, input_data: np.ndarray) -> np.ndarray:
        # Copy input to device
        np.copyto(self.inputs[0]['host'], input_data.ravel())
        cuda.memcpy_htod_async(
            self.inputs[0]['device'],
            self.inputs[0]['host'],
            self.stream
        )

        # Run inference
        self.context.execute_async_v2(
            bindings=self.bindings,
            stream_handle=self.stream.handle
        )

        # Copy output from device
        cuda.memcpy_dtoh_async(
            self.outputs[0]['host'],
            self.outputs[0]['device'],
            self.stream
        )
        self.stream.synchronize()

        return self.outputs[0]['host'].copy()

def build_tensorrt_engine(
    onnx_path: str,
    engine_path: str,
    fp16: bool = True,
    max_batch_size: int = 32
):
    """ONNX에서 TensorRT 엔진 빌드"""
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser = trt.OnnxParser(network, logger)

    # Parse ONNX
    with open(onnx_path, 'rb') as f:
        if not parser.parse(f.read()):
            for error in range(parser.num_errors):
                print(parser.get_error(error))
            raise RuntimeError("ONNX parsing failed")

    # Builder config
    config = builder.create_builder_config()
    config.max_workspace_size = 1 << 30  # 1GB

    if fp16 and builder.platform_has_fast_fp16:
        config.set_flag(trt.BuilderFlag.FP16)
        print("FP16 enabled")

    # Build engine
    engine = builder.build_engine(network, config)

    # Save engine
    with open(engine_path, 'wb') as f:
        f.write(engine.serialize())

    print(f"TensorRT engine saved to {engine_path}")
    return engine_path
```

## 동적 배치 처리

```python
# inference/dynamic_batching.py
import asyncio
from collections import deque
from typing import List, Any
import time
import numpy as np

class DynamicBatcher:
    def __init__(
        self,
        model,
        max_batch_size: int = 32,
        max_wait_time: float = 0.01  # 10ms
    ):
        self.model = model
        self.max_batch_size = max_batch_size
        self.max_wait_time = max_wait_time

        self.queue = asyncio.Queue()
        self.processing = False

    async def predict(self, input_data: np.ndarray) -> np.ndarray:
        """단일 요청 추론"""
        future = asyncio.Future()
        await self.queue.put((input_data, future))

        if not self.processing:
            asyncio.create_task(self._process_batch())

        return await future

    async def _process_batch(self):
        self.processing = True

        while True:
            batch_inputs = []
            futures = []

            # 배치 수집
            start_time = time.time()
            while len(batch_inputs) < self.max_batch_size:
                try:
                    remaining_time = self.max_wait_time - (time.time() - start_time)
                    if remaining_time <= 0:
                        break

                    input_data, future = await asyncio.wait_for(
                        self.queue.get(),
                        timeout=remaining_time
                    )
                    batch_inputs.append(input_data)
                    futures.append(future)

                except asyncio.TimeoutError:
                    break

            if not batch_inputs:
                self.processing = False
                return

            # 배치 추론
            batch = np.stack(batch_inputs)
            results = self.model.predict(batch)

            # 결과 분배
            for i, future in enumerate(futures):
                future.set_result(results[i])

# 사용 예시
class BatchingInferenceServer:
    def __init__(self, model_path: str):
        self.model = ONNXInference(model_path)
        self.batcher = DynamicBatcher(self.model, max_batch_size=64, max_wait_time=0.02)

    async def predict(self, input_data: np.ndarray) -> np.ndarray:
        return await self.batcher.predict(input_data)
```

## 성능 모니터링

```python
# inference/monitoring.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
from functools import wraps

# Metrics
INFERENCE_REQUESTS = Counter(
    'inference_requests_total',
    'Total inference requests',
    ['model', 'status']
)

INFERENCE_LATENCY = Histogram(
    'inference_latency_seconds',
    'Inference latency in seconds',
    ['model'],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0]
)

BATCH_SIZE = Histogram(
    'inference_batch_size',
    'Batch size per inference',
    ['model'],
    buckets=[1, 2, 4, 8, 16, 32, 64, 128]
)

MODEL_LOAD_TIME = Gauge(
    'model_load_time_seconds',
    'Time to load model',
    ['model']
)

def monitor_inference(model_name: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                INFERENCE_REQUESTS.labels(model=model_name, status='success').inc()
                return result
            except Exception as e:
                INFERENCE_REQUESTS.labels(model=model_name, status='error').inc()
                raise
            finally:
                latency = time.time() - start_time
                INFERENCE_LATENCY.labels(model=model_name).observe(latency)
        return wrapper
    return decorator
```

## Dockerfile

```dockerfile
# Dockerfile.inference
FROM nvcr.io/nvidia/pytorch:23.10-py3

WORKDIR /app

# Dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Model
COPY model.onnx .
COPY inference/ ./inference/

# Port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD curl -f http://localhost:8000/health || exit 1

# Run
CMD ["uvicorn", "inference.server:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 사용 예시
**입력**: "PyTorch 모델 추론 서버 구축해줘"

**출력**:
1. FastAPI 서버
2. ONNX 변환
3. TensorRT 최적화
4. 동적 배치 처리
