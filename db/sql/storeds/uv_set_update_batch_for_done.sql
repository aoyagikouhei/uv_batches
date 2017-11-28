DROP TYPE IF EXISTS type_uv_set_update_batch_for_done CASCADE;
CREATE TYPE type_uv_set_update_batch_for_done AS (
  batch_uuid UUID
);

-- バッチを終了用に更新する
-- 引数
--   p_batch_uuid : バッチUUID
--   p_now : 現在時刻
--   p_pg : プログラム名
--   p_operator_uuid : 実行者UUID
-- 戻り値
--   batch_id : バッチID
-- 例外
CREATE OR REPLACE FUNCTION uv_set_update_batch_for_done(
  p_batch_uuid UUID DEFAULT NULL
  ,p_now TIMESTAMP DEFAULT NULL
  ,p_pg TEXT DEFAULT NULL
  ,p_operator_uuid UUID DEFAULT NULL
) RETURNS SETOF type_uv_set_update_batch_for_done AS $FUNCTION$
DECLARE
  w_now TIMESTAMP := COALESCE(p_now, NOW());
  w_pg TEXT := COALESCE(p_pg, 'uv_set_update_batch_for_done');
  w_batch RECORD;
  w_activity_json JSONB;
BEGIN
  -- パラメーターチェック
  IF p_batch_uuid IS NULL THEN
    RAISE SQLSTATE 'U0002' USING MESSAGE = 'p_batch_uuid is null';
  END IF;
  
  RETURN QUERY
  UPDATE public.batches SET
    batch_end_at = w_now
    ,updated_at = w_now
    ,updated_uuid = p_operator_uuid
    ,updated_pg = w_pg
  WHERE
    uuid = p_batch_uuid
  RETURNING
    uuid
  ;
END;
$FUNCTION$ LANGUAGE plpgsql;
