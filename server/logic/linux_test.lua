
--[[
	登录测试环境 外网  内网
]]

ssh -p 2202 root@103.192.253.83 -- 登录测试服务器
7WjoMHnJnmBBtpNxEjwpjbqjukKktxuc -- 密码
scp /root/test/v2game1219.sql root@10.1.2.1:/root/software/  -- 拷贝sql文件到内网服务器
ssh root@10.1.2.1 -- 登录内网服务器
www.123.com -- 密码
-- 进入mysql，导入表
mysql -uroot -p 
root
drop database v2game;
show databases;
create database v2game;
show databases;
use v2game;
set names utf8mb4;
source /root/software/v2game1219.sql
show tables;


-- crontab定时器
命令：crontab -e
输入：* * * * * curl -H "Content-Type: application/json" -X POST  --data '{"msg_id":"request_return_daily_rebate"}' http://127.0.0.1:8781/chaotu

-- 修改更新包下载版本号
http://127.0.0.1:8781/chaotu?msg_id=uptate_version&version=3
