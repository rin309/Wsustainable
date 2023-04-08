# Wsustainable
このツールは、選択したサーバー上に既に構成されている WSUS (Windows Server Update Services サービス) における更新プログラムの拒否を自動化するためのツールです。
現在プレビュー版として公開しているため、全機能は実装されていません。
仕様を大きく変更する可能性があるため、本番環境に組み込まないでください。
また、プレビュー中の仕様変更はバージョンの更新では実装しないため、本ページの導入手順を参照してください。



# 事前に必要な作業
事前に WSUS をインストール、構成してください。(https://jpmem.github.io/blog/wsus/2023-02-16_01/)

- 製品: クライアントで使用している製品のみ選択する (https://qiita.com/rin309/items/7872d2772f02c4eb33a6)
- 分類: ドライバー、ドライバーセット以外の使用する項目を選択する (https://jpmem.github.io/blog/wsus/2018-06-19_01/)
- 言語: 日本語、英語
- 同期スケジュール: 自動
- 自動承認: 必要に応じて構成してください (自動承認を有効にすると、スクリプト動作までの間にタイムラグが発生します)


# 使い方
1. サーバーに ManagementMsOfficeDeploymentToolShare を AllUser にインストールします
2. PowerShell を管理者として実行し、下記コマンドを実行します
`Show-WsustainableSettings`
3. 必要なコンポーネントを選択して `インストール` をクリックします
![WSUSサーバー向け追加コンポーネント](https://user-images.githubusercontent.com/760251/230725560-7cb1b45b-65e2-405b-ab38-63b796c2999e.png)
4. `実行` をクリックし、`接続できました` と表示されたことを確認してから `次へ` をクリックします
![WSUSサーバーの選択](https://user-images.githubusercontent.com/760251/230725567-13e884ba-f23b-492e-a1b9-48d89a65eaf9.png)
5. 現在の設定値を上書きします。問題が無ければ `次へ` をクリックします
![WSUS向けのチューニング](https://user-images.githubusercontent.com/760251/230725571-750fd92b-98ff-40eb-9abb-d74209cba58b.png)
6. 必要に応じて選択してから `次へ` をクリックします
![残す更新プログラムの選択](https://user-images.githubusercontent.com/760251/230725575-79bf9749-0c7c-4468-9386-4dea9f41b228.png)
7. 必要に応じて選択してから `次へ` をクリックします
![更新プログラムを拒否する条件](https://user-images.githubusercontent.com/760251/230725599-a1d62784-31e9-4dab-a746-b3d2a690c4ce.png)
8. 必要に応じて選択してから `次へ` をクリックします (WSUSの同期スケジュール完了後に動作するようにしてください)
![実行スケジュール](https://user-images.githubusercontent.com/760251/230725616-d22fbeb7-1ad2-4023-b91d-46734511e11f.png)


# ログの確認
下記フォルダーに保存されます。
C:\ProgramData\Wsustainable\0.1\Logs\


# 実行アカウント
ログインしていない状態でも実行させるために SYSTEM ユーザーを指定していますが、下記の理由で変更されたい場合もあると思われます。
  
- 動作しないため、エラー画面を表示させたい
- プロキシなどのネットワーク環境要因によって、ユーザーを指定したい
- 動作する権限を最小限にするため、ユーザーを指定したい
  
このスクリプトでは、実行権限・フォルダーやネットワークへのアクセス権限に問題が無ければ実行できると考えております。  
必要に応じて、ユーザーの変更はタスクスケジューラーから行ってください。  
![Optimize-WsusContents のプロパティ (ローカル コンピューター)](https://user-images.githubusercontent.com/760251/230722128-428d6ed1-ae26-48ee-8892-dc52784ae8ee.png)
