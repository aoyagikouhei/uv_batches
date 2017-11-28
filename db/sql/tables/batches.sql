DROP TABLE IF EXISTS source.batches CASCADE;

CREATE TABLE source.batches (
  uuid UUID NOT NULL DEFAULT gen_random_uuid()
  ,batch_kbn TEXT NOT NULL DEFAULT ''
  ,batch_start_at TIMESTAMP
  ,batch_end_at TIMESTAMP
  ,batch_second_count BIGINT NOT NULL DEFAULT 0
  ,batch_recoverly_second_count BIGINT NOT NULL DEFAULT 0
  ,created_uuid UUID
  ,updated_uuid UUID
  ,deleted_uuid UUID
  ,created_at TIMESTAMP NOT NULL DEFAULT NOW()
  ,updated_at TIMESTAMP NOT NULL DEFAULT NOW()
  ,deleted_at TIMESTAMP
  ,created_pg TEXT NOT NULL DEFAULT ''
  ,updated_pg TEXT NOT NULL DEFAULT ''
  ,deleted_pg TEXT NOT NULL DEFAULT ''
  ,bk TEXT
  ,PRIMARY KEY(uuid)
);

CREATE UNIQUE INDEX idx_batches_batch_kbn ON source.batches(batch_kbn);

CREATE TABLE public.batches (
  LIKE source.batches INCLUDING ALL
) INHERITS (source.batches);


CREATE TABLE garbage.batches (
  LIKE source.batches INCLUDING ALL
) INHERITS (source.batches);
