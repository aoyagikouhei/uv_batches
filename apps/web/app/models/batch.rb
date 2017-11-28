class Batch < ApplicationRecord
  class << self
    def start_batch(batch_kbn)
      sql = <<-SQL
        SELECT
          t1.batch_uuid
          ,t1.batch_start_at
          ,t1.batch_end_at
          ,t1.activity_json
        FROM uv_set_update_batch_for_start(
          p_batch_kbn := :batch_kbn
        ) AS t1
      SQL
      list = find_by_sql([sql, batch_kbn: batch_kbn])
      list.blank? ? nil : list.first
    end

    def end_batch(batch_uuid)
      sql = <<-SQL
        SELECT
          t1.batch_uuid
        FROM uv_set_update_batch_for_done(
          p_batch_uuid := :batch_uuid
        ) AS t1
      SQL
      find_by_sql([sql, batch_uuid: batch_uuid])
    end
  end
end
