namespace :batches do
  BATCH_KBN_DAILY = '00101'
  BATCH_KBN_MONTHLY = '00102'

  # バッチの開始
  def start_batch(batch_kbn)
    # バッチ実行
    data = ::Batch.start_batch(batch_kbn)

    # 取得できない場合は他のプロセスが実行したので終了
    return nil if data.blank?

    # バッチリカバリー発動チェック
    if data.activity_json.present?
      # バッチリカバリーを通知する。ここではログ
      content = <<-TXT
batch_kbn = #{batch_kbn}
batch_start_at = #{data.batch_start_at}
batch_end_at = #{data.batch_end_at}
#{data.activity_json.map {|x| JSON.pretty_generate(x)}.join("\n")}
      TXT
      Rails.logger.warn(content)
    end

    data.batch_uuid
  end

  # バッチが実行可能ならブロックを実行する
  def execute_batch(batch_kbn)
    # バッチ開始
    batch_uuid = start_batch(batch_kbn)

    # 取得できない場合は他のプロセスが実行したので終了
    return nil if batch_uuid.blank?

    # ブロックを実行
    result = yield

    # バッチの完了をDBに保存
    ::Batch.end_batch(batch_uuid)
    result
  end

  # bundle exec rails batches:daily
  desc "daily batch"
  task daily: :environment do
    execute_batch(BATCH_KBN_DAILY) do
      Rails.logger.debug("daily batch execute!")
    end
  end

  # bundle exec rails batches:monthly
  desc "monthly batch"
  task monthly: :environment do
    execute_batch(BATCH_KBN_MONTHLY) do
      Rails.logger.debug("monthly batch execute!")
    end
  end
end
