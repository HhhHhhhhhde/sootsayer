import 'dart:math';

import 'package:flutter/material.dart';

/// 本地隐私冷知识，无需网络；打开时随机一条，可点击「换一个」切换。
const List<String> kPrivacyTips = [
  '你知道吗？超过 80% 的 App 会在后台尝试读取你的粘贴板。',
  '💡 小贴士：不常用的 App 建议关闭「精确位置」权限。',
  '公共 Wi‑Fi 下尽量避免登录网银或支付，数据可能被中间人截获。',
  '删除 App 前先在系统设置里检查是否已撤销其敏感权限。',
  '许多免费 App 通过广告 SDK 收集设备指纹，用于跨应用精准投放。',
  '在系统设置中重置或限制「广告标识符」，可减少跨 App 行为追踪。',
  '截图分享前，留意是否包含订单号、地址或聊天记录等敏感信息。',
  '相册「最近删除」仍会暂存一段时间，彻底清理前记得同步清空。',
  '蓝牙长期开启时，部分场景下可能被用于室内定位或邻近追踪。',
  '授予「所有文件访问」前，请确认该 App 是否真的需要全盘读取。',
  '语音助手常处于唤醒监听状态，使用前不妨看一眼厂商隐私政策。',
  '无痕浏览主要不保留本地记录，网络侧仍可能看到你的访问行为。',
  '为重要账号开启两步验证：密码泄露时仍能多一道防线。',
  '快递面单上的姓名、电话、地址，丢弃前建议撕碎或涂抹处理。',
  '社交「签到」与定位动态可能暴露常去地点与作息规律。',
  '不少 App 会读取通讯录做「好友推荐」，不需要时可在设置里关掉。',
  '剪贴板里的密码、验证码，用完尽快清空，避免被恶意 App 读取。',
  '系统「权限使用记录」能帮你发现谁在偷偷访问相机、麦克风等。',
  '若云同步未采用端到端加密，服务商在技术上可能访问你的文件内容。',
  '儿童设备上的家长控制与使用数据，同样属于需要保护的隐私范畴。',
  '扫描来源不明的二维码前多想一想，可能跳转到钓鱼或恶意页面。',
  '招聘类 App 的简历含大量个人信息，注意谁可见、是否对外展示。',
  '健身与跑步 App 的轨迹数据，同样属于敏感的行为与位置信息。',
  '关闭「个性化推荐」往往能减少基于你行为画像的广告与内容推送。',
  '出售二手手机前，务必「恢复出厂」并选择清除全部数据再出手。',
  '部分输入法默认开启云端联想，输入敏感内容时可考虑纯本地模式。',
  '使用 VPN 时若服务商不可信，你的流量反而会被集中看到。',
  '「游客登录」有时仍会收集设备标识，用于统计或风控。',
  '手机丢失后尽快用「查找设备」锁定，并挂失 SIM 与支付账户。',
  '共享屏幕或直播时，注意通知栏是否会弹出短信验证码。',
  '企业办公 App 若启用 MDM，可能具备远程擦除等能力，条款要读清。',
  '健康类 App 的心率、睡眠等数据，在不少地区受专门隐私法规约束。',
  '游戏实名请认准官方渠道，勿在第三方页面随意提交身份证照片。',
  '关闭相册「人物/场景识别」类功能，可减少人脸等生物特征在本地聚类。',
  '短信转发到邮箱或云端时，两步验证码可能经过额外通道，注意风险。',
  '境外 App 的数据可能存储在海外服务器，隐私政策里会写跨境传输。',
  '系统安全更新常修补已知漏洞，长期不更新会放大被攻击面。',
  '遇到权限弹窗别惯性点「允许」，先看清这项权限具体用途再决定。',
  '公共 USB 充电口理论上存在数据窃取风险，优先使用电源插座充电。',
  '「安装未知应用」权限只给真正可信的安装来源，避免恶意包。',
  '智能音箱录下的语音片段，可能被用于改进识别模型，可看是否可关闭上传。',
  '社交软件「已读」与「正在输入」会暴露你的在线与回复节奏。',
  '退出「用户体验改进计划」类选项，通常能减少匿名使用数据上传。',
  '浏览器扩展权限很大，只保留常用且来源可靠的少数几个。',
  '系统「分享」面板里会列出目标 App，注意别误发到公开社交。',
  '照片背景中的门牌、工牌、快递单，放大后往往也能泄露隐私。',
  '部分免费 VPN 通过出售日志或用户带宽盈利，天下没有免费午餐。',
  '智能手表同步到云端的健康数据，同样要用强密码与两步验证保护。',
  '论坛发帖避免写清住址、车牌、真实姓名等可组合识别的信息。',
  '不少 App 提供「下载我的数据」导出，可直观看到收集了哪些字段。',
  '人脸用于支付或门禁时，留意是否可在设置中关闭或仅限本地处理。',
  '主题、字体、夜间模式等偏好有时也会被用来丰富用户画像。',
  '在网吧、打印店等公共电脑切勿勾选「记住我」或保存密码。',
  '「在其他应用上层显示」权限常被滥用为全屏广告，非必要勿开。',
  '关闭「附近的人」「同城」类功能，可减少基于地理位置的社交暴露。',
  '应用锁与系统锁屏密码是两回事，支付与聊天类 App 可单独加锁。',
  '邮件「已读回执」可能在你不知情时向发件人回报打开时间。',
  '清理浏览器 Cookie 与站点数据，可削弱部分跨站追踪能力。',
  '使用「屏幕使用时间」不仅防沉迷，也能发现异常活跃的可疑 App。',
];

class PrivacyTipCard extends StatefulWidget {
  const PrivacyTipCard({super.key});

  @override
  State<PrivacyTipCard> createState() => _PrivacyTipCardState();
}

class _PrivacyTipCardState extends State<PrivacyTipCard> {
  late int _index;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _index = _random.nextInt(kPrivacyTips.length);
  }

  void _pickAnother() {
    if (kPrivacyTips.length <= 1) return;
    setState(() {
      var next = _index;
      var guard = 0;
      while (next == _index && guard < 16) {
        next = _random.nextInt(kPrivacyTips.length);
        guard++;
      }
      _index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.55),
              cs.secondaryContainer.withValues(alpha: 0.45),
              cs.tertiaryContainer.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '隐私冷知识',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                kPrivacyTips[_index],
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickAnother,
                  icon: Icon(
                    Icons.shuffle_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                  label: Text(
                    '换一个',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
