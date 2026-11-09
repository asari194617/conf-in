# カンファイン

高専カンファレンスなどのイベント向けの参加登録・受付アプリです。イベント作成、参加申込、QR コードでの当日受付、参加者一覧の CSV 出力、一斉メール送信に対応しています。

## ローカル起動

Ruby のバージョンは `.ruby-version`、Bundler と gem のバージョンは `Gemfile.lock` を参照してください。標準のローカル構成は SQLite です。

```sh
gem install bundler -v 4.0.24
BUNDLE_WITHOUT=mysql bundle install
BUNDLE_WITHOUT=mysql bin/rails db:prepare
BUNDLE_WITHOUT=mysql bin/rails server
```

[http://localhost:3000](http://localhost:3000) を開きます。パスワード再設定や参加申込などで送信されるメールは、SMTP 未設定なら `tmp/mail/` に保存されます。

```sh
BUNDLE_WITHOUT=mysql bin/rails test
```

テストは既定で `db/test.sqlite3` を使います。別のテスト用 DB を使う場合は `TEST_DATABASE_URL` を設定します。

## Docker Compose

Docker Compose は MySQL 9.7 LTS を使います。アプリ用 DB は起動時に準備されます。

```sh
docker compose up --build
```

[http://localhost:3000](http://localhost:3000) を開きます。SMTP 未設定時のメールは `docker compose exec web ls tmp/mail` で確認できます。MySQL のデータは `mysql_data` ボリュームに保存されます。

## メールと本番設定

Gmail 経由で配信する場合は `.env.template` を `.env` にコピーし、`GMAIL_USER` と `GMAIL_PASSWORD`（Google のアプリ パスワード）を設定してください。Compose は `.env` を自動で読み込みます。Docker を使わない場合は、Rails を起動するシェルで `set -a; source .env; set +a` を実行してください。

メールに含まれるリンクの URL は `APP_HOST`（必要ならポートを含む）と `APP_PROTOCOL` で指定できます。本番環境では `RAILS_ENV=production`、`SECRET_KEY_BASE`、公開 URL、メール設定を指定し、`bin/rails assets:precompile` を実行してください。MySQL を使う場合は `DATABASE_URL` を設定し、`mysql` グループを含めてインストールします。

## 旧版からの移行

旧版の SQLite データを引き継ぐ場合は、DB をバックアップしてから既存の DB に対して `bin/rails db:prepare` を実行します。MySQL 5.6 を使っていた場合は、旧データディレクトリを新しいコンテナに直接マウントせず、SQL ダンプを新しい DB に復元してから `bin/rails db:prepare` を実行します。更新後は再ログインが必要です。
