
DROP TABLE IF EXISTS `d_club`;
CREATE TABLE `d_club` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `creater` int(11) DEFAULT '0' COMMENT '创始人ID',
  `imgid` int(3) DEFAULT '0' COMMENT '图片id',
  `name` varchar(50) DEFAULT '' COMMENT '俱乐部名称',
  `areaid` int(11) DEFAULT '0',
  `member_count` int(11) DEFAULT '1' COMMENT '成员数',
  `max_member_count` int(11) DEFAULT '200' COMMENT '最大成员数',
  `fund` int(11) DEFAULT '0' COMMENT '基金',
  `intro` varchar(255) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '介绍',
  `addtime` datetime DEFAULT NULL COMMENT '俱乐部创建时间',
  `status` int(2) DEFAULT '0' COMMENT '俱乐部状态（0：正常，-1：解散）',
  `__version` int(11) DEFAULT '0' COMMENT '版本号，用于防止异步数据',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_club_apply
-- ----------------------------
DROP TABLE IF EXISTS `d_club_apply`;
CREATE TABLE `d_club_apply` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) DEFAULT '0' COMMENT '申请人UID',
  `clubid` int(11) DEFAULT '0' COMMENT '俱乐部ID',
  `msg` varchar(255) DEFAULT '' COMMENT '验证申请描述',
  `status` int(2) DEFAULT '0' COMMENT '申请状态（0：申请t提交，1：申请通过 ，-1：驳回，-10：驳回并不接收申请）',
  `addtime` datetime DEFAULT NULL COMMENT '申请时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_club_fundrecord
-- ----------------------------
DROP TABLE IF EXISTS `d_club_fundrecord`;
CREATE TABLE `d_club_fundrecord` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clubid` int(11) DEFAULT '0' COMMENT '俱乐部ID',
  `uid` int(11) DEFAULT '0' COMMENT '补充基金玩家ID',
  `fund` int(11) DEFAULT '0' COMMENT '充值基金数量',
  `addtime` datetime DEFAULT NULL COMMENT '充值基金时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_club_member
-- ----------------------------
DROP TABLE IF EXISTS `d_club_member`;
CREATE TABLE `d_club_member` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clubid` int(11) DEFAULT '0' COMMENT '俱乐部ID',
  `uid` int(11) DEFAULT '0' COMMENT '用户ID',
  `maxmsgid` int(11) DEFAULT '0' COMMENT '最大俱乐部消息ID',
  `roletype` int(2) DEFAULT '0' COMMENT '成员角色类型(100:创建者，10:管理员，1：高级会员，0：普通会员）',
  `addtime` datetime DEFAULT NULL COMMENT '添加成员时间',
  `maxapplymsgid` int(11) DEFAULT '0' COMMENT '最大俱乐部申请消息ID',
  `status` int(2) DEFAULT '0' COMMENT '成员状态（0：正常，-1：开除）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_club_msg
-- ----------------------------
DROP TABLE IF EXISTS `d_club_msg`;
CREATE TABLE `d_club_msg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clubid` int(11) DEFAULT '0' COMMENT '俱乐部ID',
  `uid` int(11) NOT NULL DEFAULT '0' COMMENT '发送人员ID',
  `content` varchar(1024) NOT NULL DEFAULT '' COMMENT '消息内容',
  `addtime` datetime NOT NULL COMMENT '消息发送时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=273 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_club_verify
-- ----------------------------
DROP TABLE IF EXISTS `d_club_verify`;
CREATE TABLE `d_club_verify` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '俱乐部审核记录',
  `applyid` int(11) DEFAULT '0' COMMENT '申请ID',
  `uid` int(11) DEFAULT '0' COMMENT '审核人员id',
  `status` int(2) DEFAULT '0' COMMENT '审核状态（1：审核通过，-1：驳回，-10：驳回并屏蔽申请）',
  `addtime` varchar(20) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '申请时间',
  `msg` varchar(255) DEFAULT '' COMMENT '审核描述',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `c_area`;
CREATE TABLE `c_area` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `province_id` int(11) NOT NULL,
  `province` varchar(50) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '省份名称',
  `isspecial` int(11) DEFAULT '0' COMMENT '是否是直辖市',
  `sort` int(4) DEFAULT '0' COMMENT '排序',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of c_area
-- ----------------------------
INSERT INTO `c_area` VALUES ('1', '11', '北京市', '1', '1');
INSERT INTO `c_area` VALUES ('2', '12', '天津市', '1', '2');
INSERT INTO `c_area` VALUES ('3', '13', '河北省', '0', '65');
INSERT INTO `c_area` VALUES ('4', '14', '山西省', '0', '71');
INSERT INTO `c_area` VALUES ('5', '15', '内蒙古自治区', '0', '85');
INSERT INTO `c_area` VALUES ('6', '21', '辽宁省', '0', '73');
INSERT INTO `c_area` VALUES ('7', '22', '吉林省', '0', '75');
INSERT INTO `c_area` VALUES ('8', '23', '黑龙江省', '0', '81');
INSERT INTO `c_area` VALUES ('9', '31', '上海市', '1', '3');
INSERT INTO `c_area` VALUES ('10', '32', '江苏省', '0', '83');
INSERT INTO `c_area` VALUES ('11', '33', '浙江省', '0', '50');
INSERT INTO `c_area` VALUES ('12', '34', '安徽省', '0', '51');
INSERT INTO `c_area` VALUES ('13', '35', '福建省', '0', '52');
INSERT INTO `c_area` VALUES ('14', '36', '江西省', '0', '53');
INSERT INTO `c_area` VALUES ('15', '37', '山东省', '0', '55');
INSERT INTO `c_area` VALUES ('16', '41', '河南省', '0', '60');
INSERT INTO `c_area` VALUES ('17', '42', '湖北省', '0', '61');
INSERT INTO `c_area` VALUES ('18', '43', '湖南省', '0', '54');
INSERT INTO `c_area` VALUES ('19', '44', '广东省', '0', '62');
INSERT INTO `c_area` VALUES ('20', '45', '广西壮族自治区', '0', '90');
INSERT INTO `c_area` VALUES ('21', '46', '海南省', '0', '63');
INSERT INTO `c_area` VALUES ('22', '50', '重庆市', '1', '4');
INSERT INTO `c_area` VALUES ('23', '51', '四川省', '0', '64');
INSERT INTO `c_area` VALUES ('24', '52', '贵州省', '0', '70');
INSERT INTO `c_area` VALUES ('25', '53', '云南省', '0', '72');
INSERT INTO `c_area` VALUES ('26', '54', '西藏自治区', '0', '91');
INSERT INTO `c_area` VALUES ('27', '61', '陕西省', '0', '74');
INSERT INTO `c_area` VALUES ('28', '62', '甘肃省', '0', '80');
INSERT INTO `c_area` VALUES ('29', '63', '青海省', '0', '82');
INSERT INTO `c_area` VALUES ('30', '64', '宁夏回族自治区', '0', '92');
INSERT INTO `c_area` VALUES ('31', '65', '新疆维吾尔自治区', '0', '93');
INSERT INTO `c_area` VALUES ('34', '70', '香港', '1', '5');
INSERT INTO `c_area` VALUES ('35', '71', '澳门', '1', '6');
INSERT INTO `c_area` VALUES ('36', '80', '海外', '1', '7');
INSERT INTO `c_area` VALUES ('37', '81', '台湾', '0', '84');


ALTER TABLE `d_score` ADD COLUMN `clubid`  int(11) NULL DEFAULT 0 COMMENT '俱乐部ID' AFTER `id`;

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='5', `pkey`='authority_1', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='5');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\"],\"80\":[\"user_manager\",\"operateList\"],\"90\":[\"user_manager\",\"operateList\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');


ALTER TABLE `d_score` MODIFY COLUMN `roomid`  int(11) NOT NULL ;
ALTER TABLE `d_score` ADD COLUMN `roundid`  int(11) NOT NULL DEFAULT 0 AFTER `room_datetime`;

-- ----------------------------
-- Table structure for `d_version`
-- ----------------------------
DROP TABLE IF EXISTS `d_version`;
CREATE TABLE `d_version` (
  `version` int(11) NOT NULL,
  `url_head` varchar(256) DEFAULT NULL,
  `version_url` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of d_version
-- ----------------------------
INSERT INTO `d_version` VALUES ('2', 'http://119.23.248.196:8080/static/pack/poker_', 'http://119.23.248.196:8080/version_url?v=');

INSERT INTO `d_config` VALUES ('8', 'horserace', '请不要用于赌博~~~ 微信客服：xxxxx', '跑马灯', '2017-07-01 11:15:14');
INSERT INTO `d_config` VALUES ('9', 'room_round', '[12,20,30]', '开局数', '2017-08-01 11:15:14');
INSERT INTO `d_config` VALUES ('10', 'room_card', '{\"poker_4_13_12\":30, \"poker_4_13_20\":50, \"poker_4_13_30\":80,\r\n\"poker_3_17_12\":30, \"poker_3_17_20\":50, \"poker_3_17_30\":80,\r\n\"poker_5_13_12\":40, \"poker_5_13_20\":70, \"poker_5_13_30\":100,\r\n\"poker_6_13_12\":50, \"poker_6_13_20\":80, \"poker_6_13_30\":120,\r\n\"mahjong_4_13_12\":30, \"mahjong_4_13_20\":50, \"mahjong_4_13_30\":80, \r\n\"bullfight_4_5_12\":30, \"bullfight_4_5_20\":50, \"bullfight_4_5_30\":80,\r\n\"bullfight_5_5_12\":40, \"bullfight_5_5_20\":70, \"bullfight_5_5_30\":100,\r\n\"bullfight_6_5_12\":50, \"bullfight_6_5_20\":80, \"bullfight_6_5_30\":120}', '房卡配置', '2017-08-01 11:15:14');
INSERT INTO `d_config` VALUES ('11', 'channel', 'dyj', '渠道:dyj(大赢家)', '2017-08-01 11:15:14');

CREATE TABLE `d_score_log` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`uid`  int(11) NOT NULL ,
`score`  int(11) NOT NULL ,
`update_time`  datetime NOT NULL ,
`action`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`roomid`  int(11) NOT NULL DEFAULT 0 ,
`roundid`  int(11) NOT NULL DEFAULT 0 ,
`round`  int(11) NOT NULL DEFAULT 0 ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
ROW_FORMAT=Compact
;


INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('7', 'web_title', '后台管理系统', '网站标题', '2017-07-01 11:15:14');
INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('8', 'horserace', '请不要用于赌博~~~ 微信客服：xxxxx', '跑马灯', '2017-07-01 11:15:14');
INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('9', 'room_round', '[12,20,30]', '开局数', '2017-08-01 11:15:14');
INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('10', 'room_card', '{\"poker_4_13_12\":30, \"poker_4_13_20\":50, \"poker_4_13_30\":80,\r\n\"poker_3_17_12\":30, \"poker_3_17_20\":50, \"poker_3_17_30\":80,\r\n\"poker_5_13_12\":40, \"poker_5_13_20\":70, \"poker_5_13_30\":100,\r\n\"poker_6_13_12\":50, \"poker_6_13_20\":80, \"poker_6_13_30\":120,\r\n\"mahjong_4_13_12\":30, \"mahjong_4_13_20\":50, \"mahjong_4_13_30\":80, \r\n\"bullfight_4_5_12\":30, \"bullfight_4_5_20\":50, \"bullfight_4_5_30\":80,\r\n\"bullfight_5_5_12\":40, \"bullfight_5_5_20\":70, \"bullfight_5_5_30\":100,\r\n\"bullfight_6_5_12\":50, \"bullfight_6_5_20\":80, \"bullfight_6_5_30\":120}', '房卡配置', '2017-08-01 11:15:14');
INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('11', 'channel', 'dyj', '渠道:dyj(大赢家)', '2017-08-01 11:15:14');

UPDATE `d_config` SET `id`='7', `pkey`='web_title', `pvalue`='后台管理系统', `remark`='网站标题', `create_time`='2017-07-01 11:15:14' WHERE (`id`='7');
UPDATE `d_config` SET `id`='8', `pkey`='horserace', `pvalue`='请不要用于赌博~~~ 微信客服：xxxxx', `remark`='跑马灯', `create_time`='2017-07-01 11:15:14' WHERE (`id`='8');
UPDATE `d_config` SET `id`='9', `pkey`='room_round', `pvalue`='[12,20,30]', `remark`='开局数', `create_time`='2017-08-01 11:15:14' WHERE (`id`='9');
UPDATE `d_config` SET `id`='10', `pkey`='room_card', `pvalue`='{\"poker_4_13_12\":30, \"poker_4_13_20\":50, \"poker_4_13_30\":80,\r\n\"poker_3_17_12\":30, \"poker_3_17_20\":50, \"poker_3_17_30\":80,\r\n\"poker_5_13_12\":40, \"poker_5_13_20\":70, \"poker_5_13_30\":100,\r\n\"poker_6_13_12\":50, \"poker_6_13_20\":80, \"poker_6_13_30\":120,\r\n\"mahjong_4_13_12\":30, \"mahjong_4_13_20\":50, \"mahjong_4_13_30\":80, \r\n\"bullfight_4_5_12\":30, \"bullfight_4_5_20\":50, \"bullfight_4_5_30\":80,\r\n\"bullfight_5_5_12\":40, \"bullfight_5_5_20\":70, \"bullfight_5_5_30\":100,\r\n\"bullfight_6_5_12\":50, \"bullfight_6_5_20\":80, \"bullfight_6_5_30\":120}', `remark`='房卡配置', `create_time`='2017-08-01 11:15:14' WHERE (`id`='10');
UPDATE `d_config` SET `id`='11', `pkey`='channel', `pvalue`='dyj', `remark`='渠道:dyj(大赢家)', `create_time`='2017-08-01 11:15:14' WHERE (`id`='11');

CREATE TABLE `d_consume_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL DEFAULT '0' COMMENT '大局游戏id',
  `update_time` datetime NOT NULL COMMENT '消耗房卡时间',
  `type` varchar(64) NOT NULL DEFAULT '',
  `value` int(11) NOT NULL DEFAULT '0',
  `action` varchar(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for d_consume
-- ----------------------------
CREATE TABLE `d_consume` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `b_gameid` int(11) DEFAULT '0' COMMENT '大局游戏id',
  `roomid` int(11) DEFAULT '0' COMMENT '房间id 可推断出房间类型（1：十三水，3：麻将）',
  `userid` int(11) DEFAULT '0' COMMENT '房卡的消费者id',
  `agentid` int(11) DEFAULT '0' COMMENT '代理用户id',
  `createtime` datetime DEFAULT NULL COMMENT '消耗房卡时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='5', `pkey`='authority_1', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='5');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"cNotice\",\"muserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"100\":[\"cNotice\",\"muserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"80\":[\"operateList\",\"setting\",\"default\"],\"90\":[\"operateList\",\"setting\",\"default\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');

INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('12', 'index_name', '/userManager', '后台首页', '2017-08-12 11:15:14');

--2017.8.19
ALTER TABLE d_club_apply ADD `roomid` INT default 0;  
ALTER TABLE d_club_apply modify column status int comment '申请状态（0：申请提交，1：申请通过 ，-1：驳回,-2：请求已过期，-10：驳回并不接收申请）'; 
CREATE TABLE `d_room` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `roundid` int(11) DEFAULT '0' COMMENT '房间大局ID',
  `clubid` int(11) DEFAULT '0' COMMENT '俱乐部ID',
  `roominfo` text COMMENT '房间信息（json）',
  `addtime` datetime DEFAULT NULL COMMENT '添加时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO d_config VALUES(13, 'share_money', 30, '分享获得钻石', '2017-08-19 15:57:11');

ALTER TABLE `d_user` ADD COLUMN `share_time`  int(11) NULL DEFAULT 0 COMMENT '分享时间' AFTER `__version`;

ALTER TABLE `d_room` ADD COLUMN `starttime`  datetime DEFAULT NULL COMMENT '牌局开始时间' AFTER `roominfo`;
ALTER TABLE `d_room` change `addtime` `endtime` datetime;
ALTER TABLE `d_room` modify column `endtime` datetime comment '牌局结算时间'; 
ALTER TABLE `d_room` ADD COLUMN `scoreinfo` text COMMENT '结算信息（json）' AFTER `roominfo`;
ALTER TABLE `d_room` ADD COLUMN `roomid` int(11) DEFAULT '0' COMMENT '房间id' AFTER `id`;

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='5', `pkey`='authority_1', `pvalue`='{\"1000\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"100\":[\"user_manager\",\"cNotice\",\"wuserList\",\"order\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"80\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"],\"90\":[\"user_manager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='5');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"cNotice\",\"muserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"100\":[\"cNotice\",\"muserList\",\"order\",\"room\",\"point\",\"loginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"80\":[\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"90\":[\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');

CREATE TABLE `d_setlog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bg_userid` int(11) DEFAULT '0' COMMENT '后台操作人id',
  `roomid` int(11) DEFAULT '0' COMMENT '房间ID',
  `roundid` int(11) DEFAULT '0' COMMENT '对局ID',
  `set_uid` int(11) DEFAULT '0' COMMENT '设置的玩家id',
  `addtime` datetime DEFAULT NULL COMMENT '设置时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `d_setlog` modify column `addtime` int(11) DEFAULT '0' COMMENT '设置时间'; 

--2017.08.22
UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"80\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"90\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='5', `pkey`='authority_1', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\"],\"80\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"],\"90\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='5');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"cNotice\",\"muserList\",\"worder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"100\":[\"cNotice\",\"muserList\",\"worder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"80\":[\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"],\"90\":[\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');

--dingding  xzj zhongmin quanc 2017.08.22


ALTER TABLE `d_club_msg` ADD COLUMN `raw_content` varchar(1024) NOT NULL DEFAULT '' COMMENT '未过滤的，原始发送数据' AFTER `content`;

ALTER TABLE `d_user_log` ADD COLUMN `taskid` int(11) DEFAULT '0' COMMENT '关联的任务id（任务执行成功才最终成功）' AFTER `result`;

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"100\":[\"cNotice\",\"wuserList\",\"worder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');


-- all
INSERT INTO `d_config` (`id`, `pkey`, `pvalue`, `remark`, `create_time`) VALUES ('14', 'server_status', '0', '0正常1测试2关闭', '2017-08-30 10:13:05');

ALTER TABLE `d_user` ADD COLUMN `user_test`  int(11) NULL DEFAULT 0 COMMENT '0默认账号1内测账号' AFTER `share_time`;


--dingding zhongmin  2017.09.07

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\",\"default\"],\"80\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\"],\"90\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\",\"default\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='5', `pkey`='authority_1', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"order\",\"room\",\"point\",\"agent\",\"loginlog\",\"operateList\",\"setting\"],\"80\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"],\"90\":[\"userManager\",\"agent\",\"wuserList\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='5');

-- dyj xzj  2017.09.09

CREATE TABLE `d_web_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) DEFAULT '0' COMMENT '用户id',
  `orderid` varchar(50) DEFAULT '' COMMENT 'xzj订单id',
  `money` int(11) DEFAULT '0' COMMENT '添加的钻石数',
  `taskid` int(11) DEFAULT '0' COMMENT '关联的任务id',
  `addtime` datetime DEFAULT NULL COMMENT '添加时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- xzj  2017.09.10

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"1000\":[\"default\",\"cNotice\",\"wuserList\",\"worder\",\"weborder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"100\":[\"cNotice\",\"wuserList\",\"worder\",\"weborder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');
ALTER TABLE `d_web_order` ADD COLUMN `price` double DEFAULT 0 COMMENT 'RMB' AFTER `money`;


-- xzj  2017.09.12

ALTER TABLE `d_consume_log` ADD COLUMN `start_value` int(11) DEFAULT '0' COMMENT '开始数量' AFTER `action`;
ALTER TABLE `d_consume_log` ADD COLUMN `end_value` int(11) DEFAULT '0' COMMENT '结束数量' AFTER `start_value`;
ALTER TABLE `d_consume_log` ADD COLUMN `remark` varchar(200) DEFAULT '' COMMENT '添加钻石备注信息' AFTER `end_value`;

UPDATE `d_config` SET `id`='4', `pkey`='authority_0', `pvalue`='{\"10000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"1000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"100\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='4');
UPDATE `d_config` SET `id`='6', `pkey`='authority_2', `pvalue`='{\"10000\":[\"userManager\",\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"agent\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\"],\"1000\":[\"default\",\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"100\":[\"cNotice\",\"wuserList\",\"worder\",\"consumelog\",\"weborder\",\"room\",\"point\",\"wloginlog\",\"operateList\",\"setting\",\"default\",\"rRoomRecords\",\"setlog\",\"bgorder\",\"agent\"],\"80\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"],\"90\":[\"cmembers\",\"bgorder\",\"operateList\",\"setting\"]}', `remark`='页面权限列表', `create_time`='2017-06-16 01:15:14' WHERE (`id`='6');
