# Wsustainable
`現在プレビュー版として公開しているため、全機能は実装されていません。また、仕様を大きく変更する可能性があるため、本番環境に組み込まないでください。`
このツールは、選択したサーバー上に既に構成されている WSUS (Windows Server Update Services サービス) における更新プログラムの拒否を自動化するためのツールです。

# 事前に必要な作業
事前に WSUS をインストール、構成してください。(https://jpmem.github.io/blog/wsus/2023-02-16_01/)

- 製品: クライアントで使用している製品のみ選択する (https://qiita.com/rin309/items/7872d2772f02c4eb33a6)
- 分類: ドライバー、ドライバーセット以外の使用する項目を選択する (https://jpmem.github.io/blog/wsus/2018-06-19_01/)
- 言語: 日本語、英語
- 同期スケジュール: 自動
- 自動承認: 必要に応じて構成してください (自動承認を有効にすると、スクリプト動作までの間、不要な更新プログラムが承認された状態となります)

# インストールと使い方
- https://github.com/rin309/Wsustainable/wiki/Install
- https://github.com/rin309/Wsustainable/wiki/HowToUse

# 想定している動作環境 (テストをした環境ではありません。自己責任にてお願いします。)
- Windows Server 2019
- Windows Server 2022
- Windows Server 2025
