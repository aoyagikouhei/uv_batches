DROP TYPE IF EXISTS type_uv_set_update_batch_for_start CASCADE;
CREATE TYPE type_uv_set_update_batch_for_start AS (
  batch_uuid UUID
  ,batch_start_at TIMESTAMP
  ,batch_end_at TIMESTAMP
  ,activity_json JSONB
);

-- バッチを開始する
-- 引数
--   p_batch_kbn : バッチ区分
--   p_now : 現在時刻
--   p_pg : プログラム名
--   p_operator_uuid : 実行者UUID
-- 戻り値
--   batch_uuid : バッチUUID
--   batch_start_at : 以前のバッチ開始日時(デバッグ用)
--   batch_end_at : 以前のバッチ終了日時(デバッグ用)
--   activity_json : 動作しているSQL一覧(デバッグ用)
-- 例外
CREATE OR REPLACE FUNCTION uv_set_update_batch_for_start(
  p_batch_kbn TEXT DEFAULT NULL
  ,p_now TIMESTAMP DEFAULT NULL
  ,p_pg TEXT DEFAULT NULL
  ,p_operator_uuid UUID DEFAULT NULL
) RETURNS SETOF type_uv_set_update_batch_for_start AS $FUNCTION$
DECLARE
  w_now TIMESTAMP := COALESCE(p_now, NOW());
  w_pg TEXT := COALESCE(p_pg, 'uv_set_update_batch_for_start');
  w_batch RECORD;
  w_activity_json JSONB;
BEGIN
  -- パラメーターチェック
  IF p_batch_kbn IS NULL OR '' = p_batch_kbn THEN
    RAISE SQLSTATE 'U0002' USING MESSAGE = 'p_batch_kbn is null';
  END IF;

  -- 有効なバッチレコードを取得する
  SELECT
    t1.uuid
    ,t1.batch_start_at
    ,t1.batch_end_at
  INTO
    w_batch
  FROM
    public.batches AS t1
  WHERE
    -- バッチ区分が一致している
    t1.batch_kbn = p_batch_kbn
    AND (
      -- 開始されていない
      t1.batch_start_at IS NULL

      OR (
        -- 完了している
        t1.batch_start_at < t1.batch_end_at

        -- 完了して一定期間経過した
        AND t1.batch_end_at < w_now - (t1.batch_second_count || 'second')::interval
      )

      OR (
        -- 完了していない
        (
          t1.batch_end_at IS NULL 
          OR t1.batch_start_at > t1.batch_end_at
        )

        -- 開始してから規定時間を超えてしまった。
        AND t1.batch_start_at < w_now - (t1.batch_recoverly_second_count || 'second')::interval
      )
    )
  LIMIT
    1
  ;

  -- 存在しなければ終了
  IF w_batch.uuid IS NULL THEN
    RETURN;
  END IF;

  -- バッチの更新
  UPDATE batches SET
    batch_start_at = w_now
    ,updated_at = w_now
    ,updated_uuid = p_operator_uuid
    ,updated_pg = w_pg
  WHERE
    uuid = w_batch.uuid
    AND (
      batch_start_at IS NULL
      OR batch_start_at = w_batch.batch_start_at
    )
  ;

  -- 更新チェック
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- リカバリーチェック
  IF 
    w_batch.batch_start_at IS NOT NULL
    AND (
      w_batch.batch_end_at IS NULL 
      OR w_batch.batch_start_at > w_batch.batch_end_at
    )
  THEN
    -- 実行中のSQL回収
    SELECT 
      json_agg(row_to_json(pg_stat_activity))
    INTO
      w_activity_json
    FROM 
      pg_stat_activity 
    WHERE
      state <> 'idle'
    ;
  END IF;

  RETURN QUERY SELECT
    w_batch.uuid
    ,w_batch.batch_start_at
    ,w_batch.batch_end_at
    ,w_activity_json
  ;
END;
$FUNCTION$ LANGUAGE plpgsql;
