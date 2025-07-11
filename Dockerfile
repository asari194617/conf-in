# 1. ベースとなるOSとRubyのバージョンを指定
FROM ruby:1.9.3-p551

# 2. パッケージ取得先をアーカイブサイトに固定し、GPGキーの期限切れを無視してライブラリをインストール
RUN echo "deb http://archive.debian.org/debian/ jessie main" > /etc/apt/sources.list \
    && apt-get update -o Acquire::Check-Valid-Until=false -qq \
    && apt-get install -y --force-yes build-essential libmysqlclient-dev nodejs

# 3. アプリケーションを配置するディレクトリを作成
WORKDIR /usr/src/app

# 4. Gemfileをコピーして、bundle installを実行
COPY Gemfile* ./
RUN bundle install

# 5. プロジェクトの全ファイルをコンテナにコピー
COPY . .

# 6. Railsサーバーを起動する設定
CMD ["rails", "server", "-b", "0.0.0.0"]
