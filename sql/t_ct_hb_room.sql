/*
 Navicat Premium Data Transfer

 Source Server         : 127.0.0.1
 Source Server Type    : MySQL
 Source Server Version : 50720
 Source Host           : localhost
 Source Database       : v2game

 Target Server Type    : MySQL
 Target Server Version : 50720
 File Encoding         : utf-8

 Date: 12/16/2017 00:51:56 AM
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `t_ct_hb_room`
-- ----------------------------
DROP TABLE IF EXISTS `t_ct_hb_room`;
CREATE TABLE `t_ct_hb_room` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `room_id` varchar(64) COLLATE utf8_bin NOT NULL COMMENT '房间号',
  `round_id` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '1' COMMENT '局数ID',
  `round_num` int(6) NOT NULL DEFAULT '1' COMMENT '局数',
  `time` bigint(20) NOT NULL DEFAULT '0' COMMENT '结算时间',
  `banker_id` bigint(10) NOT NULL DEFAULT '0' COMMENT '庄家ID',
  `room_freeze_golden` float(3,0) NOT NULL DEFAULT '0' COMMENT '房间冻结钻石',
  `step` int(1) NOT NULL DEFAULT '0' COMMENT '进行到的步骤',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

SET FOREIGN_KEY_CHECKS = 1;
