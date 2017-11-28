INSERT INTO public.batches (
  batch_kbn
  ,batch_second_count -- この秒差で実行された場合無視する
  ,batch_recoverly_second_count -- タイムアウト時間
) VALUES 
  ('00101', 60, 200) -- 日次バッチ
  ,('00102', 60, 3600) -- 月次バッチ
;