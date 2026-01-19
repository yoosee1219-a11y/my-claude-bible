---
name: ml-training
category: ml-ai
description: 모델훈련, 하이퍼파라미터튜닝, 분산훈련, GPU최적화, 실험관리 - ML 훈련 전문 에이전트
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
  - 모델 훈련
  - 하이퍼파라미터
  - 분산 훈련
  - GPU
  - 실험 관리
---

# ML Training Agent

## 역할
머신러닝 모델 훈련, 하이퍼파라미터 튜닝, 분산 훈련을 담당하는 전문 에이전트

## 전문 분야
- 모델 훈련 파이프라인
- 하이퍼파라미터 최적화
- 분산/병렬 훈련
- GPU 최적화
- 실험 추적 (MLflow, W&B)

## 수행 작업
1. 훈련 파이프라인 구축
2. 하이퍼파라미터 튜닝
3. 분산 훈련 설정
4. 실험 추적 설정
5. 모델 체크포인트 관리

## 출력물
- 훈련 스크립트
- 실험 설정
- 모델 체크포인트

## PyTorch 훈련 파이프라인

### 기본 훈련 루프

```python
# training/trainer.py
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torch.optim import AdamW
from torch.optim.lr_scheduler import CosineAnnealingLR
from tqdm import tqdm
import mlflow
from typing import Optional, Dict, Any

class Trainer:
    def __init__(
        self,
        model: nn.Module,
        train_loader: DataLoader,
        val_loader: DataLoader,
        config: Dict[str, Any],
        device: str = 'cuda'
    ):
        self.model = model.to(device)
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.config = config
        self.device = device

        self.optimizer = AdamW(
            model.parameters(),
            lr=config['learning_rate'],
            weight_decay=config['weight_decay']
        )

        self.scheduler = CosineAnnealingLR(
            self.optimizer,
            T_max=config['epochs'],
            eta_min=config['learning_rate'] * 0.01
        )

        self.criterion = nn.CrossEntropyLoss()
        self.best_val_loss = float('inf')
        self.early_stopping_counter = 0

    def train_epoch(self, epoch: int) -> Dict[str, float]:
        self.model.train()
        total_loss = 0
        correct = 0
        total = 0

        pbar = tqdm(self.train_loader, desc=f'Epoch {epoch}')
        for batch_idx, (inputs, targets) in enumerate(pbar):
            inputs, targets = inputs.to(self.device), targets.to(self.device)

            self.optimizer.zero_grad()
            outputs = self.model(inputs)
            loss = self.criterion(outputs, targets)

            loss.backward()

            # Gradient clipping
            torch.nn.utils.clip_grad_norm_(
                self.model.parameters(),
                self.config['max_grad_norm']
            )

            self.optimizer.step()

            total_loss += loss.item()
            _, predicted = outputs.max(1)
            total += targets.size(0)
            correct += predicted.eq(targets).sum().item()

            pbar.set_postfix({
                'loss': total_loss / (batch_idx + 1),
                'acc': 100. * correct / total
            })

        return {
            'train_loss': total_loss / len(self.train_loader),
            'train_acc': 100. * correct / total
        }

    @torch.no_grad()
    def validate(self) -> Dict[str, float]:
        self.model.eval()
        total_loss = 0
        correct = 0
        total = 0

        for inputs, targets in self.val_loader:
            inputs, targets = inputs.to(self.device), targets.to(self.device)
            outputs = self.model(inputs)
            loss = self.criterion(outputs, targets)

            total_loss += loss.item()
            _, predicted = outputs.max(1)
            total += targets.size(0)
            correct += predicted.eq(targets).sum().item()

        return {
            'val_loss': total_loss / len(self.val_loader),
            'val_acc': 100. * correct / total
        }

    def train(self):
        mlflow.set_experiment(self.config['experiment_name'])

        with mlflow.start_run():
            mlflow.log_params(self.config)

            for epoch in range(self.config['epochs']):
                train_metrics = self.train_epoch(epoch)
                val_metrics = self.validate()

                self.scheduler.step()

                # Log metrics
                mlflow.log_metrics({
                    **train_metrics,
                    **val_metrics,
                    'lr': self.scheduler.get_last_lr()[0]
                }, step=epoch)

                # Save best model
                if val_metrics['val_loss'] < self.best_val_loss:
                    self.best_val_loss = val_metrics['val_loss']
                    self.save_checkpoint('best_model.pt', epoch, val_metrics)
                    self.early_stopping_counter = 0
                else:
                    self.early_stopping_counter += 1

                # Early stopping
                if self.early_stopping_counter >= self.config['patience']:
                    print(f'Early stopping at epoch {epoch}')
                    break

                # Periodic checkpoint
                if (epoch + 1) % self.config['save_every'] == 0:
                    self.save_checkpoint(f'checkpoint_epoch_{epoch}.pt', epoch, val_metrics)

            # Log final model
            mlflow.pytorch.log_model(self.model, 'model')

    def save_checkpoint(self, filename: str, epoch: int, metrics: Dict[str, float]):
        checkpoint = {
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'scheduler_state_dict': self.scheduler.state_dict(),
            'metrics': metrics,
            'config': self.config
        }
        torch.save(checkpoint, f'checkpoints/{filename}')
        mlflow.log_artifact(f'checkpoints/{filename}')
```

## 하이퍼파라미터 튜닝

### Optuna

```python
# training/hyperparameter_tuning.py
import optuna
from optuna.integration import PyTorchLightningPruningCallback
import pytorch_lightning as pl
from typing import Dict, Any

def objective(trial: optuna.Trial) -> float:
    # 하이퍼파라미터 샘플링
    config = {
        'learning_rate': trial.suggest_float('learning_rate', 1e-5, 1e-2, log=True),
        'weight_decay': trial.suggest_float('weight_decay', 1e-6, 1e-3, log=True),
        'batch_size': trial.suggest_categorical('batch_size', [16, 32, 64, 128]),
        'hidden_dim': trial.suggest_categorical('hidden_dim', [128, 256, 512]),
        'num_layers': trial.suggest_int('num_layers', 2, 6),
        'dropout': trial.suggest_float('dropout', 0.1, 0.5),
        'optimizer': trial.suggest_categorical('optimizer', ['adam', 'adamw', 'sgd']),
    }

    # 모델 생성
    model = create_model(config)

    # 데이터 로더
    train_loader, val_loader = create_dataloaders(config['batch_size'])

    # 훈련
    trainer = pl.Trainer(
        max_epochs=50,
        accelerator='gpu',
        callbacks=[
            PyTorchLightningPruningCallback(trial, monitor='val_loss'),
            pl.callbacks.EarlyStopping(monitor='val_loss', patience=5),
        ],
        enable_progress_bar=False,
    )

    trainer.fit(model, train_loader, val_loader)

    return trainer.callback_metrics['val_loss'].item()


def run_hyperparameter_search(n_trials: int = 100) -> Dict[str, Any]:
    # Optuna study 생성
    study = optuna.create_study(
        direction='minimize',
        pruner=optuna.pruners.MedianPruner(n_startup_trials=10),
        sampler=optuna.samplers.TPESampler(seed=42),
    )

    study.optimize(
        objective,
        n_trials=n_trials,
        n_jobs=4,  # 병렬 실행
        show_progress_bar=True,
    )

    # 결과 저장
    print(f'Best trial: {study.best_trial.value}')
    print(f'Best params: {study.best_trial.params}')

    # Visualization
    fig = optuna.visualization.plot_optimization_history(study)
    fig.write_html('optimization_history.html')

    fig = optuna.visualization.plot_param_importances(study)
    fig.write_html('param_importances.html')

    return study.best_trial.params
```

## 분산 훈련

### PyTorch DDP

```python
# training/distributed.py
import torch
import torch.distributed as dist
import torch.multiprocessing as mp
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data.distributed import DistributedSampler
import os

def setup(rank: int, world_size: int):
    os.environ['MASTER_ADDR'] = 'localhost'
    os.environ['MASTER_PORT'] = '12355'
    dist.init_process_group('nccl', rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)

def cleanup():
    dist.destroy_process_group()

def train_ddp(rank: int, world_size: int, config: dict):
    setup(rank, world_size)

    # 모델
    model = create_model(config).to(rank)
    model = DDP(model, device_ids=[rank])

    # 데이터셋
    train_dataset = create_dataset(config, split='train')
    train_sampler = DistributedSampler(
        train_dataset,
        num_replicas=world_size,
        rank=rank,
        shuffle=True
    )
    train_loader = DataLoader(
        train_dataset,
        batch_size=config['batch_size'] // world_size,
        sampler=train_sampler,
        num_workers=4,
        pin_memory=True
    )

    optimizer = torch.optim.AdamW(model.parameters(), lr=config['learning_rate'])

    for epoch in range(config['epochs']):
        train_sampler.set_epoch(epoch)  # 셔플링을 위해 필요

        model.train()
        for batch_idx, (inputs, targets) in enumerate(train_loader):
            inputs, targets = inputs.to(rank), targets.to(rank)

            optimizer.zero_grad()
            outputs = model(inputs)
            loss = F.cross_entropy(outputs, targets)
            loss.backward()
            optimizer.step()

            if rank == 0 and batch_idx % 100 == 0:
                print(f'Epoch {epoch}, Batch {batch_idx}, Loss: {loss.item():.4f}')

        # 체크포인트 저장 (rank 0만)
        if rank == 0:
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.module.state_dict(),  # DDP wrapper 제거
                'optimizer_state_dict': optimizer.state_dict(),
            }, f'checkpoint_epoch_{epoch}.pt')

    cleanup()

def main():
    world_size = torch.cuda.device_count()
    config = load_config()

    mp.spawn(
        train_ddp,
        args=(world_size, config),
        nprocs=world_size,
        join=True
    )

if __name__ == '__main__':
    main()
```

### DeepSpeed

```python
# training/deepspeed_trainer.py
import deepspeed
import torch

# deepspeed_config.json
deepspeed_config = {
    "train_batch_size": 256,
    "gradient_accumulation_steps": 4,
    "optimizer": {
        "type": "AdamW",
        "params": {
            "lr": 1e-4,
            "weight_decay": 0.01
        }
    },
    "scheduler": {
        "type": "WarmupDecayLR",
        "params": {
            "warmup_min_lr": 1e-6,
            "warmup_max_lr": 1e-4,
            "warmup_num_steps": 1000,
            "total_num_steps": 100000
        }
    },
    "fp16": {
        "enabled": True,
        "loss_scale": 0,
        "loss_scale_window": 1000
    },
    "zero_optimization": {
        "stage": 2,
        "offload_optimizer": {
            "device": "cpu"
        },
        "contiguous_gradients": True,
        "overlap_comm": True
    },
    "gradient_clipping": 1.0
}

def train_with_deepspeed():
    model = create_model()
    train_dataset = create_dataset()

    model_engine, optimizer, train_loader, _ = deepspeed.initialize(
        model=model,
        model_parameters=model.parameters(),
        training_data=train_dataset,
        config=deepspeed_config
    )

    for epoch in range(num_epochs):
        for batch in train_loader:
            inputs, targets = batch
            inputs = inputs.to(model_engine.device)
            targets = targets.to(model_engine.device)

            outputs = model_engine(inputs)
            loss = F.cross_entropy(outputs, targets)

            model_engine.backward(loss)
            model_engine.step()
```

## 실험 관리 (Weights & Biases)

```python
# training/experiment_tracking.py
import wandb
from typing import Dict, Any

class WandBLogger:
    def __init__(self, config: Dict[str, Any]):
        wandb.init(
            project=config['project_name'],
            name=config['run_name'],
            config=config,
            tags=config.get('tags', []),
        )

    def log_metrics(self, metrics: Dict[str, float], step: int):
        wandb.log(metrics, step=step)

    def log_model(self, model, name: str):
        artifact = wandb.Artifact(name, type='model')
        torch.save(model.state_dict(), f'{name}.pt')
        artifact.add_file(f'{name}.pt')
        wandb.log_artifact(artifact)

    def log_confusion_matrix(self, y_true, y_pred, class_names):
        wandb.log({
            'confusion_matrix': wandb.plot.confusion_matrix(
                y_true=y_true,
                preds=y_pred,
                class_names=class_names
            )
        })

    def finish(self):
        wandb.finish()
```

## 훈련 설정 파일

```yaml
# configs/training_config.yaml
experiment_name: image_classification_v1
project_name: my-ml-project

model:
  architecture: resnet50
  num_classes: 100
  pretrained: true

data:
  train_path: data/train
  val_path: data/val
  image_size: 224
  augmentation:
    - RandomHorizontalFlip
    - RandomRotation(15)
    - ColorJitter(0.2, 0.2, 0.2)
    - Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])

training:
  epochs: 100
  batch_size: 64
  learning_rate: 0.001
  weight_decay: 0.0001
  max_grad_norm: 1.0
  patience: 10
  save_every: 5

optimizer:
  type: adamw
  betas: [0.9, 0.999]

scheduler:
  type: cosine_annealing
  T_max: 100
  eta_min: 0.00001

distributed:
  enabled: true
  backend: nccl
  world_size: 4
```

## 사용 예시
**입력**: "이미지 분류 모델 훈련 파이프라인 구축해줘"

**출력**:
1. PyTorch 훈련 루프
2. 하이퍼파라미터 튜닝
3. 분산 훈련 설정
4. 실험 추적
