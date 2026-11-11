# カンファイン

2011~12年ごろに一部高専カンファレンスで使われていた(と思われる)アプリケーションのリポジトリです。
- Dockerfile
- docker-compose.yml
- database.yml
- .env.template
を追加しています。

## 利用上の注意

Dockerfileなどでレガシー環境に対応できるようにしていますが、あくまで個人利用を前提として作成されています。
依存関係などが非常に古く、アーカイブサイトを用いるなどして成り立っているほか、例えばRuby on Rails v3.2.17には第三者により、レンダリングメソッドを無制限に使用するアプリケーションを利用されることで、任意の Ruby コードを実行される脆弱性があります。

(参考サイト)[https://jvndb.jvn.jp/ja/contents/2016/JVNDB-2016-001980.html]

本番環境で使用する場合は、依存関係の更新を行った上で使用することをおすすめします。

## 使い方

```
docker-compose up --build
```

メール送信機能を利用する場合は、`.env.template`ファイルを元にして環境変数を設定してください。

## Required signing secret (legacy master branch)

Before starting this legacy branch, copy `.env.template` to `.env` and set
`SECRET_TOKEN` to a new, unique random value. For example, generate one locally:

```sh
ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
```

Keep the generated value private. Docker Compose passes `SECRET_TOKEN` from `.env`
to the web container. When running Rails directly, export it in the process
environment first. Startup fails if it is missing or shorter than 30 characters.
Never commit `.env` or reuse the old signing secret from Git history.

The previously hard-coded signing secret originated upstream and remains public
in repository history and other copies. Removing it from this branch does not
revoke it. Any deployment that used that value must replace it; changing the
signing secret invalidates previously signed cookies. This fix does not make the
legacy Rails dependencies safe for production; upgrade them before deployment.
