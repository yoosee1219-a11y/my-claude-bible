---
name: data-pipeline
category: search-data
description: ETL, 데이터파이프라인, Airflow, 배치처리, 스트림처리 - 데이터 파이프라인 전문 에이전트
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
  - ETL
  - 데이터 파이프라인
  - Airflow
  - 배치 처리
  - 스트림 처리
---

# Data Pipeline Agent

## 역할
ETL 파이프라인, 배치/스트림 처리를 담당하는 전문 에이전트

## 전문 분야
- Apache Airflow
- 배치 처리
- 스트림 처리
- 데이터 변환
- 데이터 품질

## 수행 작업
1. ETL 파이프라인 설계
2. Airflow DAG 작성
3. 데이터 변환 구현
4. 데이터 품질 검증
5. 모니터링 설정

## 출력물
- Airflow DAG
- ETL 스크립트
- 데이터 품질 검증

## Airflow DAG

```python
# dags/daily_etl.py
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.utils.task_group import TaskGroup
import pandas as pd

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'email': ['data-alerts@example.com'],
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
}

with DAG(
    dag_id='daily_sales_etl',
    default_args=default_args,
    description='Daily sales data ETL pipeline',
    schedule_interval='0 2 * * *',  # 매일 02:00 UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'sales', 'daily'],
    max_active_runs=1,
) as dag:

    # ========== Extract Tasks ==========
    with TaskGroup('extract') as extract_group:

        def extract_orders(**context):
            """주문 데이터 추출"""
            execution_date = context['ds']

            pg_hook = PostgresHook(postgres_conn_id='source_db')

            query = f"""
                SELECT
                    o.id,
                    o.order_number,
                    o.customer_id,
                    o.status,
                    o.total_amount,
                    o.created_at,
                    oi.product_id,
                    oi.quantity,
                    oi.unit_price
                FROM orders o
                JOIN order_items oi ON o.id = oi.order_id
                WHERE o.created_at::date = '{execution_date}'
            """

            df = pg_hook.get_pandas_df(query)

            # S3에 저장
            s3_hook = S3Hook(aws_conn_id='aws_default')
            csv_buffer = df.to_csv(index=False)
            s3_hook.load_string(
                string_data=csv_buffer,
                key=f'raw/orders/{execution_date}/orders.csv',
                bucket_name='data-lake',
                replace=True
            )

            return df.shape[0]

        def extract_products(**context):
            """상품 데이터 추출"""
            pg_hook = PostgresHook(postgres_conn_id='source_db')

            df = pg_hook.get_pandas_df("""
                SELECT id, name, category, brand, price
                FROM products
                WHERE is_active = true
            """)

            s3_hook = S3Hook(aws_conn_id='aws_default')
            csv_buffer = df.to_csv(index=False)
            s3_hook.load_string(
                string_data=csv_buffer,
                key='reference/products/products.csv',
                bucket_name='data-lake',
                replace=True
            )

            return df.shape[0]

        extract_orders_task = PythonOperator(
            task_id='extract_orders',
            python_callable=extract_orders,
        )

        extract_products_task = PythonOperator(
            task_id='extract_products',
            python_callable=extract_products,
        )

    # ========== Transform Tasks ==========
    with TaskGroup('transform') as transform_group:

        def transform_sales(**context):
            """매출 데이터 변환"""
            execution_date = context['ds']

            s3_hook = S3Hook(aws_conn_id='aws_default')

            # 데이터 로드
            orders_content = s3_hook.read_key(
                key=f'raw/orders/{execution_date}/orders.csv',
                bucket_name='data-lake'
            )
            products_content = s3_hook.read_key(
                key='reference/products/products.csv',
                bucket_name='data-lake'
            )

            import io
            orders_df = pd.read_csv(io.StringIO(orders_content))
            products_df = pd.read_csv(io.StringIO(products_content))

            # 변환
            # 1. 상품 정보 조인
            sales_df = orders_df.merge(
                products_df[['id', 'category', 'brand']],
                left_on='product_id',
                right_on='id',
                how='left'
            )

            # 2. 집계
            daily_sales = sales_df.groupby(['category', 'brand']).agg({
                'order_number': 'nunique',
                'quantity': 'sum',
                'unit_price': lambda x: (x * sales_df.loc[x.index, 'quantity']).sum()
            }).reset_index()

            daily_sales.columns = ['category', 'brand', 'order_count', 'units_sold', 'revenue']
            daily_sales['date'] = execution_date

            # 저장
            parquet_buffer = daily_sales.to_parquet(index=False)
            s3_hook.load_bytes(
                bytes_data=parquet_buffer,
                key=f'transformed/daily_sales/{execution_date}/sales.parquet',
                bucket_name='data-lake',
                replace=True
            )

            return daily_sales.shape[0]

        def calculate_metrics(**context):
            """KPI 메트릭 계산"""
            execution_date = context['ds']

            s3_hook = S3Hook(aws_conn_id='aws_default')

            orders_content = s3_hook.read_key(
                key=f'raw/orders/{execution_date}/orders.csv',
                bucket_name='data-lake'
            )

            import io
            orders_df = pd.read_csv(io.StringIO(orders_content))

            metrics = {
                'date': execution_date,
                'total_orders': orders_df['order_number'].nunique(),
                'total_revenue': float(orders_df['unit_price'].sum() * orders_df['quantity'].sum()),
                'unique_customers': orders_df['customer_id'].nunique(),
                'avg_order_value': float(orders_df.groupby('order_number')['total_amount'].first().mean()),
            }

            # JSON으로 저장
            import json
            s3_hook.load_string(
                string_data=json.dumps(metrics),
                key=f'metrics/daily/{execution_date}/metrics.json',
                bucket_name='data-lake',
                replace=True
            )

            return metrics

        transform_sales_task = PythonOperator(
            task_id='transform_sales',
            python_callable=transform_sales,
        )

        calculate_metrics_task = PythonOperator(
            task_id='calculate_metrics',
            python_callable=calculate_metrics,
        )

    # ========== Load Tasks ==========
    with TaskGroup('load') as load_group:

        def load_to_warehouse(**context):
            """데이터 웨어하우스에 로드"""
            execution_date = context['ds']

            # Redshift COPY
            redshift_hook = PostgresHook(postgres_conn_id='redshift')

            redshift_hook.run(f"""
                COPY fact_daily_sales
                FROM 's3://data-lake/transformed/daily_sales/{execution_date}/'
                IAM_ROLE 'arn:aws:iam::123456789:role/RedshiftS3Role'
                FORMAT AS PARQUET;
            """)

        load_warehouse_task = PythonOperator(
            task_id='load_to_warehouse',
            python_callable=load_to_warehouse,
        )

    # ========== Quality Tasks ==========
    with TaskGroup('quality') as quality_group:

        def check_data_quality(**context):
            """데이터 품질 검증"""
            execution_date = context['ds']

            redshift_hook = PostgresHook(postgres_conn_id='redshift')

            # 품질 검사
            checks = [
                # Row count check
                {
                    'name': 'row_count',
                    'query': f"""
                        SELECT COUNT(*) as cnt
                        FROM fact_daily_sales
                        WHERE date = '{execution_date}'
                    """,
                    'check': lambda x: x > 0,
                },
                # Null check
                {
                    'name': 'null_revenue',
                    'query': f"""
                        SELECT COUNT(*) as cnt
                        FROM fact_daily_sales
                        WHERE date = '{execution_date}' AND revenue IS NULL
                    """,
                    'check': lambda x: x == 0,
                },
                # Duplicate check
                {
                    'name': 'duplicates',
                    'query': f"""
                        SELECT COUNT(*) - COUNT(DISTINCT category || brand) as cnt
                        FROM fact_daily_sales
                        WHERE date = '{execution_date}'
                    """,
                    'check': lambda x: x == 0,
                },
            ]

            failed_checks = []
            for check in checks:
                result = redshift_hook.get_first(check['query'])[0]
                if not check['check'](result):
                    failed_checks.append(f"{check['name']}: {result}")

            if failed_checks:
                raise ValueError(f"Data quality checks failed: {', '.join(failed_checks)}")

            return 'All checks passed'

        quality_check_task = PythonOperator(
            task_id='check_data_quality',
            python_callable=check_data_quality,
        )

    # ========== Notification ==========
    def send_completion_notification(**context):
        """완료 알림"""
        execution_date = context['ds']
        ti = context['ti']

        metrics = ti.xcom_pull(task_ids='transform.calculate_metrics')

        # Slack 알림
        from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook

        slack_hook = SlackWebhookHook(slack_webhook_conn_id='slack_webhook')
        slack_hook.send_text(f"""
:white_check_mark: Daily Sales ETL Completed

*Date:* {execution_date}
*Total Orders:* {metrics['total_orders']:,}
*Total Revenue:* ${metrics['total_revenue']:,.2f}
*Unique Customers:* {metrics['unique_customers']:,}
*Avg Order Value:* ${metrics['avg_order_value']:.2f}
        """)

    notify_task = PythonOperator(
        task_id='send_notification',
        python_callable=send_completion_notification,
        trigger_rule='all_success',
    )

    # ========== Dependencies ==========
    extract_group >> transform_group >> load_group >> quality_group >> notify_task
```

## 스트림 처리 (Flink)

```python
# streaming/flink_job.py
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings
from pyflink.table.expressions import col

def create_sales_streaming_job():
    # 환경 설정
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(4)

    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, settings)

    # Kafka Source
    t_env.execute_sql("""
        CREATE TABLE orders_source (
            order_id STRING,
            customer_id STRING,
            product_id STRING,
            quantity INT,
            unit_price DECIMAL(10, 2),
            order_time TIMESTAMP(3),
            WATERMARK FOR order_time AS order_time - INTERVAL '5' SECOND
        ) WITH (
            'connector' = 'kafka',
            'topic' = 'orders',
            'properties.bootstrap.servers' = 'kafka:9092',
            'properties.group.id' = 'flink-consumer',
            'format' = 'json',
            'scan.startup.mode' = 'latest-offset'
        )
    """)

    # 실시간 집계
    t_env.execute_sql("""
        CREATE TABLE sales_aggregates_sink (
            window_start TIMESTAMP(3),
            window_end TIMESTAMP(3),
            total_orders BIGINT,
            total_revenue DECIMAL(12, 2),
            unique_customers BIGINT,
            PRIMARY KEY (window_start, window_end) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = 'jdbc:postgresql://postgres:5432/analytics',
            'table-name' = 'realtime_sales_aggregates',
            'username' = 'analytics',
            'password' = '${POSTGRES_PASSWORD}'
        )
    """)

    # 5분 윈도우 집계
    t_env.execute_sql("""
        INSERT INTO sales_aggregates_sink
        SELECT
            TUMBLE_START(order_time, INTERVAL '5' MINUTE) as window_start,
            TUMBLE_END(order_time, INTERVAL '5' MINUTE) as window_end,
            COUNT(DISTINCT order_id) as total_orders,
            SUM(quantity * unit_price) as total_revenue,
            COUNT(DISTINCT customer_id) as unique_customers
        FROM orders_source
        GROUP BY TUMBLE(order_time, INTERVAL '5' MINUTE)
    """)

if __name__ == '__main__':
    create_sales_streaming_job()
```

## 데이터 품질 프레임워크

```python
# quality/data_quality.py
from great_expectations.core import ExpectationSuite
from great_expectations.dataset import PandasDataset
import pandas as pd
from typing import List, Dict

class DataQualityChecker:
    def __init__(self, df: pd.DataFrame):
        self.dataset = PandasDataset(df)
        self.results = []

    def expect_column_not_null(self, column: str) -> 'DataQualityChecker':
        result = self.dataset.expect_column_values_to_not_be_null(column)
        self.results.append(result)
        return self

    def expect_column_unique(self, column: str) -> 'DataQualityChecker':
        result = self.dataset.expect_column_values_to_be_unique(column)
        self.results.append(result)
        return self

    def expect_column_in_range(
        self, column: str, min_val: float, max_val: float
    ) -> 'DataQualityChecker':
        result = self.dataset.expect_column_values_to_be_between(
            column, min_value=min_val, max_value=max_val
        )
        self.results.append(result)
        return self

    def expect_column_in_set(
        self, column: str, value_set: List
    ) -> 'DataQualityChecker':
        result = self.dataset.expect_column_values_to_be_in_set(
            column, value_set=value_set
        )
        self.results.append(result)
        return self

    def expect_table_row_count_between(
        self, min_count: int, max_count: int
    ) -> 'DataQualityChecker':
        result = self.dataset.expect_table_row_count_to_be_between(
            min_value=min_count, max_value=max_count
        )
        self.results.append(result)
        return self

    def validate(self) -> Dict:
        success_count = sum(1 for r in self.results if r.success)
        total_count = len(self.results)

        return {
            'success': all(r.success for r in self.results),
            'success_rate': success_count / total_count if total_count > 0 else 0,
            'total_checks': total_count,
            'passed_checks': success_count,
            'failed_checks': [
                {
                    'expectation': r.expectation_config.expectation_type,
                    'kwargs': r.expectation_config.kwargs,
                    'result': r.result
                }
                for r in self.results if not r.success
            ]
        }

# 사용 예시
def validate_orders_data(df: pd.DataFrame) -> Dict:
    checker = DataQualityChecker(df)

    result = (
        checker
        .expect_column_not_null('order_id')
        .expect_column_unique('order_id')
        .expect_column_not_null('customer_id')
        .expect_column_in_range('total_amount', 0, 1000000)
        .expect_column_in_set('status', ['pending', 'completed', 'cancelled'])
        .expect_table_row_count_between(1, 10000000)
        .validate()
    )

    return result
```

## 사용 예시
**입력**: "일일 매출 데이터 ETL 파이프라인 구축해줘"

**출력**:
1. Airflow DAG
2. Extract/Transform/Load 태스크
3. 데이터 품질 검증
4. 알림 설정
