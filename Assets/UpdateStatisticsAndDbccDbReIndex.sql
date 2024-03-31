/*

https://jpmem.github.io/blog/wsus/2022-05-09_01/
*/

-- 統計情報の更新クエリ
Use [SUSDB]
Exec sp_msforeachtable 'update statistics ? with fullscan'
Go

-- インデックスの再構築
Use [SUSDB]
Exec sp_MSForEachtable 'DBCC DBREINDEX (''?'')'
Go